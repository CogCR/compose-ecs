require 'yaml'
require 'erb'

module Spaceape
  module Cloudformation
    class ConfigExpander
      MACRO_REGEX = %r{^__(\w+)__$}
      LAUNCHCONFIG_CFNDSL = "./launchconfig.cfndsl"

      def initialize(config_hash, opts = {})
        shared_config = opts.fetch(:shared_config) { Spaceape::Cloudformation::Generator::SHARED_CONFIG } 
        @region = opts.fetch(:region) { "us-east-1" }
        @config_hash = config_hash
        @shared_config = YAML.load(File.open(shared_config))
        @service = @config_hash["STACK_NAME"] # We know this is set by the Generator class
        @lc_cfndsl = opts.fetch(:launchconfig_cfndsl) { File.join(@service, LAUNCHCONFIG_CFNDSL) }
        @policy_dir = opts.fetch(:policy_dir) { "./iam/policies" }
      end

      # Macros of the form __NAME__ will be processed by checking if
      # a 'name' method exists, and calling it if so.
      # Otherwise we fall back to pulling the region-specific
      # value from the shared config file
      def expand
        @config_hash.each_pair do |k,v|
          next unless String(v).match(MACRO_REGEX)
          makro = $1
          if self.respond_to?(makro.downcase)
            @config_hash[k] = self.send(makro.downcase)
          else
            @config_hash[k] = @shared_config[makro][@region]
          end
        end
        return @config_hash
      end

      def spot_bid
        @shared_config["SPOT_BID"][@config_hash["INSTANCE_TYPE"]]
      end

      def ami
        @shared_config["AMI"][@config_hash["AMI_PROFILE"]][@region]
      end

      def userdata
        File.read(@config_hash["USER_DATA_PATH"])
      end

      # Pull in the per-environment SSL certificate
      def ssl_cert
        @shared_config["SSL_CERT"][@config_hash["ENVIRONMENT"]][@region]
      end

      def launchconfig
        tmpl = File.read(@lc_cfndsl)
        tmpl += gen_iam_policies
        return tmpl
      end

      private

      def gen_iam_policies
        raise "__LAUNCHCONFIG__ requires at least one policy." unless @config_hash["POLICIES"]
        genned_policies = []
        policy_tmpl = %Q[
       Resource("<%= resource_name %>") {
       Type "AWS::IAM::Policy"
       Property("PolicyName", "<%= name %>")
       Property("PolicyDocument", { "Statement" => {
          "Resource" =>  [
    <% resource.each do |r| -%>
            "<%= r %>",
    <% end -%>
           ],
          "Effect" =>  "<%= effect %>",
          "Action" =>  [
    <% perms.each do |p| -%>
            "<%= p %>",
    <% end -%>
      ]
        } 
          } )
   Property("Roles", [ Ref("RootRole") ] )
  }
  ]
        @config_hash["POLICIES"].each do |p|
          name = p
          resource_name = p.split(/_/).map { |x| x.capitalize }.join + "IAMPolicy"
          policy_conf = YAML.load(File.read(File.join(@policy_dir, "#{p}.yml")))
          resource = policy_conf["RESOURCE"]
          effect = policy_conf["EFFECT"]
          perms = policy_conf["PERMS"]
          erb = ERB.new(policy_tmpl, nil, '-')
          genned_policies << erb.result(binding)
        end
        return genned_policies.join("\n")
        rescue Errno::ENOENT => e
          raise "Missing policy file: #{e}"
       end

    end
  end 
end

# compose-ecs [![Build Status](https://api.travis-ci.org/spaceapegames/compose-ecs.svg?branch=master)](https://travis-ci.org/spaceapegames/compose-ecs)
Convert Docker Compose files into AWS ECS Task Definitions


## ComposeECS
You can use the ComposeECS object to convert Docker Compose definitions to ECS Task definitions like so:
```ruby
require 'compose-ecs'

# Create a new ComposeECS object by specifying the task family and passing in the Docker Compose string.
c = ComposeECS.new(family, compose_string)

# The Task Definition can then be extracted as a hash...
full_task_definition_hash = c.to_hash
# ... a JSON object...
full_task_definition_json_object = c.to_json
# ... or a pretty JSON string.
full_task_definition_as_string = c.to_s
```

You must ensure that your Docker Compose definiton specifies `image` and `mem_limit` as both are required by ECS.

ComposeECS currently only supports the key-value syntax for environment variables.
## CLI
The CLI tool allows you to convert Docker Compose definitions to ECS Task definitions as part of a shell operation:

`ecs-compose convert <task_family> <compose_file_path>`

This will return the text of the full ECS Task Definition - volumes and family attribute included.

## Supported Docker Compose Features

ComposeECS currently only supports a subset of the intersection of Docker Compose and ECS Task Definition functionality. We expect this to reach 100% coverage before `v1.0.0`.

| Docker Compose Attribute | Task Definition Attribute | Supported Syntax  | Example                                                      |
|--------------------------|---------------------------|-------------------|--------------------------------------------------------------|
| image                    | image                     | String            | `"redis"`                                                    |
| hostname                 | hostname                  | String            | `"myHost"`                                                   |
| mem_limit                | memory                    | String            | `"100m"` or `"10g"`                                          |
| command                  | command                   | String or Array   | `"redis-server -p 6379"` or `["redis-server", "-p", "6379"]` |
| ports                    | portMappings              | YAML Array[String]| `"8080:8080"`, `"8080:8080/udp"` or `"8080"`                 |
| labels                   | dockerLabels              | YAML KV[String]   | `MYLBL: "ALBL"` (Note: ECS does not allow _'s in the key)    |
| dns                      | dnsServers                | YAML Array[String]| `- "127.0.0.1"`                                              |
| volumes_from             | volumesFrom               | String            | `"myContainer"`                                              |
| environment              | environment               | YAML KV[String]   | `MYVAR: "AVAR"` (Note: ECS does not allow _'s in the key)    |
| links                    | links                     | YAML Array[String]| `- "myContainer"`                                                |

## Contributing

If you'd like to contribute to this project, please raise an issue and indicate that you'd like to take on the work prior to submitting a pull request. Only pull requests with matching issues that explain the motivation behind the change and at least some test coverage will be considered for integration.

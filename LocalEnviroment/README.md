# D2B docker-compose resources for local development environment

This is section is dedicated to docker settings for prepare a local environment, so any developer can use only one docker command and set up all dependencies allowing a more agile developing process.

Allocated in this folder, type the follow command:

    docker-compose up

With the  below command you enabled these service dependencies:

- RabbitMQ (*ports: **5672**, **15672** - service name: **rabbitmq***)
- Redis (*port: **6379** - service name: **redis***)
- DynamoDB (*port: **8010** - service name: **dynamodb***)
- PostgreSQL (*port: **5432** - service name: **postgres***)
- Mongo (*port: **27017** - service name: **mongo***)
- Mongo Express (*port: **8082** - service name: **mongo***)

If you only want to run up an specific service, can type the follow command:

    docker-compose up <service-name>

For **postgres** the initialization script are in the **postgres-scripts** folder, here you can put all of the SQL initialization scripts, including from DDL sentences to DML with initial data.

*Pygmalion - Galatea*
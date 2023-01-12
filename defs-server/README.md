# OGC Definitions Server Docker configuration

This project contains a ready-to-use Docker Compose configuration to run an OGC Definitions Server:

* A Fuseki dataset named `ogc-na` is available.
* A single VocPrez instance is published under `/vocprez` for the `ogc-na` dataset.
* The files for [the OGC NamingAuthority repository](https://github.com/opengeospatial/NamingAuthority)
  is available under /ogc-na, refreshed automatically  every 30 minutes.

## How to add new instances

New datasets and VocPrez instances can be added by editing `docker-compose.yml`. 

* To add a new Fuseki dataset, inside the `fuseki` service, create a new environment variable named
  `FUSEKI_DATASET_XYZ` (where `XYZ` is a unique identifier), and set its value to the name of the new
  Fuseki dataset (e.g. `xyz`).
* To add a new VocPrez instance:

  1. Copy the whole `vocprez` service block and give it a new name (e.g. `vocprez-xyz`).
  2. Update the value of its `SPARQL_ENDPOINT` and `SYSTEM_URI_BASE` environment variables.
  3. Add a new entry in the `nginx` service's `DOCKER_PROXY` environment variable.

* To add a new repository:
  
  1. Add a new, unique `CRON_REPO_xyz` environment variable to the `repos-cron` service.
  2. Add a new entry in the `nginx` service's `DOCKER_PROXY` environment variable.

The just run `docker compose up -d` to apply the changes and recreate the containers. 
There is no need to expose ports on the new VocPrez instance. 

## nginx reverse proxy configuration

nginx configuration is generated automatically from the `DOCKER_PROXY` environment variable for the 
`nginx` service. Its value should be a JSON array of objects that have one of these formats:

  * `location` and `repo` for git repositories
  * `location`, `service` and `port` for services.
    * An optional `upstreamLocation` property can be defined that will be used for the local path of the
      `proxy_pass` directive (the same value passed in `location` will be used by default).
    * An optional `headers` object can be added which will be translated to HTTP request headers.
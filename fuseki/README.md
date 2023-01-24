# Fuseki Docker image

This image can be used to deploy Fuseki containers.

Based on [stain/jena-docker](https://github.com/stain/jena-docker).

## Running

```shell
docker run -p 3030:3030 dockerogc/fuseki
```

**Container data is not persisted by default**. If persistence is necessary,
it can be done by binding a volume to `/fuseki`:

```shell
docker run -p 3030:3030 -v $(pwd)/fuseki-data:/fuseki dockerogc/fuseki
```

## Environment variables

### Runtime

| Variable         | Default value  | Description                                                                                                     |
|------------------|----------------|-----------------------------------------------------------------------------------------------------------------|
| `ADMIN_PASSWORD` | `"admin"`      | Password for Fuseki admin UI. If no password is provided, a random one will be generated and printed on startup |

#### Datasets

For convenience the container can create TDB2 datasets (if they do not already exist) on startup.
These datasets will have their `tdb2:unionDefaultGraph` set to `true`.

Dataset creation is controlled by using environment variables in the `FUSEKI_DATASET_MY_DATASET=my_dataset` form,
where only the variable value matters; the previous example would create a `my_dataset` TDB2 dataset on startup
if one does not exist.

Additionally, for every `FUSEKI_DATASET_MY_DATASET` variable, the following two variables can be defined:

* `FUSEKI_INITIAL_DATA_MY_DATASET`, with a file (or glob) to load initial data from.
* `FUSEKI_INITIAL_GRAPH_MY_DATASET` with the IRI of the graph where initial data will be loaded.

For example, the following defines an `ogc-na` repository with initial data loaded onto the
`urn:x-ogc:defs-server/initial-data` graph (of course, the /initial-data directory needs to be
mounted on the container):

```shell
FUSEKI_DATASET_OGC_NA=ogc-na
FUSEKI_INITIAL_DATA_OGC_NA="/initial-data/*.ttl"
FUSEKI_INITIAL_GRAPH_OGC_NA="<urn:x-ogc:defs-server/initial-data>"
```

**Note**: The writable endpoints (SPARQL/Update, Graph Store RW) for all datasets created in this manner are restricted
to the admin user by default.

### Building Docker images

| Variable         | Default value  | Description                   |
|------------------|----------------|-------------------------------|
| `FUSEKI_VERSION` | `"4.6.1"`      | Fuseki version to deploy      |
| `FUSEKI_SHA512`  | `"12a7c24..."` | SHA512 sum for Fuseki package |
| `FUSEKI_BASE`    | `/fuseki`      | Fuseki base (data) directory  |
| `FUSEKI_HOME`    | `/jena-fuseki` | Fuseki application directory  |

## Exposed ports

* 3030: Fuseki HTTP interface
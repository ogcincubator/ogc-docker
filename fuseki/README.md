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

For convenience the container can create datasets (if they do not already exist) on startup.
These datasets will have their `tdb2:unionDefaultGraph` set to `true`.

Dataset creation is controlled by using environment variables in the `FUSEKI_DATASET_MY_DATASET=my_dataset` form,
where only the variable value matters; the previous example would create a `my_dataset` dataset on startup
if one does not exist.

### Building Docker images

| Variable         | Default value  | Description                   |
|------------------|----------------|-------------------------------|
| `FUSEKI_VERSION` | `"4.6.1"`      | Fuseki version to deploy      |
| `FUSEKI_SHA512`  | `"12a7c24..."` | SHA512 sum for Fuseki package |
| `FUSEKI_BASE`    | `/fuseki`      | Fuseki base (data) directory  |
| `FUSEKI_HOME`    | `/jena-fuseki` | Fuseki application directory  |

## Exposed ports

* 3030: Fuseki HTTP interface
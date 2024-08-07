# Mongo-Initializr

Docker image for building MongoDB databases using the `Mongo-Initializr` scripts.

## Docker image

By default the database is initialized on startup of the container using the [docker-entrypoint.sh](docker/docker-entrypoint.sh) script. The behavior of this script can be customized based on the `MI_*`-variables.

### Variables

* `MI_DATABASE_USERNAME`, `MI_DATABASE_PASSWORD`: Username and password used for initializing and building the database. If set an admin user is created in the `admin` database.
* `MI_INPUT_FILE`: The file which contains a list of dbdata-files and the corresponding database collection. If set the build and sync are executed.
* `MI_NEXUS_BASE_URL`, `MI_NEXUS_REPOSITORY`: The base-url and nexus repository where the dbdata-files are located.
* `MI_DATABASE_NAME`: The name of the database to initialize. If set all the `MI_INPUT_FILE`-files are added to the database.
* `MI_DATABASE_VERSION`: The version of the database, which will be added to the database constants. 
* `MI_RUN_SCRIPT_FOLDER`: The folder there the `_run.js` file is located. If *not* set, the runner wil *not* be executed.
* `MI_BIN_FOLDER`: The folder where the Mongo-Initializr scripts are located.
* `MI_SOURCE_FOLDER`: The folder where the database sources are located.
* `MI_DBDATA_FOLDER`: The folder where the dbdata-files are located.
* `MI_SKIP_DBDATA_SYNC`: Set to `true` if the dbdata sync should be skipped.
* `MI_SKIP_BIN_FOLDER_CLEANUP`: Set to `true` if the bin-folder should be kept.
* `MI_SKIP_SOURCE_FOLDER_CLEANUP`: Set to `true` if the source-folder should be kept.
* `MI_SKIP_DBDATA_FOLDER_CLEANUP`: Set to `true` if the dbdata-folder should be kept.
* `MI_SKIP_UNSET_ENVS`: Set to `true` if all the `MI_*` environment variables should be kept after the `docker-entrypoint.sh` entrypoint script is runned.
* `HTTPS_DATA_USERNAME`, `HTTPS_DATA_PASSWORD`: The username and password of the nexus repository used for syncing the dbdata-files.

### Examples of how to use the aerius-mongo-initializr image

Initialize the example-project database using a Docker run.
``` bash
docker run \
	--name example-project \
	-v /projects/example-project/git/example-project/:/source \
	-e MI_INPUT_FILE="/source/example-project/src/data/initdb.json" \
	-e MI_RUN_SCRIPT_FOLDER="/source/example-project/src/main" \
	-e MI_DATABASE_NAME=example \
	-e MI_DATABASE_VERSION=0.0.1 \
	-e MI_NEXUS_BASE_URL=https://nexus.aerius.nl \
	-e MI_NEXUS_REPOSITORY=dbdata \
	-e HTTPS_DATA_USERNAME=${HTTPS_DATA_USERNAME} \
	-e HTTPS_DATA_PASSWORD=${HTTPS_DATA_PASSWORD} \
	aerius-mongo-initializr:0.1-SNAPSHOT-7.0.6
```

<br>

Example-project-database with local dbdata files using a Docker run.
``` bash
docker run \
	--name example-project \
	-v /projects/example-project/git/example-project/:/source \
	-v /projects/example-project/dbdata/:/dbdata \
	-e MI_INPUT_FILE="/source/example-project/src/data/initdb.json" \
	-e MI_RUN_SCRIPT_FOLDER="/source/example-project/src/main" \
	-e MI_DATABASE_NAME=example \
	-e MI_DATABASE_VERSION=0.0.1 \
	-e MI_SKIP_DBDATA_SYNC=true \
	aerius-mongo-initializr:0.1-SNAPSHOT-7.0.6
```

<br>

Example-project Dockerfile where a default `MI_INPUT_FILE` and `MI_RUN_SCRIPT_FOLDER` value is specified, the database source is copied and the `Mongo-Initializr` is executed to initialize the database during the Docker build fase.
```bash
FROM aerius-mongo-initializr:0.1-SNAPSHOT-7.0.6

ARG MI_DATABASE_NAME
ARG MI_DATABASE_USERNAME
ARG MI_DATABASE_PASSWORD
ARG MI_DATABASE_VERSION
ARG MI_INPUT_FILE
ARG MI_RUN_SCRIPT_FOLDER
ARG MI_NEXUS_BASE_URL
ARG MI_NEXUS_REPOSITORY
ARG MI_BIN_FOLDER
ARG MI_SOURCE_FOLDER
ARG MI_DBDATA_FOLDER
ARG MI_SKIP_DBDATA_SYNC
ARG MI_SKIP_BIN_FOLDER_CLEANUP
ARG MI_SKIP_SOURCE_FOLDER_CLEANUP
ARG MI_SKIP_DBDATA_FOLDER_CLEANUP
ARG MI_SKIP_UNSET_ENVS
ARG HTTPS_DATA_USERNAME
ARG HTTPS_DATA_PASSWORD

ENV MI_INPUT_FILE=${MI_INPUT_FILE:-"/source/example-project/src/data/initdb.json"} \
    MI_RUN_SCRIPT_FOLDER=${MI_RUN_SCRIPT_FOLDER:-"/source/example-project/src/main"}

COPY ./source ${MI_SOURCE_FOLDER}

RUN /mongo-initializr.sh
```

## Image build

There are two scripts for building the Docker images.
* `update.sh` Creates the Dockerfile files for the specified Mongo versions.
* `build_images.sh` Builds all generated Dockerfile files.

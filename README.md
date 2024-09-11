# Mongo-Initializr

Docker image for building MongoDB databases using the `Mongo-Initializr` scripts.

## Docker image

By default the database is initialized on startup of the container using the Docker [ENTRYPOINT](docker/docker-entrypoint.sh) which is executing the [Mongo-Initializr](docker/mongo-initializr.sh) script. The behavior of this script can be customized based on the `MI_*`-variables.

### Variables

* `MONGO_INITDB_ROOT_USERNAME`, `MONGO_INITDB_ROOT_PASSWORD`: Username and password used for initializing and building the database (both default set to aerius).
* `MONGO_INITDB_DATABASE`: The name of the database to initialize (default set to mongo).
* `MI_INPUT_FILE`: The file which contains a list of dbdata-files and the corresponding database collection. If set the build and sync are executed.
* `MI_NEXUS_BASE_URL`, `MI_NEXUS_REPOSITORY`: The base-url and nexus repository where the dbdata-files are located.
* `MI_DATABASE_VERSION`: The version of the database, which will be added to the database constants. 
* `MI_RUN_SCRIPT_FOLDER`: The folder there the `_run.js` file is located. If *not* set, the runner wil *not* be executed.
* `MI_DUMP_DATABASE`: Set to `true` if a (gzipped) binary export of the database needs to be created.
* `MI_INITIALIZE_ON_BUILD`: Set to `true` if the database is going to be initialized during the Docker image build. You need to add `RUN /usr/local/bin/docker-entrypoint.sh mongod` to you `Dockerfile` in order to start the initialization during the Docker build. 
* `MI_SKIP_DBDATA_SYNC`: Set to `true` if the dbdata sync should be skipped.
* `MI_SKIP_UNSET_ENVS`: Set to `true` if all the `MI_*` environment variables should be kept after the `docker-entrypoint.sh` entrypoint script is runned.
* `MI_BIN_FOLDER_CLEANUP`: Set to `true` if the bin-folder should be removed.
* `MI_SOURCE_FOLDER_CLEANUP`: Set to `true` if the source-folder should be removed.
* `MI_DBDATA_FOLDER_CLEANUP`: Set to `true` if the dbdata-folder should be removed.
* `HTTPS_DATA_USERNAME`, `HTTPS_DATA_PASSWORD`: The username and password of the nexus repository used for syncing the dbdata-files.

### (Docker) Folders
* `MI_BIN_FOLDER` (`/mi/bin`): Folder where you can find the `Mongo-Initializr` scripts.
* `MI_SOURCE_FOLDER` (`/mi/source`): Folder for the database source code.
* `MI_DBDATA_FOLDER` (`/mi/dbdata`): Folder for all dbdata files.
* `MI_DUMP_FOLDER` (`/mi/dump`): Folder for all database dumps. All dumps in this folder will be restored by the [Mongo-Initializr](docker/mongo-initializr.sh) script.

### Examples of how to use the aerius-mongo-initializr image

Initialize the example-project database using a Docker run.
``` bash
docker run \
	--name example-project \
	--volume /projects/example-project/git/example-project/source/:/mi/source \
	--env MI_INPUT_FILE="/mi/source/example-project/src/data/initdb.json" \
	--env MI_RUN_SCRIPT_FOLDER="/mi/source/example-project/src/main" \
	--env MONGO_INITDB_DATABASE=example \
	--env MI_DATABASE_VERSION=0.0.1 \
	--env MI_NEXUS_BASE_URL=https://nexus.example-project.nl \
	--env MI_NEXUS_REPOSITORY=dbdata \
	--env HTTPS_DATA_USERNAME=${HTTPS_DATA_USERNAME} \
	--env HTTPS_DATA_PASSWORD=${HTTPS_DATA_PASSWORD} \
	aerius-mongo-initializr:0.1-SNAPSHOT-7.0.6
```

<br>

Example-project-database with local dbdata files using a Docker run.
``` bash
docker run \
	--name example-project \
	--volume /projects/example-project/git/example-project/source/:/mi/source \
	--volume /projects/example-project/dbdata/:/mi/dbdata \
	--env MI_INPUT_FILE="/mi/source/example-project/src/data/initdb.json" \
	--env MI_RUN_SCRIPT_FOLDER="/mi/source/example-project/src/main" \
	--env MONGO_INITDB_DATABASE=example \
	--env MI_DATABASE_VERSION=0.0.1 \
	--env MI_SKIP_DBDATA_SYNC=true \
	aerius-mongo-initializr:0.1-SNAPSHOT-7.0.6
```

<br>

Dockerfile for initializing the database during the Docker build.
```bash
#syntax = docker/dockerfile:1
FROM aerius-mongo-initializr:0.1-SNAPSHOT-7.0.6 

ARG MONGO_INITDB_DATABASE
ARG MONGO_INITDB_ROOT_USERNAME
ARG MONGO_INITDB_ROOT_PASSWORD
ARG MI_DATABASE_VERSION
ARG MI_INPUT_FILE=${MI_INPUT_FILE:-"/mi/source/database-depositions/src/data/initdb.json"}
ARG MI_RUN_SCRIPT_FOLDER=${MI_RUN_SCRIPT_FOLDER:-"/mi/source/database-depositions/src/main"}
ARG MI_DUMP_DATABASE
ARG MI_INITIALIZE_ON_BUILD=true
ARG MI_NEXUS_BASE_URL
ARG MI_NEXUS_REPOSITORY
ARG MI_SKIP_DBDATA_SYNC
ARG MI_SKIP_BIN_FOLDER_CLEANUP
ARG MI_SKIP_SOURCE_FOLDER_CLEANUP
ARG MI_SKIP_DBDATA_FOLDER_CLEANUP
ARG MI_SKIP_UNSET_ENVS
ARG HTTPS_DATA_USERNAME
ARG HTTPS_DATA_PASSWORD

# Copy all necessary scripts
COPY ./source /mi/source

# Run the docker-entrypoint in order to initialize the database
RUN /usr/local/bin/docker-entrypoint.sh mongod
```

## Image build

There are two scripts for building the Docker images.
* [`update.sh`](update.sh) - Creates the Dockerfile files for the specified Mongo versions.
* [`build_images.sh`](build_images.sh) - Builds all generated Dockerfile files.

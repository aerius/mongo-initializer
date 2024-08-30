# Mongo-Initializr

Docker image for building MongoDB databases using the `Mongo-Initializr` scripts.

## Docker image

The database is initialized on startup of the container using the Docker [ENTRYPOINT](docker/docker-entrypoint.sh) which is executing the [Mongo-Initializr](docker/mongo-initializr.sh) script. The behavior of this script can be customized based on the `MI_*`-variables.

### Variables

* `MONGO_INITDB_ROOT_USERNAME`, `MONGO_INITDB_ROOT_PASSWORD`: Username and password used for initializing and building the database (both default set to aerius).
* `MONGO_INITDB_DATABASE`: The name of the database to initialize (default set to mongo).
* `MI_INPUT_FILE`: The file which contains a list of dbdata-files and the corresponding database collection. If set the build and sync are executed.
* `MI_NEXUS_BASE_URL`, `MI_NEXUS_REPOSITORY`: The base-url and nexus repository where the dbdata-files are located.
* `MI_DATABASE_VERSION`: The version of the database, which will be added to the database constants. 
* `MI_RUN_SCRIPT_FOLDER`: The folder there the `_run.js` file is located. If *not* set, the runner wil *not* be executed.
* `MI_SKIP_DBDATA_SYNC`: Set to `true` if the dbdata sync should be skipped.
* `MI_SKIP_UNSET_ENVS`: Set to `true` if all the `MI_*` environment variables should be kept after the `docker-entrypoint.sh` entrypoint script is runned.
* `MI_BIN_FOLDER_CLEANUP`: Set to `true` if the bin-folder should be removed.
* `MI_SOURCE_FOLDER_CLEANUP`: Set to `true` if the source-folder should be removed.
* `MI_DBDATA_FOLDER_CLEANUP`: Set to `true` if the dbdata-folder should be removed.
* `HTTPS_DATA_USERNAME`, `HTTPS_DATA_PASSWORD`: The username and password of the nexus repository used for syncing the dbdata-files.


### Examples of how to use the aerius-mongo-initializr image

Initialize the example-project database using a Docker run.
``` bash
docker run \
	--name example-project \
	-v /projects/example-project/git/example-project/:/mi/source \
	-e MI_INPUT_FILE="/mi/source/example-project/src/data/initdb.json" \
	-e MI_RUN_SCRIPT_FOLDER="/mi/source/example-project/src/main" \
	-e MONGO_INITDB_DATABASE=example \
	-e MI_DATABASE_VERSION=0.0.1 \
	-e MI_NEXUS_BASE_URL=https://nexus.example-project.nl \
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
	-v /projects/example-project/git/example-project/:/mi/source \
	-v /projects/example-project/dbdata/:/mi/dbdata \
	-e MI_INPUT_FILE="/mi/source/example-project/src/data/initdb.json" \
	-e MI_RUN_SCRIPT_FOLDER="/mi/source/example-project/src/main" \
	-e MONGO_INITDB_DATABASE=example \
	-e MI_DATABASE_VERSION=0.0.1 \
	-e MI_SKIP_DBDATA_SYNC=true \
	aerius-mongo-initializr:0.1-SNAPSHOT-7.0.6
```

## Image build

There are two scripts for building the Docker images.
* [`update.sh`](update.sh) - Creates the Dockerfile files for the specified Mongo versions.
* [`build_images.sh`](build_images.sh) - Builds all generated Dockerfile files.

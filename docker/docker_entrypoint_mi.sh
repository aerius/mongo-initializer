#!/usr/bin/env bash

# Exit on error
set -e

: ${MI_BIN_FOLDER?'MI_BIN_FOLDER must be provided'}

#################
### Functions ###
#################

_log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] $@${COLOR_OFF}"
}

init_database() {
  : ${MI_DATABASE_USERNAME?'MI_DATABASE_USERNAME must be provided'}
  : ${MI_DATABASE_PASSWORD?'MI_DATABASE_PASSWORD must be provided'}

  _log "Start mongod"
  mongod \
    --quiet \
    --fork \
    --logpath /var/log/mongodb.log \
    --dbpath /data/db/ \
    --bind_ip_all

  # Wait until mongod is up
  until mongosh --eval "db.adminCommand('ping')" >/dev/null 2>&1; do
    sleep 0.5s
  done

  # Create the AERIUS user in admin database
  # Add void to supress the --eval output
  _log "Create user '$MI_DATABASE_USERNAME'"
  mongosh admin --quiet --eval " \
    void \
    db.createUser({ \
      user: '$MI_DATABASE_USERNAME', \
      pwd: '$MI_DATABASE_PASSWORD', \
      roles: [{ role: 'root', db: 'admin' }] \
    })"
}

sync_dbdata() {
  : ${MI_INPUT_FILE?'MI_INPUT_FILE must be provided'}
  : ${MI_DBDATA_FOLDER?'MI_DBDATA_FOLDER must be provided'}
  : ${MI_NEXUS_BASE_URL?'MI_NEXUS_BASE_URL must be provided'}
  : ${MI_NEXUS_REPOSITORY?'MI_NEXUS_REPOSITORY must be provided'}
  : ${HTTPS_DATA_USERNAME?'HTTPS_DATA_USERNAME must be provided'}
  : ${HTTPS_DATA_PASSWORD?'HTTPS_DATA_PASSWORD must be provided'}

  # Sync dbdata
  _log "Sync mongo dbdata"
  "$MI_BIN_FOLDER/mi-sync.sh" \
    --input-file "${MI_INPUT_FILE}" \
    --data-folder "${MI_DBDATA_FOLDER}" \
    --nexus-url "${MI_NEXUS_BASE_URL}" \
    --nexus-repo "${MI_NEXUS_REPOSITORY}" \
    --nexus-username "${HTTPS_DATA_USERNAME}" \
    --nexus-password "${HTTPS_DATA_PASSWORD}"
}

add_dbdata() {
  : ${MI_INPUT_FILE?'MI_INPUT_FILE must be provided'}
  : ${MI_DBDATA_FOLDER?'MI_DBDATA_FOLDER must be provided'}
  : ${MI_DATABASE_USERNAME?'MI_DATABASE_USERNAME must be provided'}
  : ${MI_DATABASE_PASSWORD?'MI_DATABASE_PASSWORD must be provided'}
  : ${MI_DATABASE_NAME?'MI_DATABASE_NAME must be provided'}
  : ${MI_DATABASE_VERSION?'MI_DATABASE_VERSION must be provided'}

  # Build database
  _log "Build mongo database"
  "$MI_BIN_FOLDER/mi-build.sh" \
    --input-file "${MI_INPUT_FILE}" \
    --data-folder "${MI_DBDATA_FOLDER}" \
    --mongo-username "${MI_DATABASE_USERNAME}" \
    --mongo-password "${MI_DATABASE_PASSWORD}" \
    --database-name "${MI_DATABASE_NAME}" \
    --database-version "${MI_DATABASE_VERSION}"
}

run_script_runner() {
  : ${MI_DATABASE_USERNAME?'MI_DATABASE_USERNAME must be provided'}
  : ${MI_DATABASE_PASSWORD?'MI_DATABASE_PASSWORD must be provided'}
  : ${MI_DATABASE_NAME?'MI_DATABASE_NAME must be provided'}
  : ${MI_RUN_SCRIPT_FOLDER?'MI_RUN_SCRIPT_FOLDER must be provided'}

  # Run shell script runner
  _log "Start mogno shell script runner"
  "$MI_BIN_FOLDER/mi-runner.sh" \
    --mongo-username "${MI_DATABASE_USERNAME}" \
    --mongo-password "${MI_DATABASE_PASSWORD}" \
    --database-name "${MI_DATABASE_NAME}" \
    --run-folder "${MI_RUN_SCRIPT_FOLDER}"
}

_clean_folder() {
  local folder_path=$1
  local skip=$2

  if [ "$skip" = "true" ]; then
    _log "Skip deleting folder '$folder_path'"
  else
    if [ -d "$folder_path" ]; then
      rm -rf "$folder_path"
      _log "Folder '$folder_path' deleted"
    else
      _log "Folder '$folder_path' does not exists and therefore cannot be deleted."
    fi
  fi
}

cleanup() {
  _log "Cleanup image"

  _clean_folder $MI_BIN_FOLDER $MI_SKIP_BIN_FOLDER_CLEANUP
  _clean_folder $MI_SOURCE_FOLDER $MI_SKIP_SOURCE_FOLDER_CLEANUP
  _clean_folder $MI_DBDATA_FOLDER $MI_SKIP_DBDATA_FOLDER_CLEANUP
  
  if [ "$MI_SKIP_UNSET_ENVS" = "true" ]; then
    _log "Skip unsetting all MI-variables"
  else
    for var in $(env | grep '^MI_' | sort | awk -F= '{print $1}'); do
      _log "Unset variable '$var'"
      unset "$var"
    done
  fi
}


#####################
### The real deal ###
#####################

# Check if init and build are desired
if [ -n "$MI_DATABASE_USERNAME" ] && [ -n "$MI_DATABASE_PASSWORD" ]; then
  
  # Init database
  init_database
  
  if [ -n "$MI_INPUT_FILE" ]; then

    # Sync dbdata
    if [ "$MI_SKIP_DBDATA_SYNC" = true ]; then
      _log "MI_SKIP_DBDATA_SYNC is set to true. No dbdata sync is desired."
    else
      sync_dbdata
    fi

    # Add dbdata
    if [ -n "$MI_DATABASE_NAME" ]; then
      add_dbdata
    else
      _log "MI_DATABASE_NAME is not set. Probably no dbdata add is desired."
    fi

  else
    _log "MI_INPUT_FILE is not set. Probably no dbdata sync and build is desired."
  fi

  # Run script runner
  if [ -n "$MI_RUN_SCRIPT_FOLDER" ]; then
      run_script_runner
  else
    _log "MI_RUN_SCRIPT_FOLDER is not set. Probably no script runner run is desired."
  fi
  
else
  _log "MI_DATABASE_USERNAME or MI_DATABASE_PASSWORD is not set. Probably no init and build is desired."
fi

# Cleanup folders and ENV'S
cleanup

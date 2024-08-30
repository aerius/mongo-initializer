#!/usr/bin/env bash

# Exit on error
set -e

: ${MI_BIN_FOLDER?'MI_BIN_FOLDER must be provided'}

#################
### Functions ###
#################

_log() {
    echo -e "\033[0;32m[$(date '+%Y-%m-%d %H:%M:%S')] $@\033[0m"
}

sync_dbdata() {
  : ${MI_INPUT_FILE?'MI_INPUT_FILE must be provided'}
  : ${MI_DBDATA_FOLDER?'MI_DBDATA_FOLDER must be provided'}
  : ${MI_NEXUS_BASE_URL?'MI_NEXUS_BASE_URL must be provided'}
  : ${MI_NEXUS_REPOSITORY?'MI_NEXUS_REPOSITORY must be provided'}
  : ${HTTPS_DATA_USERNAME?'HTTPS_DATA_USERNAME must be provided'}
  : ${HTTPS_DATA_PASSWORD?'HTTPS_DATA_PASSWORD must be provided'}

  # Sync dbdata
  _log "Sync dbdata files"
  "${MI_BIN_FOLDER}/mi-dbdata-sync.sh" \
    --input-file "${MI_INPUT_FILE}" \
    --data-folder "${MI_DBDATA_FOLDER}" \
    --nexus-url "${MI_NEXUS_BASE_URL}" \
    --nexus-repo "${MI_NEXUS_REPOSITORY}" \
    --nexus-username "${HTTPS_DATA_USERNAME}" \
    --nexus-password "${HTTPS_DATA_PASSWORD}"
}

import_dbdata() {
  : ${MI_INPUT_FILE?'MI_INPUT_FILE must be provided'}
  : ${MI_DBDATA_FOLDER?'MI_DBDATA_FOLDER must be provided'}
  : ${MONGO_INITDB_ROOT_USERNAME?'MONGO_INITDB_ROOT_USERNAME must be provided'}
  : ${MONGO_INITDB_ROOT_PASSWORD?'MONGO_INITDB_ROOT_PASSWORD must be provided'}
  : ${MONGO_INITDB_DATABASE?'MONGO_INITDB_DATABASE must be provided'}
  : ${MI_DATABASE_VERSION?'MI_DATABASE_VERSION must be provided'}

  # Build database
  _log "Import dbdata files"
  "${MI_BIN_FOLDER}/mi-dbdata-import.sh" \
    --input-file "${MI_INPUT_FILE}" \
    --data-folder "${MI_DBDATA_FOLDER}" \
    --mongo-username "${MONGO_INITDB_ROOT_USERNAME}" \
    --mongo-password "${MONGO_INITDB_ROOT_PASSWORD}" \
    --database-name "${MONGO_INITDB_DATABASE}" \
    --database-version "${MI_DATABASE_VERSION}"
}

run_script_runner() {
  : ${MONGO_INITDB_ROOT_USERNAME?'MONGO_INITDB_ROOT_USERNAME must be provided'}
  : ${MONGO_INITDB_ROOT_PASSWORD?'MONGO_INITDB_ROOT_PASSWORD must be provided'}
  : ${MONGO_INITDB_DATABASE?'MONGO_INITDB_DATABASE must be provided'}
  : ${MI_RUN_SCRIPT_FOLDER?'MI_RUN_SCRIPT_FOLDER must be provided'}

  # Run shell script runner
  _log "Start mongo shell script runner"
  "${MI_BIN_FOLDER}/mi-runner.sh" \
    --mongo-username "${MONGO_INITDB_ROOT_USERNAME}" \
    --mongo-password "${MONGO_INITDB_ROOT_PASSWORD}" \
    --database-name "${MONGO_INITDB_DATABASE}" \
    --run-folder "${MI_RUN_SCRIPT_FOLDER}"
}

_clean_folder() {
  local folder_path=${1}
  local cleanup=${2}

  if [[ "${cleanup}" == "true" ]]; then
    if [[ -d "${folder_path}" ]]; then
      rm -rf "${folder_path}"
      _log "Folder '${folder_path}' deleted"
    else
      _log "Folder '${folder_path}' does not exists and therefore cannot be deleted."
    fi
  else
    _log "Keep folder '${folder_path}'"
  fi
}

cleanup() {
  _log "Cleanup image"

  _clean_folder ${MI_BIN_FOLDER} ${MI_BIN_FOLDER_CLEANUP}
  _clean_folder ${MI_SOURCE_FOLDER} ${MI_SOURCE_FOLDER_CLEANUP}
  _clean_folder ${MI_DBDATA_FOLDER} ${MI_DBDATA_FOLDER_CLEANUP}
  
  if [[ "${MI_SKIP_UNSET_ENVS}" == "true" ]]; then
    _log "Skip unsetting all MI-variables"
  else
    while read mi_env_line; do
      local var="${mi_env_line%%=*}"
      _log "Unset variable '$var'"
      unset "${var}"
    done < <(env | grep '^MI_')
  fi
}


#####################
### The real deal ###
#####################

# Check if init and build are desired
if [[ -n "${MONGO_INITDB_ROOT_USERNAME}" ]] && [[ -n "${MONGO_INITDB_ROOT_PASSWORD}" ]]; then
  
  if [[ -n "${MI_INPUT_FILE}" ]]; then

    # Sync dbdata
    if [[ "${MI_SKIP_DBDATA_SYNC}" == true ]]; then
      _log "MI_SKIP_DBDATA_SYNC is set to true. No dbdata sync is desired."
    else
      sync_dbdata
    fi

    # Add dbdata
    if [[ -n "${MONGO_INITDB_DATABASE}" ]]; then
      import_dbdata
    else
      _log "MONGO_INITDB_DATABASE is not set. Probably no dbdata add is desired."
    fi

  else
    _log "MI_INPUT_FILE is not set. Probably no dbdata sync and build is desired."
  fi

  # Run script runner
  if [[ -n "${MI_RUN_SCRIPT_FOLDER}" ]]; then
      run_script_runner
  else
    _log "MI_RUN_SCRIPT_FOLDER is not set. Probably no script runner run is desired."
  fi
  
else
  _log "MONGO_INITDB_ROOT_USERNAME or MONGO_INITDB_ROOT_PASSWORD is not set. Probably no init and build is desired."
fi

# Cleanup folders and ENV'S
cleanup


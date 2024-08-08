#!/usr/bin/env bash

# Exit on error
set -e

# Default values
DEFAULT_RUN_FOLDER="/runner"
DEFAULT_MONGO_HOST="localhost"
DEFAULT_MONGO_PORT="27017"

RUN_FOLDER="${DEFAULT_RUN_FOLDER}"
MONGO_HOST="${DEFAULT_MONGO_HOST}"
MONGO_PORT="${DEFAULT_MONGO_PORT}"
MONGO_USER=""
MONGO_PASS=""
DATABASE_NAME=""


SCRIPT_PATH=$(readlink -f "${0}")
SCRIPT_DIR=$(dirname "${SCRIPT_PATH}")


RUN_FILE="_run.js"


# Include functions
source "${SCRIPT_DIR}/include.functions.sh"


# Function to display the banner
display_banner() {
    _log "------------------------------------------"
    _log "- Mongo-Initializr - Shell script runner  "
    _log "------------------------------------------"
    _log
}

# Function to display script usage
display_help() {
    _log
    _log "Usage: $(basename -- $0) [OPTIONS]"
    _log "Options:"
    _log "  -r, --run-folder [arg]        Specify run folder (default: ${DEFAULT_RUN_FOLDER})"
    _log
    _log "      --mongo-hostname [arg]    Specify MongoDB hostname (default: ${DEFAULT_MONGO_HOST})"
    _log "      --mongo-port [arg]        Specify MongoDB port (default: ${DEFAULT_MONGO_PORT})"
    _log "      --mongo-username [arg]    Specify MongoDB username"
    _log "      --mongo-password [arg]    Specify MongoDB password"
    _log
    _log "      --database-name [arg]     Specify database name"
    _log
    _log "  -h, --help                    Display this help message"
    exit 1
}

# Function to parse command line arguments
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case "${1}" in
            -r|--run-folder)
                RUN_FOLDER="$2"
                shift 2
                ;;
            --mongo-host)
                MONGO_HOST="$2"
                shift 2
                ;;
            --mongo-port)
                MONGO_PORT="$2"
                shift 2
                ;;
            --mongo-username)
                MONGO_USER="$2"
                MONGO_NOAUTH=false
                shift 2
                ;;
            --mongo-password)
                MONGO_PASS="$2"
                shift 2
                ;;
            --database-name)
                DATABASE_NAME="$2"
                shift 2
                ;;
            -h|--help)
                display_help
                ;;
            *)
                _log "Unknown option: ${1}"
                display_help
                ;;
        esac
    done
}

# Function for validating the command line arguments
validate_arguments() {
    # Check if all mongo settings are set
    if [[ -z "${MONGO_USER}" ]] || [[ -z "${MONGO_PASS}" ]]; then
        _log "Error: Mongo credentials are required."
        display_help
    fi

    # Check if database-version is set
    if [[ -z "${DATABASE_NAME}" ]]; then
        _log "Error: Database name is required."
        display_help
    fi

    # Check if rin-file exists
    if [[ ! -e "${RUN_FOLDER}/${RUN_FILE}" ]]; then
        _log "Error: Could not find '${RUN_FILE}' in '${RUN_FOLDER}'."
        display_help
    fi
}

# Function for starting the shell script runner
start_runner() {
    pushd "${RUN_FOLDER}"
    _mongosh --file "_run.js"
    popd
}


# Main script logic
display_banner

parse_arguments "$@"

validate_arguments

_log "Start runner"
start_runner

_log "Done!"

#!/usr/bin/env bash

# Exit on error
set -e

# Echo output colors
GREEN='\033[0;32m'
COLOR_OFF='\033[0m'

# Method to displaying messages
_log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] $@${COLOR_OFF}"
}

# Helper function to call mongoimport
_mongoimport() { 
    mongoimport --uri "mongodb://$MONGO_HOST:$MONGO_PORT/$DATABASE_NAME" --username $MONGO_USER --password $MONGO_PASS --authenticationDatabase admin $@
}

# Helper function to call mongosh
_mongosh() {
    mongosh "$MONGO_HOST:$MONGO_PORT/$DATABASE_NAME" --username $MONGO_USER --password $MONGO_PASS --authenticationDatabase admin $@
}

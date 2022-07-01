#!/bin/bash
#
# sync-from-storage.sh
#
# This script uses azcopy to sync all containers from an Azure Storage Account
#
# Usage:
# ./sync-from-storage.sh <storage-account-name> <destination-directory-path>
# ./sync-from-storage.sh "mystorageaccount" "/sync-from-mystorageaccount"

info_log() {
    # log informational messages to stdout
    echo "$(date +'%FT%T') INFO: ${BASH_SOURCE[0]} ${1}"
}

error_log() {
    # log error messages to stderr
    echo "$(date +'%FT%T') ERROR: ${BASH_SOURCE[0]} ${1}" 1>&2
}

exit_with_error() {
    # log a message to stderr and exit 1
    error_log "${1}"
    exit 1
}

if [[ "$#" -ne 2 ]]; then
    # check for the required arguments, if they're not specified return how to use this script
    info_log "uses azcopy to sync all containers from an Azure Storage Account"
    error_log "ERROR: usage: ${BASH_SOURCE[0]} <storage-account-name> <destination-directory-path>"
    exit 1
fi

storage_account_name=${1}
destination_dir=${2}

info_log "start"

# check for Azure CLI
if ! command -v az &>/dev/null; then
    error_log "az could not be found. This script requires the Azure CLI."
    info_log "see https://docs.microsoft.com/en-us/cli/azure/install-azure-cli for installation instructions."
    exit 1
fi

# check for azcopy
if ! command -v azcopy &>/dev/null; then
    error_log "azcopy could not be found. This script requires azcopy."
    info_log "see https://docs.microsoft.com/en-us/azure/storage/common/storage-use-azcopy-v10 for installation instructions."
    exit 1
fi

# get the blob endpoint
info_log "Retrieving blob endpoint from $storage_account_name"
blob_endpoint=$(az storage account show --name $storage_account_name --query "primaryEndpoints.blob" --output tsv) || exit_with_error "Failed to retrieve blob endpoint. Exiting."

# get all the containers in the storage account
info_log "Retrieving all containers from $storage_account_name"
containers=$(az storage container list --account-name $storage_account_name --query [].name --output tsv --auth-mode login --only-show-errors) || exit_with_error "Failed to retrieve containers from storage account. Exiting."

# if we could not get back containers, exit
if [ -z "$containers" ]; then
    info_log "No containers retreived from storage account $storage_account_name. Exiting."
    exit 1
fi

# for each container, download all its blobs to the destination directory
for container in $containers; do
    source="$blob_endpoint$container"
    destination="$destination_dir/$container"

    sudo mkdir -p -m=777 "$destination"

    info_log "Syncing any newer from $source into $destination using 'azcopy sync'"
    azcopy sync "$source" "$destination" --recursive
done

info_log "end"

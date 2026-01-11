#!/usr/bin/env zsh
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"


function deploy() {
set -e
NEW_DEPLOY="/root/deploy-mng/$(date '+%Y%m%d_%H%M%S')_deploy"
cp -r "${SCRIPT_DIR}/deploy" "${NEW_DEPLOY}"
cd "${NEW_DEPLOY}"
sh -x build-and-run.sh
}



function delete_backup_folder(){
DAYS_TO_KEEP=5
CUTOFF_DATE=$(date -d "-${DAYS_TO_KEEP} days" '+%Y%m%d')

echo "Cleaning up backups older than ${DAYS_TO_KEEP} days (before ${CUTOFF_DATE})..."
for folder in "${SCRIPT_DIR}"/*_deploy; do
    if [[ -d "${folder}" ]]; then
        folder_name=$(basename "${folder}")
        # Extract date part (YYYYMMDD) from folder name like 20260111_200817_deploy
        folder_date="${folder_name%%_*}"
        if [[ "${folder_date}" =~ ^[0-9]{8}$ ]] && [[ "${folder_date}" -lt "${CUTOFF_DATE}" ]]; then
            echo "Deleting old backup: ${folder}"
            rm -rf "${folder}"
        fi
    fi
done
echo "Cleanup completed."
}

deploy
# Cleanup: Delete backup folders older than 5 days based on folder name
delete_backup_folder

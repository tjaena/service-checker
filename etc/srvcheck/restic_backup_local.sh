#!/usr/bin/env bash
# Make backup my system with restic to SFTP.
# This script is typically run by: /etc/systemd/system/restic-backup@local.{service,timer}

# Exit on failure, pipe failure
set -e -o pipefail


# key and value pairs of service url and hc-ping.com uuid
declare -A SERVICES
SERVICES["b565600b-02b1-4a1f-9455-23dc918d2022"]="http://grey.dmz.local/portainer/"

# function of checking service
checkService() {
    HTTP_RESPONSE=$(curl -fsS --retry 5 --write-out %{http_code} $1)

    if [ "$HTTP_RESPONSE" == "200" ]; then
		echo "checkService OK" $1
		return 0
    else
		echo "checkService KO" $1
		return 1
	fi
}

startPing() {
	# $1 should always be the uuid of the service
	curl -fsS -m 10 --retry 5 "https://hc-ping.com/${1}/start"
}

badPing() {
	# $1 should always be the uuid of the service
	# $2 should be the error code
	if $2; then
		echo "has $2"
		curl -fsS -m 10 --retry 5 "https://hc-ping.com/${1}/${2}"
		return 0
	else
		echo "has none"
		curl -fsS -m 10 --retry 5 "https://hc-ping.com/${1}/1"
		return 0
}

goodPing() {
	# $1 should always be the uuid of the service
	curl -fsS -m 10 --retry 5 "https://hc-ping.com/${1}/0"
	if curl -fsS -m 10 --retry 5 "https://hc-ping.com/${1}/0"; then
		echo "curl successfull"
		return 0
	else
		echo "curl error - none"
		return 1
}

# iterate for each service id of array
for UUID in ${!SERVICES[@]}; do
	startPing "${UUID}"
	if checkService "${SERVICES[${UUID}]}"; then
		goodPing "${UUID}"
	else
		badPing "${UUID}" "2"
	fi
	echo ${UUID} ${SERVICES[${UUID}]}
done

# # How many backups to keep.
# RETENTION_DAYS=7
# RETENTION_WEEKS=4
# RETENTION_MONTHS=3
# RETENTION_YEARS=1

# # What to backup, and what to not
# BACKUP_PATHS="/ /boot /home"
# [ -d /mnt/media ] && BACKUP_PATHS+=" /mnt/media"
# BACKUP_EXCLUDES="--exclude-file /etc/restic/backup_exclude"
# for dir in /home/*
# do
# 	if [ -f "$dir/.backup_exclude" ]
# 	then
# 		BACKUP_EXCLUDES+=" --exclude-file $dir/.backup_exclude"
# 	fi
# done

# BACKUP_TAG=local


# # Set all environment variables like
# # RESTIC_REPOSITORY etc.
# source /etc/restic/sftp_local_env.sh
# curl -fsS -m 10 --retry 5 "https://hc-ping.com/${HC_ID}/start"

# # NOTE start all commands in background and wait for them to finish.
# # Reason: bash ignores any signals while child process is executing and thus my trap exit hook is not triggered.
# # However if put in subprocesses, wait(1) waits until the process finishes OR signal is received.
# # Reference: https://unix.stackexchange.com/questions/146756/forward-sigterm-to-child-in-bash

# # Remove locks from other stale processes to keep the automated backup running.
# restic unlock &
# wait $!

# # Do the backup!
# # See restic-backup(1) or http://restic.readthedocs.io/en/latest/040_backup.html
# # --one-file-system makes sure we only backup exactly those mounted file systems specified in $BACKUP_PATHS, and thus not directories like /dev, /sys etc.
# # --tag lets us reference these backups later when doing restic-forget.
# restic backup \
# 	--verbose \
# 	--one-file-system \
# 	--tag $BACKUP_TAG \
# 	$BACKUP_EXCLUDES \
# 	$BACKUP_PATHS &
# wait $!

# # Dereference and delete/prune old backups.
# # See restic-forget(1) or http://restic.readthedocs.io/en/latest/060_forget.html
# # --group-by only the tag and path, and not by hostname. This is because I create a B2 Bucket per host, and if this hostname accidentially change some time, there would now be multiple backup sets.
# restic forget \
# 	--verbose \
# 	--tag $BACKUP_TAG \
#         --prune \
# 	--group-by "paths,tags" \
# 	--keep-daily $RETENTION_DAYS \
# 	--keep-weekly $RETENTION_WEEKS \
# 	--keep-monthly $RETENTION_MONTHS \
# 	--keep-yearly $RETENTION_YEARS &
# wait $!

# # Check repository for errors.
# # NOTE this takes much time (and data transfer from remote repo?), do this in a separate systemd.timer which is run less often.
# #restic check &
# #wait $!

# echo "Backup & cleaning is done."

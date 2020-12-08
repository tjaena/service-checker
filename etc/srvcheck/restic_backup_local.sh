#!/usr/bin/env bash
# This script should check the reachability of all local web services and report the results to hc-ping.com

# Exit on failure, pipe failure
set -e -o pipefail


# key and value pairs of service url and hc-ping.com uuid
declare -A SERVICES
SERVICES["b565600b-02b1-4a1f-9455-23dc918d2022"]="http://grey.dmz.local/portainer/"

# if the url is reachable, then it returns a error code of 0 (OK)
checkService() {
	HTTP_RESPONSE=$(curl -fsS --retry 5 --write-out %{http_code} --output /dev/null $1)

	if [ "$HTTP_RESPONSE" == "200" ]; then
		echo "checkService OK" $1
		# 0 = true
		return 0
	else
		echo "checkService KO" $1
		# 1 = false
		return 1
	fi
}

startPing() {
	# $1 should always be the uuid of the service
	curl -fsS -m 10 --retry 5 "https://hc-ping.com/${1}/start"
}

sendPing() {
	# $1 should always be the uuid of the service
	# $2 should be the error code
	if [ -z "$2" ]; then
		echo "has none"
		curl -fsS -m 10 --retry 5 "https://hc-ping.com/${1}"
		return 0
	else
		echo "has $2"
		curl -fsS -m 10 --retry 5 "https://hc-ping.com/${1}/${2}"
		return 0
	fi
}

# iterate for each service id of array
for UUID in ${!SERVICES[@]}; do
	startPing "${UUID}"
	if checkService "${SERVICES[${UUID}]}"; then
		sendPing "${UUID}" "0"
	else
		sendPing "${UUID}" "1"
	fi
	echo ${UUID} ${SERVICES[${UUID}]}
done
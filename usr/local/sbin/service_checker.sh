#!/usr/bin/env bash
# This script should check the reachability of all local web services and report the results to hc-ping.com

# Exit on failure, pipe failure
set -e -o pipefail


# key and value pairs of service url and hc-ping.com uuid
declare -A SERVICES

# Add all your services here, you need to create a hc-ping entry first
SERVICES["add your hc-ping id here!"]="<service-url>"

# if the url is reachable, then it returns a error code of 0 (OK)
checkService() {
	HTTP_RESPONSE=$(curl -fsS --retry 5 --write-out %{http_code} --output /dev/null $1)

	if [ "$HTTP_RESPONSE" == "200" ]; then
		# 0 = true
		return 0
	else
		# 1 = false
		return 1
	fi
}

startPing() {
	# $1 should always be the uuid of the service
	curl -fsS -m 10 --retry 5 "https://hc-ping.com/${1}/start"
}

# call it without an 2nd argument to return a successful error code
sendPing() {
	# $1 should always be the uuid of the service
	# $2 should be the error code
	if [ -z "$2" ]; then
		curl -fsS -m 10 --retry 5 "https://hc-ping.com/${1}"
		# 0 = true
		return 0
	else
		curl -fsS -m 10 --retry 5 "https://hc-ping.com/${1}/${2}"
		# 0 = true
		return 0
	fi
}

# iterate for each service id of array
for UUID in ${!SERVICES[@]}; do
	startPing "${UUID}"
	if checkService "${SERVICES[${UUID}]}"; then
		# 0 = No Error
		sendPing "${UUID}" "0"
	else
		# 1 = Error
		sendPing "${UUID}" "1"
	fi
	echo ${UUID} ${SERVICES[${UUID}]}
	# just to give hc-ping a rest and not to trigger the rate limiter
	sleep 1
done
#!/bin/ash

# Default the TZ environment variable to UTC.
TZ=${TZ:-UTC}
export TZ

# Set environment variable that holds the Internal Docker IP
INTERNAL_IP=$(ip route get 1 | awk '{print $(NF-2);exit}')
export INTERNAL_IP

# Switch to the container's working directory
cd /home/container || exit 1

# Convert all of the "{{VARIABLE}}" parts of the command into the expected shell
# variable format of "${VARIABLE}" before evaluating the string and automatically
# replacing the values.
PARSED=$(echo "${STARTUP}" | sed -e 's/{{/${/g' -e 's/}}/}/g' | eval echo "$(cat -)")

RELEASE_PAGE=$(curl -sSL https://runtime.fivem.net/artifacts/fivem/build_proot_linux/master/)
CHANGELOGS_PAGE=$(curl -sSL https://changelogs-live.fivem.net/api/changelog/versions/linux/server)

if [[ "${FIVEM_VERSION}" == "recommended" ]] || [[ -z ${FIVEM_VERSION} ]]; then
	DOWNLOAD_LINK=$(echo $CHANGELOGS_PAGE | jq -r '.recommended_download')
elif [[ "${FIVEM_VERSION}" == "latest" ]]; then
	DOWNLOAD_LINK=$(echo $CHANGELOGS_PAGE | jq -r '.latest_download')
else
	VERSION_LINK=$(echo -e "${RELEASE_PAGE}" | grep -Eo 'href=".*/*.tar.xz"' | grep -Eo '".*"' | sed 's/\"//g' | sed 's/\.\///1' | grep ${FIVEM_VERSION})

	if [[ "${VERSION_LINK}" == "" ]]; then
		echo -e "defaulting to recommended as the version requested was invalid."
		DOWNLOAD_LINK=$(echo $CHANGELOGS_PAGE | jq -r '.recommended_download')
	else
		DOWNLOAD_LINK=$(echo https://runtime.fivem.net/artifacts/fivem/build_proot_linux/master/${VERSION_LINK})
	fi
fi

if [ ! -z "${DOWNLOAD_URL}" ]; then
	if curl --output /dev/null --silent --head --fail ${DOWNLOAD_URL}; then
		echo -e "link is valid. setting download link to ${DOWNLOAD_URL}"
		DOWNLOAD_LINK=${DOWNLOAD_URL}
	else
		echo -e "link is invalid closing out"
		exit 2
	fi
fi

if [ ! -z "${DOWNLOAD_LINK}" ]; then
	echo -e "Running curl -sSL ${DOWNLOAD_LINK} -o ${DOWNLOAD_LINK##*/}"
	curl -sSL ${DOWNLOAD_LINK} -o ${DOWNLOAD_LINK##*/}
	echo "Extracting fivem artifacts"
	FILETYPE=$(file -F ',' ${DOWNLOAD_LINK##*/} | cut -d',' -f2 | cut -d' ' -f2)

	if [ "$FILETYPE" == "gzip" ]; then
		tar xzf ${DOWNLOAD_LINK##*/}
	elif [ "$FILETYPE" == "Zip" ]; then
		unzip ${DOWNLOAD_LINK##*/}
	elif [ "$FILETYPE" == "XZ" ]; then
		tar xf ${DOWNLOAD_LINK##*/}
	else
		echo -e "unknown filetype. Exiting"
		exit 2
	fi

	rm -rf ${DOWNLOAD_LINK##*/} run.sh
fi

# Display the command we're running in the output, and then execute it with the env
# from the container itself.
printf "\033[1m\033[33mcontainer@pterodactyl~ \033[0m%s\n" "$PARSED"
# shellcheck disable=SC2086
exec env ${PARSED} | tee logs/$(date --utc +'%Y-%m-%d-%H%M%S').log

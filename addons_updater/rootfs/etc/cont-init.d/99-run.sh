#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

##########
# UPDATE #
##########

bashio::log.info "Starting $(lastversion --version)"

bashio::log.info "Checking status of referenced repositoriess..."
VERBOSE=$(bashio::config 'verbose')

#Defining github value
LOGINFO="... github authentification" && if [ "$VERBOSE" = true ]; then bashio::log.info "$LOGINFO"; fi

GITUSER=$(bashio::config 'gituser')
GITPASS=$(bashio::config 'gitpass')
GITMAIL=$(bashio::config 'gitmail')
git config --system http.sslVerify false
git config --system credential.helper 'cache --timeout 7200'
git config --system user.name "${GITUSER}"
git config --system user.password "${GITPASS}"
git config --system user.email "${GITMAIL}"

if bashio::config.has_value 'gitapi'; then
    LOGINFO="... setting github API" && if [ "$VERBOSE" = true ]; then bashio::log.info "$LOGINFO"; fi
    GITHUB_API_TOKEN=$(bashio::config 'gitapi')
    export GITHUB_API_TOKEN
fi

    #Create or update local version
    REPOSITORY=$(bashio::config 'repository')
    BASENAME=$(basename "https://github.com/$REPOSITORY")

    if [ ! -d "/data/$BASENAME" ]; then
        LOGINFO="... cloning ${REPOSITORY}" && if [ "$VERBOSE" = true ]; then bashio::log.info "$LOGINFO"; fi
        cd /data/ || exit
        git clone "https://github.com/${REPOSITORY}"
    else
        LOGINFO="... updating ${REPOSITORY}" && if [ "$VERBOSE" = true ]; then bashio::log.info "$LOGINFO"; fi
        cd "/data/$BASENAME" || exit
        git pull --rebase &>/dev/null || git reset --hard &>/dev/null
        git pull --rebase &>/dev/null
    fi

LOGINFO="... parse addons" && if [ "$VERBOSE" = true ]; then bashio::log.info "$LOGINFO"; fi

# Go through all folders, add to filters if not existing
echo "go in folder"

cd /data/"$BASENAME"
for f in *; do
if [ -f "$f"/updater.json ]; then
    SLUG=$f

    #Define the folder addon
    LOGINFO="... $SLUG : checking slug exists in repo" && if [ "$VERBOSE" = true ]; then bashio::log.info "$LOGINFO"; fi
    cd /data/"${BASENAME}"/"${SLUG}" || { bashio::log.error "$SLUG addon not found in this repository. Exiting."; continue; }

    # Get variables
    UPSTREAM=$(jq -r .upstream updater.json)
    BETA=$(jq -r .beta updater.json)
    FULLTAG=$(jq -r .github fulltag updater.json)
    HAVINGASSET=$(jq -r .github_havingasset updater.json)
    SOURCE=$(jq -r .source updater.json)
    FILTER_TEXT=$(jq -r .github_tagfilter updater.json)
    DATE="$(date '+%d-%m-%Y')"

    #Find current version
    LOGINFO="... $SLUG : get current version" && if [ "$VERBOSE" = true ]; then bashio::log.info "$LOGINFO"; fi
    CURRENT=$(jq .upstream_version updater.json) || { bashio::log.error "$SLUG addon upstream tag not found in updater.json. Exiting."; continue; }

    if [ "$SOURCE" = "dockerhub" ]; then
        # Use dockerhub as upstream
        # shellcheck disable=SC2116
        DOCKERHUB_REPO=$(echo "${UPSTREAM%%/*}")
        DOCKERHUB_IMAGE=$(echo "$UPSTREAM" | cut -d "/" -f2)
        LASTVERSION=$(
            curl -f -L -s --fail "https://hub.docker.com/v2/repositories/${DOCKERHUB_REPO}/${DOCKERHUB_IMAGE}/tags/?page_size=10" |
            jq '.results | .[] | .name' -r |
            sed -e '/.*latest.*/d' |
            sed -e '/.*dev.*/d' |
            sort -V |
            tail -n 1
        )
        [ "${BETA}" = true ] &&
        LASTVERSION=$(
            curl -f -L -s --fail "https://hub.docker.com/v2/repositories/${DOCKERHUB_REPO}/${DOCKERHUB_IMAGE}/tags/?page_size=10" |
            jq '.results | .[] | .name' -r |
            sed -e '/.*latest.*/d' |
            sed -e '/.*dev.*/!d' |
            sort -V |
            tail -n 1
        )

    else
        # Use github as upstream
        ARGUMENTS=""
        #Prepare tag flag
        if [ "${FULLTAG}" = true ]; then
            LOGINFO="... $SLUG : fulltag is on" && if [ "$VERBOSE" = true ]; then bashio::log.info "$LOGINFO"; fi
            ARGUMENTS="$ARGUMENTS --format tag"
        else
            LOGINFO="... $SLUG : fulltag is off" && if [ "$VERBOSE" = true ]; then bashio::log.info "$LOGINFO"; fi
        fi

        #Prepare tag flag
        if [ "${HAVINGASSET}" = true ]; then
            LOGINFO="... $SLUG : asset_only tag is on" && if [ "$VERBOSE" = true ]; then bashio::log.info "$LOGINFO"; fi
            ARGUMENTS="$ARGUMENTS --having-asset"
        else
            LOGINFO="... $SLUG : asset_only is off" && if [ "$VERBOSE" = true ]; then bashio::log.info "$LOGINFO"; fi
        fi

        #Prepare tag flag
        if [ "${FILTER_TEXT}" = "null" ] || [ "${FILTER_TEXT}" = "" ]; then
            FILTER_TEXT=""
        else
            LOGINFO="... $SLUG : filter_text is on" && if [ "$VERBOSE" = true ]; then bashio::log.info "$LOGINFO"; fi
            ARGUMENTS="$ARGUMENTS --only $FILTER_TEXT"
        fi

        #If beta flag, select beta version
        if [ "${BETA}" = true ]; then
            LOGINFO="... $SLUG : beta is on" && if [ "$VERBOSE" = true ]; then bashio::log.info "$LOGINFO"; fi
            # shellcheck disable=SC2086
            LASTVERSION=$(lastversion --pre "https://github.com/$UPSTREAM" $ARGUMENTS) || continue
        else
            LOGINFO="... $SLUG : beta is off" && if [ "$VERBOSE" = true ]; then bashio::log.info "$LOGINFO"; fi
            # shellcheck disable=SC2086
            LASTVERSION=$(lastversion "https://github.com/$UPSTREAM" $ARGUMENTS) || continue
        fi

    fi

    # Add brackets
    LASTVERSION='"'${LASTVERSION}'"'

    # Do not compare with ls tag for linuxserver images (to avoid updating only for dependencies)
    #LASTVERSION2=${LASTVERSION%-ls*}
    #CURRENT2=${CURRENT%-ls*}
    LASTVERSION2=${LASTVERSION}
    CURRENT2=${CURRENT}

    # Update if needed
    if [ "${CURRENT2}" != "${LASTVERSION2}" ]; then
        LOGINFO="... $SLUG : update from ${CURRENT} to ${LASTVERSION}" && if [ "$VERBOSE" = true ]; then bashio::log.info "$LOGINFO"; fi

        #Change all instances of version
        LOGINFO="... $SLUG : updating files" && if [ "$VERBOSE" = true ]; then bashio::log.info "$LOGINFO"; fi
        for files in "config.json" "config.yaml" "Dockerfile" "build.json" "build.yaml";do
            if [ -f /data/"${BASENAME}"/"${SLUG}"/$files ]; then
                sed -i "s/${CURRENT}/${LASTVERSION}/g" /data/"${BASENAME}"/"${SLUG}"/"$files"
            fi
        done

        # Remove " and modify version
        LASTVERSION=${LASTVERSION//\"/}
        CURRENT=${CURRENT//\"/}
        jq --arg variable "$LASTVERSION" '.version = $variable' /data/"${BASENAME}"/"${SLUG}"/config.json | sponge /data/"${BASENAME}"/"${SLUG}"/config.json # Replace version tag
        jq --arg variable "$LASTVERSION" '.upstream_version = $variable' /data/"${BASENAME}"/"${SLUG}"/updater.json | sponge /data/"${BASENAME}"/"${SLUG}"/updater.json # Replace upstream tag
        jq --arg variable "$DATE" '.last_update = $variable' /data/"${BASENAME}"/"${SLUG}"/updater.json | sponge /data/"${BASENAME}"/"${SLUG}"/updater.json # Replace date tag

        #Update changelog
        touch "/data/${BASENAME}/${SLUG}/CHANGELOG.md"
        sed -i "1i - Update to latest version from $UPSTREAM" "/data/${BASENAME}/${SLUG}/CHANGELOG.md"
        sed -i "1i ## ${LASTVERSION} (${DATE})" "/data/${BASENAME}/${SLUG}/CHANGELOG.md"
        sed -i "1i " "/data/${BASENAME}/${SLUG}/CHANGELOG.md"
        LOGINFO="... $SLUG : files updated" && if [ "$VERBOSE" = true ]; then bashio::log.info "$LOGINFO"; fi

        #Git commit and push
        git add -A # add all modified files
        git commit -m "Updater bot : $SLUG updated to ${LASTVERSION}" >/dev/null

        LOGINFO="... $SLUG : push to github" && if [ "$VERBOSE" = true ]; then bashio::log.info "$LOGINFO"; fi
        git remote set-url origin "https://${GITUSER}:${GITPASS}@github.com/${REPOSITORY}" &>/dev/null
        git push &>/dev/null

        #Log
        bashio::log.yellow "... $SLUG updated from ${CURRENT} to ${LASTVERSION}"

    else
        bashio::log.green "... $SLUG is up-to-date ${CURRENT}"
    fi
fi
done || true # Continue even if issue

bashio::log.info "Addons update completed"

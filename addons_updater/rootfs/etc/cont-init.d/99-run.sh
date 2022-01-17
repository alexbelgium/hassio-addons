#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

##########
# UPDATE #
##########

bashio::log.info "Starting $(lastversion --version)"

bashio::log.info "Checking status of referenced repositoriess..."
VERBOSE=$(bashio::config 'verbose')

#Defining github value
LOGINFO="... github authentification" && if [ $VERBOSE = true ]; then bashio::log.info $LOGINFO; fi

GITUSER=$(bashio::config 'gituser')
GITPASS=$(bashio::config 'gitpass')
GITMAIL=$(bashio::config 'gitmail')
git config --system http.sslVerify false
git config --system credential.helper 'cache --timeout 7200'
git config --system user.name ${GITUSER}
git config --system user.password ${GITPASS}
git config --system user.email ${GITMAIL}

if bashio::config.has_value 'gitapi'; then
  LOGINFO="... setting github API" && if [ $VERBOSE = true ]; then bashio::log.info $LOGINFO; fi

  export GITHUB_API_TOKEN=$(bashio::config 'gitapi')
fi

LOGINFO="... parse addons" && if [ $VERBOSE = true ]; then bashio::log.info $LOGINFO; fi

for addons in $(bashio::config "addon|keys"); do
  SLUG=$(bashio::config "addon[${addons}].slug")
  REPOSITORY=$(bashio::config "addon[${addons}].repository")
  UPSTREAM=$(bashio::config "addon[${addons}].upstream")
  BETA=$(bashio::config "addon[${addons}].beta")
  FULLTAG=$(bashio::config "addon[${addons}].fulltag")
  HAVINGASSET=$(bashio::config "addon[${addons}].having_asset")
  SOURCE=$(bashio::config "addon[${addons}].source")
  BASENAME=$(basename "https://github.com/$REPOSITORY")
  DATE="$(date '+%d-%m-%Y')"

  #Create or update local version
  if [ ! -d /data/$BASENAME ]; then
    LOGINFO="... $SLUG : cloning ${REPOSITORY}" && if [ $VERBOSE = true ]; then bashio::log.info $LOGINFO; fi
    cd /data/
    git clone "https://github.com/${REPOSITORY}"
  else
    LOGINFO="... $SLUG : updating ${REPOSITORY}" && if [ $VERBOSE = true ]; then bashio::log.info $LOGINFO; fi
    cd "/data/$BASENAME"
    git pull --rebase &>/dev/null || git reset --hard &>/dev/null
    git pull --rebase &>/dev/null
  fi

  #Define the folder addon
  LOGINFO="... $SLUG : checking slug exists in repo" && if [ $VERBOSE = true ]; then bashio::log.info $LOGINFO; fi
  cd /data/${BASENAME}/${SLUG} || bashio::log.error "$SLUG addon not found in this repository. Exiting. Exiting."

  #Find current version
  LOGINFO="... $SLUG : get current version" && if [ $VERBOSE = true ]; then bashio::log.info $LOGINFO; fi
  CURRENT=$(jq .upstream config.json) || bashio::log.error "$SLUG addon upstream tag not found in config.json. Exiting."

  if [ $SOURCE = "dockerhub" ]; then
    # Use dockerhub as upstream
    DOCKERHUB_REPO=$(echo "${UPSTREAM%%/*}")
    DOCKERHUB_IMAGE=$(echo $UPSTREAM | cut -d "/" -f2)
    LASTVERSION=$(
      curl -L -s --fail "https://hub.docker.com/v2/repositories/${DOCKERHUB_REPO}/${DOCKERHUB_IMAGE}/tags/?page_size=1000" |
        jq '.results | .[] | .name' -r |
        sed -e '/.*latest.*/d' |
        sed -e '/.*dev.*/d' |
        sort -V |
        tail -n 1
    )
    [ ${BETA} = true ] &&
      LASTVERSION=$(
        curl -L -s --fail "https://hub.docker.com/v2/repositories/${DOCKERHUB_REPO}/${DOCKERHUB_IMAGE}/tags/?page_size=1000" |
          jq '.results | .[] | .name' -r |
          sed -e '/.*latest.*/d' |
          sed -e '/.*dev.*/!d' |
          sort -V |
          tail -n 1
      )

  else
    # Use github as upstream
    #Prepare tag flag
    if [ ${FULLTAG} = true ]; then
      LOGINFO="... $SLUG : fulltag is on" && if [ $VERBOSE = true ]; then bashio::log.info $LOGINFO; fi
      FULLTAG="--format tag"
    else
      LOGINFO="... $SLUG : fulltag is off" && if [ $VERBOSE = true ]; then bashio::log.info $LOGINFO; fi
      FULLTAG=""
    fi

    #Prepare tag flag
    if [ ${HAVINGASSET} = true ]; then
      LOGINFO="... $SLUG : asset_only tag is on" && if [ $VERBOSE = true ]; then bashio::log.info $LOGINFO; fi
      HAVINGASSET="--having-asset"
    else
      LOGINFO="... $SLUG : asset_only is off" && if [ $VERBOSE = true ]; then bashio::log.info $LOGINFO; fi
      HAVINGASSET=""
    fi

    #If beta flag, select beta version
    if [ ${BETA} = true ]; then
      LOGINFO="... $SLUG : beta is on" && if [ $VERBOSE = true ]; then bashio::log.info $LOGINFO; fi
      LASTVERSION=$(lastversion --pre "https://github.com/$UPSTREAM" $FULLTAG $HAVINGASSET) || break
    else
      LOGINFO="... $SLUG : beta is off" && if [ $VERBOSE = true ]; then bashio::log.info $LOGINFO; fi
      LASTVERSION=$(lastversion "https://github.com/$UPSTREAM" $FULLTAG $HAVINGASSET) || break
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
  if [ ${CURRENT2} != ${LASTVERSION2} ]; then
    LOGINFO="... $SLUG : update from ${CURRENT} to ${LASTVERSION}" && if [ $VERBOSE = true ]; then bashio::log.info $LOGINFO; fi

    #Change all instances of version
    LOGINFO="... $SLUG : updating files" && if [ $VERBOSE = true ]; then bashio::log.info $LOGINFO; fi
    sed -i "s/${CURRENT}/${LASTVERSION}/g" /data/${BASENAME}/${SLUG}/config.json
    sed -i "s/${CURRENT}/${LASTVERSION}/g" /data/${BASENAME}/${SLUG}/Dockerfile || true                                                  #Allow absence of Dockerfile
    [ -f "/data/${BASENAME}/${SLUG}/build.json" ] && sed -i "s/${CURRENT}/${LASTVERSION}/g" /data/${BASENAME}/${SLUG}/build.json || true #Allow absence of build.json

    # Remove " and modify version
    LASTVERSION=${LASTVERSION//\"/}
    CURRENT=${CURRENT//\"/}
    jq --arg variable $LASTVERSION '.version = $variable' /data/${BASENAME}/${SLUG}/config.json | sponge /data/${BASENAME}/${SLUG}/config.json # Replace version tag

    #Update changelog
    touch /data/${BASENAME}/${SLUG}/CHANGELOG.md
    sed -i "1i - Update to latest version from $UPSTREAM" /data/${BASENAME}/${SLUG}/CHANGELOG.md
    sed -i "1i ## ${LASTVERSION} (${DATE})" /data/${BASENAME}/${SLUG}/CHANGELOG.md
    sed -i "1i " /data/${BASENAME}/${SLUG}/CHANGELOG.md
    LOGINFO="... $SLUG : files updated" && if [ $VERBOSE = true ]; then bashio::log.info $LOGINFO; fi

    #Git commit and push
    git add -A # add all modified files
    git commit -m "Updater bot : $SLUG updated to ${LASTVERSION}" >/dev/null

    LOGINFO="... $SLUG : push to github" && if [ $VERBOSE = true ]; then bashio::log.info $LOGINFO; fi
    git remote set-url origin "https://${GITUSER}:${GITPASS}@github.com/${REPOSITORY}" &>/dev/null
    git push &>/dev/null

    #Log
    bashio::log.yellow "... $SLUG updated from ${CURRENT} to ${LASTVERSION}"

  else
    bashio::log.green "... $SLUG is up-to-date ${CURRENT}"
  fi

done

bashio::log.info "Addons update completed"

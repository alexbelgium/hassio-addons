#!/usr/bin/with-contenv bashio

bashio::log.info "Checking status of referenced repositoriess..."

#Defining github values
bashio::log.info "... github authentification"
GITUSER=$(bashio::config 'gituser')
GITPASS=$(bashio::config 'gitpass')
GITMAIL=$(bashio::config 'gitmail')
git config --system http.sslVerify false
git config --system credential.helper 'cache --timeout 7200'
git config --system user.name ${GITUSER}
git config --system user.password ${GITPASS}
git config --system user.email ${GITMAIL}

#if bashio::config.has_value 'gitapi'; then
#bashio::log.info "... setting github API"
export GITHUB_API_TOKEN=$(bashio::config 'gitapi')
#fi

bashio::log.info "... parse addons"
for addons in $(bashio::config "addon|keys"); do
    SLUG=$(bashio::config "addon[${addons}].slug")
    REPOSITORY=$(bashio::config "addon[${addons}].repository")
    UPSTREAM=$(bashio::config "addon[${addons}].upstream")
    BETA=$(bashio::config "addon[${addons}].beta")
    FULLTAG=$(bashio::config "addon[${addons}].fulltag")
    BASENAME=$(basename "https://github.com/$REPOSITORY")
  
      #Create or update local version
      if [ ! -d /data/$BASENAME ]; then 
        bashio::log.info "... $SLUG : cloning ${REPOSITORY}"
        cd /data/
        git clone "https://github.com/${REPOSITORY}"
      else
        bashio::log.info "... $SLUG : updating ${REPOSITORY}"       
        cd "/data/$BASENAME"
        git fetch 
          if [ "$(git rev-parse HEAD)" !== "$(git rev-parse @{u})" ]; then
        git pull --ff-only
        fi
      fi

      #Define the folder addon
      bashio::log.info "... $SLUG : checking slug exists in repo"
      cd /data/${BASENAME}/${SLUG} || bashio::log.error "$SLUG addon not found in this repository. Exiting." exit
  
      #Find current version
      bashio::log.info "... $SLUG : get current version"
      CURRENT=$(jq .version config.json) || bashio::log.error "$SLUG addon version in config.json not found. Exiting." exit
      
#Prepare tag flag
if [ ${FULLTAG} = true ]; then
bashio::log.info "... $SLUG : fulltag is on"
FULLTAG="--format tag"
else
bashio::log.info "... $SLUG : fulltag is off"
FULLTAG=""
fi 

      #If beta flag, select beta version
      if [ ${BETA} = true ]; then
      bashio::log.info "... $SLUG : beta is on"
      LASTVERSION='"'$(lastversion --pre "https://github.com/$UPSTREAM" $FULLTAG)'"'
      else 
      bashio::log.info "... $SLUG : beta is off"
      LASTVERSION='"'$(lastversion "https://github.com/$UPSTREAM" $FULLTAG)'"'
      fi

    if [ ${CURRENT} != ${LASTVERSION} ]; then
        bashio::log.info "... $SLUG : update from $CURRENT to $LASTVERSION"

        
        #Change all instances of version
      bashio::log.info "... $SLUG : updating files"
      
      files=$(grep -rl ${CURRENT} /data/${BASENAME}/${SLUG}) && echo $files | xargs sed -i "s/${CURRENT}/${LASTVERSION}/g"
      
if [ $files != null ]; then
      git commit -m "Bot update to $LASTVERSION" $files || true
      
      #Git commit and push
      bashio::log.info "... $SLUG : push to master"
      git remote set-url origin "https://${GITUSER}:${GITPASS}@github.com/${REPOSITORY}" |  echo                                  
      git push | echo "No changes"

      #Update the current flag
      bashio::log.info "... $SLUG : updating current flag"
      sed -i "s/${CURRENT}/${LASTVERSION}/g" /data/options.json                                                       
                                                                     
      #Log                                                 
      bashio::log.info "... $SLUG : updated and published"  
else
bashio::log.info "... $SLUG : couldn't update, please check the current version"
fi
      
    else                                                                                
        bashio::log.info "Addon $SLUG is already up-to-date."                           
    fi                                                               
done                                                                 
exit

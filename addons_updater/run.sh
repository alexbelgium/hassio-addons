#!/usr/bin/with-contenv bashio

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
    BASENAME=$(basename "https://github.com/$REPOSITORY")
  
      #Create or update local version
      if [ ! -d /data/$BASENAME ]; then
        LOGINFO="... $SLUG : cloning ${REPOSITORY}" && if [ $VERBOSE = true ]; then bashio::log.info $LOGINFO; fi
        cd /data/
        git clone "https://github.com/${REPOSITORY}"
      else
        LOGINFO="... $SLUG : updating ${REPOSITORY}" && if [ $VERBOSE = true ]; then bashio::log.info $LOGINFO; fi   
        cd "/data/$BASENAME"
      # git pull --rebase
      git status
      git reset --hard
      fi

      #Define the folder addon
      LOGINFO="... $SLUG : checking slug exists in repo" && if [ $VERBOSE = true ]; then bashio::log.info $LOGINFO; fi   
      cd /data/${BASENAME}/${SLUG} || bashio::log.error "$SLUG addon not found in this repository. Exiting." exit
  
      #Find current version
      LOGINFO="... $SLUG : get current version" && if [ $VERBOSE = true ]; then bashio::log.info $LOGINFO; fi   
      CURRENT=$(jq .version config.json) || bashio::log.error "$SLUG addon version in config.json not found. Exiting." exit
      
#Prepare tag flag
if [ ${FULLTAG} = true ]; then
LOGINFO="... $SLUG : fulltag is on" && if [ $VERBOSE = true ]; then bashio::log.info $LOGINFO; fi   
FULLTAG="--format tag"
else
LOGINFO="... $SLUG : fulltag is off" && if [ $VERBOSE = true ]; then bashio::log.info $LOGINFO; fi   
FULLTAG=""
fi 

      #If beta flag, select beta version
      if [ ${BETA} = true ]; then
      LOGINFO="... $SLUG : beta is on" && if [ $VERBOSE = true ]; then bashio::log.info $LOGINFO; fi   
      LASTVERSION=$(lastversion --pre "https://github.com/$UPSTREAM" $FULLTAG)
      else 
      LOGINFO="... $SLUG : beta is off" && if [ $VERBOSE = true ]; then bashio::log.info $LOGINFO; fi
      LASTVERSION=$(lastversion "https://github.com/$UPSTREAM" $FULLTAG)
      fi

     # Take only into account first part of tag
     # CURRENT=${CURRENT:0:${#LASTVERSION}}

     # Add brackets
     CURRENT='"'$CURRENT'"'
     LASTVERSION='"'$LASTVERSION'"'

     # Update if needed 
    if [ ${CURRENT} != ${LASTVERSION} ]; then
      LOGINFO="... $SLUG : update from $CURRENT to $LASTVERSION" && if [ $VERBOSE = true ]; then bashio::log.info $LOGINFO; fi   
        
        #Change all instances of version
      LOGINFO="... $SLUG : updating files" && if [ $VERBOSE = true ]; then bashio::log.info $LOGINFO; fi   
      files=$(grep -rl ${CURRENT} /data/${BASENAME}/${SLUG}) && echo $files | xargs sed -i "s/${CURRENT}/${LASTVERSION}/g"
      
      #Update changelog
      touch /data/${BASENAME}/${SLUG}/CHANGELOG.md
      sed -i "1i\- Update to latest version from $UPSTREAM" /data/${BASENAME}/${SLUG}/CHANGELOG.md 
      sed -i "1i\## ${LASTVERSION:1:-1}" /data/${BASENAME}/${SLUG}/CHANGELOG.md
      sed -i "1i\ " /data/${BASENAME}/${SLUG}/CHANGELOG.md
           
if [ $files != null ]; then
      git commit -m "Update to $LASTVERSION" $files || true
      git commit -m "Update to $LASTVERSION" /data/${BASENAME}/${SLUG}/CHANGELOG.md || true
      
      #Git commit and push
      LOGINFO="... $SLUG : push to github" && if [ $VERBOSE = true ]; then bashio::log.info $LOGINFO; fi   
      git remote set-url origin "https://${GITUSER}:${GITPASS}@github.com/${REPOSITORY}" |  echo                                  
      git push | echo "No changes"                                                   
                                                                     
      #Log                                                 
      bashio::log.info "$SLUG updated to $LASTVERSION"  
else
bashio::log.error "... $SLUG : update failed"
fi
      
    else                                                                                
      bashio::log.info "Addon $SLUG is already up-to-date"                        
    fi                                                               
done                                                                 

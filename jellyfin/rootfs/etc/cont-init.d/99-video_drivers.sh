#!/usr/bin/with-contenv bashio

exit 0

# Determine if setup is needed
if [ ! -f "/usr/bin/apt" ]; then
    echo "**** Image is not Ubuntu, skipping drivers install ****"
    exit 0
fi

bashio::log.info "Installing graphic drivers"

#Add source
if [ ! -f "/etc/apt/sources.list.d/kisak-mesa-focal.list" ]; then
    echo "**** Adding kisak-mesa repo ****"
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys F63F0F2B90935439
    echo "deb http://ppa.launchpad.net/kisak/kisak-mesa/ubuntu focal main" > /etc/apt/sources.list.d/kisak-mesa-focal.list
fi

if [ $(uname -m) = "x86_64" ]; then
    apt-get install -y clinfo
    if [ -d /opencl-intel ]; then
      echo "**** Installing/updating opencl-intel debs ****"
      pkgs='intel-opencl-icd'
    else
      echo "**** Installing/updating AMD drivers ****"
      apt-get update >/dev/null
      pkgs='mesa-vdpau-drivers mesa-va-drivers mesa-vdpau-drivers libdrm-radeon1'
    fi
else
   pkgs='libgles2-mesa libgles2-mesa-dev xorg-dev'
fi

      install=false
       for pkg in $pkgs; do
        status="$(dpkg-query -W --showformat='${db:Status-Status}' "$pkg" 2>&1)"
        if [ ! $? = 0 ] || [ ! "$status" = installed ]; then
          install=true
          break
       fi
      done 
      if "$install"; then
        apt-get install -y $pkgs
      fi
    fi

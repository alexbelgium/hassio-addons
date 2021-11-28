Options can be configured :
```yaml
GUID: user
GPID: user
localdisks: sda1 #put the hardware name of your drive to mount separated by commas, or its label. Ex: sda1, sdb1, MYNAS...
networkdisks: "<//SERVER/SHARE>" # list of smbv2/3 servers to mount (optional)
cifsusername: "username" # smb username (optional)
cifspassword: "password" # smb password (optional)
CONFIG_LOCATION : Custom env variables : can be added to the config.yaml file referenced in the addon options. Full env variables can be found here : https://github.com/linuxserver/docker-paperless-ng. It must be entered in a valid yaml format, that is verified at launch of the addon.
```

 

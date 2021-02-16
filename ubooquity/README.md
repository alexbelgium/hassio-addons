# Home assistant add-on: Ubooquity
![Supports aarch64 Architecture][aarch64-shield] ![Supports amd64 Architecture][amd64-shield] ![Supports armhf Architecture][armhf-shield] ![Supports armv7 Architecture][armv7-shield]

## About

Free, lightweight and easy-to-use home server for your comics and ebooks
This addon is based on the [docker image](https://github.com/linuxserver/ubooquity) from linuxserver.io.

## Installation

The installation of this add-on is pretty straightforward and not different in
comparison to installing any other Hass.io add-on.

1. [Add my Hass.io add-ons repository][repository] to your Hass.io instance.
1. Install this add-on.
1. Click the `Save` button to store your configuration.
1. Start the add-on.
1. Check the logs of the add-on to see if everything went well.
1. Carefully configure the add-on to your preferences, see the official documentation for for that.

## Configuration
Access the admin page at http://<your-ip>:2203/ubooquity/admin and set a password.
Then you can access the webui at http://<your-ip>:2202/ubooquity/ (or top left of the admin page)
This container will automatically scan your files at startup.

Network disk is mounted to /share/storagecifs

```yaml
GUID: user
GPID: user
maxmem: 300 # The quantity of memory allocated to Ubooquity depends on the hardware your are running it on. If this quantity is too small, you might sometime saturate it with when performing memory intensive operations. That’s when you get java.lang.OutOfMemoryError: Java heap space errors. You can explicitly set the amount of memory Ubooquity is allowed to use (be careful to set a value lower than the actual physical memory of your hardware). Value is a number of megabytes ( put just a number, without MB )
networkdisks: "<//SERVER/SHARE>" # list of smbv2/3 servers to mount (optional)
cifsusername: "username" # smb username (optional)
cifspassword: "password" # smb password (optional)
```

## Support
Create an issue on the [repository github][repository]

[repository]: https://github.com/alexbelgium/hassio-addons
[aarch64-shield]: https://img.shields.io/badge/aarch64-yes-green.svg
[amd64-shield]: https://img.shields.io/badge/amd64-yes-green.svg
[armhf-shield]: https://img.shields.io/badge/armhf-yes-green.svg
[armv7-shield]: https://img.shields.io/badge/armv7-yes-green.svg

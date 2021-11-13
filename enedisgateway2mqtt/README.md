# Home assistant add-on: Enedisgateway2mqtt

[![Donate][donation-badge]](https://www.buymeacoffee.com/alexbelgium)

[donation-badge]: https://img.shields.io/badge/Buy%20me%20a%20coffee-%23d32f2f?logo=buy-me-a-coffee&style=flat&logoColor=white

![Supports 
 Architecture][aarch64-shield] ![Supports amd64 Architecture][amd64-shield] ![Supports armhf Architecture][armhf-shield] ![Supports armv7 Architecture][armv7-shield]

_Thanks to everyone having starred my repo! To star it click on the image below, then it will be on top right. Thanks!_

[![Stargazers repo roster for @alexbelgium/hassio-addons](https://reporoster.com/stars/alexbelgium/hassio-addons)](https://github.com/alexbelgium/hassio-addons/stargazers)

## About

Enedisgateway2mqtt use Enedis Gateway API to send data in your MQTT Broker.
See its github for all informations : https://github.com/m4dm4rtig4n/enedisgateway2mqtt/blob/master/README.md

## Configuration

There are 3 ways to configure this addon :
- Using the addon options
- Using the custom_var field, where variables not already defined in the addon options can be described using the format : var1=text1,var2=text2
- Manually editing the file /config/enedisgateway2mqtt/enedisgateway2mqtt.conf and adding options with the format var1=text1

All variables defined the in the addon options and custom_var fields are automatically copied in the /config/enedisgateway2mqtt/enedisgateway2mqtt.conf file.

The complete list of options can be seen here : https://github.com/m4dm4rtig4n/enedisgateway2mqtt#environment-variable

## Installation

The installation of this add-on is pretty straightforward and not different in
comparison to installing any other Hass.io add-on.

1. [Add my Hass.io add-ons repository][repository] to your Hass.io instance.
1. Install this add-on.
1. Click the `Save` button to store your configuration.
1. Start the add-on.
1. Check the logs of the add-on to see if everything went well.
1. Carefully configure the add-on to your preferences, see the official documentation for for that.

[smb-shield]: https://img.shields.io/badge/SMB--green?style=plastic.svg
[repository]: https://github.com/alexbelgium/hassio-addons
[aarch64-shield]: https://img.shields.io/badge/aarch64-yes-green.svg
[amd64-shield]: https://img.shields.io/badge/amd64-yes-green.svg
[armhf-shield]: https://img.shields.io/badge/armhf-yes-green.svg
[armv7-shield]: https://img.shields.io/badge/armv7-yes-green.svg

Portainer can be used to execute custom commands in a docker container. It is a lightweight management UI which allows you to easily manage a Docker host(s) or Docker swarm clusters.

This is the **Business Edition** variant, shipping the `portainer/portainer-ee` build. Business Edition is free for up to 3 nodes with a license key obtained by registering at <https://www.portainer.io/take-3>. Enter that key in the web UI on first launch; without one it runs a time-limited trial. All add-on options and behaviour are otherwise identical to the Community Edition add-on.

# Quick start
- Add my repository using this link
[![Add repository on my Home Assistant][repository-badge]][repository-url]
- Install the Portainer Business Edition addon from my repo
- On first launch, open the web UI and enter your Business Edition license key
- In the configuration panel of the addon, you can change the password
- In the main page of the addon, disable "Protection mode", then start the addon
- Login (default name is `admin`, default password is `homeassistant`)
- Click on `Primary` in the environement (at the center of the page)
- Click on `Containers` in the left menu bar
- Increase the number of items per page to see all your addons
- Click on the symbol `>_` next to the name of your selected addon to open the console page
- Either change the username, or more usually just click connect
- Type your commands, you have full access to the terminal of this specific container (this does not affect other parts of your HA system)

# Impact on your system
- There is no impact of installing, or running portainer
- Installing manually a custom container will modify your HA status to an unsupported/unhealthy state. You will be blocked from upgrading Home Assistant and upgrading any Add-ons you may have. Stopping this custom container will reset the normal status

# Tips and tricks

## Reset database
Just change the password in your addon options and the database will be reset

## Timeout of 60s
The addon includes a very long timeout. However, if you use another layer of proxy such as the addon nginx proxy manager, it will default to a timeout of 60s. You'll have to adapt the proxy layer to increase timeout. More details here : https://github.com/portainer/portainer/issues/2953#issuecomment-1235795256

## Further reference
- Here is a full guide on using it : https://codeopolis.com/posts/beginners-guide-to-portainer/
- Old page on the HA community forum about portainer : https://community.home-assistant.io/t/home-assistant-community-add-on-portainer

[repository-badge]: https://img.shields.io/badge/Add%20repository%20to%20my-Home%20Assistant-41BDF5?logo=home-assistant&style=for-the-badge
[repository-url]: https://my.home-assistant.io/redirect/supervisor_add_addon_repository/?repository_url=https%3A%2F%2Fgithub.com%2Falexbelgium%2Fhassio-addons

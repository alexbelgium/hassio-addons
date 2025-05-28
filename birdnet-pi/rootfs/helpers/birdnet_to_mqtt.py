#! /usr/bin/env python3
# birdnet_to_mqtt.py

import os
import sys
import time
import re
import datetime
import json
import logging
import paho.mqtt.client as mqtt
import requests

sys.path.append("/home/pi/BirdNET-Pi/scripts/utils")
from helpers import get_settings

# Setup basic configuration for logging
logging.basicConfig(level=logging.INFO)
log = logging.getLogger(__name__)

# Used in flickrimage
flickr_images = {}
conf = get_settings()
settings_dict = dict(conf)

# MQTT server configuration
mqtt_server = "%%mqtt_server%%"
mqtt_user = "%%mqtt_user%%"
mqtt_pass = "%%mqtt_pass%%"
mqtt_port = "%%mqtt_port%%"
mqtt_topic = "birdnet"
bird_lookup_url_base = "http://en.wikipedia.org/wiki/"


def on_connect(client, userdata, flags, rc):  # , properties=None):
    """Callback for when the client receives a CONNACK response from the server."""
    if rc == 0:
        log.info("Connected to MQTT Broker!")
    else:
        log.error(f"Failed to connect, return code {rc}\n")


def get_bird_code(scientific_name):
    with open("/home/pi/BirdNET-Pi/scripts/ebird.php", "r") as file:
        data = file.read()

    array_str = re.search(r"\$ebirds = \[(.*?)\];", data, re.DOTALL).group(1)

    bird_dict = {
        re.search(r'"(.*?)"', line).group(1): re.search(r'=> "(.*?)"', line).group(1)
        for line in array_str.split("\n")
        if "=>" in line
    }

    return bird_dict.get(scientific_name)


def automatic_mqtt_publish(file, detection, path):
    bird = {}
    bird["Date"] = detection.date
    bird["Time"] = detection.time
    bird["ScientificName"] = detection.scientific_name.replace("_", " ")
    bird["CommonName"] = detection.common_name
    bird["Confidence"] = detection.confidence
    bird["SpeciesCode"] = get_bird_code(detection.scientific_name)
    bird["ClipName"] = path
    bird["url"] = bird_lookup_url_base + detection.scientific_name.replace(" ", "_")

    # Flickimage
    image_url = ""
    common_name = detection.common_name
    if len(settings_dict.get("FLICKR_API_KEY")) > 0:
        if common_name not in flickr_images:
            try:
                headers = {"User-Agent": "Python_Flickr/1.0"}
                url = (
                    "https://www.flickr.com/services/rest/?method=flickr.photos.search&api_key="
                    + str(settings_dict.get("FLICKR_API_KEY"))
                    + "&text="
                    + str(common_name)
                    + " bird&sort=relevance&per_page=5&media=photos&format=json&license=2%2C3%2C4%2C5%2C6%2C9&nojsoncallback=1"
                )
                resp = requests.get(url=url, headers=headers, timeout=10)

                resp.encoding = "utf-8"
                data = resp.json()["photos"]["photo"][0]

                image_url = (
                    "https://farm"
                    + str(data["farm"])
                    + ".static.flickr.com/"
                    + str(data["server"])
                    + "/"
                    + str(data["id"])
                    + "_"
                    + str(data["secret"])
                    + "_n.jpg"
                )
                flickr_images[common_name] = image_url
            except Exception as e:
                print("FLICKR API ERROR: " + str(e))
                image_url = ""
        else:
            image_url = flickr_images[common_name]

        bird["FlickrImage"] = image_url

        json_bird = json.dumps(bird)
        mqttc.reconnect()
        mqttc.publish(mqtt_topic, json_bird, 1)
        log.info("Posted to MQTT: ok")


mqttc = mqtt.Client("birdnet_mqtt")
mqttc.username_pw_set(mqtt_user, mqtt_pass)
mqttc.on_connect = on_connect

try:
    mqttc.connect(mqtt_server, mqtt_port)
    mqttc.loop_start()

    # Assuming `file` and `detections` are provided from somewhere
    # automatic_mqtt_publish(file, detections)

except Exception as e:
    log.error("Cannot post mqtt: %s", e)

finally:
    mqttc.loop_stop()
    mqttc.disconnect()

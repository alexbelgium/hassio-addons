#! /usr/bin/env python3
# birdnet_to_mqtt.py
#
# from https://gist.github.com/JuanMeeske/08b839246a62ff38778f701fc1da5554
#
# monitor the records in the syslog file for info from the birdnet system on birds that it detects
# publish this data to mqtt
#

import time
import re
import dateparser
import datetime
import json
import sys
import logging
import paho.mqtt.client as mqtt

# Setup basic configuration for logging
logging.basicConfig(level=logging.INFO)

# Constants
SYSLOG_FILE_PATH = '/proc/1/fd/1'
MQTT_SERVER = "%%mqtt_server%%"  # Replace with your MQTT server address or hostname
MQTT_PORT = %%mqtt_port%%
MQTT_KEEPALIVE = 60
MQTT_TOPIC_ALL_BIRDS = 'birdnet'
CLIENT_ID = 'python-mqtt'
USERNAME = "%%mqtt_user%%"  # Replace with your MQTT username
PASSWORD = "%%mqtt_pass%%"  # Replace with your MQTT password
# Extract the value of confidence and convert it to float
with open('/config/birdnet.conf', 'r') as file:
    lines = file.readlines()
    for line in lines:
        if line.startswith('CONFIDENCE='):
            CONFIDENCE = float(line.split('=')[1].strip())

# Regular expression pattern to parse log entries
RE_BIRD_ENTRY = re.compile(
    r'(\d{4}-\d{2}-\d{2};\d{2}:\d{2}:\d{2};[^;]+;[^;]+;\d+\.\d+;\d+\.\d+;\d+\.\d+;\d+\.\d+;\d+;\d+\.\d+;\d+\.\d+;)([^ ]+\.mp3)'
)

def file_row_generator(file_path):
    """ Generator that yields new lines from a file continuously. """
    with open(file_path, 'r') as file:
        file.seek(0, 2)  # Move the pointer to the end of the file
        while True:
            line = file.readline()
            if not line:
                time.sleep(0.1)  # Sleep briefly to avoid busy waiting
                continue
            yield line

def on_connect(client, userdata, flags, rc, properties=None):
    """ Callback for when the client receives a CONNACK response from the server. """
    if rc == 0:
        logging.info("Connected to MQTT Broker!")
    else:
        logging.error(f"Failed to connect, return code {rc}\n")

def on_disconnect(client, userdata, rc, disconnect_flags, properties=None):
    """ Callback for when the client disconnects from the server. """
    logging.info(f"Disconnected from MQTT Broker with rc: {rc}")

# Setup MQTT client
mqtt_client = mqtt_client.Client(client_id)
mqtt_client.username_pw_set(USERNAME, PASSWORD)
mqtt_client.on_connect = on_connect
mqtt_client.on_disconnect = on_disconnect

# Connect to MQTT Broker
mqtt_client.connect(MQTT_SERVER, MQTT_PORT, MQTT_KEEPALIVE)
mqtt_client.loop_start()

try:
    # Process each new line in the syslog file
    for row in file_row_generator(SYSLOG_FILE_PATH):
        try:
            match = RE_BIRD_ENTRY.search(row)
            if match:
                details, mp3_filename = match.groups()
                details_list = details.split(';')
                detection_date = details_list[0]
                detection_time = details_list[1]
                species = details_list[2]
                common_name = details_list[3]
                latitude = float(details_list[5])
                longitude = float(details_list[6])

                confidence = float(details_list[4])
                if confidence > CONFIDENCE:
                    bird_data = {
                        'SourceNode': 'BirdNET-Pi',
                        'Date': detection_date,
                        'Time': detection_time,
                        'ScientificName': species,
                        'CommonName': common_name,
                        'Confidence': confidence,
                        'Latitude': latitude,
                        'Longitude': longitude,
                        'ClipName': mp3_filename
                    }

                    logging.info(f"Published bird data: {bird_data}")

                    # Publishing data to MQTT
                    mqtt_client.publish(MQTT_TOPIC_ALL_BIRDS, json.dumps(bird_data), qos=1)
                else:
                    continue  # Skip this iteration if no matching log entry is found
            else:
                continue  # Skip this iteration if no matching log entry is found

        except Exception as e:
            logging.error(f"Error processing row: {e}")

finally:
    mqtt_client.loop_stop()
    mqtt_client.disconnect()

sys.exit(0)

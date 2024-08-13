#! /usr/bin/env python3
# birdnet_to_mqtt.py
#
# Adapted from : https://gist.github.com/deepcoder/c309087c456fc733435b47d83f4113ff
# Adapted from : https://gist.github.com/JuanMeeske/08b839246a62ff38778f701fc1da5554
#
# monitor the records in the syslog file for info from the birdnet system on birds that it detects
# publish this data to mqtt
#

import time
import re
import dateparser
import datetime
import json
import logging
import paho.mqtt.client as mqtt
import subprocess

# Setup basic configuration for logging
logging.basicConfig(level=logging.INFO)

# this generator function monitors the requested file handle for new lines added at its end
# the newly added line is returned by the function
def file_row_generator(s):
    while True :
        line = s.readline()
        if not line:
            time.sleep(0.1)
            continue
        yield line

# mqtt server
mqtt_server = "%%mqtt_server%%" # server for mqtt
mqtt_user = "%%mqtt_user%%"  # Replace with your MQTT username
mqtt_pass = "%%mqtt_pass%%"  # Replace with your MQTT password
mqtt_port = %%mqtt_port%% # port for mqtt

# mqtt topic for bird heard above threshold will be published
mqtt_topic_confident_birds = 'birdnet'

# url base for website that will be used to look up info about bird
bird_lookup_url_base = 'http://en.wikipedia.org/wiki/'

# regular expression patters used to decode the records from birdnet
re_high_clean = re.compile(r'(?<=^\[birdnet_analysis\]\[INFO\] ).*?(?=\.mp3$)')

syslog = open('/proc/1/fd/1', 'r')

def on_connect(client, userdata, flags, rc, properties=None):
    """ Callback for when the client receives a CONNACK response from the server. """
    if rc == 0:
        logging.info("Connected to MQTT Broker!")
    else:
        logging.error(f"Failed to connect, return code {rc}\n")

def get_bird_code(scientific_name):
    with open('/home/pi/BirdNET-Pi/scripts/ebird.php', 'r') as file:
        data = file.read()

    # Extract the array from the PHP file
    array_str = re.search(r'\$ebirds = \[(.*?)\];', data, re.DOTALL).group(1)

    # Convert the PHP array to a Python dictionary
    bird_dict = {re.search(r'"(.*?)"', line).group(1): re.search(r'=> "(.*?)"', line).group(1)
                 for line in array_str.split('\n') if '=>' in line}

    # Return the corresponding value for the given bird's scientific name
    return bird_dict.get(scientific_name)

# this little hack is to make each received record for the all birds section unique
# the date and time that the log returns is only down to the 1 second accuracy, do
# you can get multiple records with same date and time, this will make Home Assistant not
# think there is a new reading so we add a incrementing tenth of second to each record received
ts_noise = 0.0

#try :
# connect to MQTT server
mqttc = mqtt.Client('birdnet_mqtt')  # Create instance of client with client ID
mqttc.username_pw_set(mqtt_user, mqtt_pass) # Use credentials
mqttc.connect(mqtt_server, mqtt_port)  # Connect to (broker, port, keepalive-time)
mqttc.on_connect = on_connect
mqttc.loop_start()

# call the generator function and process each line that is returned
for row in file_row_generator(syslog):
    # bird found above confidence level found, process it
    if re_high_clean.search(row) :

        # this slacker regular expression work, extracts the data about the bird found from the log line
        # I do the parse in two passes, because I did not know the re to do it in one!

        raw_high_bird = re.search(re_high_clean, row)
        raw_high_bird = raw_high_bird.group(0)

        # the fields we want are separated by semicolons, so split
        high_bird_fields = raw_high_bird.split(';')

        # build a structure in python that will be converted to json
        bird = {}

        # human time in this record is in two fields, date and time. They are human format
        # combine them together separated by a space and they turn the human data into a python
        # timestamp
        raw_ts = high_bird_fields[0] + ' ' + high_bird_fields[1]

        #bird['ts'] = str(datetime.datetime.timestamp(dateparser.parse(raw_ts)))
        bird['Date'] = high_bird_fields[0]
        bird['Time'] = high_bird_fields[1]
        bird['ScientificName'] = high_bird_fields[2]
        bird['CommonName'] = high_bird_fields[3]
        bird['Confidence'] = high_bird_fields[4]
        bird['SpeciesCode'] = get_bird_code(high_bird_fields[2])
        bird['ClipName'] = high_bird_fields[11]

        # build a url from scientific name of bird that can be used to lookup info about bird
        bird['url'] = bird_lookup_url_base + high_bird_fields[2].replace(' ', '_')

        # Flickimage
        image_url = ""
        if len(settings_dict.get('FLICKR_API_KEY')) > 0:
            if comName not in flickr_images:
                try:
                    headers = {'User-Agent': 'Python_Flickr/1.0'}
                    url = ('https://www.flickr.com/services/rest/?method=flickr.photos.search&api_key=' + str(settings_dict.get('FLICKR_API_KEY')) +
                           '&text=' + str(comName) + ' bird&sort=relevance&per_page=5&media=photos&format=json&license=2%2C3%2C4%2C5%2C6%2C9&nojsoncallback=1')
                    resp = requests.get(url=url, headers=headers, timeout=10)

                    resp.encoding = "utf-8"
                    data = resp.json()["photos"]["photo"][0]

                    image_url = 'https://farm'+str(data["farm"])+'.static.flickr.com/'+str(data["server"])+'/'+str(data["id"])+'_'+str(data["secret"])+'_n.jpg'
                    flickr_images[comName] = image_url
                except Exception as e:
                    print("FLICKR API ERROR: "+str(e))
                    image_url = ""
            else:
                image_url = flickr_images[comName]
            bird['Image'] = image_url

        # convert to json string we can sent to mqtt
        json_bird = json.dumps(bird)

        print('Posted to MQTT : ok')

        mqttc.publish(mqtt_topic_confident_birds, json_bird, 1)

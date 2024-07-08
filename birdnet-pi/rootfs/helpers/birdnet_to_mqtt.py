#! /usr/bin/env python3
# birdnet_to_mqtt.py
#
# 202306171542
#
# monitor the records in the syslog file for info from the birdnet system on birds that it detects
# publish this data to mqtt
#

import time
import re
import dateparser    
import datetime
import json
import paho.mqtt.client as mqtt


# this generator function monitors the requested file handle for new lines added at its end
# the newly added line is returned by the function
def file_row_generator(s):
    while True :
        line = s.readline()
        if not line:
            time.sleep(0.1)
            continue
        yield line

# flag to select whether to process all detections, if False, only the records above the set threshold will be processed

process_all = False

# mqtt server
mqtt_server = "%%mqtt_server%%" # server for mqtt
mqtt_user = "%%mqtt_user%%"  # Replace with your MQTT username
mqtt_pass = "%%mqtt_pass%%"  # Replace with your MQTT password
mqtt_port = %%mqtt_port%% # port for mqtt

# mqtt topic where all heard birds will be published
mqtt_topic_all_birds = 'birdpi/all'

# mqtt topic for bird heard above threshold will be published
mqtt_topic_confident_birds = 'birdpi/confident'

# url base for website that will be used to look up info about bird
bird_lookup_url_base = 'http://en.wikipedia.org/wiki/'

# regular expression patters used to decode the records from birdnet

re_all_found = re.compile(r'birdnet_analysis\.sh.*\(.*\)')
re_found_bird = re.compile(r'\(([^)]+)\)')
re_log_timestamp = re.compile(r'.+?(?= birdnet-)')

re_high_found = re.compile(r'(?<=python3\[).*\.mp3$')
re_high_clean = re.compile(r'(?<=\]:).*\.mp3$')

syslog = open('/proc/1/fd/1', 'r')

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
mqttc.loop_start()

# call the generator function and process each line that is returned
for row in file_row_generator(syslog):
    # if line in log is from 'birdnet_analysis.sh' routine, then operate on it

    # if selected the process the line return for every detection, even below threshold, this generates a lot more records to MQTT
    if process_all and re_all_found.search(row) :

        # get time stamp of the log entry
        timestamp = str(datetime.datetime.timestamp(dateparser.parse(re.search(re_log_timestamp, row).group(0))) + ts_noise)

        ts_noise = ts_noise + 0.1
        if ts_noise > 0.9 :
            ts_noise = 0.0

        # extract the scientific name, common name and confidence level from the log entry
        res = re.search(re_found_bird, row).group(1).split(',', 1)

        # messy code to deal with single and/or double quotes around scientific name and common name
        # while keeping a single quote in string of common name if that is part of bird name
        if '"' in res[0] :
            res[0] = res[0].replace('"', '')
        else :
            res[0] = res[0].replace("'", "")

        # scientific name of bird is found prior to the underscore character
        # common name of bird is after underscore string
        # remainder of string is the confidence level
        sci_name = res[0].split('_', 1)[0]
        com_name = res[0].split('_', 1)[1]
        confid = res[1].replace(' ', '')

        # build python structure of fields that we will then turn into a json string
        bird = {}
        bird['ts'] = timestamp
        bird['sciname'] = sci_name
        bird['comname'] = com_name
        bird['confidence'] = confid
        # build a url from scientific name of bird that can be used to lookup info about bird
        bird['url'] = bird_lookup_url_base + sci_name.replace(' ', '_')

        # convert to json string we can sent to mqtt
        json_bird = json.dumps(bird)

        print(json_bird)

        mqttc.publish(mqtt_topic_all_birds, json_bird, 1)

    # bird found above confidence level found, process it
    if re_high_found.search(row) :

        # this slacker regular expression work, extracts the data about the bird found from the log line
        # I do the parse in two passes, because I did not know the re to do it in one!

        raw_high_bird = re.search(re_high_found, row)
        raw_high_bird = raw_high_bird.group(0)
        raw_high_bird = re.search(re_high_clean, raw_high_bird)
        raw_high_bird = raw_high_bird.group(0)

        # the fields we want are separated by semicolons, so split
        high_bird_fields = raw_high_bird.split(';')

        # build a structure in python that will be converted to json
        bird = {}

        # human time in this record is in two fields, date and time. They are human format
        # combine them together separated by a space and they turn the human data into a python
        # timestamp
        raw_ts = high_bird_fields[0] + ' ' + high_bird_fields[1]

        bird['ts'] = str(datetime.datetime.timestamp(dateparser.parse(raw_ts)))
        bird['sciname'] = high_bird_fields[2]
        bird['comname'] = high_bird_fields[3]
        bird['confidence'] = high_bird_fields[4]
        # build a url from scientific name of bird that can be used to lookup info about bird
        bird['url'] = bird_lookup_url_base + high_bird_fields[2].replace(' ', '_')

        # convert to json string we can sent to mqtt
        json_bird = json.dumps(bird)

        print(json_bird)

        mqttc.publish(mqtt_topic_confident_birds, json_bird, 1)
        

#!/bin/bash

# Check if there are at least 2 arguments
if [ $$ -lt 2 ]; then
  echo "This script requires at least two arguments!"
  exit 1
fi

set +u #avoid error with apprise variables
source /etc/birdnet/birdnet.conf

#OLDNAME="Mésange_charbonnière-78-2024-05-02-birdnet-RTSP_1-18:14:08.mp3"
#NEWNAME="Lapinus atricapilla_Lapinu à tête noire"
OLDNAME="$1"
NEWNAME="$2"
LABELS_FILE="$HOME/BirdNET-Pi/model/labels.txt"
DB_FILE="$HOME/BirdNET-Pi/scripts/birds.db"
DETECTIONS_TABLE="detections"

# Check if $NEWNAME is found in the file $LABELS_FILE
if ! grep -q "$NEWNAME" "$LABELS_FILE"; then
    echo "Error: $NEWNAME not found in $LABELS_FILE"
    exit 1
fi

# Extract the part before the _ from $NEWNAME
NEWNAME_comname="${NEWNAME#*_}"
NEWNAME_sciname="${NEWNAME%%_*}"

# Get the line where the column "File_Name" matches exactly $OLDNAME
IFS='|' read -r OLDNAME_sciname OLDNAME_comname OLDNAME_date < <(sqlite3 "$DB_FILE" "SELECT Sci_Name, Com_Name, Date FROM $DETECTIONS_TABLE WHERE File_Name = '$OLDNAME';")

echo "This script will change the identification $OLDNAME from $OLDNAME_comname to $NEWNAME_comname"

if [[ -z "$OLDNAME_sciname" ]]; then
    echo "Error: No line matching $OLDNAME in $DB_FILE"
    exit 1
fi

# Replace spaces with underscores
NEWNAME_comname2="${NEWNAME_comname// /_}"
OLDNAME_comname2="${OLDNAME_comname// /_}"

# Replace OLDNAME_comname2 with NEWNAME_comname2 in OLDNAME
echo $OLDNAME
NEWNAME_filename="${OLDNAME//$OLDNAME_comname2/$NEWNAME_comname2}"

# Check if the file exists
FILE_PATH="$HOME/BirdSongs/Extracted/By_Date/$OLDNAME_date/$OLDNAME_comname2/$OLDNAME"
if [[ -f $FILE_PATH ]]; then
    # Ensure the new directory exists
    NEW_DIR="$HOME/BirdSongs/Extracted/By_Date/$OLDNAME_date/$NEWNAME_comname2"
    mkdir -p "$NEW_DIR"
    
    # Move and rename the file
    mv "$FILE_PATH" "$NEW_DIR/$NEWNAME_filename"
    mv "$FILE_PATH".png "$NEW_DIR/$NEWNAME_filename".png
    
    echo "Files moved!"
else
    echo "Error: File $FILE_PATH does not exist"
fi

# Update the database
sqlite3 "$DB_FILE" "UPDATE $DETECTIONS_TABLE SET Sci_Name = '$NEWNAME_sciname', Com_Name = '$NEWNAME_comname', File_Name = '$NEWNAME_filename' WHERE File_Name = '$OLDNAME';"

echo "Database entry remove"

echo "All done!"

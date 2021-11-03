#!/usr/bin/env bash

# https://blog.ip2location.com/knowledge-base/find-distance-between-2-ips-using-bash/

#This is the location of bin file
#You must modify for your system
BIN_FILE="IP2LOCATION-LITE-DB5.BIN"


EARTH_RADIUS="6371"
PI="3.141592653589793"

#Converts degrees in radians (
deg2rad() {
        bc -l <<< "$1 * $PI / 180"
}

#Converts radians in degrees
rad2deg()  {
        bc -l <<< "$1 * 180 / $PI"
}

#Calculates acos($radians), because bc has no acos function
acos()  {
        bc -l <<<"$PI / 2 - a($1 / sqrt(1 - $1 * $1))"
}

#Applies The Spherical Law of Cosines for finding distance between 2 coordinates
getDistance() {
    delta_lat=$(bc <<<"$LAT2 - $LAT1")
    delta_lon=$(bc <<<"$LONG2 - $LONG1")
    LAT1=$(deg2rad "$LAT1")
    LONG1=$(deg2rad "$LONG1")
    LAT2=$(deg2rad "$LAT2")
    LONG2=$(deg2rad "$LONG2")
    delta_lat=$(deg2rad "$delta_lat")
    delta_lon=$(deg2rad "$delta_lon")

    DISTANCE=$(bc -l <<< "s($LAT1) * s($LAT2) + c($LAT1) * c($LAT2) * c($delta_lon)")

    DISTANCE=$(acos "$DISTANCE")
    DISTANCE=$(bc -l <<< "$DISTANCE * $EARTH_RADIUS")
    DISTANCE=$(bc <<<"scale=4; $DISTANCE / 1")
}

#Retrieves the coordinates for the 2 IPs
getCoordinate() {
    #Call ip2locationLatLong for $IP1
    output=$(./ip2locationLatLong "$BIN_FILE" "$IP1")

    #Parse the output to obtain both coordinates
    LAT1=$(echo "$output" | cut -d ',' -f 1)
    LONG1=$(echo "$output" | cut -d ',' -f 2)

    #Call ip2locationLatLong for $IP2
    output=$(./ip2locationLatLong "$BIN_FILE" "$IP2")

    #Parse the output to obtain both coordinates
    LAT2=$(echo "$output" | cut -d ',' -f 1)
    LONG2=$(echo "$output" | cut -d ',' -f 2)
}

#Prints the coordinates for the 2 IPs
printCoordinate() {
    echo "Coordinates for $IP1: ($LAT1,$LONG1)"
    echo "Coordinates for $IP2: ($LAT2,$LONG2)"
}

#Checks if the coordinates are not empty
validCoord() {
    ip=$1
    coord=$2

    if [ "$coord" = "" ]; then
        echo "$ip is not a good address"
        exit 0
    fi
}

#Checks if the script is run with 2 parameters
if [ $# -ne 2 ]; then
    echo "Usage: $(basename "$0") IP1 IP2"
    exit 0
fi

if [ ! -s "ip2locationLatLong" ]; then
    echo "ip2locationLatLong not found!"
    exit 0
fi

IP1=$1
IP2=$2

#Retrieves and validates the coordinates
getCoordinate
printCoordinate
validCoord "$IP1" "$LAT1"
validCoord "$IP1" "$LONG1"
validCoord "$IP2" "$LAT2"
validCoord "$IP2" "$LONG2"

#Calculate and print the distance
getDistance
echo "Distance between $IP1 and $IP2 is $DISTANCE km"

# How to get distanct between 2 IP:
# DISTANCT_2IP=$(./ip2location_distance.sh IP1 IP2 | grep -Eo 'is ([0-9.])+ km' | grep -Eo '([0-9.])+')
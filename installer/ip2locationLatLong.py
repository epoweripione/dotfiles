# Usage:
# python ip2locationLatLong.py 8.8.8.8
# python ip2locationLatLong.py 8.8.8.8 orig
# python ip2locationLatLong.py 8.8.8.8 city
# python ip2locationLatLong.py 8.8.8.8 full
import os
import sys
import re
import IP2Location

def check_ip(ipAddr):
    compile_ip=re.compile('^(1\d{2}|2[0-4]\d|25[0-5]|[1-9]\d|[1-9])\.(1\d{2}|2[0-4]\d|25[0-5]|[1-9]\d|\d)\.(1\d{2}|2[0-4]\d|25[0-5]|[1-9]\d|\d)\.(1\d{2}|2[0-4]\d|25[0-5]|[1-9]\d|\d)$')
    if compile_ip.match(ipAddr):
        return True    
    else:    
        return False

# ScriptName = sys.argv[0]

if (len(sys.argv) == 1):
    print('Usage: python ' + sys.argv[0] + ' IPAddress')
    exit(0)

TargetIP = sys.argv[1]
if (not check_ip(TargetIP)):
    print(TargetIP + ' isn\'t a valid IP address!')
    exit(0)

if (len(sys.argv) > 2):
    OutputContent = sys.argv[2]
else:
    OutputContent = 'latitude'

'''
    Cache the database into memory to accelerate lookup speed.
    WARNING: Please make sure your system have sufficient RAM to use this feature.
'''
# database = IP2Location.IP2Location(os.path.join("data", "IP2LOCATION-LITE-DB5.BIN"), "SHARED_MEMORY")

database = IP2Location.IP2Location(os.path.join("./", "IP2LOCATION-LITE-DB5.BIN"))

rec = database.get_all(TargetIP)

if (OutputContent == 'orig'):
    print(rec)
elif (OutputContent == 'full'):
    if (rec.country_short): print('Country(short): ' + rec.country_short)
    if (rec.country_long): print('Country(long): ' + rec.country_long)
    if (rec.region): print('Region: ' + rec.region)
    if (rec.city): print('City: ' + rec.city)
    if (rec.isp): print('ISP: ' + rec.isp)
    print('Latitude: ' + str(rec.latitude))
    print('Longitude: ' + str(rec.longitude))
    if (rec.domain): print('Domain: ' + rec.domain)
    if (rec.zipcode): print('Zipcode: ' + rec.zipcode)
    if (rec.timezone): print('Timezone: ' + rec.timezone)
    if (rec.netspeed): print('Netspeed: ' + rec.netspeed)
    if (rec.idd_code): print('IDD Code: ' + rec.idd_code)
    if (rec.area_code): print('Area Code: ' + rec.area_code)
    if (rec.weather_code): print('Weather Code: ' + rec.weather_code)
    if (rec.weather_name): print('Weather Name: ' + rec.weather_name)
    if (rec.mcc): print('MCC: ' + rec.mcc)
    if (rec.mnc): print('MNC: ' + rec.mnc)
    if (rec.mobile_brand): print('Mobile Brand: ' + rec.mobile_brand)
    if (rec.elevation): print('Elevation: ' + rec.elevation)
    if (rec.usage_type): print('Usage type: ' + rec.usage_type)
elif (OutputContent == 'city'):
    if (rec.country_short): print('Country(short): ' + rec.country_short)
    if (rec.country_long): print('Country(Long): ' + rec.country_long)
    if (rec.region): print('Region: ' + rec.region)
    if (rec.city): print('City: ' + rec.city)
else:
    print(str(rec.latitude) + ',' + str(rec.longitude))

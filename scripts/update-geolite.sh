#!/bin/bash

mkdir -p /var/www/app/uploads/system/
# This script will download the licensed MaxMind GeoLite2-City Database
wget -q "https://download.maxmind.com/app/geoip_download?edition_id=GeoLite2-City&license_key=${BLESTA_MM_LICENSE}&suffix=tar.gz" -O /tmp/GeoLite2-City.tar.gz && \
tar xzf /tmp/GeoLite2-City.tar.gz -C /var/www/app/uploads/system/ \
--strip-components=1 \
--wildcards \
--no-anchored '*GeoLite2-City.mmdb' && \
rm -f /tmp/GeoLite2-City.tar.gz 
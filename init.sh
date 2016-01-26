#!/bin/sh

rm -rf cache/maps
rm -rf cache/data
rm -rf cache/zips

mkdir -p cache/maps
mkdir -p cache/data
mkdir -p cache/zips

rm -f logs/access.log
mkdir -p logs
touch logs/access.log

chown www-data:www-data cache/maps
chown www-data:www-data cache/data
chown www-data:www-data cache/zips

chown www-data:www-data logs/access.log

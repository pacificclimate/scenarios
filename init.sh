#!/bin/sh

sudo rm -rf cache/maps
sudo rm -rf cache/data
sudo rm -rf cache/zips

mkdir -p cache/maps
mkdir -p cache/data
mkdir -p cache/zips

sudo rm -f logs/access.log
mkdir -p logs
touch logs/access.log

sudo chown www-data:www-data cache/maps
sudo chown www-data:www-data cache/data
sudo chown www-data:www-data cache/zips

sudo chown www-data:www-data logs/access.log

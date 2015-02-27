#!/bin/sh

sudo rm -rf cache/maps
sudo rm -rf cache/data
sudo rm -rf cache/zips

sudo mkdir -p cache/maps
sudo mkdir -p cache/data
sudo mkdir -p cache/zips

sudo rm -f logs/access.log
sudo mkdir -p logs
sudo touch logs/access.log

sudo chown www-data:www-data cache/maps
sudo chown www-data:www-data cache/data
sudo chown www-data:www-data cache/zips

sudo chown www-data:www-data logs/access.log

#!/bin/sh

sudo rm -rf cache/maps
sudo rm -rf cache/data
sudo rm -rf cache/zips

mkdir cache/maps
mkdir cache/data
mkdir cache/zips

sudo rm logs/access.log
touch logs/access.log

sudo chown www-data:www-data cache/maps
sudo chown www-data:www-data cache/data
sudo chown www-data:www-data cache/zips

sudo chown www-data:www-data logs/access.log

#!/bin/sh
sudo apt update
sudo apt -yf dist-upgrade
sudo apt-get -y --purge autoremove
sudo apt-get autoclean
pihole -g -up
pihole -up

#!/bin/sh
sudo systemctl stop whoogle
pip install whoogle-search
sudo systemctl restart whoogle

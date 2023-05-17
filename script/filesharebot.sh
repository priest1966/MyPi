#!/usr/bin/env bash

# Wait for the network to be fully configured
systemctl wait network-online.target

# Change to the File-Sharing-Bot userbot directory
cd /home/$USER/File-sharing-Bot

# Start the userbot
python3 main.py


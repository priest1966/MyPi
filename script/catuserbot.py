#!/usr/bin/env bash

# Wait for the network to be fully configured
systemctl wait network-online.target

# Change to the catuserbot directory
cd /home/$USER/catuserbot

# Activate the virtual environment and start the userbot
source venv/bin/activate && python3 -m userbot

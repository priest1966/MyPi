#!/usr/bin/env bash

# Wait for the network to be fully configured
systemctl wait network-online.target

# Change to the Ultroid userbot directory
cd /home/$USER//Ultroid

# Activate the virtual environment and start the userbot
source venv/bin/activate && bash startup


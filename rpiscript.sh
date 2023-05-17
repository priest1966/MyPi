#!/bin/bash
#Pihole Pivpn Whoogle Codeserver Ultroid Installation Script
#Upgrade and update system

sudo apt-get update
sudo apt-get upgrade -y
echo Update or Upgrade complete.
echo
echo


# Jellyfin
sudo apt install curl gnupg
sudo mkdir /etc/apt/keyrings
curl -fsSL https://repo.jellyfin.org/$( awk -F'=' '/^ID=/{ print $NF }' /etc/os-release )/jellyfin_team.gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/jellyfin.gpg
cat <<EOF | sudo tee /etc/apt/sources.list.d/jellyfin.sources
Types: deb
URIs: https://repo.jellyfin.org/$( awk -F'=' '/^ID=/{ print $NF }' /etc/os-release )
Suites: $( awk -F'=' '/^VERSION_CODENAME=/{ print $NF }' /etc/os-release )
Components: main
Architectures: $( dpkg --print-architecture )
Signed-By: /etc/apt/keyrings/jellyfin.gpg
EOF
sudo apt update
sudo apt install jellyfin


# Installing Pihole
echo Installing pihole...
curl -sSL https://install.pi-hole.net | bash
echo done
echo
echo 

#Installing Pivpn
echo Installing pivpn...
curl -L https://install.pivpn.io | bash
echo done
echo
echo

# Instlaling Whoogle-search
echo Installing Whoogle-Search...
pip install whoogle-search
sudo cp ~/MyPi/service/whoogle.service /lib/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable whoogle
sudo systemctl start whoogle
echo 
echo 

# Installing Code-server
echo Installing Code-Server...
echo Its take time for download Code-server
curl -fsSL https://code-server.dev/install.sh | sh
code-server
#Edit config file nano ~/.config/code-server/config.yaml
echo Code-Server installation complete!
echo done
echo
echo

# Installation Ultroid
echo Installling Ultroid...
cd ~
git clone https://github.com/TeamUltroid/Ultroid
cd Ultroid
pip3 install virtualenv
virtualenv -p /usr/bin/python3 venv
. ./venv/bin/activate
echo 
sudo apt install -y libavformat-dev libavcodec-dev libavdevice-dev libavutil-dev libswscale-dev libswresample-dev libavfilter-dev pkg-config
echo
pip install --upgrade pip
pip3 uninstall telethon -y
pip3 install https://github.com/New-dev0/Telethon/archive/Vector.zip
pip3 install -U -r re*/st*/optional-requirements.txt
pip3 install -U -r requirements.txt
sudo apt install mediainfo ffmpeg -y && pip install mediainfo
sudo apt install flac
pip uninstall telegraph -y && pip install git+https://github.com/xditya/telegraph
pip install coloredlogs
pip3 install pytgcalls==3.0.0.dev21 && pip3 install av -q --no-binary av
cp ~/MyPi/config/env ~/Ultroid/.env
sudo cp ~/MyPi/service/ultroid.service /etc/systemd/system
sudo systemctl enable ultroid.service
sudo systemctl start ultroid.service
echo done
echo
echo


# Catuserbot
sudo apt install --no-install-recommends -y curl git libffi-dev libjpeg-dev libwebp-dev python3-lxml python3-psycopg2 libpq-dev libcurl4-openssl-dev libxml2-dev libxslt1-dev python3-pip python3-sqlalchemy openssl wget python3 python3-dev libreadline-dev libyaml-dev gcc zlib1g ffmpeg libssl-dev libgconf-2-4 libxi6 unzip libopus0 libopus-dev python3-venv libmagickwand-dev pv tree mediainfo nano nodejs
git clone https://github.com/TgCatUB/catuserbot
cd catuserbot
virtualenv venv
source venv/bin/activate
pip3 install -r requirements.txt
cp ~/MyPi/config/catbotconfig.py ~/catuserbot/config.py
sudo cp ~/MyPi/service/catuserbot.service /etc/systemd/system
sudo systemctl enable catuserbot.service
sudo systemctl start catuserbot.service


# File share Bot
git clone https://github.com/CodeXBotz/File-Sharing-Bot.git
cd File-Sharing-Bot
pip3 install -r requirements.txt
cp ~/MyPi/config/config.py ~/File-Sharing-Bot
sudo cp ~/MyPi/service/filesharebot.service /etc/systemd/system
sudo systemctl enable filesharebot.service
sudo systemctl start filesharebot.service

# Ftp Server
sudo apt install vsftpd
sudo nano /etc/vsftpd.conf
echo Find CTRL + W and uncomment the following lines by removing the hash sign
echo
echo
# write_enable=YES, local_umask=022, chroot_local_user=YES
# Find the anonymous_enable=YES and change to anonymous_enable=NO
# Edit user_sub_token=$USER 
# Local_root=/home/$USER/FTP
mkdir -p /home/$USER/FTP
chmod a-w /home/$USER/FTP
sudo service vsftpd restart

# Make Directory
cd ~
cd ~/MyPi/script
chmod +x *.sh
mkdir Logs
echo done
echo
echo

# Duckdns https://www.duckdns.org/
cd ~
mkdir duckdns
cd duckdns
nano duck.sh
chmod 700 duck.sh
./duck.sh
cat duck.log
echo done
echo
echo

crontab -e

# Now Reboot your Pi







#------------------------------------------------------------
## Install dependencies
sudo apt update
sudo apt install -y build-essential git wget curl subversion \
  libncurses5-dev libssl-dev libxml2-dev libsqlite3-dev uuid-dev \
  libjansson-dev libedit-dev pkg-config autoconf automake libtool \
  unixodbc-dev libcurl4-openssl-dev libspeex-dev libspeexdsp-dev \
  libogg-dev libvorbis-dev libsrtp2-dev libopus-dev libresample1-dev \
  sox mpg123 xmlstarlet bison flex

# Asterisk initial install
cd /usr/src
sudo wget https://downloads.asterisk.org/pub/telephony/asterisk/asterisk-22-current.tar.gz
sudo tar xzf asterisk-22-current.tar.gz
cd asterisk-22*/

# Country code pre-requisites
sudo contrib/scripts/install_prereq install

# MP3 support for music-on-hold
sudo contrib/scripts/get_mp3_source.sh

## Further config, compile & install
# Configure (bundle PJSIP if needed, or use system one)
sudo ./configure --with-jansson-bundled --with-pjproject-bundled

# Select modules (highly recommended for first run) 
# Asterisk Module and Build Option Selection should appear
sudo make menuselect

# Enable chan_pjsip, res_pjsip (under Channel Drivers).
# Enable desired codecs (ulaw, alaw, g722, opus, etc.).
# Enable sounds and MOH if needed.
# Save & exit.

# Compile asterisk
sudo make -j$(nproc)
sudo make install
sudo make samples
sudo make config
sudo make install-logrotate

## Create Asterisk User and Permissions
sudo groupadd asterisk
sudo useradd -r -d /var/lib/asterisk -g asterisk asterisk
sudo chown -R asterisk:asterisk /etc/asterisk /var/lib/asterisk /var/log/asterisk /var/spool/asterisk /var/run/asterisk /usr/lib/asterisk

# Edit and add to /etc/asterisk/asterisk.conf
# [options]
# runuser = asterisk
# rungroup = asterisk

## Ensure your RTP ports are setup (/etc/asterisk/rtp.conf):
# [general]
# rtpstart=10000
# rtpend=20000

# Modules (/etc/asterisk/modules.conf — disable legacy chan_sip):
# Add to /etc/asterisk/modules.conf
noload => chan_sip.so
load => res_pjsip.so
load => chan_pjsip.so

# Edit /etc/asterisk/pjsip.conf, adjust to your own network (I used my VPN IP)
[global]
type=global
user_agent=Asterisk PBX

[transport-udp]
type=transport
protocol=udp
bind=0.0.0.0:5060
external_media_address=YOUR_PUBLIC_IP
external_signaling_address=YOUR_PUBLIC_IP
local_net=192.168.0.0/16   ; adjust for your network

## Basic dialplan (/etc/asterisk/extensions.conf — start simple):
[general]
static=yes
writeprotect=no

[internal]
exten => 100,1,Dial(PJSIP/100)   ; example extension

[from-pstn]   ; incoming from trunk
exten => _X.,1,Answer()
 same => n,Playback(hello-world)
 same => n,Hangup()

## Update services
sudo systemctl enable asterisk
sudo systemctl start asterisk
sudo systemctl status asterisk

# Test
sudo asterisk -rvvv

# UFW entries
sudo ufw allow 5060/udp
sudo ufw allow 5060/tcp
sudo ufw allow 10000:20000/udp
#------------------------------------------------------------
sudo ufw reload

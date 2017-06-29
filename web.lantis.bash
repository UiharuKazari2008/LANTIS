#!/bin/bash

# LANTIS EasyLink 2 #

# Default Values
### Local Config - This host
LOCAL_USER=root               # User to login as
LOCAL_PORT=65500              # Local SSH port to connect back into
LOCAL_WEBHOST=127.0.0.1       # Server Host to rouute web traffic to
LOCAL_WEBPORT1=80             # Server Port (HTTP)
LOCAL_WEBPORT2=443            # Server Port (HTTPS)
LOCAL_OPEN=1                  # Is your local site ports open? Bypass NAT otherwise
### Remote Config - End Point for presentation
REMOTE_USER=root              # User to login as
REMOTE_PORT=22                # SSH port of Remote Server
REMOTE_WEBPORT1=80            # Server Port (HTTP)
REMOTE_WEBPORT2=443           # Server Port (HTTPS)
REMOTE_KILL=0                 # Kill what ever is using port #1
REMOTE_SETUP=0                # Setup Remote Host
#Keys - Common key shared between hosts
KEY=lantis.key          # SSH Key to auth with for both directions

########################################################################################################################

# Display Usage
USAGE(){
cat << EOF
     __    ___    _   _________________
    / /   /   |  / | / /_  __/  _/ ___/
   / /   / /| | /  |/ / / /  / / \__ \ 
  / /___/ ___ |/ /|  / / / _/ / ___/ / 
 /_____/_/  |_/_/ |_/ /_/ /___//____/  
 Lain Anonymous NetworkIng System
 by : Academy City Research
	
 support : help.lantis.project@acr.moe

 Usage:

 Remote Host ===========================================================
 -h  Host to connect to (IP Address or FQDN) (REQUIRED)
 -p  SSH Port (Default: 22)
 -u  User to login as (Default: root)

 Local Host ============================================================
 -P  SSH Port (Default: 65500)
 -U  User to login as (Default: root)

 Router ================================================================
 -H  Local Server (Default: 127.0.0.1)
 -a  Public Port 1   -A Server Port 1 (Default: 80)
 -b  Public Port 2   -B Server Port 2 (Default: 443)

 Extra Options =========================================================
 -K  Key to use for both directions (Default: lantis.key + .pub)
 -R  Use Reverse SSH Tunneling to bypass inbound NAT requirements. 
       Useful if you dont have access to the firewall or router.
 -K  Kill zombie SSH sessions to make way for this connection
 -S  Setup Remote Server
 -C  Source File to use
 -Z  Display Setup Guide

EOF
}
# Display Setup Guide
SETUPGUIDE(){
cat << EOF
     __    ___    _   _________________
    / /   /   |  / | / /_  __/  _/ ___/
   / /   / /| | /  |/ / / /  / / \__ \ 
  / /___/ ___ |/ /|  / / / _/ / ___/ / 
 /_____/_/  |_/_/ |_/ /_/ /___//____/  
 Lain Anonymous NetworkIng System
 by : Academy City Research
	
 support : help.lantis.project@acr.moe

 Setup Guide:

 1) Generate a SSH key in ~/.ssh/id_rsa
      [root@local]~ ssh-keygen –b 4086
 2) Add id_rsa.pub to /root /.ssh/authorized_keys on the remote server
 3) Generate a SSH key for LANTIS in your current directory where the script will stay
      [root@local]~/LANTIS ssh-keygen –b 4096 –f lantis.key
 4) Run this script with –S to auto-setup the remote server and any other options you need like -R
      [root@local]~/LANTIS lantis.bash –h 123.45.67.89 –S 
 5) You should be fine as long as your destination host allows your default ssh key
 6) Normaly use:
      [root@local]~/LANTIS nohup bash lantis.bash –h 123.45.67.89
      nohup: ignoring input and appending output to ‘nohup.out’
      [root@local]~/LANTIS tail nohup.out

EOF
}
# Parse Options
while getopts "h:puPUHabABSRKC:Z" opt; do
  case $opt in
	h) REMOTE_HOST=${OPTARG};;
	p) REMOTE_PORT=${OPTARG};;
	u) REMOTE_USER=${OPTARG};;
	P) LOCAL_PORT=${OPTARG};;
	U) LOCAL_USER=${OPTARG};;
	H) LOCAL_WEBHOST=${OPTARG};;
	a) LOCAL_WEBPORT1=${OPTARG};;
	b) LOCAL_WEBPORT2=${OPTARG};;
	A) REMOTE_WEBPORT1=${OPTARG};;
	B) REMOTE_WEBPORT2=${OPTARG};;
	S) REMOTE_SETUP=1;;
	R) LOCAL_OPEN=0;;
	K) REMOTE_KILL=1;;
	C) source ${OPTARG};;
	Z) SETUPGUIDE; exit;;
    \?) echo "[PEBKAC] WTF is -$OPTARG?, thats not a accepted option, Abort"; USAGE; exit 1;;
    :) echo "[PEBKAC] -$OPTARG requires an argument, Abort"; USAGE; exit 1;;
  esac
done
# Display Usage with no options
if [ $# -lt 1 ]; then USAGE; exit; fi
#SSH Options - Options used for connection
COMMON_OPT="-C -2 -o BatchMode=yes -o StrictHostKeyChecking=no -o TCPKeepAlive=yes -o ServerAliveInterval=5 -o ConnectTimeout=15 -o LogLevel=Error"
LOCAL_OPT="-N -o CompressionLevel=9 -o ExitOnForwardFailure=yes -g -L ${REMOTE_WEBPORT1}:${LOCAL_WEBHOST}:${LOCAL_WEBPORT1} -L ${REMOTE_WEBPORT2}:${LOCAL_WEBHOST}:${LOCAL_WEBPORT2}"

########################################################################################################################

cat << EOF
     __    ___    _   _________________
    / /   /   |  / | / /_  __/  _/ ___/
   / /   / /| | /  |/ / / /  / / \__ \ 
  / /___/ ___ |/ /|  / / / _/ / ___/ / 
 /_____/_/  |_/_/ |_/ /_/ /___//____/  
 Lain Anonymous NetworkIng System
 by : Academy City Research

EOF
echo "= LANTIS EasyLink 2 - Academy City Research ========="
while [ 0 -eq 0 ]; do # Main Loop #####################################################################################
# Check Internet Connection
wget -q --spider https://google.com --timeout=15
if [ $? -eq 0 ]; then # CHECK - Internet Verification ###################################
echo "[$(date)][---] Internet Connection Ready"
# CHECK - Host Verification #############################################################
{ ssh ${REMOTE_HOST} -l ${REMOTE_USER} -p ${REMOTE_PORT} -i ${KEY} ${COMMON_OPT} 'echo "[$(date)][---] End-Point is ready"'
} || { 
# FAULT - Host Verification #############################################################
echo "[$(date)][!!!] End-Point failed to login"
if [ ${REMOTE_SETUP} -eq 1 ]; then # Setup Server #######################################
	echo "[$(date)][>>>] Passing Key..."
	scp ${COMMON_OPT} -o Port=${REMOTE_PORT} ${KEY} ${REMOTE_USER}@${REMOTE_HOST}:${KEY}
	echo "[$(date)][>>>] Setting up the Key..."
	echo "$(cat ${KEY}.pub)" >> ~/.ssh/authorized_keys
	ssh ${REMOTE_HOST} -l ${REMOTE_USER} -p ${REMOTE_PORT} -i ~/.ssh/id_rsa ${COMMON_OPT} << EOF
		echo "$(cat ${KEY}.pub)" >> ~/.ssh/authorized_keys
		#echo "LANTIS" > /etc/motd
EOF
	echo "[$(date)][---] Auto-Setup Complete"
fi # Setup Server #######################################################################
} # END - Host Verification #############################################################
if [ ${LOCAL_OPEN} -eq 0 ]; then # Use Reverse SSH Tunneling
REMOTE_PFWD=" -R ${LOCAL_PORT}:127.0.0.1:22"
LOCAL_IP="127.0.0.1"
echo "[$(date)][---] Reverse Conection will be used"
elif [ ${LOCAL_OPEN} -eq 1 ]; then # Use Direct Connection
REMOTE_PFWD=""
LOCAL_IP="$(curl ipinfo.io/ip 2> /dev/null)"
fi
#Start Stage 2 and Connect Back
echo "[$(date)][>>>] Establishing Control line..." 
ssh ${REMOTE_HOST} -l ${REMOTE_USER} -p ${REMOTE_PORT} -i ${KEY} ${COMMON_OPT} ${REMOTE_PFWD} << EOF
	if [ ${REMOTE_KILL} -eq 1 ]; then # Kill stale SSH port forwarding
		echo "[$(date)][>>>] Sanitizing End-Point..."
		netstat -tlpn | grep ":${LOCAL_WEBPORT1} " | sed -n 's@.* \([0-9]*\)/ssh.*@kill \1@p' | sh > /dev/null
	fi
	echo "[$(date)][<<<] Linked! Accepting Incoming Connections..."
	ssh $LOCAL_IP -l ${LOCAL_USER} -p ${LOCAL_PORT} -i ${KEY} $LOCAL_OPT ${COMMON_OPT}
	echo "[$(date)][!!!] ERROR! Early Termination!"
EOF
else # ELSE - Internet Verification ###########################################################
echo "[$(date)][!!!] ERROR! Internet Connection is not ready!"
fi # END - Internet Verification ###########################################################
echo "[$(date)][!!!] ERROR! Connection Failed!"
sleep 2
done # Main Loop ######################################################################################################
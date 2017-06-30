#!/bin/bash

# LANTIS EasyLink 2 #
# Default Values
### Local Config - This host
LOCAL_USER=root               # User to login as
LOCAL_PORT=65500              # Local SSH port to connect back into
LOCAL_OPEN=1                  # Is your local site ports open? Bypass NAT otherwise
### Remote Config - End Point for presentation
REMOTE_USER=root              # User to login as
REMOTE_PORT=22                # SSH port of Remote Server
REMOTE_KILL=0                 # Kill what ever is using port #1
REMOTE_SETUP=0                # Setup Remote Host
#Keys - Common key shared between hosts
KEY=lantis.key          # SSH Key to auth with for both directions

########################################################################################################################

# Parse Options
while getopts "qnh:p:u:H:P:U:D:t:T:LSRK" opt; do 
  case $opt in
	q) 
	n) 
	h) 
	p) 
	u) 
	H) 
	P) 
	U) 
	D) 
	t) 
	T) 
	L) 
	S) 
	R) 
	K) 
	Z) SETUPGUIDE; exit;;
    \?) echo "[PEBKAC] WTF is -$OPTARG?, thats not a accepted option, Abort"; USAGE; exit 1;;
    :) echo "[PEBKAC] -$OPTARG requires an argument, Abort"; USAGE; exit 1;;
  esac
done
# Display Usage with no options
if [ $# -lt 1 ]; then USAGE; exit; fi
#SSH Options - Options used for connection
COMMON_OPT="-C -2 -o BatchMode=yes -o StrictHostKeyChecking=no -o TCPKeepAlive=yes -o ServerAliveInterval=5 -o ConnectTimeout=15 -o LogLevel=Error"

########################################################################################################################

LOCAL_OPT="-N -o CompressionLevel=9 -o ExitOnForwardFailure=yes ${REMOTE_FWDPUBLIC}"

while [ ${CONNECTION_STATUS} = "E" ]; do # Main Loop ##################################################################
echo 
# Check Internet Connection
wget -q --spider https://google.com --timeout=15
if [ $? -eq 0 ]; then # CHECK - Internet Verification ###################################
echo "[${CONNECTION_NAME}][$(date)][---] Internet Connection Ready"
# CHECK - Host Verification #############################################################
{ ssh ${REMOTE_HOST} -l ${REMOTE_USER} -p ${REMOTE_PORT} -i ${KEY} ${COMMON_OPT} 'echo "[${CONNECTION_NAME}][$(date)][---] End-Point is ready"'
} || { 
# FAULT - Host Verification #############################################################
echo "[${CONNECTION_NAME}][$(date)][!!!] End-Point failed to login"
if [ ${REMOTE_SETUP} -eq 1 ]; then # Setup Server #######################################
	echo "[${CONNECTION_NAME}][$(date)][>>>] Passing Key..."
	scp ${COMMON_OPT} -o Port=${REMOTE_PORT} ${KEY} ${REMOTE_USER}@${REMOTE_HOST}:${KEY}
	echo "[${CONNECTION_NAME}][$(date)][>>>] Setting up the Key..."
	echo "$(cat ${KEY}.pub)" >> ~/.ssh/authorized_keys
	ssh ${REMOTE_HOST} -l ${REMOTE_USER} -p ${REMOTE_PORT} -i ~/.ssh/id_rsa ${COMMON_OPT} << EOF
		echo "$(cat ${KEY}.pub)" >> ~/.ssh/authorized_keys
		#echo "LANTIS" > /etc/motd
EOF
	echo "[${CONNECTION_NAME}][$(date)][---] Auto-Setup Complete"
fi # Setup Server #######################################################################
} # END - Host Verification #############################################################
if [ ${LOCAL_OPEN} -eq 0 ]; then # Use Reverse SSH Tunneling
REMOTE_PFWD=" -R ${LOCAL_PORT}:127.0.0.1:22"
LOCAL_IP="127.0.0.1"
echo "[${CONNECTION_NAME}][$(date)][---] Reverse Conection will be used"
elif [ ${LOCAL_OPEN} -eq 1 ]; then # Use Direct Connection
REMOTE_PFWD=""
LOCAL_IP="$(curl ipinfo.io/ip 2> /dev/null)"
fi
#Start Stage 2 and Connect Back
echo "[${CONNECTION_NAME}][$(date)][>>>] Establishing Control line..." 
ssh ${REMOTE_HOST} -l ${REMOTE_USER} -p ${REMOTE_PORT} -i ${KEY} ${COMMON_OPT} ${REMOTE_PFWD} << EOF
	if [ ${REMOTE_KILL} -eq 1 ]; then # Kill stale SSH port forwarding
		echo "[${CONNECTION_NAME}][$(date)][>>>] Sanitizing End-Point..."
		netstat -tlpn | grep ":${LOCAL_WEBPORT1} " | sed -n 's@.* \([0-9]*\)/ssh.*@kill \1@p' | sh > /dev/null
	fi
	echo "[${CONNECTION_NAME}][$(date)][<<<] Linked! Accepting Incoming Connections"
	ssh $LOCAL_IP -l ${LOCAL_USER} -p ${LOCAL_PORT} -i ${KEY} $LOCAL_OPT ${COMMON_OPT}
	echo "[${CONNECTION_NAME}][$(date)][!!!] ERROR! Early Termination!"
EOF
else # ELSE - Internet Verification #####################################################
echo "[${CONNECTION_NAME}][$(date)][!!!] ERROR! Internet Connection is not ready!"
fi # END - Internet Verification ########################################################
echo "[${CONNECTION_NAME}][$(date)][!!!] ERROR! Connection Failed!"
sleep 2
done # Main Loop ######################################################################################################

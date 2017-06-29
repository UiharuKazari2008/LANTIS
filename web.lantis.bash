#!/bin/bash

# LANTIS EasyLink 2 #

### Local Config - This host
LOCAL_USER=root               # User to login as
LOCAL_PORT=65500              # Local SSH port to connect back into
LOCAL_WEBHOST=127.0.0.1       # Server Host to rouute web traffic to
LOCAL_WEBPORT=80              # Server Port
LOCAL_OPEN=0                  # Is your local site ports open? Bypass NAT otherwise

### Remote Config - End Point for presentation
REMOTE_HOST=104.236.243.143   # Server to use
REMOTE_USER=root              # User to login as
REMOTE_PORT=22                # SSH port of Remote Server
REMOTE_KILL80=1               # Kill what ever is using port 80
REMOTE_SETUP=1                # Setup Remote Host

#Keys - Common key shared between hosts
KEY=/root/lantis.key          # SSH Key to auth with for both directions

#SSH Options - Options used for connection
COMMON_OPT="-C -2 -o BatchMode=yes -o StrictHostKeyChecking=no -o TCPKeepAlive=yes -o ServerAliveInterval=5 -o ConnectTimeout=15 -o LogLevel=Error"
LOCAL_OPT="-N -o CompressionLevel=9 -o ExitOnForwardFailure=yes -g -L ${LOCAL_WEBPORT}:${LOCAL_WEBHOST}:${LOCAL_WEBPORT} -L 443:${LOCAL_WEBHOST}:443"








####################                                                                                                               ####################








echo "= LANTIS EasyLink 2 - Academy City Research ========="

while [ 0 -eq 0 ]; do
# Check Internet Connection
wget -q --spider https://google.com --timeout=15
if [ $? -eq 0 ]; then
echo "[$(date)][---] Internet Connection Ready"

{ 
ssh ${REMOTE_HOST} -l ${REMOTE_USER} -p ${REMOTE_PORT} -i ${KEY} ${COMMON_OPT} 'echo "[$(date)][---] End-Point is ready"'
} || { 
echo "[$(date)][!!!] End-Point failed to login"
#Setup Server - Uncomment to setup server
if [ ${REMOTE_SETUP} -eq 1 ]; then
	#Upload Current SSH Key
	echo "[$(date)][>>>] Passing Key..."
	scp ${COMMON_OPT} -o Port=${REMOTE_PORT} ${KEY} ${REMOTE_USER}@${REMOTE_HOST}:${KEY}
	echo "[$(date)][>>>] Setting up the Key..."
	echo "$(cat ${KEY}.pub)" >> ~/.ssh/authorized_keys
	ssh ${REMOTE_HOST} -l ${REMOTE_USER} -p ${REMOTE_PORT} -i ~/.ssh/id_rsa ${COMMON_OPT} << EOF
		echo "$(cat ${KEY}.pub)" >> ~/.ssh/authorized_keys
		echo "LANTIS" > /etc/motd
EOF
	echo "[$(date)][---] Config Complete"
fi
}

# Bypass Inbound NAT
if [ ${LOCAL_OPEN} -eq 0 ]; then
REMOTE_PFWD=" -R ${LOCAL_PORT}:127.0.0.1:22"
LOCAL_IP="127.0.0.1"
elif [ ${LOCAL_OPEN} -eq 1 ]; then
REMOTE_PFWD=""
LOCAL_IP="$(curl ipinfo.io/ip 2> /dev/null)"
fi

#Start Stage 2 and Connect Back
echo "[$(date)][>>>] Establishing Control line..." 

ssh ${REMOTE_HOST} -l ${REMOTE_USER} -p ${REMOTE_PORT} -i ${KEY} ${COMMON_OPT} ${REMOTE_PFWD} << EOF
	#Kill stale SSH port forwarding
	if [ ${REMOTE_KILL80} -eq 1 ]; then
		echo "[$(date)][>>>] Sanitizing End-Point..."
		netstat -tlpn | grep ":${LOCAL_WEBPORT} " | sed -n 's@.* \([0-9]*\)/ssh.*@kill \1@p' | sh > /dev/null
	fi
	if [ ${LOCAL_OPEN} -eq 0 ]; then
		echo "[$(date)][<<<] Reverse Conection will be used"
	fi
	echo "[$(date)][<<<] Linked! Accepting Incoming Connections..."
	# SSH back in for port fowarding
	ssh $LOCAL_IP -l ${LOCAL_USER} -p ${LOCAL_PORT} -i ${KEY} $LOCAL_OPT ${COMMON_OPT}
	echo "[$(date)][!!!] ERROR! Early Termination!"
EOF

else
#Else, Connection failed
echo "[$(date)][!!!] ERROR! Internet Connection is not ready!"
fi
#When Connection dropped
echo "[$(date)][!!!] ERROR! Connection Failed!"
sleep 2
done

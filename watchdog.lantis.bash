#!/bin/bash
# LANTIS EasyLink 2 #
# Stop if no options
if [ $# -lt 1 ]; echo "No Data"; exit 1; fi
REMOTE_PORTPUB=""; DRY=0
# Parse Options
while getopts "n:h:p:u:H:P:U:D:t:T:LSRK" opt; do 
  case $opt in
	n) CONNECTION_NAME=${OPTARG};;
	h) REMOTE_HOST=${OPTARG};;
	p) REMOTE_PORT=${OPTARG};;
	u) REMOTE_USER=${OPTARG};;
	H) LOCAL_IP=${OPTARG};;
	P) LOCAL_PORT=${OPTARG};;
	U) LOCAL_USER=${OPTARG};;
	D) LOCAL_FWDHOST=${OPTARG};;
	t) REMOTE_FWDPORT=${OPTARG};;
	T) LOCAL_FWDPORT=${OPTARG};;
	L) REMOTE_PORTPUB="-g ";;
	S) REMOTE_SETUP=1;;
	R) LOCAL_OPEN=0;;
	K) REMOTE_KILL=1;;
	X) DRY=1;;
    \?) echo "[PEBKAC] WTF is -$OPTARG?, thats not a accepted option, Abort"; USAGE; exit 1;;
    :) echo "[PEBKAC] -$OPTARG requires an argument, Abort"; USAGE; exit 1;;
  esac
done
echo "[${CONNECTION_NAME}][$(date)][INFO] DATA LOADED"
### Local Config - This host
KEY=lantis.key          # SSH Key to auth with for both directions
#SSH Options - Options used for connection
COMMON_OPT="-C -2 -o BatchMode=yes -o StrictHostKeyChecking=no -o TCPKeepAlive=yes -o ServerAliveInterval=5 -o ConnectTimeout=15 -o LogLevel=Error"
LOCAL_OPT="-N -o CompressionLevel=9 -o ExitOnForwardFailure=yes"
LOCAL_PFWD="-L ${REMOTE_FWDPORT}:${LOCAL_FWDHOST}:${LOCAL_FWDPORT}"

########################################################################################################################


########################################################################################################################


while [ $# -gt 9 ]; do # Main Loop ##################################################################
wget -q --spider https://google.com --timeout=15
if [ $? -eq 0 ]; then # CHECK - Internet Verification ###################################
echo "[${CONNECTION_NAME}][$(date)][INFO] Outbound Internet Connection:  Passed"
# CHECK - Host Verification #############################################################
{ ssh ${REMOTE_HOST} -l ${REMOTE_USER} -p ${REMOTE_PORT} -i ${KEY} ${COMMON_OPT} << EOF
echo "[${CONNECTION_NAME}][$(date)][INFO] Outbound End-Point:            Passed"
EOF
} || { 
# FAULT - Host Verification #############################################################
echo "[${CONNECTION_NAME}][$(date)][ERR!] Outbound End-Point:            No Shell Access/Failed"
if [ ${REMOTE_SETUP} -eq 1 ]; then # Setup Server #######################################
	{echo "[${CONNECTION_NAME}][$(date)][INFO] Passing Key to End-Point..."
	scp ${COMMON_OPT} -o Port=${REMOTE_PORT} ${KEY} ${REMOTE_USER}@${REMOTE_HOST}:${KEY}
	ssh ${REMOTE_HOST} -l ${REMOTE_USER} -p ${REMOTE_PORT} -i ~/.ssh/id_rsa ${COMMON_OPT} << EOF
		echo "$(cat ${KEY}.pub)" >> ~/.ssh/authorized_keys
EOF
	echo "[${CONNECTION_NAME}][$(date)][INFO] Passing Key to Local..."
	if [ ${LOCAL_IP} = "~" ] || [ ${LOCAL_OPEN} -eq 0 ]; then echo "$(cat ${KEY}.pub)" >> ~/.ssh/authorized_keys
	else 
		scp ${COMMON_OPT} -o Port=${REMOTE_PORT} ${KEY} ${LOCAL_IP}@${LOCAL_USER}:${KEY}
		ssh ${REMOTE_HOST} -l ${REMOTE_USER} -p ${REMOTE_PORT} -i ~/.ssh/id_rsa ${COMMON_OPT} << EOF
		echo "$(cat ${KEY}.pub)" >> ~/.ssh/authorized_keys
EOF
	fi
	echo "[${CONNECTION_NAME}][$(date)][INFO] Key Exchange Complete"
	} || { echo "[${CONNECTION_NAME}][$(date)][ERR!] Key Exchange Failed!"; exit 1 }
fi # Setup Server #######################################################################
} # END - Host Verification #############################################################
if [ ${LOCAL_OPEN} -eq 0 ]; then # Use Reverse SSH Tunneling
	REMOTE_PFWD=" -R ${LOCAL_PORT}:127.0.0.1:22"; LOCAL_IP="127.0.0.1"; echo "[${CONNECTION_NAME}][$(date)][INFO] Reverse Conection will be used"
elif [ ${LOCAL_OPEN} -eq 1 ]; then # Use Direct Connection
	REMOTE_PFWD="";	if [ ${LOCAL_IP} = "~" ]; then LOCAL_IP="$(curl ipinfo.io/ip 2> /dev/null)"; fi
fi
#Start Stage 2 and Connect Back
echo "[${CONNECTION_NAME}][$(date)][INFO][>>>] Establishing Control..." 
ssh ${REMOTE_HOST} -l ${REMOTE_USER} -p ${REMOTE_PORT} -i ${KEY} ${COMMON_OPT} ${REMOTE_PFWD} << EOF
	if [ ${REMOTE_KILL} -eq 1 ]; then # Kill stale SSH port forwarding
		echo "[${CONNECTION_NAME}][$(date)][INFO][<<<] Sanitizing End-Point..."
		netstat -tlpn | grep ":${REMOTE_FWDPORT} " | sed -n 's@.* \([0-9]*\)/ssh.*@kill \1@p' | sh > /dev/null
	fi
	echo "[${CONNECTION_NAME}][$(date)][INFO][<<<] Linked!"
	if [ ${DRY} -eq 1 ]; then echo "ssh $(LOCAL_IP) -l ${LOCAL_USER} -p ${LOCAL_PORT} -i ${KEY} ${COMMON_OPT} ${LOCAL_OPT} ${REMOTE_PORTPUB}${LOCAL_PFWD}"
	else ssh $(LOCAL_IP) -l ${LOCAL_USER} -p ${LOCAL_PORT} -i ${KEY} ${COMMON_OPT} ${LOCAL_OPT} ${REMOTE_PORTPUB}${LOCAL_PFWD}; fi
	echo "[${CONNECTION_NAME}][$(date)][ERR!][<<<] ETOL"
EOF
if [ ${DRY} -eq 1 ]; then exit 0; fi
else # ELSE - Internet Verification #####################################################
echo "[${CONNECTION_NAME}][$(date)][ERR!] Outbound Internet Connection:  Failed"
fi # END - Internet Verification ########################################################
echo "[${CONNECTION_NAME}][$(date)][ERR!] Connection was lost!"
sleep 2
done # Main Loop ######################################################################################################
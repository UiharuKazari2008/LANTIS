#!/bin/bash

# LANTIS EasyLink 2 #
# OPERATIONS ###########################################################################################################
TEST_HOST_VERIFY () { 
${CMD_SSH} ${REMOTE_HOST} -l ${REMOTE_USER} -p ${REMOTE_PORT} -i ${KEY} ${COMMON_OPT} << EOF
echo "[${CONNECTION_NAME}][$(date)][INFO] Outbound End-Point:           OK"
EOF
}
TEST_HOST_FAILED () { 
echo "[${CONNECTION_NAME}][$(date)][ERR!] Outbound End-Point:    No Access"
if [ ${REMOTE_SETUP} -eq 1 ]; then
	echo "[${CONNECTION_NAME}][$(date)][INFO] Passing Key to End-Point..."
	${CMD_SCP} ${COMMON_OPT} -o Port=${REMOTE_PORT} ${KEY} ${REMOTE_USER}@${REMOTE_HOST}:${KEY}
	${CMD_SSH} ${REMOTE_HOST} -l ${REMOTE_USER} -p ${REMOTE_PORT} -i ${SETUP_KEY} ${COMMON_OPT} << EOF
		echo "$(cat ${KEY}.pub)" >> ~/.ssh/authorized_keys
EOF
	echo "[${CONNECTION_NAME}][$(date)][INFO] Passing Key to Local..."
	if [ ${LOCAL_IP} = "~" ] || [ ${LOCAL_OPEN} -eq 0 ]; then echo "$(cat ${KEY}.pub)" >> ~/.ssh/authorized_keys
	else 
		${CMD_SCP} ${COMMON_OPT} -o Port=${REMOTE_PORT} ${KEY} ${LOCAL_IP}@${LOCAL_USER}:${KEY}
		${CMD_SSH} ${REMOTE_HOST} -l ${REMOTE_USER} -p ${REMOTE_PORT} -i ${SETUP_KEY} ${COMMON_OPT} << EOF
		echo "$(cat ${KEY}.pub)" >> ~/.ssh/authorized_keys
EOF
	fi
	echo "[${CONNECTION_NAME}][$(date)][INFO] Key Exchange Complete"
fi
}
TEST_INET_VERIFY () {
wget -q --spider ${HOST_VERIFY} --timeout=${TIMEOUT_VERIFY_INET}
}
TEST_INET_PASSED () {
echo "[${CONNECTION_NAME}][$(date)][INFO] Outbound Internet Connection: OK"
}
TEST_INET_FAILED () {
echo "[${CONNECTION_NAME}][$(date)][ERR!] Outbound Internet Connection: Failed"
sleep ${TIME_FAILED_INET}
}
TEST_CONN_FAILED () {
echo "[${CONNECTION_NAME}][$(date)][ERR!] Connection was lost!"
sleep ${TIME_FAILED_CONN}
}
SELECT_REVERSE () {
if [ ${LOCAL_OPEN} -eq 0 ]; then # Use Reverse SSH Tunneling
	REMOTE_PFWD="-R ${LOCAL_PORT}:127.0.0.1:22"; LOCAL_IP="127.0.0.1"; echo "[${CONNECTION_NAME}][$(date)][INFO] Reverse Conection will be used"
elif [ ${LOCAL_OPEN} -eq 1 ]; then # Use Direct Connection
	REMOTE_PFWD="";	if [ ${LOCAL_IP} = "~" ]; then LOCAL_IP="$(curl ipinfo.io/ip 2> /dev/null)"; fi
fi
}
CONNECT_HOST () {
echo "[${CONNECTION_NAME}][$(date)][INFO][>>>] Establishing Control..." 
if [ ${DRY} -eq 1 ]; then echo "${CMD_SSH} ${REMOTE_HOST} -l ${REMOTE_USER} -p ${REMOTE_PORT} -i ${KEY} ${COMMON_OPT} ${REMOTE_PFWD} <<"; fi
${CMD_SSH} ${REMOTE_HOST} -l ${REMOTE_USER} -p ${REMOTE_PORT} -i ${KEY} ${COMMON_OPT} ${REMOTE_PFWD} << EOF
	if [ ${REMOTE_KILL} -eq 1 ]; then echo "[${CONNECTION_NAME}][$(date)][INFO][<<<] Sanitizing End-Point..."
		netstat -tlpn | grep ":${REMOTE_FWDPORT} " | sed -n 's@.* \([0-9]*\)/${CMD_SSH}.*@kill \1@p' | sh > /dev/null
	fi
	echo "[${CONNECTION_NAME}][$(date)][INFO][<<<] Linked!"; pkill -f "^${CMD_SSH}.*${LOCAL_PFWD}$" > /dev/null
	if [ ${DRY} -eq 1 ]; then echo "${CMD_SSH} ${LOCAL_IP} -l ${LOCAL_USER} -p ${LOCAL_PORT} -i ${KEY} ${COMMON_OPT} ${LOCAL_OPT} ${REMOTE_PORTPUB}${LOCAL_PFWD}"
	else ${CMD_SSH} ${LOCAL_IP} -l ${LOCAL_USER} -p ${LOCAL_PORT} -i ${KEY} ${COMMON_OPT} ${LOCAL_OPT}${REMOTE_PORTPUB} -L ${LOCAL_PFWD}; fi
	echo "[${CONNECTION_NAME}][$(date)][ERR!][<<<] ETOL"
EOF
if [ ${DRY} -eq 1 ]; then exit 0; fi
}
KILL_HOST() {
echo "[${CONNECTION_NAME}][$(date)][INFO][>>>] Establishing Control..." 
if [ ${DRY} -eq 1 ]; then echo "${CMD_SSH} ${REMOTE_HOST} -l ${REMOTE_USER} -p ${REMOTE_PORT} -i ${KEY} ${COMMON_OPT} ${REMOTE_PFWD} <<"; fi
${CMD_SSH} ${REMOTE_HOST} -l ${REMOTE_USER} -p ${REMOTE_PORT} -i ${KEY} ${COMMON_OPT} ${REMOTE_PFWD} << EOF
	echo "[${CONNECTION_NAME}][$(date)][INFO][<<<] Dropping...!"
	if [ ${DRY} -eq 1 ]; then echo "pkill -f "^${CMD_SSH}.*${LOCAL_PFWD}$" > /dev/null"; else pkill -f "^${CMD_SSH}.*${LOCAL_PFWD}$" > /dev/null; fi
EOF
if [ ${DRY} -eq 1 ]; then exit 0; fi
}
# PARSE INPUT ##########################################################################################################
if [ $# -lt 1 ]; then echo "No Data"; exit 1; fi
REMOTE_PORTPUB=""; DRY=0; LOCAL_OPEN=1; REMOTE_KILL=0
while getopts "m:n:h:p:u:H:P:U:D:t:T:LSRKX" opt; do 
  case $opt in
  	m) OPER_MODE=${OPTARG};;
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
	L) REMOTE_PORTPUB=" -g";;
	S) REMOTE_SETUP=1;;
	R) LOCAL_OPEN=0;;
	K) REMOTE_KILL=1;;
	X) DRY=1;;
    \?) echo "[PEBKAC] WTF is -$OPTARG?, thats not a accepted option, Abort"; USAGE; exit 1;;
    :) echo "[PEBKAC] -$OPTARG requires an argument, Abort"; USAGE; exit 1;;
  esac
done
# POST VAR #############################################################################################################
TIME_FAILED_CONN=2; TIME_FAILED_INET=5; TIMEOUT_VERIFY_INET=15; HOST_VERIFY="https://google.com"
CMD_SSH="ssh"; CMD_SCP="scp"; KEY=lantis.key; SETUP_KEY="$HOME/.ssh/id_rsa"
COMMON_OPT="-C -2 -o BatchMode=yes -o StrictHostKeyChecking=no -o TCPKeepAlive=yes -o ServerAliveInterval=5 -o ConnectTimeout=15 -o LogLevel=Error"
LOCAL_OPT="-N -o CompressionLevel=9 -o ExitOnForwardFailure=yes"; LOCAL_PFWD="${REMOTE_FWDPORT}:${LOCAL_FWDHOST}:${LOCAL_FWDPORT}"
# MAIN RUNTIME #########################################################################################################
echo "[${CONNECTION_NAME}][$(date)][INFO] DATA LOADED"
if  [ ${OPER_MODE} -eq 1 ]; then while [ $# -gt 9 ]; do
		if TEST_INET_VERIFY; then TEST_INET_PASSED
			{ TEST_HOST_VERIFY 
			} || { 
			TEST_HOST_FAILED 
			}; SELECT_REVERSE; CONNECT_HOST
		else TEST_INET_FAILED; fi; TEST_CONN_FAILED
	done
elif  [ ${OPER_MODE} -eq 2 ]; then REMOTE_SETUP=0; if TEST_INET_VERIFY; then TEST_INET_PASSED
		{ TEST_HOST_VERIFY 
		} || { 
		TEST_HOST_FAILED
		}; SELECT_REVERSE; KILL_HOST
	else TEST_INET_FAILED; fi; TEST_CONN_FAILED
fi
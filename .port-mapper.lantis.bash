REMOTE_PORTPUB=""; LOCAL_PORTPUB=""; DRY=0; LOCAL_OPEN="false"; REMOTE_KILL="false"; REMOTE_SETUP="false"; LOOPCON=1; LOCAL_PFWD=""; REMOTE_LOCALPFWD=""; REMOTE_LPORT="22";
TIME_FAILED_CONN=2; TIME_FAILED_INET=5; TIMEOUT_VERIFY_INET=15; HOST_VERIFY="https://google.com"; DATE_FORMAT='+%d/%m/%Y %H:%M:%S'
CMD_SSH="ssh"; CMD_SCP="scp"; KEY=lantis.key; SETUP_KEY="$HOME/.ssh/id_rsa"; LOCAL_OPT="-N -o ExitOnForwardFailure=yes"; FILENAME="";
COMMON_OPT="-C -2 -o BatchMode=yes -o StrictHostKeyChecking=no -o TCPKeepAlive=yes -o ServerAliveInterval=5 -o ConnectTimeout=15 -o LogLevel=Error"
LOCAL_CONTROLMASTER_INTERFACE=".LANTIS_INTERFACE"; REMOTE_CONTROLMASTER_INTERFACE=".LANTIS_INTERFACE";
source ./.watchdog.lantis.config
source $1

sleep 3;

while :
do
  while [ "$(${CONNECTION_COMMAND} -O check || echo 'no')" == "no"  ]
  do
    sleep 3
  done

  if [ -n "${FORWARD_PORTS}" ]; then
    for _PORT_SET in ${FORWARD_PORTS}; do
      ${CONNECTION_COMMAND} << "EOF"
      echo "[${CONNECTION_NAME}][$(date ${DATE_FORMAT})][INFO][<<<] Forwarding ${_PORT_SET}"
      ${CMD_SSH} ${LOCAL_HOST:-127.0.0.1} -l ${LOCAL_USER:-root} -p ${REMOTE_LPORT} -i ${KEY_NAME:-lantis}.key ${COMMON_OPT} \
      -o ControlMaster=auto -o ControlPath=${LOCAL_CONTROLMASTER_INTERFACE:-.LANTIS}_${CONNECTION_NAME} \
      ${LOCAL_OPT} -O forward -L ${_PORT_SET}
EOF
    done;
  fi

  if [ -n "${REVERSE_PORTS}" ] && [ "${2}" = "1" ]; then
    for _PORT_SET in ${REVERSE_PORTS}; do
      echo "[${CONNECTION_NAME}][$(date \"${DATE_FORMAT}\")][INFO][>>>] Pulling ${_PORT_SET}"
      ${CONNECTION_COMMAND} -O forward -L ${_PORT_SET}
    done;
  fi

  while [ "$(${CONNECTION_COMMAND} -O check || echo 'no')" != "no"  ]
  do
    sleep 3
  done
done

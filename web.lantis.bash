# LANTIS EasyConnect #

### Local Config - This host
LOCAL_USER=root
LOCAL_PORT=65500
LOCAL_WEBHOST=127.0.0.1

### Remote Config - End Point for presentation
REMOTE_HOST=104.236.243.143
REMOTE_USER=root
REMOTE_PORT=22
REMOTE_KILL80=1
# Setup Remote Host
REMOTE_SETUP=0

#Keys - Common key shared between hosts
KEY=/root/lantis.key

#SSH Options - Options used for connection
COMMON_OPT="-C -2 -o BatchMode=yes -o StrictHostKeyChecking=no -o TCPKeepAlive=yes -o ServerAliveInterval=5 -o ConnectTimeout=15 -o LogLevel=Error"
LOCAL_OPT="-N -o CompressionLevel=9 -o ExitOnForwardFailure=yes -g -L 80:${LOCAL_WEBHOST}:80 -L 443:${LOCAL_WEBHOST}:443"






####################                                                                                                               ####################






echo "= LANTIS EasyLink 2 - Academy City Research ========="

while [ 0 -eq 0 ]; do
# Check Internet Connection
wget -q --spider https://google.com --timeout=15
if [ $? -eq 0 ]; then
echo "[$(date)][---] Internet Connection Ready"


#Setup Server - Uncomment to setup server
if [ $REMOTE_SETUP -eq 1 ]; then
	#Upload Current SSH Key
	echo "[$(date)][>>>] Passing Key..."
	scp $COMMON_OPT -o Port=$REMOTE_PORT $KEY ${REMOTE_USER}@${REMOTE_HOST}:${KEY}
	echo "[$(date)][~~~] Setting up End-Point..."
	cat ${KEY}.pub | ssh $REMOTE_HOST -l $REMOTE_USER -p $REMOTE_PORT -i ~/.ssh/id_rsa $COMMON_OPT 'cat >> /root/.ssh/authorized_keys'
	ssh $REMOTE_HOST -l $REMOTE_USER -p $REMOTE_PORT -i ~/.ssh/id_rsa $COMMON_OPT << EOF
		echo "LANTIS" > /etc/motd
EOF
fi

{ 
ssh $REMOTE_HOST -l $REMOTE_USER -p $REMOTE_PORT -i $KEY $COMMON_OPT "echo "[$(date)][---] End-Point is ready""

#Start Stage 2 and Connect Back
echo "[$(date)][>>>] Establishing Control line..." 
ssh $REMOTE_HOST -l $REMOTE_USER -p $REMOTE_PORT -i $KEY $COMMON_OPT << EOF
	#Kill stale SSH port forwarding
	if [ $REMOTE_KILL80 -eq 1 ]; then
		echo "[$(date)][>>>] Sanitizing End-Point..."
		netstat -tlpn | grep ":80 " | sed -n 's@.* \([0-9]*\)/ssh.*@kill \1@p' | sudo sh
	fi
	echo "[$(date)][<<<] Linked! Accepting Incoming Connections..."
	# SSH back in for port fowarding
	ssh $(curl ipinfo.io/ip 2> /dev/null) -l $LOCAL_USER -p $LOCAL_PORT -i $KEY $LOCAL_OPT $COMMON_OPT
	echo "[$(date)][!!!] ERROR! Early Termination of line!"
EOF
} || { 
echo "[$(date)][!!!] End-Point Error!"
}
else
#Else, Connection failed
echo "[$(date)][!!!] ERROR! Internet Connection is not ready!"
fi
#When Connection dropped
echo "[$(date)][!!!] ERROR! Connection Failed!"
sleep 2
done

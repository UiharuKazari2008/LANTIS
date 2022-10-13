# LANTIS EasyLink Router 4
LANTIS is a system that allows you use simple low end Linux systems (Raspberry Pi and bellow) to securely route ports to the internet and bypass the inbound NAT rule requirement. All using SSH as the secure transport. 

## Features
* File based configuration
* Automatic Connection Recovery and Internet Connection Verification
* Instant Public IP Address Update (when using Direct Connection Mode)
* Inbound NAT Bypass (uses Reverse Tunneling to bypass NAT)
* Multilayer Connection Encryption
* Port Hijack (Kills whatever is using the port and hijacks access to port)
* Multiple Ports on a single connections
* Automatic Setup and Key Exchange (See Setup Guide)
* Minimal System Footprint
* Leaves little evidence (beware of SSH logs)
* Bidirectional port routing

## Example use case
* Privacy of your location
* Changing dynamic IP
* No control over your router or unable to port forward
* Quick and simple access to another datacenter/site
* Can’t open ports due to security
* Double-NAT (Behind multiple NAT routers)

## Requirements
* Remote SSH Hosts with remote access (2 if you want to run watchdog separately) to present port
* Local SSH Host (Watchdog can be ran from a separate host)
* Root SSH Access on Remote Host (For ports 1-1024)
* Trusted SSH Key for Setup
* BASH and SSH
* ***(Optional)*** Disable MOTD and SSH Banner

## Setup
1. Install SSH your host (Windows users will need to enable the feature)
2. Generate a SSH Key Pair and add to authorized_keys file for the user
3. Clone this Git
4. cd LANTIS/
5. Generate a SSH Key pair with the name lantis.key
```shell
~/IdeaProjects/LANTIS (master ✘)✹✭ ᐅ ssh-keygen -b 4096
Generating public/private rsa key pair.
Enter file in which to save the key (/Users/kazari/.ssh/id_rsa): ./lantis.key
Enter passphrase (empty for no passphrase): 
Enter same passphrase again: 
Your identification has been saved in ./lantis.key
Your public key has been saved in ./lantis.key.pub
```
6. Get a remote host from Digital Ocean or Vultr (Cheaper) with lowest hardware
7. Add your user SSH key to host for setup (Confirm you can login)
8. Configure CSV File and config files
9. Run with -X option in front of your options for Dry Run (Connects and does setup but does not route packets) 

## Configuration
The configuration meathods have chnages to file based to make things easier.

### Connection Table
#### Port Forward with Reverse Tunneling (no direct connection):
```shell
CONNECTION_NAME="PublicAPI"
ENABLED="true"

REMOTE_HOST="X.X.X.X"
REMOTE_PORT="22"
REMOTE_USER="root"
REMOTE_SETUP="true"
REMOTE_KILL="true"
LOCAL_OPEN="true"

LOCAL_USER="root"
LOCAL_PORT="65401"

FORWARD_PORTS="8989:127.0.0.1:3000"
FORWARD_PUBLIC="true"
```

* root@X.X.X.X:22 to remote host
* Remote Setup Enabled
  - Remote Host will be given the lantis.key file, using your private key in your user account
* Remote Kill Enabled
  - Any thing using the ports that are forwarded will be killed
* Reverse Connection Enabled
  - Control connection will be established, then a connection back to your local host will be established to forward the ports
* Port 8989 will be forwarded to 127.0.0.1:3000
* Ports will be open to 0.0.0.0

#### Bi-Direction Port Forward with Reverse Tunneling (no direct connection):
```shell
CONNECTION_NAME="PublicAPI"
ENABLED="true"

REMOTE_HOST="X.X.X.X"
REMOTE_PORT="22"
REMOTE_USER="root"
REMOTE_SETUP="true"
REMOTE_KILL="true"
LOCAL_OPEN="true"

LOCAL_USER="root"
LOCAL_PORT="65401"

FORWARD_PORTS="8989:127.0.0.1:3000"
REVERSE_PORTS="9357:127.0.0.1:357"
FORWARD_PUBLIC="true"
REVERSE_PUBLIC="true"
```

* root@X.X.X.X:22 to remote host
* Remote Setup Enabled
  - Remote Host will be given the lantis.key file, using your private key in your user account
* Remote Kill Enabled
  - Any thing using the ports that are forwarded will be killed
* Reverse Connection Enabled
  - Control connection will be established, then a connection back to your local host will be established to forward the ports
* Remote Host: Port 8989 will be forwarded to 127.0.0.1:3000
* Local Host: Remote hosts port 357 will be available as port 9357
* Ports will be open to 0.0.0.0 on both local and remote

#### Direct Connection Port Forwarding
```shell
CONNECTION_NAME="PublicAPI"
ENABLED="true"

REMOTE_HOST="X.X.X.X"
REMOTE_PORT="22"
REMOTE_USER="root"
REMOTE_SETUP="true"
REMOTE_KILL="true"
LOCAL_OPEN="false"

#LOCAL_HOST="1.2.3.4"
LOCAL_HOST="~"
LOCAL_USER="root"
LOCAL_PORT="65401"

FORWARD_PORTS="8989:127.0.0.1:3000 5000:127.0.0.1:5000"
FORWARD_PUBLIC="true"
```

* root@X.X.X.X:22 to remote host (for control)
* Remote Setup Enabled
    - Remote Host will be given the lantis.key file, using your private key in your user account
* Remote Kill Enabled
    - Any thing using the ports that are forwarded will be killed
* Direct connection (Ports are open)
  - When `~` is used in place of LOCAL_HOST, the public IP address will be retrieved from the internet. Otherwise specify the public IP address if its static
  - Control connection will be established, then it will directly connect to your host
* Port 8989 will be forwarded to 127.0.0.1:3000
* Port 5000 will be forwarded to 127.0.0.1:5000
* Ports will be open to 0.0.0.0

#### Options
```shell
# Name of connection (no spaces please)
CONNECTION_NAME=""
# Enable Connection (on kill this will still be called)
ENABLED=""
# Remote (public) IP address or FQDN
REMOTE_HOST=""
# Remote Hosts SSH Port Number
REMOTE_PORT=""
# Remote Hosts SSH Username
REMOTE_USER=""
# Enable Remote Key Transport
REMOTE_SETUP=""
# Kill any applications using ports
REMOTE_KILL=""
# Reverse Tunnel Mode (No Direct Connection)
LOCAL_OPEN=""
# Local (your) IP Address, FQDN, or 127.0.0.1 (LOCAL_OPEN)
LOCAL_HOST=""
# Local Hosts SSH Port Number
LOCAL_PORT=""
# Local Hosts SSH Username
LOCAL_USER=""
# Space delimited list of ports to forward
# REMOTE_PORT:LOCAL_HOST:LOCAL_PORT
FORWARD_PORTS=""
# Enable Global Access to ports on remote network or internet (0.0.0.0)
FORWARD_PUBLIC=""
# Space delimited list of ports to listen on
# Can be used to access internet hosts
# LOCAL_PORT:REMOTE_HOST:REMOTE_PORT
REVERSE_PORTS=""
# Enable Global Access to ports on local network (0.0.0.0)
REVERSE_PUBLIC=""
```

### Config Files
Defaults are fine unless you have a need to change some of the values

#### lantis.config
```shell
# Log File used for watchdogs
LOG_FILE="./lantis.log"
# Time to pause after launching a connection
TIME_LAUNCH_PAUSE=4
# Time to pause after dropping a connection
TIME_DROP_PAUSE=2
```

#### watchdog.lantis.config
```shell
# Time to pause between a connection drop
TIME_FAILED_CONN=2
# Time to paues between a internet connection drop
TIME_FAILED_INET=5
# Timeout for internet test
TIMEOUT_VERIFY_INET=15
# Host to use for internet verification
HOST_VERIFY="https://google.com"
# SSH Command
CMD_SSH="ssh"
# SCP Command
CMD_SCP="scp"
# LANTIS Key used for 2-way auth
KEY=lantis.key
# Setup key used for setting up servers
SETUP_KEY="$HOME/.ssh/id_rsa"
# Common SSH options
COMMON_OPT="-C -2 -o BatchMode=yes -o StrictHostKeyChecking=no -o TCPKeepAlive=yes -o ServerAliveInterval=5 -o ConnectTimeout=15 -o LogLevel=Error"
# Endpoint Connection Back SSH Options
LOCAL_OPT="-N -o ExitOnForwardFailure=yes"
```

## Usage
```
root@lantis-controller:~/LANTIS# bash lantis.bash
= LANTIS Router 3 - Academy City Research =========
[---------][Mon  3 Jul 17:04:16 UTC 2017][ OK ] System Ready
 support : help.lantis.project@acr.moe

 LANTIS EasyLink Router 2 - Usage:

 Launch ================================================================
 -l  Launch a Connecion           -L  Launch ALL Connections

 Drop ==================================================================
 -k  Drop a Connection            -K  Drop ALL Connections

 Extra Options (MUST be set before a action) ===========================
 -C  Use another port list (Default: ./ports.lantis.csv)
 -X  Dry Run (Does not do any action but test full connection)
 -Z  Display Setup Guide

 NOTE: You can give multiple actions (ex: -l admin -k ssh -l rdp)

root@lantis-controller:~/LANTIS#
```
### Launching a connection
```
root@lantis-controller:~/LANTIS# bash lantis.bash -C production.csv -l kazari-1
= LANTIS Router 3 - Academy City Research =========
[---------][Mon  3 Jul 17:05:44 UTC 2017][ OK ] System Ready
[kazari-1][Mon  3 Jul 17:05:47 UTC 2017][INFO] Launching Connection...
root@lantis-controller:~/LANTIS#
```
#### Log Output
```
[kazari-1][Mon  3 Jul 17:05:48 UTC 2017][INFO] DATA LOADED
[kazari-1][Mon  3 Jul 17:05:49 UTC 2017][INFO] Outbound Internet Connection: OK
[kazari-1][Mon  3 Jul 17:05:49 UTC 2017][INFO] Outbound End-Point:           OK
[kazari-1][Mon  3 Jul 17:05:51 UTC 2017][INFO][>>>] Establishing Control...
[kazari-1][Mon  3 Jul 17:05:51 UTC 2017][INFO][<<<] Linked!
```

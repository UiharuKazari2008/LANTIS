# LANTIS EasyLink Router 3
LANTIS is a system that allows you use simple low end Linux systems (Raspberry Pi and bellow) to securely route ports to the internet and bypass the inbound NAT rule requirement. All using SSH as the secure transport. 

## Features
* Easy CSV File to manage mappings (with inheritance)
* Automatic Connection Recovery and Internet Connection Verification
* Instant Public IP Address Update (when using Direct Connection Mode)
* Inbound NAT Bypass (uses Reverse Tunneling to bypass NAT)
* RSA Encrypted Data Transport
* Port Hijack (Kills whatever is using the port and hijacks access to port)
* Linked Connection Mode (Multiple Ports on a single connections)
* Automatic Setup and Key Exchange (See Setup Guide)
* Minimal System Footprint
* Leaves little evidence (beware of SSH logs)
* Allows usage of Multiple Remote and Local Hosts for routing

## Example use case
* Privacy of your location
* Changing dynamic IP
* No control over the router
* Can’t open ports due to security
* Double-NAT (Behind multiple NAT routers)

## Requirements
* Remote Linux based Hosts (3 if you want to run watchdog separately) to present port
* Local Linux based Host to create connection + watchdog (Watchdog can be ran from a separate host)
* Root SSH Access Recommended to Remote Host
* Trusted SSH Key for Setup
* Outbound SSH
* BASH and openSSH

## Setup
1 Install a Raspberry Pi or any other system
2 Generate a SSH Keypair
3 Clone this Git
4 cd LANTIS/
5 Generate a SSH Keypair with the name lantis.key
6 Get a remote host from Digital Ocean or Vultr (Cheaper) with lowest hardware
7 Add your user SSH key to host for setup  (Confirm you can login)
8 Configure CSV File and config files
9 Run with -X option in front for Dry Run (Connects and does setup but does not route packets) 

## Configuration

### Connection Table (ports.lantis.csv)
Example File:
```e;web;25.97.71.244;22;root;~;65500;root;0;0;0;80;127.0.0.1;80;1;
e;web;^;^;^;^;^;^;^;^;^;443;^;443;^;
l;admin;45.76.9.245;^;^;^;^;^;^;^;^;9998;192.168.0.90;3389;^;
^;9999;192.168.0.92;22;^;
>;6100;192.168.0.91;^;^;
e;rdp-1;^;^;^;127.0.0.1;65401;^;^;1;^;4000;192.168.0.101;3389;^;
e;rdp-2;^;^;^;^;65402;^;^;^;^;4001;192.168.0.102;^;^;
e;rdp-3;^;^;^;^;65403;^;^;^;^;4002;192.168.0.103;^;^;
d;rdp-4;^;^;^;^;65404;^;^;^;^;4003;192.168.0.104;^;^;
```

Web Server
* Sets Inital Settings
* Direct Connection with Dynamic IP
* Foward Local Host Port 80 and 443

```
;web;25.97.71.244;22;root;~;65500;root;0;0;0;80;127.0.0.1;80;1;
e;web;^;^;^;^;^;^;^;^;^;443;^;443;^;
```

Linked Connection
* Another end point but keep all other Settings
* 3 ports using same connection

```
l;admin;45.76.9.245;^;^;^;^;^;^;^;^;9998;192.168.0.90;3389;^;
^;9999;192.168.0.92;22;^;
>;6100;192.168.0.91;^;^;
```

Bypass NAT
* Bypass NAT Enabled
* Using Local Host as transport (Don't have to but simplest)
* 4 RDP Ports Open

```
e;rdp-1;^;^;^;127.0.0.1;65401;^;^;1;^;4000;192.168.0.101;3389;^;
e;rdp-2;^;^;^;^;65402;^;^;^;^;4001;192.168.0.102;^;^;
e;rdp-3;^;^;^;^;65403;^;^;^;^;4002;192.168.0.103;^;^;
d;rdp-4;^;^;^;^;65404;^;^;^;^;4003;192.168.0.104;^;^;
```

#### Options
1 Status (Enable [e], Disable [d], Linked [l])
2 Connection Name
3 Remote Host IP or FQDN
4 Remote Host SSH Port
5 Remote Host Login User
6 Local Host IP or FQDN
7 Local Host SSH Port
8 Local Host Login User
9 Setup Mode (1 = Setup Remote Host)
10 Bypass NAT (aka Reverse Tunneling)
11 Port Hijack
12 Public Port
13 Local Server IP or FQDN
14 Local Server Port
15 Listen Publicly or Local to Remote Host

#### Special Options
* ( ~ )(6: Local Host IP or FQDN) Dynamic Public IP (Only Direct Mode)
* ( ^ )(All but 1,2,12) Use last value
* (l)(1: Status) Linked Connection, Use one connection for multiple ports
..* Use `^;5999;192.168.0.47;22;^;` for other ports (12,13,14,15)
..* Use ( > ) for last port (Used as end stop, without this the whole connection will be ignored)

#### Notes
* You can use multiple connections with the same name and they will be parsed as the connection group
* To use Bypass NAT you must set 6 to 127.0.0.1, 10 to 1, and 7 to a unique port for each connection
..* Does not yet support Linked Bypass mode (Multiple Connection trough the same tunnel), use normal linked mode
* In linked mode, if one port were to get overloaded and cause a buffer overflow the whole link will drop will all linked ports and will have to automaticly reconnect. (Just a word of warning)
* Disabled Connection are still read for inheritance

### Config Files
Defaults are fine unless you have a need to change some of the values

#### lantis.config
```
# Log File used for watchdogs
LOG_FILE="./lantis.log"
# Time to pause after launching a connection
TIME_LAUNCH_PAUSE=4
# Time to pause after dropping a connection
TIME_DROP_PAUSE=2
```

#### watchdog.lantis.config
```
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
LOCAL_OPT="-N -o CompressionLevel=9 -o ExitOnForwardFailure=yes"
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
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
d;rdp-4;^;^;^;^;65404;^;^;^;^;4003;192.168.0.104;^;^;```

Web Server
* Sets Inital Settings
* Direct Connection with Dynamic IP
* Foward Local Host Port 80 and 443
```;web;25.97.71.244;22;root;~;65500;root;0;0;0;80;127.0.0.1;80;1;
e;web;^;^;^;^;^;^;^;^;^;443;^;443;^;```

Linked Connection
* Another end point but keep all other Settings
* 3 ports using same connection
```l;admin;45.76.9.245;^;^;^;^;^;^;^;^;9998;192.168.0.90;3389;^;
^;9999;192.168.0.92;22;^;
>;6100;192.168.0.91;^;^;```

Bypass NAT
* Bypass NAT Enabled
* Using Local Host as transport (Don't have to but simplest)
* 4 RDP Ports Open
```e;rdp-1;^;^;^;127.0.0.1;65401;^;^;1;^;4000;192.168.0.101;3389;^;
e;rdp-2;^;^;^;^;65402;^;^;^;^;4001;192.168.0.102;^;^;
e;rdp-3;^;^;^;^;65403;^;^;^;^;4002;192.168.0.103;^;^;
d;rdp-4;^;^;^;^;65404;^;^;^;^;4003;192.168.0.104;^;^;````

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
* [~][6: Local Host IP or FQDN] Dynamic Public IP (Only Direct Mode)
* [^][All but 1,2,12] Use last value
* [l][1: Status] Linked Connection, Use one connection for multiple ports
..* Use `^;5999;192.168.0.47;22;^;` for other ports [12,13,14,15]
..* Use [>] for last port (Used as end stop, without this the whole connection will be ignored)

#### Notes
* You can use multiple connections with the same name and they will be parsed as the connection group
* To use Bypass NAT you must set 6 to 127.0.0.1, 10 to 1, and 7 to a unique port for each connection
..* Does not yet support Linked Bypass mode (Multiple Connection trough the same tunnel), use normal linked mode
* In linked mode, if one port were to get overloaded and cause a buffer overflow the whole link will drop will all linked ports and will have to automaticly reconnect. (Just a word of warning)
* Disabled Connection are still read for inheritance
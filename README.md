# LANTIS EasyLink Router 3
LANTIS is a system that allows you use simple low end Linux systems (Raspberry Pi and bellow) to securely route ports to the internet and bypass the inbound NAT rule requirement. All using SSH as the secure transport. 

## Features
Easy CSV File to manage mappings (with inheritance)
Automatic Connection Recovery and Internet Connection Verification
Instant Public IP Address Update (when using Direct Connection Mode)
Inbound NAT Bypass (uses Reverse Tunneling to bypass NAT)
RSA Encrypted Data Transport
Port Hijack (Kills whatever is using the port and hijacks access to port)
Linked Connection Mode (Multiple Ports on a single connections)
Automatic Setup and Key Exchange (See Setup Guide)
Minimal System Footprint
Leaves little evidence (beware of SSH logs)
Allows usage of Multiple Remote and Local Hosts for routing

## Example use case
Privacy of your location
Changing dynamic IP
No control over the router
Can’t open ports due to security
Double-NAT (Behind multiple NAT routers)

## Requirements
Remote Linux based Hosts (3 if you want to run watchdog separately) to present port
Local Linux based Host to create connection + watchdog (Watchdog can be ran from a separate host)
Root SSH Access Recommended to Remote Host
Trusted SSH Key for Setup
Outbound SSH
BASH and openSSH
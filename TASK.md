# Linux project

## Final Project
Report: 7-10 pages pr person.


### Group VM
a) Proxy
	MITMProxy with http and https
	IPtables script
b) Proxy pro/con
c) Make a folder with logs to read and edit, (each user have his own file)
d) Place logfiles in a container (how does it affect security?)
e) DNS / DMZ subnet 100.11
f) Update firewall only to accept limited trafic from DMZ

### Individual VM
a) Setup Docker
b) Docker subscribe GroupVM DHCP (IP)
c) Setup security
d) Dicuss docker security

### Design Network topology (a system with services)
We will make a deployment/network diagram.

### Decide which servers should be used in the topology and how
### Docker or LXD, We will use Docker, because it is very easy and fast.
### Setup Docker
### Make the containers work together (create docker network)
### Firewall setup and documented for both group and individual VM's
### Setup and discuss security for each server and for it all together






## System description
We have a main linux server running Suse 12 which is a quite old version of suse. This gives us some limitations (forces us to be extra creative), because its not possible to work with the newest (convinient) techlologies.

The main server is functioning as a router, managing the internet connections for the computers on its subnet. 

The main server has various network tools installed which is used to monitor and control trafic on the subnet.
	- Proxy server 
		We have installed MITMProxy which is a modern proxy server and easy to use. Also we can forward https trafic, and use python to alter the packages going through the proxy.
		We used Squid to begin with, but it was quite difficult to set up https proxying, and also squid is less popular than MITMProxy.
		Https is handled by adding a .pem certificate to `/usr/local/share/ca-certificates` on the victims machines, and then `sudo update-ca-certificates`
	- Local watching
		We are survailing some of the services running on the main server. This is done by using journalctl in our own little tool made in go.
		We are survailing changes in the filesystem with AIDE and tripwire. (current problem will affect this)
		We are sending mails to the sysadmin every time in a time interval containing the newest logs
	- DHCP and DNS
		We are providing DHCP service for the hosts on the subnet.
		We are using the DNS of the omicron2 server
	- 


## Current problems

### MITMproxy in docker container
+ how can I make a transparent proxy?
+ maybe python scripts will work when in docker.

### Tripwire or AIDE
+ Snort is too new for SUSE.
+ Tripwire has lots of (good) output
+ AIDE is easy to install

### Send mail
+ I can send mail through external smtpd
+ How can I use postfix or sendmail?

### Which services should we have?
+ Matrix server with web interface (element)
+ GitTea git server with interface
+ Rsync Backup
+ (nice to have) jitsi
+ (nice to have) nebula

### 

# HOW TO INSTALL THE SUSE

1. Set image up on nebula
2. Assign 2 interfaces for network (write the ID's)
3. Setup the network config.
4. Setup the DHCP server
5. Setup the firewall
6. Install Docker
7. Docker pull mitmproxy/mitmproxy

## Post installation
After the installation its important to do a few configurations
### Disable default firewall
```
systemctl stop SuSefirewall2
systemctl disable SuSefirewall2
```
### Disable wicked
```
systemctl stop wicked
systemctl disable wicked
```
### Enable SSH
```
systemctl start sshd 
systemctl enable sshd
```
### Update the system
```
zypper update
zypper install zsh 	# for nicer shell
zypper install vim-data # for syntax in vim
```

### Create users and make them sudo

```
useradd {USERNAME} -m -s /bin/zsh -g wheel
passwd {USERNAME}
```

### Change hostname 

```
echo "t10g1" > etc/hostname
```

### Optimize reboot speed
1. Power off the host and remove the susecd from hosts
2. Go to edit `/boot/grub2/grub.cfg`
3. Find all the timeouts and set them to 0

```sh
set timeout=0
```

### Seccure SSH
Go to `/etc/ssh/sshd_config` and set these values
```
PermitRootLogin no
PasswordAuthentication no
```


## DHCPD

to install dhcpd then install dhcp server
```
zypper install dhcp-derver
```

add your internal nic to to `/etc/sysconfig/dhcpd`
```
DHCPD_INTERFACE="eth1"
```

Start and enable dhcpd in systemd


## Tripwire (from source)

(get the newest release)[https://github.com/Tripwire/tripwire-open-source/releases/download/2.4.3.7/tripwire-open-source-2.4.3.7.tar.gz]

to install tripwire on suse first install buildtools

```
zypper install -t pattern devel_C_C++
```

then configure and make the files

```
./configure --sysconfdir=/etc/tripwire
make
make install
```

you might have to manually create `/etc/tripwire`

start tripwire

tripwire will be installed in a wierd directory so to execute it you will have to run it from

```
/usr/local/sbin/tripwire --init
```

also you might have to run this

```
/usr/local/sbin/twadmin --create-polfile /etc/tripwire/twpol.txt
```

then to get the log 

```
/usr/local/sbin/tripwire --check > log.log
```

we can now send an email with the `log.log` file.

## DHCP forwarding with docker
This will come

# How to setup libvirt and bridging
We will setup libvirt and install a more modern version of suse so that we can do more stuff easier.

## Install libvirt
libvirt can be installed directly from zypper
```
zypper install libvirt
```

then to make installation easier we will install `virt-install` and accept all

```
zypper install virt-install
```

## get the new suse
We need to get the latest version of suse leap

[this is the link to download Suse Leap](https://download.opensuse.org/distribution/leap/15.2/iso/openSUSE-Leap-15.2-DVD-x86_64.iso)

we can save the file in the `/var/lib/libvirt/boot/` folder as `suse.iso`

then we will create the installation script in `/root/` and call it `virtinstall.sh` and give it execution rights `chmod +x virtinstall.sh`

```sh
#!/bin/bash

cd=suse
name=suse

virt-install \
--virt-type=kvm \
--name $name \
--ram 2048 \
--vcpus=2 \
--os-variant=generic \
--cdrom="/var/lib/libvirt/boot/$cd.iso" \
--network=bridge=br0,model=virtio \
--network=bridge=br1,model=virtio \
--graphics vnc \
--disk path=/var/lib/libvirt/images/$name.qcow2,size=10,bus=virtio,format=qcow2
```

notice that we have defined the 2 bridges `br1` and `br2`. We need to create them before we sucessfully can run `virtinstall.sh`

## network setup with bridges

The full script can also be found in the scripts folder

```sh
ip link add name br0 type bridge
ip link add name br1 type bridge

ip link set up dev br0
ip link set up dev br1

ip link set dev eth0 master br0
ip link set dev eth2 master br1

ip addr add dev br0 "192.168.150.18/24"
ip route add default dev br0 via "192.168.150.1" scope global

ip link set up dev eth0
ip link set up dev eth2

echo 1 > /proc/sys/net/ipv4/ip_forward
```

Notice we are not assigning any ip address for either `eth0` or `eth2`, this is not necesarry because the `br0` is now representing `eth0` and we can access the host machine with the ip address for `br0`. `br1` is connected to `eth2` on the link layer and we can assign the ip address for that one later inside the VM. so lets create the VM.

## Create the VM
We can now run the script `virtinstall.sh` that we created ealier.

```sh
./virtinstall.sh
```

Then we will wait a few second until the scripts is done.

We now need to connect to the vm via VNC so we will forward the port of the VM's vnc to our local workstation 

```sh
ssh -J \
	    passthru@omicron2.eitlab.diplom.dtu.dk \
	    martin@192.168.150.18 \
	    -L 5900:localhost:5900
```

The first VM's vnc port will be on 5900, if we make more then the port will increment.

When we are in vnc we just follow the installation through all the steps and restart the VM.

We now will open `virsh` on the main server18 and start the VM and enable autostart.

```sh
virsh start suse
virsh autostart suse
```

Then we can open vnc again and check the ip of the VM so that we can ssh into the vm and set it up

## Configure the VM as server29

When we have successfully logged into the VM with ssh, we can start configuring it.

Fist lets update it

```sh
zypper update
```

then lets setup the correct network configuration.


### VM network configuration
First lets disable the default firewall and network

```sh
systemctl disable firewalld
systemctl disable wicked
```

then we will go into `/root/bin` and create `network.sh` with execution rights and the following content:

```sh
#!/bin/bash

case "$1" in
start)
        echo "Starting the network"

        echo "search omicron2.eitlab.diplom.dtu.dk" > /etc/resolv.conf
        echo "nameserver 192.168.150.1" >> /etc/resolv.conf

        ip link set dev eth0 down
        ip link set dev eth1 down
        ip addr flush eth0
        ip addr flush eth1
        ip addr add "192.168.150.29/25" dev eth0 brd +
        ip addr add "192.168.169.1/24" dev eth1 brd +
        ip link set dev eth0 up
        ip link set dev eth1 up
        ip route add default via 192.168.150.1 scope global

        echo 1 > /proc/sys/net/ipv4/ip_forward

        ;;
stop)
        echo "Stopping the network"
        ip addr flush eth0
        ip addr flush eth1
        ip link set dev eth0 down 
        ip link set dev eth1 down 
        ;;
restart)
        $0 stop
        $0 start
        ;;
*)
        echo "Usage $0 [start|stop|restart]"
esac
```

We also need to add a systemd service for the network 

so we will go to `/etc/systemd/system/` and if there is a file or a symlink called `network.service` we will delete it

```sh
rm network.sh
```

then we will create a new `network.service` file in the directory

```sh
[Unit]
Description=network management service
After=local-fs.target
Before=network.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/root/bin/network.sh start
ExecStop=/root/bin/network.sh stop
ExecReload=/root/bin/network.sh restart

[Install]
WantedBy=multi-user.target
```

and remember to enable it, but first reload `systemd`

```sh
systemctl daemon-reload
systemctl enable network
```

then we can start the service, but the best would be to restart the VM since there is some network settings already set by wicked which will probably interfer with the new configuration.

```sh
reboot
```

Now we can setup the DHCP server for host conneted to the same interface as `eth1`

### VM DHCP setup

First lets install dhcp-server

```sh
zypper install dhcp-server
```

then we will edit the file `/ect/sysconfig/dhcpd` and add `eth1` as our dhcpd interface

```
DHCPD_INTERFACE="eth1"
```

then we will setup the subnet for the dhcp server in `/eth/dhcpd.conf`

```
ddns-update-style none;
default-lease-time 21600;
max-lease-time 43200;

subnet 192.168.169.0 netmask 255.255.255.0 {
        option routers 192.168.169.1;
        option domain-name "omicron2.eitlab.diplom.dtu.dk";
        option domain-name-servers 192.168.150.1;
        range 192.168.169.101 192.168.169.130;
}
```

then we need to start and enable dhdpd

```sh
systemctl enable dhcpd
systemctl start dhcpd
```

thats it now clients connected to the same interface as `eth1` will get an ip address from our dhcp server.


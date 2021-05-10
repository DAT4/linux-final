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

### Seccure SSH
Go to `/etc/ssh/sshd_config` and set these values
```
PermitRootLogin no
PasswordAuthentication no
```

```sh
set timeout=0
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

## Tripwire

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

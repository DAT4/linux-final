# VLAN and DMZ
On the host machine `server18` we have set up a vlan `eth0.100` which is controled by a bridge `br2`, the brigde is then passed into the router vm `server29`

`server29` is functioning as a firewall and DHCP server for the VLAN, 

in libvirt on `server18` we created another vm `ubu1` which only has one nic, which is assigned to the VLAN `eth0.100` through `br2` and is therfore assigned an ip address by `server29` in the range `10.100.0.101` to `10.100.0.130`

If we try to access the internet from `ubu1` we will not get any response since there is no route from the vlan to the internet. However we have a route to the host `server29` on the link layer and can access all its ip addesses `10.100.0.1`, `192.168.169.1` and `192.168.150.29`. This means we can connect to it via ssh.

So on `server29` we create a new user called `jumper` and then we go to our `sshd` config in `/etc/ssh/sshd_config` and add this to the bottom

```
Match User jumper
        AllowTcpForwarding yes
    	PasswordAuthentication no
        ForceCommand echo 'forward to backend'
        PermitOpen 130.225.170.70:22022
```


Now we want to login to the server on `130.225.170.70` and create a similar user as `jumper` and set similar rules in `/etc/ssh/sshd_config`

so first we add the user:
```
useradd -m netwk
```

then we add the config to the end of `sshd_config`:
```
Match user netwk
    ForceCommand echo 'hello fello'
    PasswordAuthentication no
    AllowTcpForwarding yes
    PermitOpen localhost:443
```
We will allow localhost on port 443 since this is also the port we expose from that server to the internet, but the idea here is just to restrict access to anything on the server, so that it can only be used for remote forwarding.

Now we want to automate the action of forwarding so we need to authenticate ourselves with an ssh key instead of writing password

Now we create a ssh key for the user on `ubu1`

```
ssh-keygen -t rsa -b 2048
```

and manually copy the key to the `jumper` accout on `server29` and the `netwk` account on `130.225.170.70`. (we cannot copy it with `ssh-copy-id` because of the `ForceCommand` we made in the `sshd_config`'s)

Then we will create a ssh config file for the user on `ubu1` in `~/.ssh/config` with the following content

```
Host parent
	User jumper
	Hostname 10.100.0.1

Host backend
	User netwk
	Hostname 130.225.170.70
	port 22022
	ProxyJump parent
	RemoteForward 8080 localhost:8080
	RemoteForward 8081 localhost:8081
	RemoteForward 8082 localhost:8082
	RemoteForward 8083 localhost:8083
	RemoteForward 8084 localhost:8084
```

This means that we have an alias `parent` which is linking to `server29` and and alias backend which is using `parent` as a proxy and forwarding a range of ports from `ubu1` to the host on `130.225.170.70`

to forwad the ports we simply need to write

```
ssh -N backend
```

`-N` means we will not ask to get a shell

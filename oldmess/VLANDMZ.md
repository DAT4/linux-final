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
useradd -m linux
```

then we add the config to the end of `sshd_config`:
```
Match user linux
    ForceCommand echo 'hello fello'
    PasswordAuthentication no
    AllowTcpForwarding yes
    PermitOpen localhost:443
```
We will allow localhost on port 443 since this is also the port we expose from that server to the internet, but the idea here is just to restrict access to anything on the server, so that it can only be used for remote forwarding.

Now we want to automate the action of forwarding so we need to authenticate ourselves with an ssh key instead of writing password

Now we create a ssh key pair for the user on `ubu1` and put them in `etc/server/ssh_keys/`

```
ssh-keygen -t rsa -b 2048
```

and manually copy the key to the `jumper` accout on `server29` and the `linux` account on `130.225.170.70`. (we cannot copy it with `ssh-copy-id` because of the `ForceCommand` we made in the `sshd_config`'s)

Then we will edit ssh client config file on `ubu1` in `/etc/ssh/ssh_config` and add the following content to the end:

```
Host parent
	User jumper
	Hostname 10.100.0.1
	IdentityFile /etc/server/ssh_keys/id_rsa

Host backend
	User linux
	Hostname 130.225.170.70
	port 22022
	ProxyJump parent
	RemoteForward 8080 localhost:8080
	RemoteForward 8081 localhost:8081
	RemoteForward 8082 localhost:8082
	RemoteForward 8083 localhost:8083
	RemoteForward 8084 localhost:8084
	IdentityFile /etc/server/ssh_keys/id_rsa
```

This means that we have an alias `parent` which is linking to `server29` and and alias backend which is using `parent` as a proxy and forwarding a range of ports from `ubu1` to the host on `130.225.170.70`

to forwad the ports we simply need to write

```
ssh -N backend
```

`-N` means we will not ask to get a shell

So now we can add this to a service file so we can have persistent port forwarding.

## forwarding service

Lets create a file `/etc/systemd/system/server.service` with the following content:

```
[Unit]
Description=Ssh forwarding service
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/ssh -N backend
RestartSec=5
Restart=always

[Install]
WantedBy=multi-user.target
```

then we can restart `systemd` 

```
systemctl daemon-reload
```

and because we are using known hosts to avoid dns spoofing attacks, then we need to login as root one time and write `yes` to accept the host. Or else the `systemd` service will never start forwading ports.

as root
```
ssh backend
```

and then enable and start the service

```
systemctl enable server
systemctl start server
```

we can now check if it works by either checking journalctl for a big pinguin

```
journalctl -xeu server
```

it should look like this
```
May 13 10:06:40 ubu2 ssh[1444]: ********************************************
May 13 10:06:40 ubu2 ssh[1444]: WELCOME TO Group4 BACKEND SERVER
May 13 10:06:40 ubu2 ssh[1444]: ********************************************
May 13 10:06:40 ubu2 ssh[1444]:          _nnnn_
May 13 10:06:40 ubu2 ssh[1444]:         dGGGGMMb     ,"""""""""""""".
May 13 10:06:40 ubu2 ssh[1444]:        @p~qp~~qMb    | Linux Rules! |
May 13 10:06:40 ubu2 ssh[1444]:        M|@||@) M|   _;..............'
May 13 10:06:40 ubu2 ssh[1444]:        @,----.JM| -'
May 13 10:06:40 ubu2 ssh[1444]:       JS^\__/  qKL
May 13 10:06:40 ubu2 ssh[1444]:      dZP        qKRb
May 13 10:06:40 ubu2 ssh[1444]:     dZP          qKKb
May 13 10:06:40 ubu2 ssh[1444]:    fZP            SMMb
May 13 10:06:40 ubu2 ssh[1444]:    HZM            MMMM
May 13 10:06:40 ubu2 ssh[1444]:    FqM            MMMM
May 13 10:06:40 ubu2 ssh[1444]:  __| ".        |\dS"qML
May 13 10:06:40 ubu2 ssh[1444]:  |    `.       | `' \Zq
May 13 10:06:40 ubu2 ssh[1444]: _)      \.___.,|     .'
May 13 10:06:40 ubu2 ssh[1444]: \____   )MMMMMM|   .'
May 13 10:06:40 ubu2 ssh[1444]:      `-'       `--' hjm
```

or we can also login to the backend server and check if the ports are open with
```
ssh -tlpn
```

# Ubu2 DMZ Host

This host machine does not have access to the internet directly. All internet out has to go through an SSH Dynamic proxy, all internet in is forwarded through SSH to a public server with NGINX installed.

## How to access UBU2

To access ubu2 SSH forwarding has to go through server29. One way to do this is making a ssh config file with following:

```
Host omicron2
	HostName omicron2.eitlab.diplon.dtu.dk
	User passthru
	Port 22

Host server29
	HostName 192.168.150.29
	User martin
	Port 22
	ProxyJump omicron2

Host ubu2
	HostName 10.100.0.101
	User martin
	Port 22
	ProxyJump server29
```

then you can access the ubu2 simply by writing 

```sh
ssh ubu2
```

in the commandline.

## How to access the internet from ubu2
Ubu2 is connected to the VLAN that was created in server18 and this VLAN does not have a direct route to the internet. So to get internet with hosts on this interface we need to proxy through the router `server29`, this can be done with ssh's `DynamicForward` feature.

To create the proxy on `localhost:1234` we will write this command
```
ssh -fND 1234 10.100.0.1
```

## How to use the proxy with apt

Create a rule `/etc/apt/apt.conf.d/12-proxy` with the following content:

```
Acquire::http::proxy "socks5h://localhost:1234";
```

now `apt` will work on that proxy.

## How to install dendrite on ubu2

Assuming git and go is already installed with apt.

First we need to set the socks5 proxy for git by writing this in the shell:

```
git config --global http.proxy socks5h://localhost:1234
```

then we can get the repo.

```
git clone https://github.com/matrix-org/dendrite
```



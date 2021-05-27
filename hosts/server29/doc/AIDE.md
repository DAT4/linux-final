# AIDE

AIDE is a HIDS (hardware intrusion detection system) and can be used to monitor changes in the filesystem on the host machine.

## Install AIDE

```sh
zypper install aide
```

## Configure aide

+ find `/etc/aide.conf` and make custom rules.
+ init aide by `aide --init`
	if the database is not created create it manually by
```
touch /var/lib/aide/aide.db
```

## Automate aide

create a script and a systemd service + timer

To send email install `sendmail` and make sure firewall allows `OUTPUT` on `dport` 25

```
zypper install sendmail	
```

**sources**
+ `server29/bin/aide.sh`
+ `server29/sys/aide.service`
+ `server29/sys/aide.timer`


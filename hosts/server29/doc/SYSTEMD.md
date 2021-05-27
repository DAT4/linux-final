# SYSTEMD

Systemd is used for managing services and automated tasks 

services are added as symlinks in `/etc/systemd/system/` 

```sh
ln -sf /root/sys/* /etc/systemd/system/
```

and enabled + started for each service / timer 

example with `proxy.service`

```sh
systemctl enable proxy --now
```

## Timers

Timers can be used instead of cron and they are very flexible and reactive.

a timer for the `firewall.service` is called `firewall.timer`. The name is very important, or else we would have to set the unit file explicitly.

`/hosts/server29/sys/firewall.timer`
```
[Unit]
Description="Restart firewall every 10 minutes"

[Timer]
OnCalendar=*:0/10
Persistent=true

[Install]
WantedBy=timers.target
```

`OnCalendar=*0/10` means every 10 minutes.

If you want to trigger the service every minute or every hour you can just write `OnCalendar=minutely` or `OnCalendar=hourly` this scalet up to `yearly`
[systemd.time](https://man.archlinux.org/man/systemd.time.7.en#CALENDAR_EVENTS)

The service file for the timer would look like this

```
[Unit]
Description=firewall service
OnFailure=status_email_martin@%n.service

[Service]
Type=simple
ExecStart=/root/bin/firewall.sh start
ExecStop=/root/bin/firewall.sh stop
ExecReload=/root/bin/firewall.sh restart

[Install]
WantedBy=multi-user.target
```

You cannot use `RemainOnExit=yes` like you would with `Type=oneshot` because that will interfeer with the timer, so if you want a "oneshot" service to show as active you need to use `Type=simple` instead

## Get mail when systemd service fails

It is possible to make a service which can be used by other services to send an email if the other service fails.
This is done by creating a simple script with `sendmail`

`/hosts/server29/bin/systemd-email.sh`
```sh
#!/bin/sh

/usr/sbin/sendmail $1 <<ERRMAIL
To: $1
From: systemd <root@$HOSTNAME.dtu>
Subject: $2
Content-Transfer-Encoding: 8bit
Content-Type: text/plain; charset=UTF-8

#$(systemctl status --full "$2")
ERRMAIL
```

This is then used by the service 

`/hosts/server29/sys/status_email_martin@.service`
```sh
[Unit]
Description=status email for %i to martin

[Service]
Type=oneshot
ExecStart=/root/bin/systemd-email.sh s195469@student.dtu.dk %i
User=root
Group=systemd-journal
```

Now this service can be used in the service for eg proxy, by setting the `OnFailure=status_email_martin@%n.service` in the `[Unit]` part of the service file

`%n` is the name of the service (`proxy`)

`/hosts/server29/sys/proxy.service`
```sh
[Unit]
Description=proxy service mitm
After=network.target
OnFailure=status_email_martin@%n.service

[Service]
Type=simple
ExecStart=/root/bin/mitmweb --mode transparent --web-host 0.0.0.0 -s /root/etc/mitmconf.py

[Install]
WantedBy=multi-user.target
```


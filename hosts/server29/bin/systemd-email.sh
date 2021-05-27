#!/bin/sh

/usr/sbin/sendmail $1 <<ERRMAIL
To: $1
From: systemd <root@$HOSTNAME.dtu>
Subject: $2
Content-Transfer-Encoding: 8bit
Content-Type: text/plain; charset=UTF-8

#$(systemctl status --full "$2")
ERRMAIL

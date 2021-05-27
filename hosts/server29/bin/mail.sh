#!/bin/bash


sendmailz(){
/usr/sbin/sendmail -t $1 <<ERRMAIL
To: $1
From: aide <root@$HOSTNAME.dtu>
Subject: aide
Content-Transfer-Encoding: 8bit
Content-Type: text/plain; charset=UTF-8

$(aide -CV)
ERRMAIL
}

sendmailz s195469@student.dtu.dk

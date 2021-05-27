#!/bin/bash

sendmailz(){
/usr/sbin/sendmail -t $1 <<ERRMAIL
To: $1
From: aide <root@$HOSTNAME.dtu>
Subject: aide
Content-Transfer-Encoding: 8bit
Content-Type: text/plain; charset=UTF-8

$2
ERRMAIL
}

database=/var/lib/aide/aide.db
database_out=/var/lib/aide/aide.db.new

if [ ! -f "$database" ]; then
        echo "$database not found" >&2
        exit 1
fi

aide -uV || true

sendmailz s195469@student.dtu.dk "$(cat /tmp/aideoutput.txt)"

cat /tmp/aideoutput.txt

mv $database $database.back
mv $database_out $database


#!/bin/bash

FILE=log4mail

cat /dev/null > $FILE
services="sshd network firewall"
for x in $services; do
	./journalfeed -proc $x -out $x.txt
done
#./sendlog $FILE
#echo "logs sent"

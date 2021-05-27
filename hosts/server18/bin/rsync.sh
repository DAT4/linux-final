#!/bin/bash

# FILES
rsync -av --delete --files-from=/root/etc/etc.rsync /etc /root/etc

# SSH
rsync -avz --delete /root/etc mama:linux/hosts/server18/
rsync -avz --delete /root/bin mama:linux/hosts/server18/
rsync -avz --delete /root/sys mama:linux/hosts/server18/
rsync -avz --delete /root/doc mama:linux/hosts/server18/

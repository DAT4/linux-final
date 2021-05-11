#!/bin/bash

case "$1" in
start)
        echo "Starting the network"

        echo "search omicron2.eitlab.diplom.dtu.dk" > /etc/resolv.conf
        echo "nameserver 192.168.150.1" >> /etc/resolv.conf

        ip link set dev eth0 down
        ip addr flush eth0
        ip addr add "192.168.169.1/24" dev eth0 brd +
        ip addr add "192.168.150.29/25" dev eth0 brd +
        ip link set dev eth0 up
        ip route add default via 192.168.150.1 scope global

        echo 1 > /proc/sys/net/ipv4/ip_forward

        ;;
stop)
        echo "Stopping the network"
        ip addr flush eth0
        ip link set dev eth0 down 
        ;;
restart)
        $0 stop
        $0 start
        ;;
*)
        echo "Usage $0 [start|stop|restart]"
esac

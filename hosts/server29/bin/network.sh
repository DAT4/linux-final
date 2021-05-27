#!/bin/bash

case "$1" in
start)
        echo "Starting the network"

        echo "search omicron2.eitlab.diplom.dtu.dk" > /etc/resolv.conf
        echo "nameserver 192.168.150.1" >> /etc/resolv.conf

        ip addr add "192.168.150.29/25" dev eth0 brd +
	ip addr add "10.100.0.1/24" dev eth1 brd +
        ip addr add "192.168.169.1/24" dev eth2 brd +

        ip link set dev eth0 up
        ip link set dev eth1 up
        ip link set dev eth2 up

        ip route add default dev eth0 via 192.168.150.1 scope global

        echo 1 > /proc/sys/net/ipv4/ip_forward

        ;;
stop)
        echo "Stopping the network"

	ip route del all

        ip addr flush eth0
        ip addr flush eth1
        ip addr flush eth2

        ip link set dev eth0 down 
        ip link set dev eth1 down 
        ip link set dev eth2 down

        ;;
restart)
        $0 stop
        $0 start
        ;;
*)
        echo "Usage $0 [start|stop|restart]"
esac


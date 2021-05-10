#!/bin/bash

case "$1" in
start)
        echo "Starting the network"

        ip link add name br0 type bridge
        ip link set up dev br0
        ip link set up dev eth0
        ip link set up dev eth1
        ip link set dev eth0 master br0

        ip addr add "192.168.158.1/24" dev eth1 brd +
        ip addr add dev br0 "192.168.150.18/24"

        ip route add default dev br0 via "192.168.150.1" scope global
        ip route add $my_int_net dev eth1

        echo 1 > /proc/sys/net/ipv4/ip_forward
        ;;
stop)
        echo "Stopping the network"
        ip route del default

        ip addr flush eth0
        ip addr flush eth1
        ip addr flush br0

        ip link set dev eth0 nomaster
        ip link set down dev br0
        ip link delete br0 type bridge

        ip link set down dev eth0
        ip link set down dev eth1

        ;;
restart)
        $0 stop
        $0 start
        ;;
*)
        echo "Usage $0 [start|stop|restart]"
esac


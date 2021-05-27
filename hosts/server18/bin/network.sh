#!/bin/bash

case "$1" in
start)
	echo "Starting the network"

	ip link add link eth0 name eth0.100 type vlan id 100

	ip link add name br0 type bridge
	ip link add name br1 type bridge
	ip link add name br2 type bridge

	ip link set up dev br0
	ip link set up dev br1
	ip link set up dev br2

	ip link set dev eth0 master br0
	ip link set dev eth1 master br1
	ip link set dev eth0.100 master br2

	ip link set up dev eth0
	ip link set up dev eth1
	ip link set up dev eth0.100

	ip addr add dev br0 "192.168.150.18/24" brd +

	ip route add default dev br0 via "192.168.150.1" scope global

	echo 1 > /proc/sys/net/ipv4/ip_forward
	;;
stop)
	echo "Stopping the network"
	ip route del default

	ip addr flush br0

	ip link set dev eth0 nomaster
	ip link set dev eth1 nomaster
	ip link set dev eth0.100 nomaster

	ip link set down dev eth0.100
	ip link set down dev eth0
	ip link set down dev eth1

	ip link set down dev br0
	ip link set down dev br1
	ip link set down dev br2

	ip link delete br0 type bridge
	ip link delete br1 type bridge
	ip link delete br2 type bridge

	ip link delete eth0.100
	;;
restart)
	$0 stop
	$0 start
	;;
*)
	echo "Usage $0 [start|stop|restart]"
esac 

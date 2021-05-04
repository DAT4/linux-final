#!/bin/bash

ip="/bin/ip"
dev=eth0
myIP="192.168.150.18/25"
router="192.168.150.1"

dev2=eth1
my_intIP="192.168.158.1/24"

case "$1" in
start)
	echo "Starting the network"

	$ip link set up dev $dev
	$ip addr add $myIP dev $dev brd +

	$ip link set up dev $dev2
	$ip addr add $my_intIP dev $dev2 brd +

	$ip route add default dev $dev via $router scope global

  	$ip route add $my_int_net dev $dev2

	echo 1 > /proc/sys/net/ipv4/ip_forward
	;;
stop)
	echo "Stopping the network"
	$ip route del default
	$ip addr del $myIP dev $dev
	$ip link set down dev $dev
	;;
restart)
	$0 stop
	$0 start
	;;
*)
	echo "Usage $0 [start|stop|restart]"
esac 

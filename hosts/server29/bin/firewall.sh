#!/bin/sh

case "$1" in
start)
    echo "Starting the firewall"

    iptables -F
    iptables -t nat -F

    # SET POLICIES
    iptables -P INPUT DROP
    iptables -P OUTPUT DROP
    iptables -P FORWARD DROP

    # ALLOW ALL TRAFIC ON LOCALHOST INTERFACE
    iptables -A INPUT -i lo -j ACCEPT

    # ALLOW ALL TRAFIC ON DMZ INTERFACE
    iptables -A INPUT -i eth1 -j ACCEPT
    iptables -A OUTPUT -o eth1 -j ACCEPT
    iptables -A FORWARD -o eth1 -j ACCEPT
    iptables -A FORWARD -i eth1 -j ACCEPT

    # SET INPUT AND OUTUT STATE ORIENTED ACCEPT FOR INPUT OUTPUT AND FORWARD
    iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
    iptables -A OUTPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
    iptables -A FORWARD -i eth0 -o eth2 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
    iptables -A FORWARD -i eth2 -o eth0 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

    # ALLOW SENDING MAIL OUT
    iptables -A OUTPUT -p tcp --dport 25 -j ACCEPT

    # ALLOW HTTP AND HTTPS
    iptables -A OUTPUT -p tcp --dport 80 -j ACCEPT
    iptables -A OUTPUT -p tcp --dport 443 -j ACCEPT

    #Allow Ping
    iptables -A INPUT -p icmp -m icmp --icmp-type 8 -j ACCEPT
    iptables -A OUTPUT -p icmp -m icmp --icmp-type 8 -j ACCEPT

    # ALLOW DNS
    iptables -A OUTPUT -p udp --sport 53 -j ACCEPT
    iptables -A OUTPUT -p udp --dport 53 -j ACCEPT

    # ALLOW SSH
    iptables -A INPUT -p tcp --dport 22 -j ACCEPT
    iptables -A OUTPUT -p tcp --dport 22 -j ACCEPT
    iptables -A OUTPUT -p tcp --dport 22022 -j ACCEPT

    # https://www.digitalocean.com/community/tutorials/how-to-forward-ports-through-a-linux-gateway-with-iptables
    iptables -A FORWARD -i eth0 -o eth2 -p tcp --dport 22 -j ACCEPT
    iptables -A FORWARD -i eth2 -o eth0 -p tcp --dport 80 -j ACCEPT
    iptables -A FORWARD -i eth2 -o eth0 -p tcp --dport 443 -j ACCEPT
    iptables -A FORWARD -i eth2 -o eth0 -p udp --dport 53 -j ACCEPT

    # PROXY HTTP AND HTTPS THROUGH SQUID ()
    # https://www.youtube.com/watch?v=mCmn3bb26xc
    iptables -I INPUT -p tcp --dport 8080 -j ACCEPT
    iptables -A OUTPUT -p tcp --dport 8081 -j ACCEPT


    iptables -t nat -A PREROUTING -i eth2 -p tcp --dport 80 -j DNAT --to 192.168.150.29:8080
    iptables -t nat -A PREROUTING -i eth1 -p tcp --dport 80 -j DNAT --to 192.168.150.29:8080
    iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 80 -j REDIRECT --to-port 8080

    iptables -t nat -A PREROUTING -i eth2 -p tcp --dport 443 -j DNAT --to 192.168.150.29:8080
    iptables -t nat -A PREROUTING -i eth1 -p tcp --dport 443 -j DNAT --to 192.168.150.29:8080
    iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 443 -j REDIRECT --to-port 8080

    iptables -t nat -A POSTROUTING -j MASQUERADE

    #iptables -vnL --line-numbers
    ;;
stop)
    echo "Stopping the firewall"
    # Accept everything
    iptables -P INPUT ACCEPT
    iptables -P OUTPUT ACCEPT
    iptables -P FORWARD ACCEPT

    # Zero, Flush, Delete extra chains
    iptables -t nat -Z
    iptables -t nat -F
    iptables -t nat -X
    iptables -Z
    iptables -F
    iptables -X

    ;;
*)
    echo "Usage $0 [start|stop]"
esac

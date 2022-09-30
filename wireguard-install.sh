#!/bin/bash
#Automatic WireGuard installation & configuration for Ubuntu 20.04
#(should work for 22.04 also)

#SET YOUR VALUES
EXT_IF_NAME="ens3" #name of external interface
EXT_IP="ExtIP"; #external IP in X.X.X.X format, without CIDR notation
EXT_PORT="ExtPort"; #any port from range 1024 - 65535
CLIENT_Q=10 #clients quantity

#DO NOT CHANGE BELOW
apt update && apt upgrade -y && apt install wireguard -y

[ ! -d /etc/wireguard ] && mkdir /etc/wireguard
umask 077; wg genkey | tee /etc/wireguard/wg0-private.key | wg pubkey > /etc/wireguard/wg0-public.key;

[ ! -d /etc/wireguard/clients ] && mkdir /etc/wireguard/clients
for N in $(seq 1 $CLIENT_Q); do
  umask 077; wg genkey | tee /etc/wireguard/clients/wg0-client$N-private.key | wg pubkey > /etc/wireguard/clients/wg0-client$N-public.key && wg genpsk > /etc/wireguard/clients/wg0-client$N-preshared.key;
done

INT_IP="10.121.19.1/24"
SRV_PUBLIC=$(cat /etc/wireguard/wg0-public.key);

printf "[Interface]\nAddress = $INT_IP\nListenPort = $EXT_PORT\nPrivateKey = $(cat /etc/wireguard/wg0-private.key)\nPostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -t nat -A POSTROUTING -s $INT_IP -o $EXT_IF_NAME -j MASQUERADE\nPostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -t nat -D POSTROUTING -s $INT_IP -o $EXT_IF_NAME -j MASQUERADE\n" > /etc/wireguard/wg0.conf

for N in $(seq 1 $CLIENT_Q); do
  CLIENT_PRIVATE=$(cat /etc/wireguard/clients/wg0-client$N-private.key);
  CLIENT_PUBLIC=$(cat /etc/wireguard/clients/wg0-client$N-public.key);
  CLIENT_PSK=$(cat /etc/wireguard/clients/wg0-client$N-preshared.key);
  printf "\n[Peer]\nPublicKey = $CLIENT_PUBLIC\nPresharedKey = $CLIENT_PSK\nAllowedIPs = 10.121.19.$(expr 1 + $N)/32\n" >> /etc/wireguard/wg0.conf;
  printf "[Interface]\nPrivateKey = $CLIENT_PRIVATE\nAddress = 10.121.19.$(expr 1 + $N)/32\nDNS = 1.1.1.1, 1.0.0.1\n\n[Peer]\nPublicKey = $SRV_PUBLIC\nPresharedKey = $CLIENT_PSK\nAllowedIPs = 0.0.0.0/0\nEndpoint = $EXT_IP:$EXT_PORT\nPersistentKeepalive = 25\n" > /etc/wireguard/clients/wg0-client$N.conf;
done

systemctl enable --now wg-quick@wg0
wg syncconf wg0 <(wg-quick strip wg0)

sed -i '/net.ipv4.ip_forward/s/^#//g' /etc/sysctl.conf
sysctl -p

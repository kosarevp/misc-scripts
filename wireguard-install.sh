#!/bin/bash

sudo su
apt update && apt upgrade -y && apt install wireguard -y
[ ! -d /etc/wireguard ] && mkdir /etc/wireguard
cd /etc/wireguard; umask 077; wg genkey | tee wg0-private.key | wg pubkey > wg0-public.key
mkdir /etc/wireguard/clients && cd "$_"
for N in {1..10}; do umask 077; wg genkey | tee wg0-client$N-private.key | wg pubkey > wg0-client$N-public.key && wg genpsk > wg0-client$N-preshared.key; done

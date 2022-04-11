sudo apt update && sudo apt upgrade -y && sudo apt install wireguard -y
[ ! -d /etc/wireguard ] && sudo mkdir /etc/wireguard;
cd /etc/wireguard; sudo umask 077; sudo wg genkey | sudo tee wg0-private.key | sudo wg genpub > wg0-public.key

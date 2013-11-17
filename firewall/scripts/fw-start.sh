#! /bin/bash

echo "- Initialisation du firewall :"

# Flush /sbin/iptables
/sbin/iptables -F 2>/dev/null

# Suppression des chaînes utilisateurs 
/sbin/iptables -X 2>/dev/null

echo "- Vidage des regles et des tables : [OK]"

# Interdire toutes connexions entrantes et sortantes
/sbin/iptables -t filter -P INPUT DROP
/sbin/iptables -t filter -P FORWARD DROP
/sbin/iptables -t filter -P OUTPUT DROP

echo "- Interdire toutes les connexions entrantes et sortantes : [OK]"

## Permettre à une connexion ouverte de recevoir du trafic en entrée.
/sbin/iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
 
## Permettre à une connexion ouverte de recevoir du trafic en sortie.
/sbin/iptables -A OUTPUT -m state ! --state INVALID -j ACCEPT

echo "- Ne pas casser les connexions établies : [OK]"

########## Regles ##########

# On accepte la boucle locale en entrée.
/sbin/iptables -A INPUT -i lo -j ACCEPT

# Autoriser le ping
/sbin/iptables -t filter -A INPUT -p icmp -j ACCEPT
/sbin/iptables -t filter -A OUTPUT -p icmp -j ACCEPT

# Autoriser SSH
/sbin/iptables -t filter -A INPUT -p tcp --dport 22 -j ACCEPT
/sbin/iptables -t filter -A OUTPUT -p tcp --dport 22 -j ACCEPT

# Autoriser DNS
/sbin/iptables -t filter -A OUTPUT -p tcp --dport 53 -j ACCEPT
/sbin/iptables -t filter -A OUTPUT -p udp --dport 53 -j ACCEPT
/sbin/iptables -t filter -A INPUT -p tcp --dport 53 -j ACCEPT
/sbin/iptables -t filter -A INPUT -p udp --dport 53 -j ACCEPT

# Autoriser NTP
/sbin/iptables -t filter -A OUTPUT -p udp --dport 123 -j ACCEPT

# Autoriser FTP
/sbin/modprobe ip_conntrack_ftp
/sbin/iptables -t filter -A INPUT -p tcp --dport 20:21 -j ACCEPT
/sbin/iptables -t filter -A OUTPUT -p tcp --dport 20:21 -j ACCEPT

# FTP Spécifique sortant
/sbin/iptables -t filter -A OUTPUT -p tcp --dport 10020:10021 -j ACCEPT

# Autoriser HTTP et HTTPS
/sbin/iptables -t filter -A OUTPUT -p tcp --dport 80 -j ACCEPT
/sbin/iptables -t filter -A INPUT -p tcp --dport 80 -j ACCEPT
/sbin/iptables -t filter -A OUTPUT -p tcp --dport 443 -j ACCEPT
/sbin/iptables -t filter -A INPUT -p tcp --dport 443 -j ACCEPT
/sbin/iptables -t filter -A INPUT -p tcp --dport 8443 -j ACCEPT

# Autoriser SMTP
/sbin/iptables -t filter -A INPUT -p tcp --dport 25 -j ACCEPT
/sbin/iptables -t filter -A OUTPUT -p tcp --dport 25 -j ACCEPT

# Autoriser VNC
/sbin/iptables -t filter -A INPUT -p tcp --dport 5901 -j ACCEPT
/sbin/iptables -t filter -A OUTPUT -p tcp --dport 5901 -j ACCEPT

# Filtrage en INPUT par IP de ports spécifiques
FILTRES=$(find /usr/local/bin/firewall -type f -name "*-firewall.sh")
if [[ -z $FILTRES ]] 
	then
	echo "  Aucun sous-script à exécuter de type /usr/local/bin/firewall/*-firewall.sh."
else
	for FILE in $FILTRES
	do
		$FILE
	done
fi

# On log les paquets en entrée + apple script anti-pollution
[ -e /usr/local/bin/firewall/anti-pollution-fw.sh ] && /usr/local/bin/firewall/anti-pollution-fw.sh

echo "- Initialisation des règles : [OK]"

# Relançons fail2ban
[ -e /etc/init.d/fail2ban ] && /etc/init.d/fail2ban restart

exit 0

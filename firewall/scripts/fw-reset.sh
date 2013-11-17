#! /bin/bash

echo "Reset des règles iptables :"

# Flush iptables
/sbin/iptables -F 2>/dev/null

# Suppression des chaînes utilisateurs 
/sbin/iptables -X 2>/dev/null

echo "- Vidage des règles et des tables : [OK]"

/sbin/iptables -P INPUT ACCEPT
/sbin/iptables -P FORWARD ACCEPT
/sbin/iptables -P OUTPUT ACCEPT

echo "- Autoriser toutes les connexions entrantes et sortantes : [OK]"

# Relançons fail2ban
    if [ -e /etc/init.d/fail2ban ]; then
        /etc/init.d/fail2ban restart
    fi

exit 0

#! /bin/bash

/sbin/iptables -F LDAP-WL >/dev/null 2>&1
/sbin/iptables -N LDAP-WL >/dev/null 2>&1

/sbin/iptables -D INPUT -p tcp -m tcp --dport 389 -j LDAP-WL >/dev/null 2>&1
/sbin/iptables -A INPUT -p tcp -m tcp --dport 389 -j LDAP-WL

if [ ! -e /etc/firewall/ldap-firewall.conf ]; then
	echo
	echo "ERROR: Le fichier de configuration /etc/firewall/ldap-firewall.conf n'existe pas !!!" >&2
	echo
	echo "Voici un exemple de configuration:"

	cat <<-LISTE_DES_IPS
		# Format des lignes:
		# ip			commentaire pouvant être inséré dans le firewall
		# Liste des ips autorisées à accéder à LDAP
		88.170.2.46             freebox.reseauenscene.fr
		109.190.1.77            serveur.reseauenscene.fr
		171.25.209.48           www.innovance-solutions.net
	LISTE_DES_IPS
	exit 1
fi

cat /etc/firewall/ldap-firewall.conf | \
while read ip comment
do
	[ -z "$ip" -o -z "${ip###*}" ] && continue
	if [ -n "$comment" ]; then
		/sbin/iptables -A LDAP-WL -s $ip -m comment --comment "$comment" -j ACCEPT
	else
		/sbin/iptables -A LDAP-WL -s $ip -j ACCEPT
	fi
done < /etc/firewall/ldap-firewall.conf

exit 0
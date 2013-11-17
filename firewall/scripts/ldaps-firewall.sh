#! /bin/bash

/sbin/iptables -F LDAPS-WL >/dev/null 2>&1
/sbin/iptables -N LDAPS-WL >/dev/null 2>&1

/sbin/iptables -D INPUT -p tcp -m tcp --dport 636 -j LDAPS-WL >/dev/null 2>&1
/sbin/iptables -A INPUT -p tcp -m tcp --dport 636 -j LDAPS-WL

if [ ! -e /etc/firewall/ldaps-firewall.conf ]; then
	echo
	echo "ERROR: Le fichier de configuration /etc/firewall/ldaps-firewall.conf n'existe pas !!!" >&2
	echo
	echo "Voici un exemple de configuration:"

	cat <<-LISTE_DES_IPS
		# Format des lignes:
		# ip			commentaire pouvant être inséré dans le firewall
		# Liste des ips autorisées à accéder à LDAPs
		88.170.2.46             freebox.reseauenscene.fr
		109.190.1.77            serveur.reseauenscene.fr
		171.25.209.48           www.innovance-solutions.net
	LISTE_DES_IPS
	exit 1
fi

cat /etc/firewall/ldaps-firewall.conf | \
while read ip comment
do
	[ -z "$ip" -o -z "${ip###*}" ] && continue
	if [ -n "$comment" ]; then
		/sbin/iptables -A LDAPS-WL -s $ip -m comment --comment "$comment" -j ACCEPT
	else
		/sbin/iptables -A LDAPS-WL -s $ip -j ACCEPT
	fi
done < /etc/firewall/ldaps-firewall.conf

exit 0
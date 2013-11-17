#! /bin/bash

/sbin/iptables -F WEBMIN-WL >/dev/null 2>&1
/sbin/iptables -N WEBMIN-WL >/dev/null 2>&1

/sbin/iptables -D INPUT -p tcp -m tcp --dport 10000 -j WEBMIN-WL >/dev/null 2>&1
/sbin/iptables -A INPUT -p tcp -m tcp --dport 10000 -j WEBMIN-WL

if [ ! -e /etc/firewall/webmin-firewall.conf ]; then
	echo
	echo "ERROR: Le fichier de configuration /etc/firewall/webmin-firewall.conf n'existe pas !!!" >&2
	echo
	echo "Voici un exemple de configuration:"

	cat <<-LISTE_DES_IPS
		# Format des lignes:
		# ip			commentaire pouvant être inséré dans le firewall
		# Liste des ips autorisées à accéder à WEBMIN
		88.170.2.46		freebox.reseauenscene.fr
		109.190.1.77	serveur.reseauenscene.fr
		82.239.138.61	serveur.gdo.name
	LISTE_DES_IPS
	exit 1
fi

cat /etc/firewall/webmin-firewall.conf | \
while read ip comment
do
	[ -z "$ip" -o -z "${ip###*}" ] && continue
	if [ -n "$comment" ]; then
		/sbin/iptables -A WEBMIN-WL -s $ip -m comment --comment "$comment" -j ACCEPT
	else
		/sbin/iptables -A WEBMIN-WL -s $ip -j ACCEPT
	fi
done < /etc/firewall/webmin-firewall.conf

exit 0
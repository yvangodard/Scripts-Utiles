#! /bin/bash

/sbin/iptables -F ETHERCALC-WL >/dev/null 2>&1
/sbin/iptables -N ETHERCALC-WL >/dev/null 2>&1

/sbin/iptables -D INPUT -p tcp -m tcp --dport 8000 -j ETHERCALC-WL >/dev/null 2>&1
/sbin/iptables -A INPUT -p tcp -m tcp --dport 8000 -j ETHERCALC-WL

if [ ! -e /etc/firewall/ethercalc-firewall.conf ]; then
	echo
	echo "ERROR: Le fichier de configuration /etc/firewall/ethercalc-firewall.conf n'existe pas !!!" >&2
	echo
	echo "Voici un exemple de configuration:"

	cat <<-LISTE_DES_IPS
		# Format des lignes:
		# ip			commentaire pouvant être inséré dans le firewall
		# Liste des ips autorisées à accéder à Ethercalc
		88.170.2.46		freebox.reseauenscene.fr
		109.190.1.77	serveur.reseauenscene.fr
		82.239.138.61	serveur.gdo.name
	LISTE_DES_IPS
	exit 1
fi

cat /etc/firewall/ethercalc-firewall.conf | \
while read ip comment
do
	[ -z "$ip" -o -z "${ip###*}" ] && continue
	if [ -n "$comment" ]; then
		/sbin/iptables -A ETHERCALC-WL -s $ip -m comment --comment "$comment" -j ACCEPT
	else
		/sbin/iptables -A ETHERCALC-WL -s $ip -j ACCEPT
	fi
done < /etc/firewall/ethercalc-firewall.conf

exit 0
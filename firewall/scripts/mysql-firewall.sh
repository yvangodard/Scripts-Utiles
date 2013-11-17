#! /bin/bash

/sbin/iptables -F MYSQL-WL >/dev/null 2>&1
/sbin/iptables -N MYSQL-WL >/dev/null 2>&1

/sbin/iptables -D INPUT -p tcp -m tcp --dport 3306 -j MYSQL-WL >/dev/null 2>&1
/sbin/iptables -A INPUT -p tcp -m tcp --dport 3306 -j MYSQL-WL

if [ ! -e /etc/firewall/mysql-firewall.conf ]; then
	echo
	echo "ERROR: Le fichier de configuration /etc/firewall/mysql-firewall.conf n'existe pas !!!" >&2
	echo
	echo "Voici un exemple de configuration:"

	cat <<-LISTE_DES_IPS
		# Format des lignes:
		# ip			commentaire pouvant être inséré dans le firewall
		# Liste des ips autorisées à accéder à MySQL
		88.170.2.46
		109.190.1.77	serveur.reseauenscene.fr
		82.239.138.61
		213.186.33.4	Cluster OVH
		90.0.244.190
		80.14.168.207
	LISTE_DES_IPS
	exit 1
fi

cat /etc/firewall/mysql-firewall.conf | \
while read ip comment
do
	[ -z "$ip" -o -z "${ip###*}" ] && continue
	if [ -n "$comment" ]; then
		/sbin/iptables -A MYSQL-WL -s $ip -m comment --comment "$comment" -j ACCEPT
	else
		/sbin/iptables -A MYSQL-WL -s $ip -j ACCEPT
	fi
done < /etc/firewall/mysql-firewall.conf

exit 0
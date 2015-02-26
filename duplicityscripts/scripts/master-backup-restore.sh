#! /bin/bash

# Charger la configuration par défaut si elle existe
[ -e /etc/master-backup.conf ] && . /etc/master-backup.conf || exit 1

# Charger une configuration si fournie en argument du script pouvant écraser certaines
# valeurs de la configuration par défaut
# Seules les configurations dont le template est /etc/master-backup*.conf sont acceptées
if [ -n "$1" -a -z "${1##/etc/master-backup*}" -a -z "${1%%*.conf}" -a -e "$1" ]; then
	. $1 || exit 1
	shift
elif [ "$1" == "--conf" ]; then
	[ -n "$2" -a -e "$2" ] && . $2 || exit 1
	shift ; shift
fi

export PATH=/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin

: ${BASE:=/var/backups/master}
: ${DEV:=}
: ${TAG:=Master-Backup}
: ${URL:=}
: ${WHAT:=}
: ${OPTIONS:=}
: ${PASSPHRASE:=__duplicity__GnuPG__passphrase__}
: ${CACHE:=~/.cache/duplicity}

timestamp () {
	date +%F-%Hh%M
}

log () {
	logger -st $TAG "$(timestamp): $*"
}

# Duplicity sert pour les sauvegardes complètes et incrémentales vers une destination
if [ -z "$URL" ]; then
	echo "Pas d'URL définie pour lister la sauvegarde"
	exit 1
fi

HERE="$PWD"

[ -d $BASE ] || mkdir -p $BASE
[ -n "$DEV" ] && mount $DEV $BASE >/dev/null 2>&1
pushd $BASE >/dev/null 2>&1 || exit 1
[ -d $BASE/tmp ] || mkdir -p $BASE/tmp

while [ -n "$1" -a -z "${1##-*}" ]
do
	# Support de l'option -t de duplicity
	if [ "$1" == "-t" ]; then
		DUPLICITY_OPTS="$DUPLICITY_OPTS --time $2"
		GOT_TIME=" (time=$2)"
		shift ; shift
	elif [ "$1" == "-f" ]; then
		DUPLICITY_OPTS="$DUPLICITY_OPTS --force"
		FORCED=" [FORCED]"
		shift
	else
		echo "Option non reconnue: $1 dans '$*'" >&2
		exit 1
	fi
done

if [ -z "$GOT_TIME" ]; then
	cat <<-HELP
		
		A savoir:
		
		1. Utilisez l'option -t avant le chemin à restaurer pour choisir une ancienne version
		Par exemple, '-t 3D' restaurera la version d'il ya 3 jours, et
		'-t 1h' restaurera la version disponible il y avait encore une heure
		Sinon, consultez la section 'TIME FORMATS' dans le 'man duplicity'
		
		2. Utilisez l'option -f pour forcer la restauration
		
	HELP
fi

# Dossier temporaire à utiliser
DUPLICITY_OPTS="$DUPLICITY_OPTS --tempdir $BASE/tmp"

# Paramètres HUBIC
unset HISTFILE
unset CLOUDFILES_USERNAME
unset CLOUDFILES_APIKEY
unset CLOUDFILES_AUTHURL
export CLOUDFILES_USERNAME=${HUBICUSER}
export CLOUDFILES_APIKEY=${HUBICPASSWORD}
export CLOUDFILES_AUTHURL="hubic|${HUBICAPPID}|${HUBICAPPSECRET}|${HUBICAPPURLREDIRECT}"

unset CACHE_OPTS
if [ -n "$CACHE" ]; then
	[ -d "$CACHE" ] || mkdir -p "$CACHE"
	CACHE_OPTS="--archive-dir $CACHE"
fi

if [ -n "$NAME" ]; then
	CACHE_OPTS="$CACHE_OPTS --name $NAME"
fi

H=$(hostname -s)

# PASSPHRASE est le secret pour le cryptage avec duplicity
export PASSPHRASE FTP_PASSWORD

# Cas d'un chemin relatif
if [ "${1#/}" == "$1" ]; then
	CIBLE="$HERE/$1"
else
	CIBLE="$1"
fi

if [ -n "$2" ]; then
	if [ "${2#/}" == "$2" ]; then
		DEST="$HERE/$2"
	else
		DEST="$2"
	fi
	VERS=" vers '$DEST'"
else
	DEST="$CIBLE"
fi

log "Tentative des restaurations de $CIBLE$GOT_TIME$VERS$FORCED"

duplicity restore $CACHE_OPTS $DUPLICITY_OPTS --file-to-restore "${CIBLE#/}" ${URL} "$DEST"
ERR=$?

popd >/dev/null 2>&1
[ -n "$DEV" ] && umount $BASE >/dev/null 2>&1

unset CLOUDFILES_USERNAME
unset CLOUDFILES_APIKEY
unset CLOUDFILES_AUTHURL

exit $ERR

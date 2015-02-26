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

# Duplicity sert pour les sauvegardes complètes et incrémentales vers une destination
if [ -z "$URL" ]; then
	echo "Pas d'URL définie pour lister la sauvegarde"
	exit 1
fi

[ -d $BASE ] || mkdir -p $BASE
[ -n "$DEV" ] && mount $DEV $BASE >/dev/null 2>&1
pushd $BASE >/dev/null 2>&1 || exit 1
[ -d $BASE/tmp ] || mkdir -p $BASE/tmp

DUPLICITY_OPTS="$*"

# Dossier temporaire à utiliser
DUPLICITY_OPTS="$DUPLICITY_OPTS --tempdir $BASE/tmp"

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

# Paramètres HUBIC
unset HISTFILE
unset CLOUDFILES_USERNAME
unset CLOUDFILES_APIKEY
unset CLOUDFILES_AUTHURL
export CLOUDFILES_USERNAME=${HUBICUSER}
export CLOUDFILES_APIKEY=${HUBICPASSWORD}
export CLOUDFILES_AUTHURL="hubic|${HUBICAPPID}|${HUBICAPPSECRET}|${HUBICAPPURLREDIRECT}"

duplicity cleanup $CACHE_OPTS $DUPLICITY_OPTS ${URL}
ERR=$?

popd >/dev/null 2>&1
[ -n "$DEV" ] && umount $BASE >/dev/null 2>&1

unset CLOUDFILES_USERNAME
unset CLOUDFILES_APIKEY
unset CLOUDFILES_AUTHURL

exit $ERR

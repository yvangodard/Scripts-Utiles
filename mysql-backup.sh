#!/bin/bash
 
## Variables
# Le script
CURRENT_DIR=$(dirname $0)
SCRIPT_NAME=$(basename $0)
# Répertoire de sauvergarde des dump SQL
LOCATION="/home/mysqldump"
# Nom du backup
DATANAME="databasebackup-$(date +%d.%m.%y@%Hh%M)"
# Répertoire temporaire
DATATMP="$LOCATION/temp"
# Mail pour l'envoi du rapport
MAIL_ADMIN="admin@reseauenscene.fr"
# Bases SQL à exclure
EXCLUSIONS='(information_schema)'
# Version du script
SCR_VERS="1.2"
# Les logs
LOGSLOCATION="/var/log/mysql-backup"
LOG_OUT="$LOGSLOCATION/out.log"
LOG_ERROR="$LOGSLOCATION/error.log"
LOG_CUMUL="$LOGSLOCATION/mysql-backup.log"
DATE_DU_JOUR=$(date)
# Initialisation signal erreur 
ERROR=0
 
if [ `whoami` != 'root' ]
	then
	echo "Ce script doit être utilisé par le compte root. Utilisez SUDO."
	exit 1
fi

umask 027

## Redirection des sorties vers nos logs
mkdir -p $LOCATION
mkdir -p $LOGSLOCATION
[ -f $LOG_OUT ] && rm  $LOG_OUT
[ -f $LOG_ERROR ] && rm  $LOG_ERROR
exec 1>> $LOG_OUT
exec 2>> $LOG_ERROR
 
echo "" >> $LOG_OUT
echo "****************************** $DATE_DU_JOUR ******************************" >> $LOG_OUT
echo "" >> $LOG_OUT
 
cd $LOCATION
 
## En fonction du jour, changement du nombre de backup à garder et du répertoire de destination
if [ "$( date +%w )" == "0" ]; then
        [ ! -d dimanche ] && mkdir -p dimanche
        DATADIR=${LOCATION}/dimanche
         # Période en jours de conservation des DUMP hebdomadaires
        KEEP_NUMBER=56
        echo "Backup hebdomadaire, $KEEP_NUMBER jours d'ancienneté seront gardés." >> $LOG_OUT
else
        [ ! -d quotidien ] && mkdir -p quotidien
        DATADIR=${LOCATION}/quotidien
        # Période en jours de conservation des DUMP quotidiens
        KEEP_NUMBER=14
        echo "Backup quotidien, $KEEP_NUMBER jours d'ancienneté seront gardés." >> $LOG_OUT
fi
 
## Création d'un répertoire temporaire pour la sauvegarde avant de zipper l'ensemble des dumps
mkdir -p "${DATATMP}/${DATANAME}"
 
# On place dans un tableau le nom de toutes les bases de données du serveur
databases="$(mysql -Bse 'show databases' | grep -v -E $EXCLUSIONS)"
echo "Bases de données à traiter :" >> $LOG_OUT
 
# Sauvegarde de toutes les bases dans le fichier du jour
# Pour chacune des bases de données trouvées ...
for database in ${databases[@]}
do
echo "- ${database}.sql"  >> $LOG_OUT
mysqldump --quick --add-locks --lock-tables --extended-insert $database  > ${DATATMP}/${DATANAME}/${database}.sql
[ $? -ne 0 ] && ERROR=1
done
 
## On commpresse (TAR) tous et on créé un lien symbolique pour le dernier
cd ${DATATMP}
echo "Création de l'archive ${DATADIR}/${DATANAME}.sql.gz" >> $LOG_OUT
tar -czf ${DATADIR}/${DATANAME}.sql.gz ${DATANAME}
[ $? -ne 0 ] && ERROR=1
cd ${DATADIR}
chmod 600 ${DATANAME}.sql.gz
[ -f last.sql.gz ] &&  rm last.sql.gz
ln -s ${DATANAME}.sql.gz last.sql.gz
 
## On supprime le répertoire temporaire
rm -rf ${DATATMP}/${DATANAME}
 
## On supprime les anciens backups
echo "Suppression des vieux DUMP éventuels" >> $LOG_OUT
find $DATADIR -name "*.sql.gz" -mtime +$KEEP_NUMBER -print -exec rm {} \;
[ $? -ne 0 ] && ERROR=1
 
## On fusionne le log d'erreur dans le log de sortie standard si il y a eu une erreur
[ $ERROR -ne 0 ] && echo "Log d'erreur :" >> $LOG_OUT ; cat $LOG_ERROR >> $LOG_OUT
 
## Envoi d'un email de notification
if [ $ERROR -ne 0 ]
then
echo "Problème lors de l'éxécution de (${0}). Merci de corriger le processus." >> $LOG_OUT
mail -s "[FAILED] Rapport Dump MySql (${0})" $MAIL_ADMIN <"${LOG_OUT}"
else
echo "Script de dump des bases MySql (${0}) exécuté avec succès."  >> $LOG_OUT
mail -s "[OK] Rapport Dump MySql (${0})" $MAIL_ADMIN <"${LOG_OUT}"
fi
 
cat $LOG_OUT >> $LOG_CUMUL
[ -f $LOG_OUT ] && rm  $LOG_OUT
[ -f $LOG_ERROR ] && rm  $LOG_ERROR
 
exit 0

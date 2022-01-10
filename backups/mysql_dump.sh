#!/bin/bash

#################################################################################################################
#                                                                                                               #
# 1. Create a backup user and add privileges:                                                                   #
#                                                                                                               #
# CREATE USER 'backup_user'@'localhost' IDENTIFIED BY '***';                                                    #
# GRANT USAGE ON *.* TO 'backup_user'@'localhost';                                                              #
# GRANT SELECT, SHOW VIEW, RELOAD, PROCESS, EVENT, TRIGGER, REPLICATION CLIENT ON *.* TO 'backup'@'localhost';  #
# FLUSH PRIVILEGES;                                                                                             #
#                                                                                                               #
# 2. Adjust variables                                                                                           #
#                                                                                                               #
# Usage:                                                                                                        #
#                                                                                                               #
# bash mysql_dump.sh                                                                                            #
#                                                                                                               #
#################################################################################################################

# Variables

BACKUP_BASE_DIR=
LOG_DIR=
DEFAULTS_FILE=
DATE=`date +%d_%m_%Y`
BACKUP_DIR=$BACKUP_BASE_DIR/daily/$DATE
LOG_NAME=$LOG_DIR/mysql_dump_`date +%d_%m_%Y_%H%M%S`.log
RETENTION=

DAYOFWEEK=$(date +"%w")
DAYOFMONTH=$(date +"%e")
DAYOFYEAR=$(date +"%j")

echo "DAYOFWEEK" : $DAYOFWEEK >> $LOG_NAME
echo "DAYOFMONTH" : $DAYOFMONTH >> $LOG_NAME
echo "DAYOFYEAR" : $DAYOFYEAR >> $LOG_NAME

# Checks:

echo "`date +%d-%m-%Y_%H:%M:%S` STARTED FULL BACKUP"

if [ ! -d "$BACKUP_DIR" ]; then
        mkdir -p $BACKUP_DIR
        if [ $? != 0 ]; then
                echo "`date +%d-%m-%Y_%H:%M:%S` FAILED FULL BACKUP: Unable to create $BACKUP_DIR"
                exit 1
        fi
else
BACKUP_DIR=$(echo $BACKUP_DIR)_`date +%H%M%S`
mkdir -p $BACKUP_DIR
fi

touch $BACKUP_DIR/test.file
if [ $? != 0 ]; then
        echo "`date +%d-%m-%Y_%H:%M:%S` FAILED FULL BACKUP: cannot write into $BACKUP_DIR"
        exit 1
else
        rm $BACKUP_DIR/test.file
fi

if [ ! -d "$LOG_DIR" ]; then
        mkdir -p $LOG_DIR
        if [ $? != 0 ]; then
                echo "`date +%d-%m-%Y_%H:%M:%S` FAILED FULL BACKUP: Unable to create $LOG_DIR"
                exit 1
        fi
fi

# Backup:

echo "`date +%d-%m-%Y_%H:%M:%S` Starting mysqldump:" >> $LOG_NAME
echo "" >> $LOG_NAME

databases=`mysql --defaults-file=$DEFAULTS_FILE -e "SHOW DATABASES;" | tr -d "| " | grep -v Database`

for db in $databases; do
    if [[ "$db" != "information_schema" ]] && [[ "$db" != _* ]] && [[ "$db" != performance_schema ]] ; then
        echo "Dumping database: $db"
        mysqldump --defaults-file=$DEFAULTS_FILE \
                  --opt \
                  --force \
                  --single-transaction \
                  --flush-logs \
                  --add-drop-database \
                  --add-drop-table \
                  --flush-privileges \
                  --allow-keywords \
                  --events \
                  --triggers \
                  --routines \
                  --databases $db > $BACKUP_DIR/`date +%Y%m%d`.$db.sql
        gzip $BACKUP_DIR/`date +%Y%m%d`.$db.sql
    fi
done

if [ $? != 0 ]; then
        echo "`date +%d-%m-%Y_%H:%M:%S` FAILED FULL BACKUP: mysqldump failed. Check $LOG_NAME"
        exit 1
fi

echo "`date +%d-%m-%Y_%H:%M:%S` COMPLETED FULL BACKUP"

echo "`date +%d-%m-%Y_%H:%M:%S` Starting cleanup: " >> $LOG_NAME
find $BACKUP_BASE_DIR/daily -mtime +$RETENTION -exec ls -ltr {} \;  -exec rm -rf {} \; >> $LOG_NAME
echo "`date +%d-%m-%Y_%H:%M:%S` Completed cleanup" >> $LOG_NAME

#!/bin/bash

# Для того, что-бы убедиться в работоспособности скрипта, проверьте значение переменных LOGDIR и --defaults-file

LOG_DIR=/root/defrag_script
LOG_NAME=$LOG_DIR/trends_`date +%d_%m_%Y_%H%M%S`.log

echo "Current execution date:" $(date) | tee -a $LOG_NAME
echo "Next execution date:" $(date -d "+4 months") | tee -a $LOG_NAME
echo " " | tee -a $LOG_NAME

echo " " | tee -a $LOG_NAME
echo "########### Processing first month" | tee -a $LOG_NAME
echo " " | tee -a $LOG_NAME

# Выбираем нужный месяц, собираем необходимые партиции и разбиваем в переменные

month1=$(date -d '-1 month' '+%Y%m')

echo " " | tee -a $LOG_NAME
echo "Before defragmentation:" | tee -a $LOG_NAME
mysql --defaults-file=/etc/zabbix/my.cnf -t << EOF >> $LOG_NAME
SELECT TABLE_SCHEMA as "Database",
TABLE_NAME as "Table",
PARTITION_NAME as "Partition Name",
round(DATA_LENGTH/1024/1024) as "Data Lenght",
round(INDEX_LENGTH/1024/1024) as "Index Lenght",
round(DATA_FREE/1024/1024) as "Data Free"
FROM information_schema.PARTITIONS
WHERE TABLE_SCHEMA = 'zabbix'
AND round(DATA_FREE/1024/1024) > 0
AND TABLE_NAME in ('trends') and PARTITION_NAME like '%p$month1%' ORDER BY TABLE_SCHEMA, PARTITION_NAME;
EOF
echo " " | tee -a $LOG_NAME
parts1=$(mysql --defaults-file=/etc/zabbix/my.cnf -se "SELECT PARTITION_NAME FROM information_schema.PARTITIONS WHERE TABLE_NAME in ('trends') AND PARTITION_NAME like '%p$month1%' limit 0, 10;" | awk -v ORS=, '{ print $parts1 }' | sed 's/,$/\n/')
parts2=$(mysql --defaults-file=/etc/zabbix/my.cnf -se "SELECT PARTITION_NAME FROM information_schema.PARTITIONS WHERE TABLE_NAME in ('trends') AND PARTITION_NAME like '%p$month1%' limit 10, 10;" | awk -v ORS=, '{ print $parts2 }' | sed 's/,$/\n/')
parts3=$(mysql --defaults-file=/etc/zabbix/my.cnf -se "SELECT PARTITION_NAME FROM information_schema.PARTITIONS WHERE TABLE_NAME in ('trends') AND PARTITION_NAME like '%p$month1%' limit 20, 11;" | awk -v ORS=, '{ print $parts3 }' | sed 's/,$/\n/')

# Подсчет количества пустых строк:

rows1=$(mysql --defaults-file=/etc/zabbix/my.cnf -se "USE zabbix; SELECT COUNT(itemid) FROM trends PARTITION ($parts1) WHERE NOT EXISTS (SELECT 1 FROM items WHERE trends.itemid = items.itemid);")
rows2=$(mysql --defaults-file=/etc/zabbix/my.cnf -se "USE zabbix; SELECT COUNT(itemid) FROM trends PARTITION ($parts2) WHERE NOT EXISTS (SELECT 1 FROM items WHERE trends.itemid = items.itemid);")
rows3=$(mysql --defaults-file=/etc/zabbix/my.cnf -se "USE zabbix; SELECT COUNT(itemid) FROM trends PARTITION ($parts3) WHERE NOT EXISTS (SELECT 1 FROM items WHERE trends.itemid = items.itemid);")
sumrows=$((rows1+rows2+rows3))
month1_name=$(date -d '-1 month' '+%B')

echo "Amount of empty rows in" "$month1_name"":" "$sumrows" | tee -a $LOG_NAME

# Удаляем пустые строки:

echo "Deleting empty rows" $(date) | tee -a $LOG_NAME
mysql --defaults-file=/etc/zabbix/my.cnf -se "USE zabbix; DELETE FROM trends PARTITION ($parts1) WHERE NOT EXISTS (SELECT 1 FROM items WHERE trends.itemid = items.itemid);"
mysql --defaults-file=/etc/zabbix/my.cnf -se "USE zabbix; DELETE FROM trends PARTITION ($parts2) WHERE NOT EXISTS (SELECT 1 FROM items WHERE trends.itemid = items.itemid);"
mysql --defaults-file=/etc/zabbix/my.cnf -se "USE zabbix; DELETE FROM trends PARTITION ($parts3) WHERE NOT EXISTS (SELECT 1 FROM items WHERE trends.itemid = items.itemid);"

# Ребилдим партиции:

echo "Rebuilding partitions" $(date) | tee -a $LOG_NAME
mysql --defaults-file=/etc/zabbix/my.cnf -se "USE zabbix; ALTER TABLE trends REBUILD PARTITION $parts1;"
mysql --defaults-file=/etc/zabbix/my.cnf -se "USE zabbix; ALTER TABLE trends REBUILD PARTITION $parts2;"
mysql --defaults-file=/etc/zabbix/my.cnf -se "USE zabbix; ALTER TABLE trends REBUILD PARTITION $parts3;"

# Аналайзим партиции:

echo "Analyzing partitions:" $(date) | tee -a $LOG_NAME
mysql --defaults-file=/etc/zabbix/my.cnf -se "USE zabbix; ALTER TABLE trends ANALYZE PARTITION $parts1;"
mysql --defaults-file=/etc/zabbix/my.cnf -se "USE zabbix; ALTER TABLE trends ANALYZE PARTITION $parts2;"
mysql --defaults-file=/etc/zabbix/my.cnf -se "USE zabbix; ALTER TABLE trends ANALYZE PARTITION $parts3;"

echo " " | tee -a $LOG_NAME
echo "After defragmentation:" | tee -a $LOG_NAME
mysql --defaults-file=/etc/zabbix/my.cnf -t << EOF >> $LOG_NAME
SELECT TABLE_SCHEMA as "Database",
TABLE_NAME as "Table",
PARTITION_NAME as "Partition Name",
round(DATA_LENGTH/1024/1024) as "Data Lenght",
round(INDEX_LENGTH/1024/1024) as "Index Lenght",
round(DATA_FREE/1024/1024) as "Data Free"
FROM information_schema.PARTITIONS
WHERE TABLE_SCHEMA = 'zabbix'
AND round(DATA_FREE/1024/1024) > 0
AND TABLE_NAME in ('trends') and PARTITION_NAME like '%p$month1%' ORDER BY TABLE_SCHEMA, PARTITION_NAME;
EOF

#########################################################################################################################################################################

echo " " | tee -a $LOG_NAME
echo "########### Processing second month" | tee -a $LOG_NAME
echo " " | tee -a $LOG_NAME

# Выбираем нужный месяц, собираем необходимые партиции и разбиваем в переменные

month2=$(date -d '-2 month' '+%Y%m')

echo " " | tee -a $LOG_NAME
echo "Before defragmentation:" | tee -a $LOG_NAME
mysql --defaults-file=/etc/zabbix/my.cnf -t << EOF >> $LOG_NAME
SELECT TABLE_SCHEMA as "Database",
TABLE_NAME as "Table",
PARTITION_NAME as "Partition Name",
round(DATA_LENGTH/1024/1024) as "Data Lenght",
round(INDEX_LENGTH/1024/1024) as "Index Lenght",
round(DATA_FREE/1024/1024) as "Data Free"
FROM information_schema.PARTITIONS
WHERE TABLE_SCHEMA = 'zabbix'
AND round(DATA_FREE/1024/1024) > 0
AND TABLE_NAME in ('trends') and PARTITION_NAME like '%p$month2%' ORDER BY TABLE_SCHEMA, PARTITION_NAME;
EOF
echo " " | tee -a $LOG_NAME
parts4=$(mysql --defaults-file=/etc/zabbix/my.cnf -se "SELECT PARTITION_NAME FROM information_schema.PARTITIONS WHERE TABLE_NAME in ('trends') AND PARTITION_NAME like '%p$month2%' limit 0, 10;" | awk -v ORS=, '{ print $parts4 }' | sed 's/,$/\n/')
parts5=$(mysql --defaults-file=/etc/zabbix/my.cnf -se "SELECT PARTITION_NAME FROM information_schema.PARTITIONS WHERE TABLE_NAME in ('trends') AND PARTITION_NAME like '%p$month2%' limit 10, 10;" | awk -v ORS=, '{ print $parts5 }' | sed 's/,$/\n/')
parts6=$(mysql --defaults-file=/etc/zabbix/my.cnf -se "SELECT PARTITION_NAME FROM information_schema.PARTITIONS WHERE TABLE_NAME in ('trends') AND PARTITION_NAME like '%p$month2%' limit 20, 11;" | awk -v ORS=, '{ print $parts6 }' | sed 's/,$/\n/')

### Подсчет количества пустых строк:
rows4=$(mysql --defaults-file=/etc/zabbix/my.cnf -se "USE zabbix; SELECT COUNT(itemid) FROM trends PARTITION ($parts4) WHERE NOT EXISTS (SELECT 1 FROM items WHERE trends.itemid = items.itemid);")
rows5=$(mysql --defaults-file=/etc/zabbix/my.cnf -se "USE zabbix; SELECT COUNT(itemid) FROM trends PARTITION ($parts5) WHERE NOT EXISTS (SELECT 1 FROM items WHERE trends.itemid = items.itemid);")
rows6=$(mysql --defaults-file=/etc/zabbix/my.cnf -se "USE zabbix; SELECT COUNT(itemid) FROM trends PARTITION ($parts6) WHERE NOT EXISTS (SELECT 1 FROM items WHERE trends.itemid = items.itemid);")
sumrows=$((rows4+rows5+rows6))
month2_name=$(date -d '-2 month' '+%B')
echo "Amount of empty rows in" "$month2_name"":" "$sumrows" | tee -a $LOG_NAME

# Удаляем пустые строки:

echo "Deleting empty rows" $(date) | tee -a $LOG_NAME
mysql --defaults-file=/etc/zabbix/my.cnf -se "USE zabbix; DELETE FROM trends PARTITION ($parts4) WHERE NOT EXISTS (SELECT 1 FROM items WHERE trends.itemid = items.itemid);"
mysql --defaults-file=/etc/zabbix/my.cnf -se "USE zabbix; DELETE FROM trends PARTITION ($parts5) WHERE NOT EXISTS (SELECT 1 FROM items WHERE trends.itemid = items.itemid);"
mysql --defaults-file=/etc/zabbix/my.cnf -se "USE zabbix; DELETE FROM trends PARTITION ($parts6) WHERE NOT EXISTS (SELECT 1 FROM items WHERE trends.itemid = items.itemid);"

# Ребилдим партиции:

echo "Rebuilding partitions" $(date) | tee -a $LOG_NAME
mysql --defaults-file=/etc/zabbix/my.cnf -se "USE zabbix; ALTER TABLE trends REBUILD PARTITION $parts4;"
mysql --defaults-file=/etc/zabbix/my.cnf -se "USE zabbix; ALTER TABLE trends REBUILD PARTITION $parts5;"
mysql --defaults-file=/etc/zabbix/my.cnf -se "USE zabbix; ALTER TABLE trends REBUILD PARTITION $parts6;"

# Аналайзим партиции:

echo "Analyzing partitions:" $(date) | tee -a $LOG_NAME
mysql --defaults-file=/etc/zabbix/my.cnf -se "USE zabbix; ALTER TABLE trends ANALYZE PARTITION $parts4;"
mysql --defaults-file=/etc/zabbix/my.cnf -se "USE zabbix; ALTER TABLE trends ANALYZE PARTITION $parts5;"
mysql --defaults-file=/etc/zabbix/my.cnf -se "USE zabbix; ALTER TABLE trends ANALYZE PARTITION $parts6;"

echo " " | tee -a $LOG_NAME
echo "After defragmentation:" | tee -a $LOG_NAME
mysql --defaults-file=/etc/zabbix/my.cnf -t << EOF >> $LOG_NAME
SELECT TABLE_SCHEMA as "Database",
TABLE_NAME as "Table",
PARTITION_NAME as "Partition Name",
round(DATA_LENGTH/1024/1024) as "Data Lenght",
round(INDEX_LENGTH/1024/1024) as "Index Lenght",
round(DATA_FREE/1024/1024) as "Data Free"
FROM information_schema.PARTITIONS
WHERE TABLE_SCHEMA = 'zabbix'
AND round(DATA_FREE/1024/1024) > 0
AND TABLE_NAME in ('trends') and PARTITION_NAME like '%p$month2%' ORDER BY TABLE_SCHEMA, PARTITION_NAME;'
EOF

#########################################################################################################################################################################

echo " " | tee -a $LOG_NAME
echo "########### Processing third month" | tee -a $LOG_NAME
echo " " | tee -a $LOG_NAME

# Выбираем нужный месяц, собираем необходимые партиции и разбиваем в переменные

month3=$(date -d '-3 month' '+%Y%m')

echo " " | tee -a $LOG_NAME
echo "Before defragmentation" | tee -a $LOG_NAME
mysql --defaults-file=/etc/zabbix/my.cnf -t << EOF >> $LOG_NAME
SELECT TABLE_SCHEMA as "Database",
TABLE_NAME as "Table",
PARTITION_NAME as "Partition Name",
round(DATA_LENGTH/1024/1024) as "Data Lenght",
round(INDEX_LENGTH/1024/1024) as "Index Lenght",
round(DATA_FREE/1024/1024) as "Data Free"
FROM information_schema.PARTITIONS
WHERE TABLE_SCHEMA = 'zabbix'
AND round(DATA_FREE/1024/1024) > 0
AND TABLE_NAME in ('trends') and PARTITION_NAME like '%p$month3%' ORDER BY TABLE_SCHEMA, PARTITION_NAME;
EOF
echo " " | tee -a $LOG_NAME

parts7=$(mysql --defaults-file=/etc/zabbix/my.cnf -se "SELECT PARTITION_NAME FROM information_schema.PARTITIONS WHERE TABLE_NAME in ('trends') AND PARTITION_NAME like '%p$month3%' limit 0, 10;" | awk -v ORS=, '{ print $parts4 }' | sed 's/,$/\n/')
parts8=$(mysql --defaults-file=/etc/zabbix/my.cnf -se "SELECT PARTITION_NAME FROM information_schema.PARTITIONS WHERE TABLE_NAME in ('trends') AND PARTITION_NAME like '%p$month3%' limit 10, 10;" | awk -v ORS=, '{ print $parts5 }' | sed 's/,$/\n/')
parts9=$(mysql --defaults-file=/etc/zabbix/my.cnf -se "SELECT PARTITION_NAME FROM information_schema.PARTITIONS WHERE TABLE_NAME in ('trends') AND PARTITION_NAME like '%p$month3%' limit 20, 11;" | awk -v ORS=, '{ print $parts6 }' | sed 's/,$/\n/')

# Подсчет количества пустых строк:

rows7=$(mysql --defaults-file=/etc/zabbix/my.cnf -se "USE zabbix; SELECT COUNT(itemid) FROM trends PARTITION ($parts7) WHERE NOT EXISTS (SELECT 1 FROM items WHERE trends.itemid = items.itemid);")
rows8=$(mysql --defaults-file=/etc/zabbix/my.cnf -se "USE zabbix; SELECT COUNT(itemid) FROM trends PARTITION ($parts8) WHERE NOT EXISTS (SELECT 1 FROM items WHERE trends.itemid = items.itemid);")
rows9=$(mysql --defaults-file=/etc/zabbix/my.cnf -se "USE zabbix; SELECT COUNT(itemid) FROM trends PARTITION ($parts9) WHERE NOT EXISTS (SELECT 1 FROM items WHERE trends.itemid = items.itemid);")
sumrows=$((rows7+rows8+rows9))
month3_name=$(date -d '-3 month' '+%B')
echo "Amount of empty rows in" "$month3_name"":" "$sumrows" | tee -a $LOG_NAME

# Удаляем пустые строки:

echo "Deleting empty rows" $(date) | tee -a $LOG_NAME
mysql --defaults-file=/etc/zabbix/my.cnf -se "USE zabbix; DELETE FROM trends PARTITION ($parts7) WHERE NOT EXISTS (SELECT 1 FROM items WHERE trends.itemid = items.itemid);"
mysql --defaults-file=/etc/zabbix/my.cnf -se "USE zabbix; DELETE FROM trends PARTITION ($parts8) WHERE NOT EXISTS (SELECT 1 FROM items WHERE trends.itemid = items.itemid);"
mysql --defaults-file=/etc/zabbix/my.cnf -se "USE zabbix; DELETE FROM trends PARTITION ($parts9) WHERE NOT EXISTS (SELECT 1 FROM items WHERE trends.itemid = items.itemid);"

# Ребилдим партиции:

echo "Rebuilding partitions" $(date) | tee -a $LOG_NAME
mysql --defaults-file=/etc/zabbix/my.cnf -se "USE zabbix; ALTER TABLE trends REBUILD PARTITION $parts7;"
mysql --defaults-file=/etc/zabbix/my.cnf -se "USE zabbix; ALTER TABLE trends REBUILD PARTITION $parts8;"
mysql --defaults-file=/etc/zabbix/my.cnf -se "USE zabbix; ALTER TABLE trends REBUILD PARTITION $parts9;"

# Аналайзим партиции:

echo "Analyzing partitions:" $(date) | tee -a $LOG_NAME
mysql --defaults-file=/etc/zabbix/my.cnf -se "USE zabbix; ALTER TABLE trends ANALYZE PARTITION $parts7;"
mysql --defaults-file=/etc/zabbix/my.cnf -se "USE zabbix; ALTER TABLE trends ANALYZE PARTITION $parts8;"
mysql --defaults-file=/etc/zabbix/my.cnf -se "USE zabbix; ALTER TABLE trends ANALYZE PARTITION $parts9;"

echo " " | tee -a $LOG_NAME
echo "After defragmentation" | tee -a $LOG_NAME
mysql --defaults-file=/etc/zabbix/my.cnf -t << EOF >> $LOG_NAME
SELECT TABLE_SCHEMA as "Database",
TABLE_NAME as "Table",
PARTITION_NAME as "Partition Name",
round(DATA_LENGTH/1024/1024) as "Data Lenght",
round(INDEX_LENGTH/1024/1024) as "Index Lenght",
round(DATA_FREE/1024/1024) as "Data Free"
FROM information_schema.PARTITIONS
WHERE TABLE_SCHEMA = 'zabbix'
AND round(DATA_FREE/1024/1024) > 0
AND TABLE_NAME in ('trends') and PARTITION_NAME like '%p$month3%' ORDER BY TABLE_SCHEMA, PARTITION_NAME;
EOF

#########################################################################################################################################################################

echo " " | tee -a $LOG_NAME
echo "########### Processing fourth month" | tee -a $LOG_NAME
echo " " | tee -a $LOG_NAME

# Выбираем нужный месяц, собираем необходимые партиции и разбиваем в переменные

month4=$(date -d '-4 month' '+%Y%m')

echo " " | tee -a $LOG_NAME
echo "Before defragmentation:" | tee -a $LOG_NAME
mysql --defaults-file=/etc/zabbix/my.cnf -t << EOF >> $LOG_NAME
SELECT TABLE_SCHEMA as "Database",
TABLE_NAME as "Table",
PARTITION_NAME as "Partition Name",
round(DATA_LENGTH/1024/1024) as "Data Lenght",
round(INDEX_LENGTH/1024/1024) as "Index Lenght",
round(DATA_FREE/1024/1024) as "Data Free"
FROM information_schema.PARTITIONS
WHERE TABLE_SCHEMA = 'zabbix'
AND round(DATA_FREE/1024/1024) > 0
AND TABLE_NAME in ('trends') and PARTITION_NAME like '%p$month4%' ORDER BY TABLE_SCHEMA, PARTITION_NAME;
EOF
echo " " | tee -a $LOG_NAME

parts10=$(mysql --defaults-file=/etc/zabbix/my.cnf -se "SELECT PARTITION_NAME FROM information_schema.PARTITIONS WHERE TABLE_NAME in ('trends') AND PARTITION_NAME like '%p$month4%' limit 0, 10;" | awk -v ORS=, '{ print $parts4 }' | sed 's/,$/\n/')
parts11=$(mysql --defaults-file=/etc/zabbix/my.cnf -se "SELECT PARTITION_NAME FROM information_schema.PARTITIONS WHERE TABLE_NAME in ('trends') AND PARTITION_NAME like '%p$month4%' limit 10, 10;" | awk -v ORS=, '{ print $parts5 }' | sed 's/,$/\n/')
parts12=$(mysql --defaults-file=/etc/zabbix/my.cnf -se "SELECT PARTITION_NAME FROM information_schema.PARTITIONS WHERE TABLE_NAME in ('trends') AND PARTITION_NAME like '%p$month4%' limit 20, 11;" | awk -v ORS=, '{ print $parts6 }' | sed 's/,$/\n/')

# Подсчет количества пустых строк:

rows10=$(mysql --defaults-file=/etc/zabbix/my.cnf -se "USE zabbix; SELECT COUNT(itemid) FROM trends PARTITION ($parts10) WHERE NOT EXISTS (SELECT 1 FROM items WHERE trends.itemid = items.itemid);")
rows11=$(mysql --defaults-file=/etc/zabbix/my.cnf -se "USE zabbix; SELECT COUNT(itemid) FROM trends PARTITION ($parts11) WHERE NOT EXISTS (SELECT 1 FROM items WHERE trends.itemid = items.itemid);")
rows12=$(mysql --defaults-file=/etc/zabbix/my.cnf -se "USE zabbix; SELECT COUNT(itemid) FROM trends PARTITION ($parts12) WHERE NOT EXISTS (SELECT 1 FROM items WHERE trends.itemid = items.itemid);")
sumrows=$((rows10+rows11+rows12))
month4_name=$(date -d '-4 month' '+%B')
echo "Amount of empty rows in" "$month4_name"":" "$sumrows" | tee -a $LOG_NAME

# Удаляем пустые строки:

echo "Deleting empty rows" $(date) | tee -a $LOG_NAME
mysql --defaults-file=/etc/zabbix/my.cnf -se "USE zabbix; DELETE FROM trends PARTITION ($parts10) WHERE NOT EXISTS (SELECT 1 FROM items WHERE trends.itemid = items.itemid);"
mysql --defaults-file=/etc/zabbix/my.cnf -se "USE zabbix; DELETE FROM trends PARTITION ($parts11) WHERE NOT EXISTS (SELECT 1 FROM items WHERE trends.itemid = items.itemid);"
mysql --defaults-file=/etc/zabbix/my.cnf -se "USE zabbix; DELETE FROM trends PARTITION ($parts12) WHERE NOT EXISTS (SELECT 1 FROM items WHERE trends.itemid = items.itemid);"

# Ребилдим партиции:

echo "Rebuilding partitions" $(date) | tee -a $LOG_NAME
mysql --defaults-file=/etc/zabbix/my.cnf -se "USE zabbix; ALTER TABLE trends REBUILD PARTITION $parts10;"
mysql --defaults-file=/etc/zabbix/my.cnf -se "USE zabbix; ALTER TABLE trends REBUILD PARTITION $parts11;"
mysql --defaults-file=/etc/zabbix/my.cnf -se "USE zabbix; ALTER TABLE trends REBUILD PARTITION $parts12;"

# Аналайзим партиции:

echo "Analyzing partitions:" $(date) | tee -a $LOG_NAME
mysql --defaults-file=/etc/zabbix/my.cnf -se "USE zabbix; ALTER TABLE trends ANALYZE PARTITION $parts10;"
mysql --defaults-file=/etc/zabbix/my.cnf -se "USE zabbix; ALTER TABLE trends ANALYZE PARTITION $parts11;"
mysql --defaults-file=/etc/zabbix/my.cnf -se "USE zabbix; ALTER TABLE trends ANALYZE PARTITION $parts12;"

echo " " | tee -a $LOG_NAME
echo "After defragmentation:" | tee -a $LOG_NAME
mysql --defaults-file=/etc/zabbix/my.cnf -t << EOF >> $LOG_NAME
SELECT TABLE_SCHEMA as "Database",
TABLE_NAME as "Table",
PARTITION_NAME as "Partition Name",
round(DATA_LENGTH/1024/1024) as "Data Lenght",
round(INDEX_LENGTH/1024/1024) as "Index Lenght",
round(DATA_FREE/1024/1024) as "Data Free"
FROM information_schema.PARTITIONS
WHERE TABLE_SCHEMA = 'zabbix'
AND round(DATA_FREE/1024/1024) > 0
AND TABLE_NAME in ('trends') and PARTITION_NAME like '%p$month4%' ORDER BY TABLE_SCHEMA, PARTITION_NAME;
EOF

echo " " | tee -a $LOG_NAME
echo "Done:" $(date) | tee -a $LOG_NAME

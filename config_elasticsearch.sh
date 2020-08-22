#!/bin/bash

#*********************************************************
# Скрипт запускать после установки elasticsearch и сетевых настроек сервера
# иначе нужно править строки в скрипте на те что в конфигах.
# Если не нужно изменять значение RAM для кучи, можно закомментировать
# !!! При повторном запуске скрипта дублирования или перезаписи строк не происходит
# К файлам прописать абсолютные пути
#*********************************************************

#Получаем RAM
MEM=$(free | awk 'NR==2{print $2}')
let "MEM/=1000000"
echo "Всего $MEM Gb памяти"
let "MEM/=2"
#MEM=$(free | awk 'NR==2{print $2}');let "MEM/=1000000*2"

#Записываем значение RAM в jvm.options по дефолту 2g
sed -i 's/-Xms2g/-Xms'$MEM'g/' jvm.options
sed -i 's/-Xmx2g/-Xmx'$MEM'g/' jvm.options
echo "Изменено в jvm.options на $MEM Gb "
#cat jvm.options | grep "Xms$MEMg\|Xmx$MEMg"

#Добавляем директиву MAX_LOCKED_MEMORY=unlimited
sed -i 's/#MAX_LOCKED_MEMORY=unlimited/MAX_LOCKED_MEMORY=unlimited/' elasticsearch

# Получаем ip адрес хоста
ip=$(hostname -i)

#Прописываем ip и port
sed -i 's/#network.host: 192.168.0.1/network.host: '$ip'/' elasticsearch.yml
sed -i 's/#http.port: 9200/http.port: 9200/' elasticsearch.yml
echo "network.host: $ip"

soft='elasticsearch soft memlock unlimited'
grep "elasticsearch soft memlock unlimited" limits.conf || sed -i '/#@student        -       maxlogins       4/a\'"${soft}" limits.conf

hard='elasticsearch hard memlock unlimited'
grep "elasticsearch hard memlock unlimited" limits.conf || sed -i '/#@student        -       maxlogins       4/a\'"${hard}" limits.conf

MemLock='LimitMEMLOCK=infinity'
grep LimitMEMLOCK=infinity elasticsearch.service || sed -i '/\[Service\]/a\'"${MemLock}" elasticsearch.service

systemctl daemon-reload
sleep 10
service elasticsearch restart

#!/bin/bash

LOCK=/var/tmp/lockfile
LOGFILE=/tmp/access.log
RESULTFILE=./result

x=7
y=7

if [ -f $LOCK ]
then
        echo "File busy"
        exit 1
else
        touch $LOCK
        trap 'rm -f $LOCK; exit $?' INT TERM EXIT
fi

logging() {
        FTARGETFILE=$1
        FRESULTFILE=$2
        MINTIME=`head -n 1 $1 |awk '{print $4}'`
        MAXTIME=`tail -n 1 $1 |awk '{print $4}'`
        echo "" >> $2
        echo "Файл начинается с $MINTIME] по $MAXTIME]" >> $2
        echo "" >> $2
        echo "$x IP адресов (с наибольшим количеством запросов) с указанием кол-ва запросов c момента последнего запуска скрипта" >> $2
        cat $1 |awk '{print $1}' |sort |uniq -c |sort -rn| tail -$x >> $2
        
        echo "" >> $2
        echo "$y запрашиваемых URL (с наибольшим количеством запросов) с указанием количества запросов c момента последнего запуска скрипта" >> $2
        cat $1 |awk '{print $7}' |sort |uniq -c |sort -rn| tail -$y >> $2
        echo "" >> $2
        
        echo "Ошибки веб-сервера/приложения c момента последнего запуска" >> $2
        cat $1 |awk '{print $9}' |grep -E "[4-5]{1}[0-9][0-9]" |sort |uniq -c |sort -rn >> $2
        echo "" >> $2
        
        echo "Список всех кодов HTTP ответа с указанием их кол-ва с момента последнего запуска скрипта." >> $2
        cat $1 |awk '{print $9}' |sort |uniq -c |sort -rn >> $2
        echo "" >> $2
}

#Start function
logging $LOGFILE $RESULTFILE

#Sending mail to admin-linux@otus.ru
cat $RESULTFILE | mail -s "My parser nginx logs" webnikolaenko@yandex.ru

#Delete result file logs
rm -f $RESULTFILE

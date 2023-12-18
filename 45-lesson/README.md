# Домашнее задание 26. "Postgres: Backup +  Репликация"

## Домашнее задание.

PostgreSQL:
- настроить hot_standby репликацию с использованием слотов.
- настроить правильное резервное копирование с помощью barman.


## Выполнение.

Результатом выполнения домашнего задания является [Vagrantfile](Vagrantfile) файл, который средствами ansible provisioning подготавливает следующий стенд:

- **node1** сервер с установленным PostgreSQL сервером.
- **node2** сервер с установленным PostgreSQL сервером и настроенной репликацией hot_standby.
- **barman** сервер с установленным и настроенным средством резервного копирования barman. 


### Проверка работы:

Запускаем стенд:

```
vagrant up
```

Итоги создания стенда:
```
PLAY RECAP *********************************************************************
barman                     : ok=20   changed=16   unreachable=0    failed=0    skipped=10   rescued=0    ignored=0   
node1                      : ok=30   changed=24   unreachable=0    failed=0    skipped=20   rescued=0    ignored=0   
node2                      : ok=25   changed=18   unreachable=0    failed=0    skipped=25   rescued=0    ignored=0   
```

Далее проверяем репликацию:

На хосте **node1** в psql создадим базу *otus_test* и выведем список БД: 

```
[vagrant@node1 ~]$ sudo -u postgres psql
could not change directory to "/home/vagrant": Permission denied
psql (14.10)
Type "help" for help.

postgres=# \l
                                  List of databases
   Name    |  Owner   | Encoding |   Collate   |    Ctype    |   Access privileges   
-----------+----------+----------+-------------+-------------+-----------------------
 otus      | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | 
 postgres  | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | 
 template0 | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | =c/postgres          +
           |          |          |             |             | postgres=CTc/postgres
 template1 | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | =c/postgres          +
           |          |          |             |             | postgres=CTc/postgres
(4 rows)

postgres=# CREATE DATABASE otus_test;
CREATE DATABASE
postgres=# 
postgres=# \l
                                  List of databases
   Name    |  Owner   | Encoding |   Collate   |    Ctype    |   Access privileges   
-----------+----------+----------+-------------+-------------+-----------------------
 otus      | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | 
 otus_test | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | 
 postgres  | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | 
 template0 | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | =c/postgres          +
           |          |          |             |             | postgres=CTc/postgres
 template1 | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | =c/postgres          +
           |          |          |             |             | postgres=CTc/postgres
(5 rows)

postgres=# select * from pg_stat_replication;
 pid  | usesysid |   usename   |  application_name  |  client_addr  | client_hostname | client_port |        backend_start         | backend_xmin |   state   | sent_lsn  | write_lsn | flush_lsn | replay_lsn |   write_lag    |    flush_lag    |   replay_lag    | sync_priority | sync_state |          reply_time  
         
------+----------+-------------+--------------------+---------------+-----------------+-------------+------------------------------+--------------+-----------+-----------+-----------+-----------+------------+----------------+-----------------+-----------------+---------------+------------+----------------------
---------
 9778 |    16384 | replication | walreceiver        | 192.168.57.12 |                 |       39124 | 2023-12-15 07:50:13.2477-03  |          739 | streaming | 0/4000BD8 | 0/4000BD8 | 0/4000BD8 | 0/4000BD8  |                |                 |                 |             0 | async      | 2023-12-15 08:11:33.6
79376-03
 9904 |    16385 | barman      | barman_receive_wal | 192.168.57.13 |                 |       50952 | 2023-12-15 07:50:20.42694-03 |              | streaming | 0/4000BD8 | 0/4000BD8 | 0/4000000 |            | 00:00:01.00386 | 00:20:55.043765 | 00:21:05.683839 |             0 | async      | 2023-12-15 08:11:26.1
72143-03
(2 rows)
```

На хосте **node2** проверим список БД, где должна появится БД *otus_test*. 

```
[vagrant@node2 ~]$ sudo -u postgres psql
could not change directory to "/home/vagrant": Permission denied
psql (14.10)
Type "help" for help.

postgres=# \l
                                  List of databases
   Name    |  Owner   | Encoding |   Collate   |    Ctype    |   Access privileges   
-----------+----------+----------+-------------+-------------+-----------------------
 otus      | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | 
 otus_test | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | 
 postgres  | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | 
 template0 | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | =c/postgres          +
           |          |          |             |             | postgres=CTc/postgres
 template1 | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | =c/postgres          +
           |          |          |             |             | postgres=CTc/postgres
(5 rows)

postgres=# select * from pg_stat_wal_receiver;
 pid  |  status   | receive_start_lsn | receive_start_tli | written_lsn | flushed_lsn | received_tli |      last_msg_send_time       |     last_msg_receipt_time     | latest_end_lsn |        latest_end_time        | slot_name |  sender_host  | sender_port |                                                       
                                                                                  conninfo                                                                                                                                         
------+-----------+-------------------+-------------------+-------------+-------------+--------------+-------------------------------+-------------------------------+----------------+-------------------------------+-----------+---------------+-------------+-------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 9105 | streaming | 0/3000000         |                 1 | 0/4000BD8   | 0/4000BD8   |            1 | 2023-12-15 08:10:33.625454-03 | 2023-12-15 08:10:33.626084-03 | 0/4000BD8      | 2023-12-15 08:02:32.799525-03 |           | 192.168.57.11 |        5432 | user=replication password=******** channel_binding=pre
fer dbname=replication host=192.168.57.11 port=5432 fallback_application_name=walreceiver sslmode=prefer sslcompression=0 sslsni=1 ssl_min_protocol_version=TLSv1.2 gssencmode=prefer krbsrvname=postgres target_session_attrs=any
(1 row)
```


Далее проверяем работу резервного копирования на хосте **barman** под пользователем *barman*.

```
[root@barman ~]# su barman

bash-4.4$ barman switch-wal node1
The WAL file 000000010000000000000004 has been closed on server 'node1'

bash-4.4$ barman cron 
Starting WAL archiving for server node1

bash-4.4$ barman check node1
Server node1:
	PostgreSQL: OK
	superuser or standard user with backup privileges: OK
	PostgreSQL streaming: OK
	wal_level: OK
	replication slot: OK
	directories: OK
	retention policy settings: OK
	backup maximum age: FAILED (interval provided: 4 days, latest backup age: No available backups)
	backup minimum size: OK (0 B)
	wal maximum age: OK (no last_wal_maximum_age provided)
	wal size: OK (0 B)
	compression settings: OK
	failed backups: OK (there are 0 failed backups)
	minimum redundancy requirements: FAILED (have 0 backups, expected at least 1)
	pg_basebackup: OK
	pg_basebackup compatible: OK
	pg_basebackup supports tablespaces mapping: OK
	systemid coherence: OK (no system Id stored on disk)
	pg_receivexlog: OK
	pg_receivexlog compatible: OK
	receive-wal running: OK
	archiver errors: OK
```
Видно, что все ОК и можно запускать создание бекапа.
```
bash-4.4$ barman backup node1
Starting backup using postgres method for server node1 in /var/lib/barman/node1/base/20231215T112022
Backup start at LSN: 0/5000060 (000000010000000000000005, 00000060)
Starting backup copy via pg_basebackup for 20231215T112022
Copy done (time: 3 seconds)
Finalising the backup.
This is the first backup for server node1
WAL segments preceding the current backup have been found:
	000000010000000000000004 from server node1 has been removed
Backup size: 41.8 MiB
Backup end at LSN: 0/7000000 (000000010000000000000006, 00000000)
Backup completed (start time: 2023-12-15 11:20:22.703844, elapsed time: 5 seconds)
Processing xlog segments from streaming for node1
	000000010000000000000005
	000000010000000000000006
```

Проверка восстановления из бекапов:

На хосте **node1** в psql удаляем базы Otus: 

```
[vagrant@node1 ~]$ sudo -u postgres psql
could not change directory to "/home/vagrant": Permission denied
psql (14.10)
Type "help" for help.

postgres=# \l
                                  List of databases
   Name    |  Owner   | Encoding |   Collate   |    Ctype    |   Access privileges   
-----------+----------+----------+-------------+-------------+-----------------------
 otus      | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | 
 otus_test | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | 
 postgres  | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | 
 template0 | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | =c/postgres          +
           |          |          |             |             | postgres=CTc/postgres
 template1 | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | =c/postgres          +
           |          |          |             |             | postgres=CTc/postgres
(5 rows)


postgres=# DROP DATABASE otus;
DROP DATABASE
postgres=# DROP DATABASE otus_test;
DROP DATABASE
postgres=# \l
                                  List of databases
   Name    |  Owner   | Encoding |   Collate   |    Ctype    |   Access privileges   
-----------+----------+----------+-------------+-------------+-----------------------
 postgres  | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | 
 template0 | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | =c/postgres          +
           |          |          |             |             | postgres=CTc/postgres
 template1 | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | =c/postgres          +
           |          |          |             |             | postgres=CTc/postgres
(3 rows)
```

Далее на хосте **barman** запустим восстановление от пользователя *barman*: 

```
[root@barman ~]# su barman

bash-4.4$ barman list-backup node1
node1 20231215T112022 - Fri Dec 15 08:10:32 2023 - Size: 33.6 MiB - WAL Size: 0 B


bash-4.4$ barman recover node1 20231215T112022 /var/lib/pgsql/14/data/ --remote-ssh-comman "ssh postgres@192.168.57.11"
Starting remote restore for server node1 using backup 20231215T112022
Destination directory: /var/lib/pgsql/14/data/
Remote command: ssh postgres@192.168.57.11
Copying the base backup.
Copying required WAL segments.
Generating archive status files
Identify dangerous settings in destination directory.

Recovery completed (start time: 2023-12-15 13:09:32.796208+00:00, elapsed time: 6 seconds)
Your PostgreSQL server has been successfully prepared for recovery!
```

Далее на хосте **node1** перезапускаем postgresql-сервер и снова проверить список БД. 

```
[vagrant@node1 ~]$ sudo -u postgres psql
could not change directory to "/home/vagrant": Permission denied
psql (14.10)
Type "help" for help.

postgres=# \l
                                  List of databases
   Name    |  Owner   | Encoding |   Collate   |    Ctype    |   Access privileges   
-----------+----------+----------+-------------+-------------+-----------------------
 otus      | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | 
 otus_test | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | 
 postgres  | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | 
 template0 | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | =c/postgres          +
           |          |          |             |             | postgres=CTc/postgres
 template1 | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | =c/postgres          +
           |          |          |             |             | postgres=CTc/postgres
(5 rows)

```

Базы otus вернулись обратно.


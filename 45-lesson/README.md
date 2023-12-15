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





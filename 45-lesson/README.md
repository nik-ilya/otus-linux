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

```





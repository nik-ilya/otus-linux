# Домашнее задание 25. "MySQL"

## Домашнее задание.

В материалах приложены ссылки на вагрант для репликации и дамп базы bet.dmp.
Базу развернуть на мастере и настроить так, чтобы реплицировались таблицы:
- bookmaker
- competition
- market
- odds     
- outcome 

Настроить GTID репликацию
Варианты которые принимаются к сдаче
- рабочий вагрантафайл
- скрины или логи SHOW TABLES
- конфиги
- пример в логе изменения строки и появления строки на реплике

## Выполнение.

Результатом выполнения домашнего задания является [Vagrantfile](Vagrantfile) файл, который средствами ansible provisioning подготавливает следующий стенд:
- Мастер сервер  **master** (ip 192.168.11.150) с БД MySQL и настроенным механизмом репликации.
- Подчиненный сервер **slave** (ip 192.168.11.151) с БД MySQL и настроенным механизмом репликации.


### Проверка работы:

После завершения выполнения  [Vagrantfile](Vagrantfile) файла подключаемся к серверу slave для проверки состояния реплики:

```

mysql> SHOW SLAVE STATUS\G
*************************** 1. row ***************************
               Slave_IO_State: Waiting for master to send event
                  Master_Host: 192.168.11.150
                  Master_User: repl
                  Master_Port: 3306
                Connect_Retry: 60
              Master_Log_File: mysql-bin.000001
          Read_Master_Log_Pos: 154
               Relay_Log_File: slave-relay-bin.000002
                Relay_Log_Pos: 367
        Relay_Master_Log_File: mysql-bin.000001
             Slave_IO_Running: Yes
            Slave_SQL_Running: Yes
              Replicate_Do_DB: 
          Replicate_Ignore_DB: 
           Replicate_Do_Table: 
       Replicate_Ignore_Table: bet.events_on_demand,bet.v_same_event
      Replicate_Wild_Do_Table: 
  Replicate_Wild_Ignore_Table: 
                   Last_Errno: 0
                   Last_Error: 
                 Skip_Counter: 0
          Exec_Master_Log_Pos: 154
              Relay_Log_Space: 574
              Until_Condition: None
               Until_Log_File: 
                Until_Log_Pos: 0
           Master_SSL_Allowed: No
           Master_SSL_CA_File: 
           Master_SSL_CA_Path: 
              Master_SSL_Cert: 
            Master_SSL_Cipher: 
               Master_SSL_Key: 
        Seconds_Behind_Master: 0
Master_SSL_Verify_Server_Cert: No
                Last_IO_Errno: 0
                Last_IO_Error: 
               Last_SQL_Errno: 0
               Last_SQL_Error: 
  Replicate_Ignore_Server_Ids: 
             Master_Server_Id: 1
                  Master_UUID: 3171d3fb-6b48-11ee-995d-5254004d77d3
             Master_Info_File: /var/lib/mysql/master.info
                    SQL_Delay: 0
          SQL_Remaining_Delay: NULL
      Slave_SQL_Running_State: Slave has read all relay log; waiting for more updates
           Master_Retry_Count: 86400
                  Master_Bind: 
      Last_IO_Error_Timestamp: 
     Last_SQL_Error_Timestamp: 
               Master_SSL_Crl: 
           Master_SSL_Crlpath: 
           Retrieved_Gtid_Set: 
            Executed_Gtid_Set: 
                Auto_Position: 1
         Replicate_Rewrite_DB: 
                 Channel_Name: 
           Master_TLS_Version: 
1 row in set (0.00 sec)
```

Подключимся к серверу **master** и добавим новую запись в таблицу *bookmaker*:
```
mysql> USE bet;
Reading table information for completion of table and column names
You can turn off this feature to get a quicker startup with -A

Database changed

mysql> INSERT INTO bookmaker (id,bookmaker_name) VALUES(1,'1xbet');
Query OK, 1 row affected (0.02 sec)

mysql> SELECT * FROM bookmaker;
+----+----------------+
| id | bookmaker_name |
+----+----------------+
|  1 | 1xbet          |
|  4 | betway         |
|  5 | bwin           |
|  6 | ladbrokes      |
|  3 | unibet         |
+----+----------------+
5 rows in set (0.00 sec)
```

Подключимся к серверу **slave** и убедимся в появлении записи *1xbet* в таблице *bookmaker*:

```
mysql> use bet;
Reading table information for completion of table and column names
You can turn off this feature to get a quicker startup with -A

Database changed
 
mysql> SELECT * FROM bookmaker;
+----+----------------+
| id | bookmaker_name |
+----+----------------+
|  1 | 1xbet          |
|  4 | betway         |
|  5 | bwin           |
|  6 | ladbrokes      |
|  3 | unibet         |
+----+----------------+
5 rows in set (0.00 sec)
```
Запись добавилась.

Проверяем процедуру репликации в bin-логах на сервере **slave**:

```
[root@slave ~]# sudo mysqlbinlog /var/lib/mysql/slave-relay-bin.000002

....

BEGIN
/*!*/;
# at 505
#231015 10:56:50 server id 1  end_log_pos 419 CRC32 0x3d5294b8 	Query	thread_id=3	exec_time=0	error_code=0
use `bet`/*!*/;
SET TIMESTAMP=1697367410/*!*/;
INSERT INTO bookmaker (id,bookmaker_name) VALUES(1,'1xbet')
/*!*/;
# at 632
#231015 10:56:50 server id 1  end_log_pos 450 CRC32 0xdac10c60 	Xid = 24
COMMIT/*!*/;
# at 663
#231015 10:58:14 server id 1  end_log_pos 515 CRC32 0x9b3b8270 	GTID	last_committed=1	sequence_number=2	rbr_only=no
SET @@SESSION.GTID_NEXT= '3171d3fb-6b48-11ee-995d-5254004d77d3:2'/*!*/;
# at 728
#231015 10:58:14 server id 1  end_log_pos 588 CRC32 0x12f19b43 	Query	thread_id=3	exec_time=0	error_code=0
SET TIMESTAMP=1697367494/*!*/;
BEGIN
/*!*/;
# at 801
#231015 10:58:14 server id 1  end_log_pos 715 CRC32 0x4cc9e622 	Query	thread_id=3	exec_time=0	error_code=0
SET TIMESTAMP=1697367494/*!*/;
INSERT INTO bookmaker (id,bookmaker_name) VALUES(2,'2xbet')
/*!*/;
# at 928
#231015 10:58:14 server id 1  end_log_pos 746 CRC32 0xc6f9c7ec 	Xid = 26
COMMIT/*!*/;
SET @@SESSION.GTID_NEXT= 'AUTOMATIC' /* added by mysqlbinlog */ /*!*/;
DELIMITER ;
# End of log file
/*!50003 SET COMPLETION_TYPE=@OLD_COMPLETION_TYPE*/;
/*!50530 SET @@SESSION.PSEUDO_SLAVE_MODE=0*/;
```


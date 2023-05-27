# Домашнее задание 17. "Резервное копирование"

## Домашнее задание.

1. Настроить стенд Vagrant с двумя виртуальными машинами: backup_server и client.
2. Настроить удаленный бекап каталога /etc c сервера client при помощи borgbackup. Резервные копии должны соответствовать следующим критериям:
- директория для резервных копий /var/backup. Это должна быть отдельная точка монтирования. В данном случае для демонстрации размер не принципиален, достаточно будет и 2GB;
- репозиторий дле резервных копий должен быть зашифрован ключом или паролем - на ваше усмотрение;
- имя бекапа должно содержать информацию о времени снятия бекапа;
- глубина бекапа должна быть год, хранить можно по последней копии на конец месяца, кроме последних трех. Последние три месяца должны содержать копии на каждый день. Т.е. должна быть правильно настроена политика удаления старых бэкапов;
- резервная копия снимается каждые 5 минут. Такой частый запуск в целях демонстрации;
- написан скрипт для снятия резервных копий. Скрипт запускается из соответствующей Cron джобы, либо systemd timer-а - на ваше усмотрение;
- настроено логирование процесса бекапа. Для упрощения можно весь вывод перенаправлять в logger с соответствующим тегом. Если настроите не в syslog, то обязательна ротация логов.
3. Запустите стенд на 30 минут.
4. Убедитесь что резервные копии снимаются.
5. Остановите бекап, удалите (или переместите) директорию /etc и восстановите ее из бекапа.
Для сдачи домашнего задания ожидаем настроенные стенд, логи процесса бэкапа и описание процесса восстановления. Формат сдачи ДЗ - vagrant + ansible.


## Выполнение.

1. Создаем инфраструктуру с двумя виртуальными машинами backup и client [Vagrantfile](Vagrantfile).
2. После создания машин запускается [provision файл](./provision.yml).

Ход настройки:

- На виртуальной машине backup:
  - Устанавливается репозиторий epel-release;
  - Устанавливается borgbackup;
  - Форматируется фаловая система ext4 на sdb;
  - Создается точка монтирования /var/backup;
  - Sdb монтируется в /var/backup;
  - Создается юзер borg;
  - Копируется публичный ключ ssh.

- На виртуальный машине client:
  - Устанавливается репозиторий epel-release;
  - Устанавливается borgbackup;
  - Копируется пара ключей ssh;
  - Копируются файлы конфигурации borg-backup.service и borg-backup.timer; 
  - Инициируется репозиторий с бэкапами;
  - Запускается borg-backup.service и borg-backup.timer;
  - Настраивается логирование и ротация логов.

## Проверка.

Проверяем репозиторий бэкапов на создание новых бэкапов:

```
[root@client ~]# borg list borg@192.168.11.160:/var/backup/
Enter passphrase for key ssh://borg@192.168.11.160/var/backup: 
etc-2023-05-26_23:54:01              Fri, 2023-05-26 23:54:02 [6d309682b4f7048aaa594610bec6277edb065c4d051225e1de7ef318638c19b9]
etc-2023-05-27_08:41:01              Sat, 2023-05-27 08:41:02 [bbd4b587481b329a2152d459a3540d0430cc6897c7e5035c12c55f808a10478b]
etc-2023-05-27_08:47:01              Sat, 2023-05-27 08:47:02 [4f339ab5a84d905fe2cf3049c0a9ba63532a5ed3862046e44cce76cc4e42f98b]
etc-2023-05-27_08:53:01              Sat, 2023-05-27 08:53:02 [2454515bd2e3682ca6ca9616c7e6e1d560aa1b6916c3047a768054c5fb5a8eba]
etc-2023-05-27_08:59:01              Sat, 2023-05-27 08:59:02 [fd98c23fef6595a691cead8731d4f58fad2a0312267dbe0607c5e38a18feff1a]
etc-2023-05-27_09:05:01              Sat, 2023-05-27 09:05:02 [3a11ef3329e4c686a8768bf1933a9b395912a728a9c50d43644776814a1dfb8e]
etc-2023-05-27_09:11:01              Sat, 2023-05-27 09:11:02 [e689c775c658e59522a9033a7ca87b61a016a1bc2db80ce6f86c222026a79cd1]
etc-2023-05-27_09:17:01              Sat, 2023-05-27 09:17:02 [039c21e745b833a698ab45c5d59f28265daa58e36430d119fe6e35d8ac42447b]
etc-2023-05-27_09:23:01              Sat, 2023-05-27 09:23:02 [c4427155e7c674e17b1c6b82aa253fb42526b9c0c42382f5239a2b332f86b417]
etc-2023-05-27_09:29:01              Sat, 2023-05-27 09:29:02 [8305b0f6cdbcfbb131956701410bc9d5166e9aff843ebc8b99df291b256c49ca]
etc-2023-05-27_09:35:01              Sat, 2023-05-27 09:35:02 [92f3e2838df12932b6541bf28539e6c0fdd08ab56560de5f4eedb51bd7c15e78]
etc-2023-05-27_09:41:01              Sat, 2023-05-27 09:41:02 [fd89d0582ce2365f19b265d5d5868397da31283f82aba86523e5720a63cf5741]
etc-2023-05-27_09:47:01              Sat, 2023-05-27 09:47:02 [3c299936ccfd7ba842fa72e59a38685b98ff827485bba74b44e2eaaffad54ef6]
```

Таймер systemd успешно запускает service каждые 5 минут.

```
[root@client ~]# systemctl list-timers -all
NEXT                         LEFT         LAST                         PASSED       UNIT                         ACTIVATES
Sat 2023-05-27 17:40:43 UTC  2min 6s left Sat 2023-05-27 17:35:43 UTC  2min 53s ago borg-backup.timer            borg-backup.service
Sun 2023-05-28 17:28:43 UTC  23h left     Sat 2023-05-27 17:28:43 UTC  9min ago     systemd-tmpfiles-clean.timer systemd-tmpfiles-clean.service
n/a                          n/a          n/a                          n/a          systemd-readahead-done.timer systemd-readahead-done.service

3 timers listed.
```

Информация о бэкапах пишется в файл /var/log/borg-backup.log

```
[root@client ~]# cat /var/log/borg-backup.log
May 27 17:13:32 client borg-backup: Remote: ssh: connect to host 192.168.11.160 port 22: Network is unreachable
May 27 17:13:32 client borg-backup: Connection closed by remote host. Is borg working on the server?
May 27 17:18:45 client borg-backup: ------------------------------------------------------------------------------
May 27 17:18:45 client borg-backup: Archive name: etc-2023-05-27_17:18:43
May 27 17:18:45 client borg-backup: Archive fingerprint: 6cccbef5c82e1446cbb80f504aec1f6b5d3872ddcd1a7ae1207be88d9dcee986
May 27 17:18:45 client borg-backup: Time (start): Sat, 2023-05-27 17:18:44
May 27 17:18:45 client borg-backup: Time (end):   Sat, 2023-05-27 17:18:45
May 27 17:18:45 client borg-backup: Duration: 0.50 seconds
May 27 17:18:45 client borg-backup: Number of files: 1702
May 27 17:18:45 client borg-backup: Utilization of max. archive size: 0%
May 27 17:18:45 client borg-backup: ------------------------------------------------------------------------------
May 27 17:18:45 client borg-backup: Original size      Compressed size    Deduplicated size
May 27 17:18:45 client borg-backup: This archive:               28.43 MB             13.49 MB             77.54 kB
May 27 17:18:45 client borg-backup: All archives:                2.62 GB              1.24 GB             12.35 MB
May 27 17:18:45 client borg-backup: Unique chunks         Total chunks
May 27 17:18:45 client borg-backup: Chunk index:                    1394               156187
May 27 17:18:45 client borg-backup: ------------------------------------------------------------------------------
May 27 17:24:35 client borg-backup: ------------------------------------------------------------------------------
May 27 17:24:35 client borg-backup: Archive name: etc-2023-05-27_17:24:33
May 27 17:24:35 client borg-backup: Archive fingerprint: f90d522f71acd06076f482c1261e9d5628ce23e189429711827c03341bec2148
May 27 17:24:35 client borg-backup: Time (start): Sat, 2023-05-27 17:24:34
May 27 17:24:35 client borg-backup: Time (end):   Sat, 2023-05-27 17:24:34
May 27 17:24:35 client borg-backup: Duration: 0.30 seconds
May 27 17:24:35 client borg-backup: Number of files: 1702
May 27 17:24:35 client borg-backup: Utilization of max. archive size: 0%
May 27 17:24:35 client borg-backup: ------------------------------------------------------------------------------
May 27 17:24:35 client borg-backup: Original size      Compressed size    Deduplicated size
May 27 17:24:35 client borg-backup: This archive:               28.43 MB             13.49 MB             32.59 kB
May 27 17:24:35 client borg-backup: All archives:                2.62 GB              1.24 GB             12.38 MB
May 27 17:24:35 client borg-backup: Unique chunks         Total chunks
May 27 17:24:35 client borg-backup: Chunk index:                    1395               156184
May 27 17:24:35 client borg-backup: ------------------------------------------------------------------------------
May 27 17:29:45 client borg-backup: ------------------------------------------------------------------------------
```

Тестируем извлечение:

```
borg extract borg@192.168.11.160:/var/backup/::etc-2023-05-27_09:47:01  etc 

```



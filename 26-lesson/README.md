# Домашнее задание 16. "Сбор логов"

## Домашнее задание.

Настраиваем центральный сервер для сбора логов в vagrant:
- поднимаем 2 машины web и log,
- на web поднимаем nginx,
- на log настраиваем центральный лог-сервер на любой системе на выбор:

   - journald,
   - rsyslog,
   - elk настраиваем аудит следящий за изменением конфигов nginx.

- все критичные логи с web должны собираться и локально и удаленно, 
- все логи с nginx должны уходить на удаленный сервер (локально только критичные), 
- логи аудита уходят ТОЛЬКО на удаленную систему.

## Выполнение.

1. Создаем инфраструктуру запуская [Vagrantfile](Vagrantfile).
2. Используя Absible запускается [provision для web](./ansible/provision-web.yml) и [provision для log](./ansible/provision-log.yml) серверов.
3. Проверяем результаты работы:


```
[root@log ~]# curl 192.168.10.10
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
.....

#Выводим логи nginx
[root@log ~]# cat /var/log/rsyslog/web/nginx_access.log 
Apr 18 05:01:14 web nginx_access: 192.168.10.1 - - [18/Apr/2023:05:01:14 +0000] "GET / HTTP/1.1" 200 4833 "-" "curl/7.68.0"
Apr 18 05:01:24 web nginx_access: 192.168.10.1 - - [18/Apr/2023:05:01:24 +0000] "GET /blablabla HTTP/1.1" 404 3650 "-" "curl/7.68.0"
Apr 18 05:22:17 web nginx_access: 192.168.10.20 - - [18/Apr/2023:05:22:17 +0000] "GET / HTTP/1.1" 200 4833 "-" "curl/7.29.0"



[root@log ~]# curl 192.168.10.10/lalalala
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">


#Выводим логи ошибок nginx
[root@log ~]# cat /var/log/rsyslog/web/nginx_error.log
Apr 18 05:01:24 web nginx_error: 2023/04/18 05:01:24 [error] 1061#1061: *2 open() "/usr/share/nginx/html/blablabla" failed (2: No such file or directory), client: 192.168.10.1, server: _, request: "GET /blablabla HTTP/1.1", host: "192.168.10.10"
Apr 18 05:23:34 web nginx_error: 2023/04/18 05:23:34 [error] 1061#1061: *4 open() "/usr/share/nginx/html/lalalala" failed (2: No such file or directory), client: 192.168.10.20, server: _, request: "GET /lalalala HTTP/1.1", host: "192.168.10.10"


# Проверяем собираются ли логи аудита для хоста web по изменению файла nginx.conf
[root@log ~]# cat /var/log/audit/audit.log | grep nginx
node=web type=CONFIG_CHANGE msg=audit(1681793738.528:153): auid=4294967295 ses=4294967295 subj=system_u:system_r:unconfined_service_t:s0 op=remove_rule key="nginx_conf" list=4 res=1
node=web type=CONFIG_CHANGE msg=audit(1681793738.528:154): auid=4294967295 ses=4294967295 subj=system_u:system_r:unconfined_service_t:s0 op=remove_rule key="nginx_conf" list=4 res=1
node=web type=CONFIG_CHANGE msg=audit(1681793738.528:157): auid=4294967295 ses=4294967295 subj=system_u:system_r:unconfined_service_t:s0 op=add_rule key="nginx_conf" list=4 res=1
node=web type=CONFIG_CHANGE msg=audit(1681793738.528:158): auid=4294967295 ses=4294967295 subj=system_u:system_r:unconfined_service_t:s0 op=add_rule key="nginx_conf" list=4 res=1
node=web type=SYSCALL msg=audit(1681794000.702:312): arch=c000003e syscall=92 success=yes exit=0 a0=1597830 a1=0 a2=0 a3=7ffcb173c2a0 items=1 ppid=1318 pid=1428 auid=1000 uid=0 gid=0 euid=0 suid=0 fsuid=0 egid=0 sgid=0 fsgid=0 tty=pts0 ses=3 comm="mc" exe="/usr/bin/mc" subj=unconfined_u:unconfined_r:unconfined_t:s0-s0:c0.c1023 key="nginx_conf"
node=web type=CWD msg=audit(1681794000.702:312):  cwd="/etc/nginx"
node=web type=PATH msg=audit(1681794000.702:312): item=0 name="/etc/nginx/nginx.conf" inode=100670289 dev=08:01 mode=0100644 ouid=0 ogid=0 rdev=00:00 obj=system_u:object_r:httpd_config_t:s0 objtype=NORMAL cap_fp=0000000000000000 cap_fi=0000000000000000 cap_fe=0 cap_fver=0
node=web type=SYSCALL msg=audit(1681794000.702:313): arch=c000003e syscall=90 success=yes exit=0 a0=1597830 a1=81a4 a2=0 a3=7ffcb173c2a0 items=1 ppid=1318 pid=1428 auid=1000 uid=0 gid=0 euid=0 suid=0 fsuid=0 egid=0 sgid=0 fsgid=0 tty=pts0 ses=3 comm="mc" exe="/usr/bin/mc" subj=unconfined_u:unconfined_r:unconfined_t:s0-s0:c0.c1023 key="nginx_conf"
node=web type=CWD msg=audit(1681794000.702:313):  cwd="/etc/nginx"
node=web type=PATH msg=audit(1681794000.702:313): item=0 name="/etc/nginx/nginx.conf" inode=100670289 dev=08:01 mode=0100644 ouid=0 ogid=0 rdev=00:00 obj=system_u:object_r:httpd_config_t:s0 objtype=NORMAL cap_fp=0000000000000000 cap_fi=0000000000000000 cap_fe=0 cap_fver=0
node=web type=SYSCALL msg=audit(1681794000.702:314): arch=c000003e syscall=2 success=yes exit=8 a0=1597830 a1=241 a2=81a4 a3=7ffcb173c2a0 items=2 ppid=1318 pid=1428 auid=1000 uid=0 gid=0 euid=0 suid=0 fsuid=0 egid=0 sgid=0 fsgid=0 tty=pts0 ses=3 comm="mc" exe="/usr/bin/mc" subj=unconfined_u:unconfined_r:unconfined_t:s0-s0:c0.c1023 key="nginx_conf"
node=web type=CWD msg=audit(1681794000.702:314):  cwd="/etc/nginx"
node=web type=PATH msg=audit(1681794000.702:314): item=0 name="/etc/nginx/" inode=67521887 dev=08:01 mode=040755 ouid=0 ogid=0 rdev=00:00 obj=system_u:object_r:httpd_config_t:s0 objtype=PARENT cap_fp=0000000000000000 cap_fi=0000000000000000 cap_fe=0 cap_fver=0
node=web type=PATH msg=audit(1681794000.702:314): item=1 name="/etc/nginx/nginx.conf" inode=100670289 dev=08:01 mode=0100644 ouid=0 ogid=0 rdev=00:00 obj=system_u:object_r:httpd_config_t:s0 objtype=NORMAL cap_fp=0000000000000000 cap_fi=0000000000000000 cap_fe=0 cap_fver=0


```

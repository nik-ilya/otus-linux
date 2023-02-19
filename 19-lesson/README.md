# Домашнее задание 13. "SELinux"

## Домашнее задание.

1. Запустить nginx на нестандартном порту 3-мя разными способами:
 - переключатели setsebool;
 - добавление нестандартного порта в имеющийся тип;
 - формирование и установка модуля SELinux.
 
2. Обеспечить работоспособность приложения при включенном selinux.

 - развернуть приложенный стенд;
 - выяснить причину неработоспособности механизма обновления зоны;
 - предложить решение (или решения) для данной проблемы;
 - выбрать одно из решений для реализации, предварительно обосновав выбор;
 - реализовать выбранное решение и продемонстрировать его работоспособность.


## Выполнение.

#### Задание 1.

Создаем стенд, поднимаем инфраструктуру и Nginx с помощью [Vagrantfile](/task1/Vagrantfile).
Проверяем статус Nginx.
````
[root@selinux ~]#  systemctl status nginx
● nginx.service - The nginx HTTP and reverse proxy server
   Loaded: loaded (/usr/lib/systemd/system/nginx.service; disabled; vendor preset: disabled)
   Active: failed (Result: exit-code) since Mon 2023-02-13 03:57:58 UTC; 1min 11s ago
  Process: 2925 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=1/FAILURE)
  Process: 2924 ExecStartPre=/usr/bin/rm -f /run/nginx.pid (code=exited, status=0/SUCCESS)

Feb 13 03:57:58 selinux systemd[1]: Starting The nginx HTTP and reverse proxy server...
Feb 13 03:57:58 selinux nginx[2925]: nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
Feb 13 03:57:58 selinux nginx[2925]: nginx: [emerg] bind() to 0.0.0.0:4881 failed (13: Permission denied)
Feb 13 03:57:58 selinux nginx[2925]: nginx: configuration file /etc/nginx/nginx.conf test failed
Feb 13 03:57:58 selinux systemd[1]: nginx.service: control process exited, code=exited status=1
Feb 13 03:57:58 selinux systemd[1]: Failed to start The nginx HTTP and reverse proxy server.
Feb 13 03:57:58 selinux systemd[1]: Unit nginx.service entered failed state.
Feb 13 03:57:58 selinux systemd[1]: nginx.service failed.

[root@selinux ~]# ss -tlpn | grep 4881

[root@selinux ~]# cat /var/log/nginx/error.log 
2023/02/13 03:57:58 [emerg] 2925#2925: bind() to 0.0.0.0:4881 failed (13: Permission denied)
````

Проверяем логи аудита.

````
[root@selinux ~]# cat /var/log/audit/audit.log | grep 4881
type=AVC msg=audit(1676260678.478:864): avc:  denied  { name_bind } for  pid=2925 comm="nginx" src=4881 scontext=system_u:system_r:httpd_t:s0 tcontext=system_u:object_r:unreserved_port_t:s0 tclass=tcp_socket permissive=0

````

**1.1 setsebool.**

C помощью утилиты audit2why смотрим информации о запрете:

````
[root@selinux ~]# grep 1676260678.478:864 /var/log/audit/audit.log | audit2why
type=AVC msg=audit(1676260678.478:864): avc:  denied  { name_bind } for  pid=2925 comm="nginx" src=4881 scontext=system_u:system_r:httpd_t:s0 tcontext=system_u:object_r:unreserved_port_t:s0 tclass=tcp_socket permissive=0

	Was caused by:
	The boolean nis_enabled was set incorrectly. 
	Description:
	Allow nis to enabled

	Allow access by executing:
	# setsebool -P nis_enabled 1
````

Разрешим в SELinux работу nginx на порту TCP 4881 c помощью переключателей setsebool.

````
[root@selinux ~]# setsebool -P nis_enabled on

[root@selinux ~]# systemctl restart nginx

[root@selinux ~]# systemctl status nginx
● nginx.service - The nginx HTTP and reverse proxy server
   Loaded: loaded (/usr/lib/systemd/system/nginx.service; disabled; vendor preset: disabled)
   Active: active (running) since Mon 2023-02-13 05:21:54 UTC; 10s ago
  Process: 21817 ExecStart=/usr/sbin/nginx (code=exited, status=0/SUCCESS)
  Process: 21815 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=0/SUCCESS)
  Process: 21814 ExecStartPre=/usr/bin/rm -f /run/nginx.pid (code=exited, status=0/SUCCESS)
 Main PID: 21819 (nginx)
   CGroup: /system.slice/nginx.service
           ├─21819 nginx: master process /usr/sbin/nginx
           └─21821 nginx: worker process

Feb 13 05:21:54 selinux systemd[1]: Starting The nginx HTTP and reverse proxy server...
Feb 13 05:21:54 selinux nginx[21815]: nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
Feb 13 05:21:54 selinux nginx[21815]: nginx: configuration file /etc/nginx/nginx.conf test is successful
Feb 13 05:21:54 selinux systemd[1]: Started The nginx HTTP and reverse proxy server.
````

Проверяем статус параметра:

````
[root@selinux ~]# getsebool -a | grep nis_enabled
nis_enabled --> on
````

Вернем настройки обратно и проверим, что nginx не запускается:

````
[root@selinux ~]# setsebool -P nis_enabled off

[root@selinux ~]# systemctl restart nginx
Job for nginx.service failed because the control process exited with error code. See "systemctl status nginx.service" and "journalctl -xe" for details.
[root@selinux ~]# systemctl status nginx
● nginx.service - The nginx HTTP and reverse proxy server
   Loaded: loaded (/usr/lib/systemd/system/nginx.service; disabled; vendor preset: disabled)
   Active: failed (Result: exit-code) since Mon 2023-02-13 05:24:19 UTC; 5s ago
  Process: 21817 ExecStart=/usr/sbin/nginx (code=exited, status=0/SUCCESS)
  Process: 21840 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=1/FAILURE)
  Process: 21839 ExecStartPre=/usr/bin/rm -f /run/nginx.pid (code=exited, status=0/SUCCESS)
 Main PID: 21819 (code=exited, status=0/SUCCESS)

Feb 13 05:24:19 selinux systemd[1]: Stopped The nginx HTTP and reverse proxy server.
Feb 13 05:24:19 selinux systemd[1]: Starting The nginx HTTP and reverse proxy server...
Feb 13 05:24:19 selinux nginx[21840]: nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
Feb 13 05:24:19 selinux nginx[21840]: nginx: [emerg] bind() to 0.0.0.0:4881 failed (13: Permission denied)
Feb 13 05:24:19 selinux nginx[21840]: nginx: configuration file /etc/nginx/nginx.conf test failed
Feb 13 05:24:19 selinux systemd[1]: nginx.service: control process exited, code=exited status=1
Feb 13 05:24:19 selinux systemd[1]: Failed to start The nginx HTTP and reverse proxy server.
Feb 13 05:24:19 selinux systemd[1]: Unit nginx.service entered failed state.
Feb 13 05:24:19 selinux systemd[1]: nginx.service failed.
````


**1.2 добавление нестандартного порта в имеющийся тип.**

Разрешим в SELinux работу nginx на порту TCP 4881 c помощью добавления нестандартного порта в имеющийся тип. Проверяем пул портов доступных для HTTP:

````
[root@selinux ~]# semanage port -l | grep http
http_cache_port_t              tcp      8080, 8118, 8123, 10001-10010
http_cache_port_t              udp      3130
http_port_t                    tcp      80, 81, 443, 488, 8008, 8009, 8443, 9000
pegasus_http_port_t            tcp      5988
pegasus_https_port_t           tcp      5989
````

Добавялем нужный порт и перегружаем ngunx:

````
[root@selinux ~]# semanage port -a -t http_port_t -p tcp 4881

[root@selinux ~]# semanage port -l | grep  http_port_t
http_port_t                    tcp      4881, 80, 81, 443, 488, 8008, 8009, 8443, 9000
pegasus_http_port_t            tcp      5988

[root@selinux ~]#  systemctl restart nginx

[root@selinux ~]#  systemctl status nginx
● nginx.service - The nginx HTTP and reverse proxy server
   Loaded: loaded (/usr/lib/systemd/system/nginx.service; disabled; vendor preset: disabled)
   Active: active (running) since Mon 2023-02-13 05:26:35 UTC; 14s ago
  Process: 21865 ExecStart=/usr/sbin/nginx (code=exited, status=0/SUCCESS)
  Process: 21862 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=0/SUCCESS)
  Process: 21861 ExecStartPre=/usr/bin/rm -f /run/nginx.pid (code=exited, status=0/SUCCESS)
 Main PID: 21867 (nginx)
   CGroup: /system.slice/nginx.service
           ├─21867 nginx: master process /usr/sbin/nginx
           └─21868 nginx: worker process

Feb 13 05:26:35 selinux systemd[1]: Starting The nginx HTTP and reverse proxy server...
Feb 13 05:26:35 selinux nginx[21862]: nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
Feb 13 05:26:35 selinux nginx[21862]: nginx: configuration file /etc/nginx/nginx.conf test is successful
Feb 13 05:26:35 selinux systemd[1]: Started The nginx HTTP and reverse proxy server.
````

Nginx запустился. Возвращаем проблему.

````
[root@selinux ~]# semanage port -d -t http_port_t -p tcp 4881

[root@selinux ~]# semanage port -l | grep  http_port_t
http_port_t                    tcp      80, 81, 443, 488, 8008, 8009, 8443, 9000
pegasus_http_port_t            tcp      5988

[root@selinux ~]#  systemctl restart nginx
Job for nginx.service failed because the control process exited with error code. See "systemctl status nginx.service" and "journalctl -xe" for details.

[root@selinux ~]#  systemctl status nginx
● nginx.service - The nginx HTTP and reverse proxy server
   Loaded: loaded (/usr/lib/systemd/system/nginx.service; disabled; vendor preset: disabled)
   Active: failed (Result: exit-code) since Mon 2023-02-13 05:27:54 UTC; 3s ago
  Process: 21865 ExecStart=/usr/sbin/nginx (code=exited, status=0/SUCCESS)
  Process: 21888 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=1/FAILURE)
  Process: 21887 ExecStartPre=/usr/bin/rm -f /run/nginx.pid (code=exited, status=0/SUCCESS)
 Main PID: 21867 (code=exited, status=0/SUCCESS)

Feb 13 05:27:54 selinux systemd[1]: Stopped The nginx HTTP and reverse proxy server.
Feb 13 05:27:54 selinux systemd[1]: Starting The nginx HTTP and reverse proxy server...
Feb 13 05:27:54 selinux systemd[1]: nginx.service: control process exited, code=exited status=1
Feb 13 05:27:54 selinux nginx[21888]: nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
Feb 13 05:27:54 selinux nginx[21888]: nginx: [emerg] bind() to 0.0.0.0:4881 failed (13: Permission denied)
Feb 13 05:27:54 selinux nginx[21888]: nginx: configuration file /etc/nginx/nginx.conf test failed
Feb 13 05:27:54 selinux systemd[1]: Failed to start The nginx HTTP and reverse proxy server.
Feb 13 05:27:54 selinux systemd[1]: Unit nginx.service entered failed state.
Feb 13 05:27:54 selinux systemd[1]: nginx.service failed.
````

**1.3 формирование и установка модуля SELinux.**

Nginx не запускается:

````
[root@selinux ~]# systemctl start nginx
Job for nginx.service failed because the control process exited with error code. See "systemctl status nginx.service" and "journalctl -xe" for details.
````
Смотрим логи с помощью утилиты audit2allow:
````
[root@selinux ~]# grep nginx /var/log/audit/audit.log | audit2allow -M nginx
******************** IMPORTANT ***********************
To make this policy package active, execute:

semodule -i nginx.pp
````

Audit2allow сформировал модуль, применяем его:

````
[root@selinux ~]# semodule -i nginx.pp

[root@selinux ~]# systemctl start nginx

[root@selinux ~]#  systemctl status nginx
● nginx.service - The nginx HTTP and reverse proxy server
   Loaded: loaded (/usr/lib/systemd/system/nginx.service; disabled; vendor preset: disabled)
   Active: active (running) since Mon 2023-02-13 05:30:40 UTC; 8s ago
  Process: 21928 ExecStart=/usr/sbin/nginx (code=exited, status=0/SUCCESS)
  Process: 21926 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=0/SUCCESS)
  Process: 21925 ExecStartPre=/usr/bin/rm -f /run/nginx.pid (code=exited, status=0/SUCCESS)
 Main PID: 21930 (nginx)
   CGroup: /system.slice/nginx.service
           ├─21930 nginx: master process /usr/sbin/nginx
           └─21931 nginx: worker process

Feb 13 05:30:40 selinux systemd[1]: Starting The nginx HTTP and reverse proxy server...
Feb 13 05:30:40 selinux nginx[21926]: nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
Feb 13 05:30:40 selinux nginx[21926]: nginx: configuration file /etc/nginx/nginx.conf test is successful
Feb 13 05:30:40 selinux systemd[1]: Started The nginx HTTP and reverse proxy server.
````
После добавления модуля nginx запустился без ошибок. 

Для удаления модуля воспользуемся командой: 

````
[root@selinux ~]# semodule -r nginx
libsemanage.semanage_direct_remove_key: Removing last nginx module (no other nginx module exists at another priority).

[root@selinux ~]# systemctl restart nginx
Job for nginx.service failed because the control process exited with error code. See "systemctl status nginx.service" and "journalctl -xe" for details.
````


#### Задание 2.

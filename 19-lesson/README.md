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

Создаем стенд, поднимаем инфраструктуру и Nginx с помощью [Vagrantfile](Vagrantfile).
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

##### 1.1 setsebool.

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








##### 1.2 добавление нестандартного порта в имеющийся тип.

##### 1.3 формирование и установка модуля SELinux.




#### Задание 2.

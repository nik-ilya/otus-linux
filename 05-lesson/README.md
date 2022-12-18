# Домашнее задание 05. "NFS"

## Домашнее задание.

### 1. Создал файл Vangrantfile с созданием двух серверов nfsserver и nfsclient.

### 2. Настройка сервера NFS.

- Установил утилиту nfs-utils:

```bash
yum install nfs-utils
```

- включил firewall:
```bash
[root@nfsserver ~]# systemctl enable firewalld --now
Created symlink from /etc/systemd/system/dbus-org.fedoraproject.FirewallD1.service to /usr/lib/systemd/system/firewalld.service.
Created symlink from /etc/systemd/system/multi-user.target.wants/firewalld.service to /usr/lib/systemd/system/firewalld.service.

[root@nfsserver ~]# systemctl status firewalld
● firewalld.service - firewalld - dynamic firewall daemon
   Loaded: loaded (/usr/lib/systemd/system/firewalld.service; enabled; vendor preset: enabled)
   Active: active (running) since Sun 2022-12-18 15:01:30 UTC; 10s ago
     Docs: man:firewalld(1)
 Main PID: 3555 (firewalld)
   CGroup: /system.slice/firewalld.service
           └─3555 /usr/bin/python2 -Es /usr/sbin/firewalld --nofork --nopid

Dec 18 15:01:30 nfsserver systemd[1]: Starting firewalld - dynamic firewall daemon...
Dec 18 15:01:30 nfsserver systemd[1]: Started firewalld - dynamic firewall daemon.
Dec 18 15:01:31 nfsserver firewalld[3555]: WARNING: AllowZoneDrifting is enabled. This is considered an insecure configuration option. It will be removed in a ...ng it now.
Hint: Some lines were ellipsized, use -l to show in full.
```

- настраиваю firewall:
 
```bash
[root@nfsserver ~]# firewall-cmd --add-service="nfs3" \
>             --add-service="rpc-bind" \
>              --add-service="mountd" \
>              --permanent
success
[root@nfsserver ~]# firewall-cmd --reload
success
[root@nfsserver ~]# 
```

- включаю NFS:

```bash
[root@nfsserver ~]# systemctl enable nfs --now
Created symlink from /etc/systemd/system/multi-user.target.wants/nfs-server.service to /usr/lib/systemd/system/nfs-server.service.
```

- создал папку и задал на нее права:
```bash
[root@nfsserver ~]# mkdir -p /srv/share/upload
[root@nfsserver ~]# chown -R nfsnobody:nfsnobody /srv/share
[root@nfsserver ~]# chmod 0777 /srv/share/upload
```
- создал файл exports:
```bash
[root@nfsserver ~]# echo '/srv/share 192.168.50.11/32(rw,sync,root_squash)' > /etc/exports
[root@nfsserver ~]# cat /etc/exports
/srv/share 192.168.50.11/32(rw,sync,root_squash)
```
- все настроено:
```bash
[root@nfsserver ~]# exportfs -r

[root@nfsserver ~]# exportfs -s
/srv/share  192.168.50.11/32(sync,wdelay,hide,no_subtree_check,sec=sys,rw,secure,root_squash,no_all_squash)
```
### 3. Настройка клиента NFS.

- аналогично с сервером установил nfs-utils, включил firewall.

- далее правим fstab для автоматического монтирования папки:

```bash
[root@nfsclient ~]# echo "192.168.50.10:/srv/share/ /mnt nfs vers=3,proto=udp,noauto,x-systemd.automount 0 0" >> /etc/fstab

[root@nfsclient ~]# systemctl daemon-reload

[root@nfsclient ~]# systemctl restart remote-fs.target
```

- проверяю монтирование папки:

```bash
[root@nfsclient mnt]# cd /mnt/
[root@nfsclient mnt]# mount | grep mnt
systemd-1 on /mnt type autofs (rw,relatime,fd=46,pgrp=1,timeout=0,minproto=5,maxproto=5,direct,pipe_ino=46761)
192.168.50.10:/srv/share/ on /mnt type nfs (rw,relatime,vers=3,rsize=32768,wsize=32768,namlen=255,hard,proto=udp,timeo=11,retrans=3,sec=sys,mountaddr=192.168.50.10,mountvers=3,mountport=20048,mountproto=udp,local_lock=none,addr=192.168.50.10)
```
### 4. Проверка работоспособности NFS.

- проверяю права на создание файлов:

```bash
[root@nfsserver ~]# cd /srv/share/upload

[root@nfsserver upload]# ls

[root@nfsserver upload]# touch check_file

[root@nfsclient upload]# touch client_file

[root@nfsclient upload]# ls
check_file  client_file

[root@nfsclient upload]# ll
total 0
-rw-r--r--. 1 root      root      0 Dec 18 15:29 check_file
-rw-r--r--. 1 nfsnobody nfsnobody 0 Dec 18 15:43 client_file

[root@nfsserver upload]# ll
total 0
-rw-r--r--. 1 root      root      0 Dec 18 15:29 check_file
-rw-r--r--. 1 nfsnobody nfsnobody 0 Dec 18 15:43 client_file
```

- перезагрузил сервер клиента - папка примонтировалась, выполняю проверки:

```bash
[vagrant@nfsclient ~]$ w
 15:47:28 up 0 min,  1 user,  load average: 1.04, 0.39, 0.14
USER     TTY      FROM             LOGIN@   IDLE   JCPU   PCPU WHAT
vagrant  pts/0    10.0.2.2         15:47    0.00s  0.06s  0.02s w
[vagrant@nfsclient ~]$ sudo -i
[root@nfsclient ~]# cd /mnt
[root@nfsclient mnt]# ll
total 0
drwxrwxrwx. 2 nfsnobody nfsnobody 43 Dec 18 15:43 upload

[root@nfsclient mnt]# cd /mnt/upload/
[root@nfsclient upload]# ll
total 0
-rw-r--r--. 1 root      root      0 Dec 18 15:29 check_file
-rw-r--r--. 1 nfsnobody nfsnobody 0 Dec 18 15:43 client_file

[root@nfsclient upload]# showmount -a 192.168.50.10
All mount points on 192.168.50.10:
192.168.50.11:/srv/share

[root@nfsclient upload]# touch final_check

[root@nfsclient upload]# ll
total 0
-rw-r--r--. 1 root      root      0 Dec 18 15:29 check_file
-rw-r--r--. 1 nfsnobody nfsnobody 0 Dec 18 15:43 client_file
-rw-r--r--. 1 nfsnobody nfsnobody 0 Dec 18 15:54 final_check
```

- перезагрузил сервер и произвел проверку:
```bash
[vagrant@nfsserver ~]$ w
 15:51:46 up 0 min,  1 user,  load average: 1.33, 0.47, 0.16
USER     TTY      FROM             LOGIN@   IDLE   JCPU   PCPU WHAT
vagrant  pts/0    10.0.2.2         15:51    2.00s  0.06s  0.02s w

[vagrant@nfsserver ~]$ ll /srv/share/upload/
total 0
-rw-r--r--. 1 root      root      0 Dec 18 15:29 check_file
-rw-r--r--. 1 nfsnobody nfsnobody 0 Dec 18 15:43 client_file

[vagrant@nfsserver ~]$ systemctl status nfs
● nfs-server.service - NFS server and services
   Loaded: loaded (/usr/lib/systemd/system/nfs-server.service; enabled; vendor preset: disabled)
  Drop-In: /run/systemd/generator/nfs-server.service.d
           └─order-with-mounts.conf
   Active: active (exited) since Sun 2022-12-18 15:51:09 UTC; 1min 21s ago
  Process: 812 ExecStartPost=/bin/sh -c if systemctl -q is-active gssproxy; then systemctl reload gssproxy ; fi (code=exited, status=0/SUCCESS)
  Process: 783 ExecStart=/usr/sbin/rpc.nfsd $RPCNFSDARGS (code=exited, status=0/SUCCESS)
  Process: 781 ExecStartPre=/usr/sbin/exportfs -r (code=exited, status=0/SUCCESS)
 Main PID: 783 (code=exited, status=0/SUCCESS)
   CGroup: /system.slice/nfs-server.service
   
[vagrant@nfsserver ~]$ systemctl status firewalld
● firewalld.service - firewalld - dynamic firewall daemon
   Loaded: loaded (/usr/lib/systemd/system/firewalld.service; enabled; vendor preset: enabled)
   Active: active (running) since Sun 2022-12-18 15:51:03 UTC; 1min 41s ago
     Docs: man:firewalld(1)
 Main PID: 404 (firewalld)
   CGroup: /system.slice/firewalld.service
           └─404 /usr/bin/python2 -Es /usr/sbin/firewalld --nofork --nopid
	   
[root@nfsserver ~]# exportfs -s
/srv/share  192.168.50.11/32(sync,wdelay,hide,no_subtree_check,sec=sys,rw,secure,root_squash,no_all_squash)

[root@nfsserver ~]# showmount -a 192.168.50.10
All mount points on 192.168.50.10:
192.168.50.11:/srv/share

[root@nfsserver ~]# ll /srv/share/upload/
total 0
-rw-r--r--. 1 root      root      0 Dec 18 15:29 check_file
-rw-r--r--. 1 nfsnobody nfsnobody 0 Dec 18 15:43 client_file
-rw-r--r--. 1 nfsnobody nfsnobody 0 Dec 18 15:54 final_check
```


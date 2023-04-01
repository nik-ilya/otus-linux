# Домашнее задание 14. "PAM"

## Домашнее задание.

Запретить всем пользователям, кроме группы admin логин в выходные (суббота и воскресенье), без учета праздников

## Выполнение.

Создаём пользователей otusadm и otus:
```
[root@pam ~]# sudo useradd otusadm && sudo useradd otus
```

Создаём пользователям пароли:
```
[root@pam ~]# echo "Otus2022!" | sudo passwd --stdin otusadm && echo "Otus2022!" | sudo passwd --stdin otus
Changing password for user otusadm.
passwd: all authentication tokens updated successfully.
Changing password for user otus.
passwd: all authentication tokens updated successfully.
```

Создаём группу admin:
```
[root@pam ~]# sudo groupadd -f admin
```

Добавляем пользователей vagrant,root и otusadm в группу admin:
```
[root@pam ~]# sudo usermod otusadm -a -G admin
[root@pam ~]# sudo usermod root -a -G admin
[root@pam ~]# sudo usermod vagrant -a -G admin
```

После создания пользователей проверяем возможность подключения по SSH к нашей ВМ в рабочий день.
```
root@otuslinux-ubu:~# ssh otus@192.168.57.10
The authenticity of host '192.168.57.10 (192.168.57.10)' can't be established.
ECDSA key fingerprint is SHA256:F2XfjLE2I7RgMXO6p0gyFTSsXOuZLqHmJynvePsJJjU.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added '192.168.57.10' (ECDSA) to the list of known hosts.
otus@192.168.57.10's password: 
[otus@pam ~]$ whoami
otus

root@otuslinux-ubu:~# ssh otusadm@192.168.57.10
otusadm@192.168.57.10's password: 
[otusadm@pam ~]$ whoami
otusadm
```

Далее создадим скрипт login.sh, по которому все пользователи кроме тех, что указаны в группе admin не смогут подключаться в выходные дни:

```
#!/bin/bash
#Первое условие: если день недели суббота или воскресенье
if [ $(date +%a) = "Sat" ] || [ $(date +%a) = "Sun" ]; then
 #Второе условие: входит ли пользователь в группу admin
 if getent group admin | grep -qw "$PAM_USER"; then
        #Если пользователь входит в группу admin, то он может подключиться
        exit 0
      else
        #Иначе ошибка (не сможет подключиться)
        exit 1
    fi
  #Если день не выходной, то подключиться может любой пользователь
  else
    exit 0
fi
```

Укажем в файле /etc/pam.d/sshd модуль pam_exec и наш скрипт:

```
[vagrant@pam ~]$ cat  /etc/pam.d/sshd 
#%PAM-1.0
auth       substack     password-auth
auth       include      postlogin
account    required     pam_exec.so /usr/local/bin/login.sh
account    required     pam_nologin.so

```

Проверим доступ в выходной день:
```
root@otuslinux-ubu:~# date
Sat 01 Apr 2023 11:50:14 AM EDT

root@otuslinux-ubu:~# ssh otus@192.168.57.10
otus@192.168.57.10's password: 
/usr/local/bin/login.sh failed: exit code 1
Connection closed by 192.168.57.10 port 22

root@otuslinux-ubu:~# ssh otusadm@192.168.57.10
otusadm@192.168.57.10's password: 
Last login: Fri Mar 31 03:49:05 2023 from 192.168.57.1
[otusadm@pam ~]$ 
```







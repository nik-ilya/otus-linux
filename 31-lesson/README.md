# Домашнее задание 20. "Фильтрация трафика"

## Домашнее задание.

1. Реализовать **knocking port**:
- centralRouter может попасть на ssh inetrRouter через knock скрипт пример в материалах.
2. Добавить inetRouter2, который виден (маршрутизируется) с хоста.
3. Запустить nginx на centralServer.
4. Пробросить 80й порт на inetRouter2 8080.
5. Дефолт в инет оставить через inetRouter.

## Выполнение.

Для выполнения данного ДЗ используем стенд из ДЗ №18 "Архитектура сетей" и добавим к этому стенду сервер inetRouter2.

### Реализация knocking port:

1. на ВМ inetRouter устанавливаются пакеты iptables, iptables-services.
2. на ВМ inetRouter пишется правило для реализации knocking port.
3. на ВМ centralRouter установлен пакет nmap, написан скрипт, стучащийся на порты 6666, 7777, 8888.
4. после простукивания портов на inetRouter можно зайти в течение 30 секунд.

   Проверка работы скрипта:
 
```
[root@centralRouter ~]# 
[root@centralRouter ~]# ssh 192.168.255.1
ssh: connect to host 192.168.255.1 port 22: Connection timed out
[root@centralRouter ~]# 
[root@centralRouter ~]# 
[root@centralRouter ~]# ./knock.sh 192.168.255.1 6666 7777 8888

Starting Nmap 6.40 ( http://nmap.org ) at 2023-07-02 12:09 UTC
Warning: 192.168.255.1 giving up on port because retransmission cap hit (0).
Nmap scan report for 192.168.255.1
Host is up (0.0014s latency).
PORT     STATE    SERVICE
6666/tcp filtered irc
MAC Address: 08:00:27:D1:E8:25 (Cadmus Computer Systems)

Nmap done: 1 IP address (1 host up) scanned in 0.37 seconds

Starting Nmap 6.40 ( http://nmap.org ) at 2023-07-02 12:09 UTC
Warning: 192.168.255.1 giving up on port because retransmission cap hit (0).
Nmap scan report for 192.168.255.1
Host is up (0.0013s latency).
PORT     STATE    SERVICE
7777/tcp filtered cbt
MAC Address: 08:00:27:D1:E8:25 (Cadmus Computer Systems)

Nmap done: 1 IP address (1 host up) scanned in 0.33 seconds

Starting Nmap 6.40 ( http://nmap.org ) at 2023-07-02 12:09 UTC
Warning: 192.168.255.1 giving up on port because retransmission cap hit (0).
Nmap scan report for 192.168.255.1
Host is up (0.0011s latency).
PORT     STATE    SERVICE
8888/tcp filtered sun-answerbook
MAC Address: 08:00:27:D1:E8:25 (Cadmus Computer Systems)

Nmap done: 1 IP address (1 host up) scanned in 0.34 seconds
[root@centralRouter ~]# 
[root@centralRouter ~]# 
[root@centralRouter ~]# 
[root@centralRouter ~]# ssh 192.168.255.1
The authenticity of host '192.168.255.1 (192.168.255.1)' can't be established.
ECDSA key fingerprint is SHA256:2sE1GcNT8ANRsXs/qIucDlp5YrTZoSapKSl4g2dvqqs.
ECDSA key fingerprint is MD5:0c:8e:4d:d7:b5:cc:37:33:46:d2:f2:59:83:a4:11:bf.
Are you sure you want to continue connecting (yes/no)? yes
Warning: Permanently added '192.168.255.1' (ECDSA) to the list of known hosts.
[root@inetRouter ~]# 

```



```
root@otuslinux-new:~/otus-linux/31-lesson# curl 192.168.50.13:8080
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
<head>
  <title>Welcome to CentOS</title>
  <style rel="stylesheet" type="text/css"> 
......
```

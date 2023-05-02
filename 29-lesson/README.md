# Домашнее задание 18. "Архитектура сетей"

## Домашнее задание.

Разворачиваем сетевую лабораторию.

Vagrantfile с начальным построением сети:

- inetRouter
- centralRouter
- centralServer

Теоретическая часть:

- Найти свободные подсети.
- Посчитать сколько узлов в каждой подсети, включая свободные.
- Указать broadcast адрес для каждой подсети.
- Проверить нет ли ошибок при разбиении.

Практическая часть:

Соединить офисы в сеть согласно схеме и настроить роутинг:

- Все сервера и роутеры должны ходить в инет черз inetRouter.
- Все сервера должны видеть друг друга.
- У всех новых серверов отключить дефолт на нат (eth0), который вагрант поднимает для связи.
- При нехватке сетевых интервейсов добавить по несколько адресов на интерфейс.

Построить следующую архитектуру:

Сеть office1:

- 192.168.2.0/26 - dev
- 192.168.2.64/26 - test servers
- 192.168.2.128/26 - managers
- 192.168.2.192/26 - office hardware

Сеть office2:

- 192.168.1.0/25 - dev
- 192.168.1.128/26 - test servers
- 192.168.1.192/26 - office hardware



## Выполнение.

1. Теоритическая часть.

![Схема стенда](net.png)

# **Описание сетей**

## **Router-net**
|network  | router-net       |
|---------|------------------|
|Netmask  | 255.255.255.252  |
|Network  | 192.168.255.0/30 |
|Broadcast| 192.168.255.3    |
|HostMin  | 192.168.255.1    |
|HostMax  | 192.168.255.2    |
|Hosts/Net| 2                |

***Свободные подсети***
 
|network  | free1            | free2           | free3           | free4           | free5          | free6          |
|---------|------------------|-----------------|-----------------|-----------------|----------------|----------------|
|Network  |192.168.255.128/25|192.168.255.64/26|192.168.255.32/27|192.168.255.16/28|192.168.255.8/29|192.168.255.4/30|
|Netmask  |255.255.255.128   |255.255.255.192  |255.255.255.224  |255.255.255.240  |255.255.255.248 |255.255.255.252 |
|Broadcast|192.168.10.255    |192.168.10.127   |192.168.10.63    |192.168.10.31    |192.168.10.15   |192.168.10.7    |
|HostMin  |192.168.10.129    |192.168.10.65    |192.168.10.33    |192.168.10.17    |192.168.10.9    |192.168.10.5    |
|HostMax  |192.168.10.254    |192.168.10.126   |192.168.10.62    |192.168.10.30    |192.168.10.14   |192.168.10.6    |
|Hosts/Net|126               |62               |30               |14               |6               |2               | 

---

## **Central-net**

|network  | dir-net         | hw-net          | mgt-net         |
|---------|-----------------|-----------------|-----------------|
|Network  | 192.168.10.0/28 | 192.168.10.32/28| 192.168.10.64/26|
|Netmask  | 255.255.255.240 | 255.255.255.240 | 255.255.255.192 |
|Broadcast| 192.168.10.15   | 192.168.10.47   | 192.168.10.127  |
|HostMin  | 192.168.10.1    | 192.168.10.33   | 192.168.10.65   |
|HostMax  | 192.168.10.14   | 192.168.10.46   | 192.168.10.126  |
|Hosts/Net| 14              | 14              | 62              |


***Свободные подсети***

|network  | free1            | free2           | free3            |
|---------|------------------|-----------------|------------------|
|Network  | 192.168.10.16/28 | 192.168.10.48/28| 192.168.10.128/25|
|Netmask  | 255.255.255.240  | 255.255.255.240 | 255.255.255.128  | 
|Broadcast| 192.168.10.31    | 192.168.10.63   | 192.168.10.255   |
|HostMin  | 192.168.10.17    | 192.168.10.49   | 192.168.10.129   |
|HostMax  | 192.168.10.30    | 192.168.10.62   | 192.168.10.254   |
|Hosts/Net| 14               | 14              | 126              |

---

## **Office1-net**

|network  | dev-net         | test-net        | mgt-net          | hw-net           |
|---------|-----------------|-----------------|------------------|------------------|
|Network  | 192.168.2.0/26  | 192.168.2.64/26 | 192.168.2.128/26 | 192.168.2.192/26 |
|Netmask  | 255.255.255.192 | 255.255.255.192 | 255.255.255.192  | 255.255.255.192  |
|Broadcast| 192.168.2.63    | 192.168.2.127   | 192.168.2.191    | 192.168.2.255    |
|HostMin  | 192.168.2.1     | 192.168.2.65    | 192.168.2.129    | 192.168.2.193    |
|HostMax  | 192.168.2.62    | 192.168.2.126   | 192.168.2.190    | 192.168.2.254    |
|Hosts/Net| 62              | 62              | 62               | 62

> Свободных подсетей нет.

---

## **Office2-net**

|network  | dev-net         | test-net         | hw-net           |
|---------|-----------------|------------------|------------------|
|Network  | 192.168.1.0/25  | 192.168.1.128/26 | 192.168.1.192/26 |
|Netmask  | 255.255.255.128 | 255.255.255.192  | 255.255.255.192  |
|Broadcast| 192.168.1.127   | 192.168.1.191    | 192.168.1.255    |
|HostMin  | 192.168.1.1     | 192.168.1.129    | 192.168.1.193    |
|HostMax  | 192.168.1.126   | 192.168.1.190    | 192.168.1.254    |
|Hosts/Net| 126             | 62               | 62               |

> Свободных подсетей нет.

---


2. Создаем инфраструктуру [Vagrantfile](Vagrantfile).
3. При помощи механизма Ansible provisioning выполняется конфигурация серверов.
4. Проверяем результаты работы:

- Проверка с office1Server:

```
[vagrant@office1Server ~]$ ping ya.ru
PING ya.ru (77.88.55.242) 56(84) bytes of data.
64 bytes from ya.ru (77.88.55.242): icmp_seq=1 ttl=57 time=54.8 ms
64 bytes from ya.ru (77.88.55.242): icmp_seq=2 ttl=57 time=54.1 ms
^C
--- ya.ru ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1001ms
rtt min/avg/max/mdev = 54.111/54.482/54.854/0.438 ms

[vagrant@office1Server ~]$ ping 192.168.255.2
PING 192.168.255.2 (192.168.255.2) 56(84) bytes of data.
64 bytes from 192.168.255.2: icmp_seq=1 ttl=63 time=2.69 ms
64 bytes from 192.168.255.2: icmp_seq=2 ttl=63 time=2.44 ms
64 bytes from 192.168.255.2: icmp_seq=3 ttl=63 time=2.38 ms
^C
--- 192.168.255.2 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2004ms
rtt min/avg/max/mdev = 2.388/2.510/2.699/0.141 ms

[vagrant@office1Server ~]$ ping 192.168.1.2
PING 192.168.1.2 (192.168.1.2) 56(84) bytes of data.
64 bytes from 192.168.1.2: icmp_seq=1 ttl=61 time=5.04 ms
64 bytes from 192.168.1.2: icmp_seq=2 ttl=61 time=5.00 ms
64 bytes from 192.168.1.2: icmp_seq=3 ttl=61 time=5.08 ms
^C
--- 192.168.1.2 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2003ms
rtt min/avg/max/mdev = 5.000/5.042/5.083/0.033 ms

[vagrant@office1Server ~]$ traceroute  192.168.1.2
traceroute to 192.168.1.2 (192.168.1.2), 30 hops max, 60 byte packets
 1  192.168.2.129 (192.168.2.129)  1.612 ms  1.479 ms  1.110 ms
 2  192.168.255.9 (192.168.255.9)  2.091 ms  3.338 ms  5.518 ms
 3  192.168.255.6 (192.168.255.6)  5.431 ms  7.688 ms  7.609 ms
 4  192.168.1.2 (192.168.1.2)  8.479 ms  8.412 ms  10.545 ms
```

- Проверка с office2Server:

```
[vagrant@office2Server ~]$ ping ya.ru
PING ya.ru (5.255.255.242) 56(84) bytes of data.
64 bytes from ya.ru (5.255.255.242): icmp_seq=1 ttl=57 time=50.5 ms
64 bytes from ya.ru (5.255.255.242): icmp_seq=2 ttl=57 time=50.3 ms
64 bytes from ya.ru (5.255.255.242): icmp_seq=3 ttl=57 time=50.1 ms
^C
--- ya.ru ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2004ms
rtt min/avg/max/mdev = 50.133/50.337/50.560/0.253 ms
 
[vagrant@office2Server ~]$ ping 192.168.255.1
PING 192.168.255.1 (192.168.255.1) 56(84) bytes of data.
64 bytes from 192.168.255.1: icmp_seq=1 ttl=62 time=3.49 ms
64 bytes from 192.168.255.1: icmp_seq=2 ttl=62 time=3.73 ms
^C
--- 192.168.255.1 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1002ms
rtt min/avg/max/mdev = 3.491/3.610/3.730/0.133 ms

[vagrant@office2Server ~]$ ping 192.168.2.130
PING 192.168.2.130 (192.168.2.130) 56(84) bytes of data.
64 bytes from 192.168.2.130: icmp_seq=1 ttl=61 time=5.10 ms
64 bytes from 192.168.2.130: icmp_seq=2 ttl=61 time=4.81 ms
64 bytes from 192.168.2.130: icmp_seq=3 ttl=61 time=4.43 ms
^C
--- 192.168.2.130 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2003ms
rtt min/avg/max/mdev = 4.437/4.785/5.102/0.272 ms

[vagrant@office2Server ~]$ traceroute 192.168.2.130
traceroute to 192.168.2.130 (192.168.2.130), 30 hops max, 60 byte packets
 1  gateway (192.168.1.1)  1.087 ms  0.981 ms  0.744 ms
 2  192.168.255.5 (192.168.255.5)  1.863 ms  2.290 ms  3.723 ms
 3  192.168.255.10 (192.168.255.10)  8.390 ms  6.652 ms  7.016 ms
 4  192.168.2.130 (192.168.2.130)  6.290 ms  6.221 ms  7.259 ms
```

- Проверка с centralRouter:

```
[vagrant@centralRouter ~]$ ping ya.ru
PING ya.ru (5.255.255.242) 56(84) bytes of data.
64 bytes from ya.ru (5.255.255.242): icmp_seq=1 ttl=61 time=48.1 ms
64 bytes from ya.ru (5.255.255.242): icmp_seq=2 ttl=61 time=47.7 ms
64 bytes from ya.ru (5.255.255.242): icmp_seq=3 ttl=61 time=47.7 ms
^C
--- ya.ru ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2001ms
rtt min/avg/max/mdev = 47.705/47.864/48.126/0.313 ms

[vagrant@centralRouter ~]$ ping 192.168.1.2
PING 192.168.1.2 (192.168.1.2) 56(84) bytes of data.
64 bytes from 192.168.1.2: icmp_seq=1 ttl=63 time=3.36 ms
64 bytes from 192.168.1.2: icmp_seq=2 ttl=63 time=2.56 ms
^C
--- 192.168.1.2 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1002ms
rtt min/avg/max/mdev = 2.562/2.964/3.366/0.402 ms

[vagrant@centralRouter ~]$ ping 192.168.2.130
PING 192.168.2.130 (192.168.2.130) 56(84) bytes of data.
64 bytes from 192.168.2.130: icmp_seq=1 ttl=63 time=2.68 ms
64 bytes from 192.168.2.130: icmp_seq=2 ttl=63 time=2.34 ms
^C
--- 192.168.2.130 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1002ms
rtt min/avg/max/mdev = 2.345/2.516/2.687/0.171 ms

[vagrant@centralRouter ~]$ traceroute 192.168.1.2
traceroute to 192.168.1.2 (192.168.1.2), 30 hops max, 60 byte packets
 1  192.168.255.6 (192.168.255.6)  1.385 ms  0.549 ms  0.520 ms
 2  192.168.1.2 (192.168.1.2)  2.288 ms  2.248 ms  2.487 ms
 
[vagrant@centralRouter ~]$ traceroute 192.168.2.130
traceroute to 192.168.2.130 (192.168.2.130), 30 hops max, 60 byte packets
 1  192.168.255.10 (192.168.255.10)  1.620 ms  1.488 ms  1.412 ms
 2  192.168.2.130 (192.168.2.130)  3.260 ms  3.211 ms  3.146 ms

```

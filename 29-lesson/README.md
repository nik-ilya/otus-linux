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

1. Создаем инфраструктуру [Vagrantfile](Vagrantfile).
2. При помощи механизма Ansible provisioning выполняется конфигурация серверов.
3. Проверяем результаты работы:

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

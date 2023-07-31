# Домашнее задание 22. "Мосты, туннели и VPN"

## Домашнее задание.

1. Между двумя виртуалками поднять vpn в режимах:

-tun;

-tap;

Прочуствовать разницу.
2. Поднять RAS на базе OpenVPN с клиентскими сертификатами, подключиться с локальной машины на виртуалку.

## Выполнение.






1. Развернул три виртуальные машины - router1, router2 и router3: [Vagrantfile](Vagrantfile).
   Все эти три виртуальные машины соединены между собой сетями (10.0.10.0/30, 10.0.11.0/30 и 10.0.12.0/30). У каждого роутера есть дополнительная сеть:
   
- на **router1** — 192.168.10.0/24
- на **router2** — 192.168.20.0/24
- на **router3** — 192.168.30.0/24

3. Используя пакет FRR производим настройку OSPF на каждой виртуальной машине (роутере) средставами [Ansible](ansible/provision.yml).
   После этого OSPF поднят на всех машинах и все сети должны быть доступны с любого роутера:

```
root@router1:~# ip r
default via 10.0.2.2 dev enp0s3 proto dhcp src 10.0.2.15 metric 100 
10.0.2.0/24 dev enp0s3 proto kernel scope link src 10.0.2.15 
10.0.2.2 dev enp0s3 proto dhcp scope link src 10.0.2.15 metric 100 
10.0.10.0/30 dev enp0s8 proto kernel scope link src 10.0.10.1 
10.0.11.0/30 nhid 29 via 10.0.12.2 dev enp0s9 proto ospf metric 20 
10.0.12.0/30 dev enp0s9 proto kernel scope link src 10.0.12.1 
192.168.10.0/24 dev enp0s10 proto kernel scope link src 192.168.10.1 
192.168.20.0/24 nhid 29 via 10.0.12.2 dev enp0s9 proto ospf metric 20 
192.168.30.0/24 nhid 29 via 10.0.12.2 dev enp0s9 proto ospf metric 20 

root@router1:~# ping 192.168.30.1
PING 192.168.30.1 (192.168.30.1) 56(84) bytes of data.
64 bytes from 192.168.30.1: icmp_seq=1 ttl=64 time=3.14 ms
64 bytes from 192.168.30.1: icmp_seq=2 ttl=64 time=1.55 ms
64 bytes from 192.168.30.1: icmp_seq=3 ttl=64 time=1.35 ms
^C
--- 192.168.30.1 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2004ms
rtt min/avg/max/mdev = 1.346/2.011/3.139/0.801 ms

root@router1:~# ping 10.0.11.2
PING 10.0.11.2 (10.0.11.2) 56(84) bytes of data.
64 bytes from 10.0.11.2: icmp_seq=1 ttl=64 time=2.94 ms
64 bytes from 10.0.11.2: icmp_seq=2 ttl=64 time=2.38 ms
64 bytes from 10.0.11.2: icmp_seq=3 ttl=64 time=2.75 ms
^C
--- 10.0.11.2 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2004ms
rtt min/avg/max/mdev = 2.375/2.688/2.938/0.234 ms

root@router1:~# vtysh

Hello, this is FRRouting (version 8.5.2).
Copyright 1996-2005 Kunihiro Ishiguro, et al.

router1# sh ip route
Codes: K - kernel route, C - connected, S - static, R - RIP,
       O - OSPF, I - IS-IS, B - BGP, E - EIGRP, N - NHRP,
       T - Table, v - VNC, V - VNC-Direct, A - Babel, F - PBR,
       f - OpenFabric,
       > - selected route, * - FIB route, q - queued, r - rejected, b - backup
       t - trapped, o - offload failure

K>* 0.0.0.0/0 [0/100] via 10.0.2.2, enp0s3, src 10.0.2.15, 23:52:13
C>* 10.0.2.0/24 is directly connected, enp0s3, 23:52:13
K>* 10.0.2.2/32 [0/100] is directly connected, enp0s3, 23:52:13
O   10.0.10.0/30 [110/300] via 10.0.12.2, enp0s9, weight 1, 23:51:32
C>* 10.0.10.0/30 is directly connected, enp0s8, 23:52:13
O>* 10.0.11.0/30 [110/200] via 10.0.12.2, enp0s9, weight 1, 23:51:37
O   10.0.12.0/30 [110/100] is directly connected, enp0s9, weight 1, 23:52:12
C>* 10.0.12.0/30 is directly connected, enp0s9, 23:52:13
O   192.168.10.0/24 [110/45] is directly connected, enp0s10, weight 1, 23:52:12
C>* 192.168.10.0/24 is directly connected, enp0s10, 23:52:13
O>* 192.168.20.0/24 [110/245] via 10.0.12.2, enp0s9, weight 1, 23:51:32
O>* 192.168.30.0/24 [110/145] via 10.0.12.2, enp0s9, weight 1, 23:51:37
```
4. Изначально файл конфигурации роутеров *frr.conf* сконфигурирован в режиме ассиметричного роутинга (на router1 стоимость интерфейса **enp0s8** установлена 1000).
   Для проверки ассиметричного роутинга пропингуем 192.168.20.1 с **router1**, а на интерфейсах **router2** запустим *tcpdump*:

```
root@router1:~# ip route 
default via 10.0.2.2 dev enp0s3 proto dhcp src 10.0.2.15 metric 100 
10.0.2.0/24 dev enp0s3 proto kernel scope link src 10.0.2.15 
10.0.2.2 dev enp0s3 proto dhcp scope link src 10.0.2.15 metric 100 
10.0.10.0/30 dev enp0s8 proto kernel scope link src 10.0.10.1 
10.0.11.0/30 nhid 29 via 10.0.12.2 dev enp0s9 proto ospf metric 20 
10.0.12.0/30 dev enp0s9 proto kernel scope link src 10.0.12.1 
192.168.10.0/24 dev enp0s10 proto kernel scope link src 192.168.10.1 
192.168.20.0/24 nhid 29 via 10.0.12.2 dev enp0s9 proto ospf metric 20 
192.168.30.0/24 nhid 29 via 10.0.12.2 dev enp0s9 proto ospf metric 20 

root@router1:~# vtysh

Hello, this is FRRouting (version 8.5.2).
Copyright 1996-2005 Kunihiro Ishiguro, et al.

router1# sh ip route 192.168.20.1
Routing entry for 192.168.20.0/24
  Known via "ospf", distance 110, metric 245, best
  Last update 1d00h14m ago
  * 10.0.12.2, via enp0s9, weight 1

router1# ping 192.168.20.1
PING 192.168.20.1 (192.168.20.1) 56(84) bytes of data.
64 bytes from 192.168.20.1: icmp_seq=1 ttl=64 time=2.82 ms
64 bytes from 192.168.20.1: icmp_seq=2 ttl=64 time=3.71 ms
64 bytes from 192.168.20.1: icmp_seq=3 ttl=64 time=2.33 ms
64 bytes from 192.168.20.1: icmp_seq=4 ttl=64 time=2.39 ms
64 bytes from 192.168.20.1: icmp_seq=5 ttl=64 time=3.82 ms
64 bytes from 192.168.20.1: icmp_seq=6 ttl=64 time=2.82 ms
64 bytes from 192.168.20.1: icmp_seq=7 ttl=64 time=2.07 ms


root@router2:~# tcpdump -i enp0s8
tcpdump: verbose output suppressed, use -v or -vv for full protocol decode
listening on enp0s8, link-type EN10MB (Ethernet), capture size 262144 bytes
17:52:23.245100 IP 10.0.10.1 > ospf-all.mcast.net: OSPFv2, Hello, length 48
17:52:23.974712 IP router2 > 10.0.12.1: ICMP echo reply, id 3, seq 45, length 64
17:52:24.729079 IP router2 > ospf-all.mcast.net: OSPFv2, Hello, length 48
17:52:24.976488 IP router2 > 10.0.12.1: ICMP echo reply, id 3, seq 46, length 64
17:52:25.978513 IP router2 > 10.0.12.1: ICMP echo reply, id 3, seq 47, length 64
17:52:26.980982 IP router2 > 10.0.12.1: ICMP echo reply, id 3, seq 48, length 64
17:52:27.982399 IP router2 > 10.0.12.1: ICMP echo reply, id 3, seq 49, length 64
17:52:28.983628 IP router2 > 10.0.12.1: ICMP echo reply, id 3, seq 50, length 64
17:52:29.985804 IP router2 > 10.0.12.1: ICMP echo reply, id 3, seq 51, length 64
17:52:31.000451 IP router2 > 10.0.12.1: ICMP echo reply, id 3, seq 52, length 64
^C
10 packets captured
10 packets received by filter
0 packets dropped by kernel


root@router2:~# tcpdump -i enp0s9
tcpdump: verbose output suppressed, use -v or -vv for full protocol decode
listening on enp0s9, link-type EN10MB (Ethernet), capture size 262144 bytes
17:52:37.012466 IP 10.0.12.1 > router2: ICMP echo request, id 3, seq 58, length 64
17:52:38.014561 IP 10.0.12.1 > router2: ICMP echo request, id 3, seq 59, length 64
17:52:39.016450 IP 10.0.12.1 > router2: ICMP echo request, id 3, seq 60, length 64
17:52:40.017576 IP 10.0.12.1 > router2: ICMP echo request, id 3, seq 61, length 64
17:52:41.031416 IP 10.0.12.1 > router2: ICMP echo request, id 3, seq 62, length 64
17:52:42.057209 IP 10.0.12.1 > router2: ICMP echo request, id 3, seq 63, length 64
^C
6 packets captured
6 packets received by filter
0 packets dropped by kernel
```
Видим, что пакеты на **router2** идут через разные интерфейсы, т.о. асимметричный роутинг работает.

5. Для симметричного роутинга необходимо изменить переменную **symmetric_routing** на **true** в файле *ansible/defaults/main.yml* и добавить стоимость интерфейса *enp0s8* на роутере **router2** равным 1000. Сделать это можно с помощью Ansible, выполнив команду:
**ansible-playbook -i ansible/hosts -l all ansible/provision.yml -t setup_ospf -e "host_key_checking=false"**

Для проверки также пропингуем 192.168.20.1 с **router1**, а на **router2** запустим *tcpdump*, чтобы убедиться в симметричном роутинге: 

```
root@router2:~# tcpdump -i enp0s9
tcpdump: verbose output suppressed, use -v or -vv for full protocol decode
listening on enp0s9, link-type EN10MB (Ethernet), capture size 262144 bytes
18:06:34.858030 IP 10.0.11.1 > ospf-all.mcast.net: OSPFv2, Hello, length 48
18:06:34.861860 IP router2 > ospf-all.mcast.net: OSPFv2, Hello, length 48
18:06:35.011821 IP 10.0.12.1 > router2: ICMP echo request, id 4, seq 36, length 64
18:06:35.011872 IP router2 > 10.0.12.1: ICMP echo reply, id 4, seq 36, length 64
18:06:36.086148 IP 10.0.12.1 > router2: ICMP echo request, id 4, seq 37, length 64
18:06:36.086202 IP router2 > 10.0.12.1: ICMP echo reply, id 4, seq 37, length 64
18:06:37.088010 IP 10.0.12.1 > router2: ICMP echo request, id 4, seq 38, length 64
18:06:37.088070 IP router2 > 10.0.12.1: ICMP echo reply, id 4, seq 38, length 64
18:06:38.090459 IP 10.0.12.1 > router2: ICMP echo request, id 4, seq 39, length 64
18:06:38.090511 IP router2 > 10.0.12.1: ICMP echo reply, id 4, seq 39, length 64
18:06:39.116936 IP 10.0.12.1 > router2: ICMP echo request, id 4, seq 40, length 64
18:06:39.116984 IP router2 > 10.0.12.1: ICMP echo reply, id 4, seq 40, length 64
```


   


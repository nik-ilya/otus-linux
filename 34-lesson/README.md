# Домашнее задание 21. "Статическая и динамическая маршрутизация, OSPF"

## Домашнее задание.

1. Поднять три виртуалки.
2. Объединить их разными vlan.
3. Поднять OSPF между машинами на базе Quagga.
4. Изобразить ассиметричный роутинг.
5. Сделать один из линков "дорогим", но что бы при этом роутинг был симметричным.

## Выполнение.

1. Развернул три виртуальные машины - router1, router2 и router3: [Vagrantfile](Vagrantfile).
   Все эти три виртуальные машины соединены между собой сетями (10.0.10.0/30, 10.0.11.0/30 и 10.0.12.0/30). У каждого роутера есть дополнительная сеть:
   
- на router1 — 192.168.10.0/24
- на router2 — 192.168.20.0/24
- на router3 — 192.168.30.0/24

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

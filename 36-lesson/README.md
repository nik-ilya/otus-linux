# Домашнее задание 22. "Мосты, туннели и VPN"

## Домашнее задание.

1. Между двумя виртуалками поднять vpn в режимах:
- tun;
- tap;

Прочуствовать разницу.

2. Поднять RAS на базе OpenVPN с клиентскими сертификатами, подключиться с локальной машины на виртуалку.

## Выполнение.

### 1. TUN/TAP. 
   1.1. Разверачиваем две машины - server  и client [Vagrantfile](Vagrantfile).
   
   1.2. С помощью Ansible запускаются плейбуки [base](ansible/playbook-base.yml) и [openvpn](ansible/playbook-openvpn.yml).

   1.3. Сразу после окончания настройки поднимается режим **TAP**:

```
[root@client ~]# ip a
....
4: tap0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UNKNOWN group default qlen 100
    link/ether 12:1e:a0:65:42:55 brd ff:ff:ff:ff:ff:ff
    inet 10.10.10.2/24 brd 10.10.10.255 scope global tap0
       valid_lft forever preferred_lft forever
    inet6 fe80::101e:a0ff:fe65:4255/64 scope link 
       valid_lft forever preferred_lft forever
```
   1.4. Проверяем командой *ping* доступность сервера:
```
[root@client ~]# ping 10.10.10.1
PING 10.10.10.1 (10.10.10.1) 56(84) bytes of data.
64 bytes from 10.10.10.1: icmp_seq=1 ttl=64 time=3.08 ms
64 bytes from 10.10.10.1: icmp_seq=2 ttl=64 time=4.14 ms
64 bytes from 10.10.10.1: icmp_seq=3 ttl=64 time=2.11 ms
64 bytes from 10.10.10.1: icmp_seq=4 ttl=64 time=2.35 ms
64 bytes from 10.10.10.1: icmp_seq=5 ttl=64 time=2.23 ms
^C
--- 10.10.10.1 ping statistics ---
5 packets transmitted, 5 received, 0% packet loss, time 4004ms
rtt min/avg/max/mdev = 2.111/2.782/4.140/0.759 ms
```

   1.5. Запускаем *iperf* для измерения скорости канала между машинами:
```
[root@client ~]# iperf3 -c 10.10.10.1 -t 40 -i 5
Connecting to host 10.10.10.1, port 5201
[  5] local 10.10.10.2 port 41936 connected to 10.10.10.1 port 5201
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  5]   0.00-5.02   sec  13.7 MBytes  22.9 Mbits/sec   10   96.8 KBytes       
[  5]   5.02-10.01  sec  13.1 MBytes  22.0 Mbits/sec    3   80.0 KBytes       
[  5]  10.01-15.01  sec  12.9 MBytes  21.6 Mbits/sec    2    103 KBytes       
[  5]  15.01-20.02  sec  12.5 MBytes  21.0 Mbits/sec    5   87.7 KBytes       
[  5]  20.02-25.00  sec  14.2 MBytes  23.9 Mbits/sec    5   81.3 KBytes       
[  5]  25.00-30.02  sec  13.4 MBytes  22.4 Mbits/sec    5    106 KBytes       
[  5]  30.02-35.01  sec  15.3 MBytes  25.7 Mbits/sec    3    110 KBytes       
[  5]  35.01-40.03  sec  13.5 MBytes  22.6 Mbits/sec    5   98.0 KBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  5]   0.00-40.03  sec   109 MBytes  22.8 Mbits/sec   38             sender
[  5]   0.00-40.11  sec   108 MBytes  22.6 Mbits/sec                  receiver

iperf Done.
```
   
   1.6. Отключаем **TAP** и включаем **TUN** на двух машинах.

```
[root@server ~]# systemctl stop openvpn@server
[root@server ~]# 
[root@server ~]# systemctl start openvpn@server-tun
```

```
[root@client ~]# systemctl stop openvpn@client
[root@client ~]# 
[root@client ~]# systemctl start openvpn@client-tun
```

   1.7.  Проверяем поднятие режима **TUN**

```
[root@client ~]# ip a
...
5: tun0: <POINTOPOINT,MULTICAST,NOARP,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UNKNOWN group default qlen 100
    link/none 
    inet 10.10.20.2/24 brd 10.10.20.255 scope global tun0
       valid_lft forever preferred_lft forever
    inet6 fe80::5d9c:8885:38:cec0/64 scope link stable-privacy 
       valid_lft forever preferred_lft forever
```

   1.8. Проверяем командой *ping* доступность сервера:
```
[root@client ~]# ping 10.10.20.1
PING 10.10.20.1 (10.10.20.1) 56(84) bytes of data.
64 bytes from 10.10.20.1: icmp_seq=1 ttl=64 time=3.14 ms
64 bytes from 10.10.20.1: icmp_seq=2 ttl=64 time=2.25 ms
64 bytes from 10.10.20.1: icmp_seq=3 ttl=64 time=3.37 ms
64 bytes from 10.10.20.1: icmp_seq=4 ttl=64 time=2.24 ms
64 bytes from 10.10.20.1: icmp_seq=5 ttl=64 time=1.93 ms
^C
--- 10.10.20.1 ping statistics ---
5 packets transmitted, 5 received, 0% packet loss, time 4006ms
rtt min/avg/max/mdev = 1.933/2.585/3.368/0.565 ms
```

 1.9. Запускаем *iperf* для измерения скорости канала между машинами:

```
[root@client ~]# iperf3 -c 10.10.20.1 -t 40 -i 5
Connecting to host 10.10.20.1, port 5201
[  5] local 10.10.20.2 port 40976 connected to 10.10.20.1 port 5201
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  5]   0.00-5.01   sec  14.0 MBytes  23.4 Mbits/sec    9   99.1 KBytes       
[  5]   5.01-10.02  sec  14.7 MBytes  24.5 Mbits/sec    4   95.1 KBytes       
[  5]  10.02-15.01  sec  15.0 MBytes  25.2 Mbits/sec    5   91.2 KBytes       
[  5]  15.01-20.02  sec  14.7 MBytes  24.7 Mbits/sec    8   87.2 KBytes       
[  5]  20.02-25.02  sec  14.8 MBytes  24.8 Mbits/sec    3   85.9 KBytes       
[  5]  25.02-30.02  sec  14.6 MBytes  24.5 Mbits/sec    4   95.1 KBytes       
[  5]  30.02-35.02  sec  15.3 MBytes  25.7 Mbits/sec    4    115 KBytes       
[  5]  35.02-40.00  sec  14.2 MBytes  24.0 Mbits/sec    5    110 KBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  5]   0.00-40.00  sec   117 MBytes  24.6 Mbits/sec   42             sender
[  5]   0.00-40.08  sec   117 MBytes  24.5 Mbits/sec                  receiver

iperf Done.
```


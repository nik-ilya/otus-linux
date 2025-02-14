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

   1.3. Сразу после окончания настройки поднимается VPN в режим **TAP**:

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
   
   1.6. Отключаем режим **TAP** и включаем режим **TUN** на двух машинах.

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
   1.10. Выводы по результатам измерения скорости в двух режимах VPN.

Скорость передачи данных выше в VPN с режимом работы TUN. Это связано с тем, что в режиме TUN используется маршрутизация на уровне IP (сетевой уровень), что позволяет более эффективно управлять трафиком и оптимизировать передачу данных.

В режиме TUN каждый клиент получает виртуальный IP-адрес в целевой сети, и маршруты определяются для отправки трафика между этими виртуальными IP-адресами. Таким образом, маршруты определяются на уровне IP, и данные передаются напрямую между клиентами и сервером.

В режиме TAP, с другой стороны, используется уровень 2 (канальный уровень), и каждый клиент получает виртуальный Ethernet-адрес. Это приводит к тому, что трафик передается через Ethernet-кадры, которые могут быть менее эффективными в сравнении с маршрутизацией на уровне IP. Кроме того, в режиме TAP могут происходить дополнительные широковещательные сообщения, что также может повлиять на производительность.
   
### RAS.

   2.1. Разверачиваем новую машину ras. [Vagrantfile](Vagrantfile).
   
   2.2. С помощью Ansible запускаются плейбуки [base](ansible/playbook-base.yml) и [ras](ansible/playbook-ras.yml).

   2.3. После настройки машины ras, запускаем openvpn на локальной машине, используя конфиг файл [client.conf](client.conf).

```
root@otuslinux-new:~/otus-linux/36-lesson# openvpn --config client.conf
Tue Aug  1 01:27:56 2023 WARNING: file './ansible/client/client.key' is group or others accessible
Tue Aug  1 01:27:56 2023 OpenVPN 2.4.7 x86_64-pc-linux-gnu [SSL (OpenSSL)] [LZO] [LZ4] [EPOLL] [PKCS11] [MH/PKTINFO] [AEAD] built on Mar 22 2022
Tue Aug  1 01:27:56 2023 library versions: OpenSSL 1.1.1f  31 Mar 2020, LZO 2.10
Tue Aug  1 01:27:56 2023 TCP/UDP: Preserving recently used remote address: [AF_INET]192.168.56.30:1207
Tue Aug  1 01:27:56 2023 Socket Buffers: R=[212992->212992] S=[212992->212992]
Tue Aug  1 01:27:56 2023 UDP link local (bound): [AF_INET][undef]:1194
Tue Aug  1 01:27:56 2023 UDP link remote: [AF_INET]192.168.56.30:1207
Tue Aug  1 01:27:56 2023 TLS: Initial packet from [AF_INET]192.168.56.30:1207, sid=96f6f144 a4ecd709
Tue Aug  1 01:27:56 2023 VERIFY OK: depth=1, CN=rasvpn
Tue Aug  1 01:27:56 2023 VERIFY KU OK
Tue Aug  1 01:27:56 2023 Validating certificate extended key usage
Tue Aug  1 01:27:56 2023 ++ Certificate has EKU (str) TLS Web Server Authentication, expects TLS Web Server Authentication
Tue Aug  1 01:27:56 2023 VERIFY EKU OK
Tue Aug  1 01:27:56 2023 VERIFY OK: depth=0, CN=rasvpn
Tue Aug  1 01:27:56 2023 Control Channel: TLSv1.3, cipher TLSv1.3 TLS_AES_256_GCM_SHA384, 2048 bit RSA
Tue Aug  1 01:27:56 2023 [rasvpn] Peer Connection Initiated with [AF_INET]192.168.56.30:1207
Tue Aug  1 01:27:57 2023 SENT CONTROL [rasvpn]: 'PUSH_REQUEST' (status=1)
Tue Aug  1 01:27:57 2023 PUSH: Received control message: 'PUSH_REPLY,topology net30,ping 10,ping-restart 120,ifconfig 10.10.30.6 10.10.30.5,peer-id 0,cipher AES-256-GCM'
Tue Aug  1 01:27:57 2023 OPTIONS IMPORT: timers and/or timeouts modified
Tue Aug  1 01:27:57 2023 OPTIONS IMPORT: --ifconfig/up options modified
Tue Aug  1 01:27:57 2023 OPTIONS IMPORT: peer-id set
Tue Aug  1 01:27:57 2023 OPTIONS IMPORT: adjusting link_mtu to 1625
Tue Aug  1 01:27:57 2023 OPTIONS IMPORT: data channel crypto options modified
Tue Aug  1 01:27:57 2023 Data Channel: using negotiated cipher 'AES-256-GCM'
Tue Aug  1 01:27:57 2023 Outgoing Data Channel: Cipher 'AES-256-GCM' initialized with 256 bit key
Tue Aug  1 01:27:57 2023 Incoming Data Channel: Cipher 'AES-256-GCM' initialized with 256 bit key
Tue Aug  1 01:27:57 2023 ROUTE_GATEWAY 45.144.49.1/255.255.255.0 IFACE=eth0 HWADDR=fa:16:3e:da:93:22
Tue Aug  1 01:27:57 2023 TUN/TAP device tun0 opened
Tue Aug  1 01:27:57 2023 TUN/TAP TX queue length set to 100
Tue Aug  1 01:27:57 2023 /sbin/ip link set dev tun0 up mtu 1500
Tue Aug  1 01:27:57 2023 /sbin/ip addr add dev tun0 local 10.10.30.6 peer 10.10.30.5
Tue Aug  1 01:27:57 2023 /sbin/ip route add 10.10.30.0/24 via 10.10.30.5
Tue Aug  1 01:27:57 2023 WARNING: this configuration may cache passwords in memory -- use the auth-nocache option to prevent this
Tue Aug  1 01:27:57 2023 Initialization Sequence Completed
```

   2.4. Проверяем поднятие VPN:

```
root@otuslinux-new:~/otus-linux/36-lesson# ip a
...
21: tun0: <POINTOPOINT,MULTICAST,NOARP,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UNKNOWN group default qlen 100
    link/none 
    inet 10.10.30.6 peer 10.10.30.5/32 scope global tun0
       valid_lft forever preferred_lft forever
    inet6 fe80::77d9:8322:8d65:a4aa/64 scope link stable-privacy 
       valid_lft forever preferred_lft forever

```

   2.5. Приверим командой *ping* доступность сервера ras с локальной машины:

```
root@otuslinux-new:~/otus-linux/36-lesson# ping 10.10.30.1
PING 10.10.30.1 (10.10.30.1) 56(84) bytes of data.
64 bytes from 10.10.30.1: icmp_seq=1 ttl=64 time=1.81 ms
64 bytes from 10.10.30.1: icmp_seq=2 ttl=64 time=1.65 ms
64 bytes from 10.10.30.1: icmp_seq=3 ttl=64 time=1.27 ms
64 bytes from 10.10.30.1: icmp_seq=4 ttl=64 time=1.15 ms
64 bytes from 10.10.30.1: icmp_seq=5 ttl=64 time=1.31 ms
64 bytes from 10.10.30.1: icmp_seq=6 ttl=64 time=1.17 ms
64 bytes from 10.10.30.1: icmp_seq=7 ttl=64 time=1.25 ms
64 bytes from 10.10.30.1: icmp_seq=8 ttl=64 time=1.68 ms
^C
--- 10.10.30.1 ping statistics ---
8 packets transmitted, 8 received, 0% packet loss, time 7009ms
rtt min/avg/max/mdev = 1.146/1.410/1.812/0.243 ms
```



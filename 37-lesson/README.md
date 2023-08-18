# Домашнее задание 23. "DNS, split-DNS"

## Домашнее задание.

1. Взять стенд https://github.com/erlong15/vagrant-bind,
- добавить еще один сервер client2,
- завести в зоне dns.lab имена:
  - web1 - смотрит на клиент1,
  - web2 - смотрит на клиент2,
- завести еще одну зону newdns.lab,
- завести в ней запись:
  - www - смотрит на обоих клиентов.
2. Настроить split-dns:
- клиент1 - видит обе зоны, но в зоне dns.lab только web1,
- клиент2 - видит только dns.lab.


## Выполнение.

Результатом выполнения домашнего задания является [Vagrantfile](Vagrantfile) файл, который средствами ansible provisioning подготавливает следующий стенд:
-    Первичный DNS сервер ns1 - 192.168.50.10
-    Вторичный DNS сервер ns2 - 192.168.50.11
-    Клиентская машина client - 192.168.50.15
-    Клиентская машина client2 - 192.168.50.16

### Проверка настройки split-DNS:

- С первой клиентской машины доступны обе зоны *www.newdns.lab* и *web1.dns.lab*, но недоступны другие ресурсы в зоне *dns.lab*.

```
[root@client ~]# ping www.newdns.lab
PING www.newdns.lab (192.168.50.15) 56(84) bytes of data.
64 bytes from client (192.168.50.15): icmp_seq=1 ttl=64 time=0.022 ms
64 bytes from client (192.168.50.15): icmp_seq=2 ttl=64 time=0.040 ms
64 bytes from client (192.168.50.15): icmp_seq=3 ttl=64 time=0.039 ms
64 bytes from client (192.168.50.15): icmp_seq=4 ttl=64 time=0.037 ms
64 bytes from client (192.168.50.15): icmp_seq=5 ttl=64 time=0.037 ms
^C
--- www.newdns.lab ping statistics ---
5 packets transmitted, 5 received, 0% packet loss, time 4001ms
rtt min/avg/max/mdev = 0.022/0.035/0.040/0.006 ms

[root@client ~]# ping web1.dns.lab
PING web1.dns.lab (192.168.50.15) 56(84) bytes of data.
64 bytes from client (192.168.50.15): icmp_seq=1 ttl=64 time=0.020 ms
64 bytes from client (192.168.50.15): icmp_seq=2 ttl=64 time=0.038 ms
64 bytes from client (192.168.50.15): icmp_seq=3 ttl=64 time=0.034 ms
64 bytes from client (192.168.50.15): icmp_seq=4 ttl=64 time=0.034 ms
64 bytes from client (192.168.50.15): icmp_seq=5 ttl=64 time=0.035 ms
^C
--- web1.dns.lab ping statistics ---
5 packets transmitted, 5 received, 0% packet loss, time 4001ms
rtt min/avg/max/mdev = 0.020/0.032/0.038/0.007 ms

[root@client ~]# ping web2.dns.lab
ping: web2.dns.lab: Name or service not known
[root@client ~]#
```

- Вторая клиентская машина не видит зоны *newdns.lab* и видит только зоны *dns.lab*.
```
[root@client2 ~]# ping www.newdns.lab
ping: www.newdns.lab: Name or service not known

[root@client2 ~]# ping web1.dns.lab
PING web1.dns.lab (192.168.50.15) 56(84) bytes of data.
64 bytes from 192.168.50.15 (192.168.50.15): icmp_seq=1 ttl=64 time=2.69 ms
64 bytes from 192.168.50.15 (192.168.50.15): icmp_seq=2 ttl=64 time=1.47 ms
64 bytes from 192.168.50.15 (192.168.50.15): icmp_seq=3 ttl=64 time=1.25 ms
64 bytes from 192.168.50.15 (192.168.50.15): icmp_seq=4 ttl=64 time=1.33 ms
64 bytes from 192.168.50.15 (192.168.50.15): icmp_seq=5 ttl=64 time=1.43 ms
64 bytes from 192.168.50.15 (192.168.50.15): icmp_seq=6 ttl=64 time=1.35 ms
c^C
--- web1.dns.lab ping statistics ---
6 packets transmitted, 6 received, 0% packet loss, time 5011ms
rtt min/avg/max/mdev = 1.250/1.588/2.690/0.500 ms


[root@client2 ~]#  ping web2.dns.lab
PING web2.dns.lab (192.168.50.16) 56(84) bytes of data.
64 bytes from client2 (192.168.50.16): icmp_seq=1 ttl=64 time=0.045 ms
64 bytes from client2 (192.168.50.16): icmp_seq=2 ttl=64 time=0.035 ms
64 bytes from client2 (192.168.50.16): icmp_seq=3 ttl=64 time=0.046 ms
64 bytes from client2 (192.168.50.16): icmp_seq=4 ttl=64 time=0.033 ms
64 bytes from client2 (192.168.50.16): icmp_seq=5 ttl=64 time=0.040 ms
64 bytes from client2 (192.168.50.16): icmp_seq=6 ttl=64 time=0.044 ms
^C
--- web2.dns.lab ping statistics ---
6 packets transmitted, 6 received, 0% packet loss, time 5001ms
rtt min/avg/max/mdev = 0.033/0.040/0.046/0.008 ms
```

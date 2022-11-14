# Урок 02. "Дисковая подсистема"

## Домашнее задание


1. Загрузился с Vagrantfile c созданием 4 дополнительных дисков.

```bash
[root@otuslinux ~]# lsblk
NAME   MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda      8:0    0   40G  0 disk
└─sda1   8:1    0   40G  0 part /
sdb      8:16   0  100M  0 disk
sdc      8:32   0  100M  0 disk
sdd      8:48   0  100M  0 disk
sde      8:64   0  100M  0 disk
```

2. Создаю raid 6 из 4 дисков

```bash
mdadm --zero-superblock --force /dev/sd{b,c,d,e}

mdadm --create --verbose /dev/md0 -l 6 -n 4 /dev/sd{b,c,d,e}

[root@otuslinux ~]# mdadm -D /dev/md0
/dev/md0:
           Version : 1.2
     Creation Time : Mon Nov 14 14:29:28 2022
        Raid Level : raid6
        Array Size : 200704 (196.00 MiB 205.52 MB)
     Used Dev Size : 100352 (98.00 MiB 102.76 MB)
      Raid Devices : 4
     Total Devices : 4
       Persistence : Superblock is persistent

       Update Time : Mon Nov 14 14:29:32 2022
             State : clean
    Active Devices : 4
   Working Devices : 4
    Failed Devices : 0
     Spare Devices : 0

            Layout : left-symmetric
        Chunk Size : 512K

Consistency Policy : resync

              Name : otuslinux:0  (local to host otuslinux)
              UUID : 8c5e782c:2beea270:8ae363b0:a7a98660
            Events : 17

    Number   Major   Minor   RaidDevice State
       0       8       16        0      active sync   /dev/sdb
       1       8       32        1      active sync   /dev/sdc
       2       8       48        2      active sync   /dev/sdd
       3       8       64        3      active sync   /dev/sde
```

3. Сломаю один диск

```bash
[root@otuslinux ~]# mdadm /dev/md0 --fail /dev/sde
mdadm: set /dev/sde faulty in /dev/md0

[root@otuslinux ~]# mdadm -D /dev/md0
/dev/md0:
           Version : 1.2
     Creation Time : Mon Nov 14 14:29:28 2022
        Raid Level : raid6
        Array Size : 200704 (196.00 MiB 205.52 MB)
     Used Dev Size : 100352 (98.00 MiB 102.76 MB)
      Raid Devices : 4
     Total Devices : 4
       Persistence : Superblock is persistent

       Update Time : Mon Nov 14 14:55:26 2022
             State : clean, degraded
    Active Devices : 3
   Working Devices : 3
    Failed Devices : 1
     Spare Devices : 0

            Layout : left-symmetric
        Chunk Size : 512K

Consistency Policy : resync

              Name : otuslinux:0  (local to host otuslinux)
              UUID : 8c5e782c:2beea270:8ae363b0:a7a98660
            Events : 19

    Number   Major   Minor   RaidDevice State
       0       8       16        0      active sync   /dev/sdb
       1       8       32        1      active sync   /dev/sdc
       2       8       48        2      active sync   /dev/sdd
       -       0        0        3      removed

       3       8       64        -      faulty   /dev/sde

[root@otuslinux ~]# cat /proc/mdstat
Personalities : [raid6] [raid5] [raid4]
md0 : active raid6 sde[3](F) sdb[0] sdd[2] sdc[1]
      200704 blocks super 1.2 level 6, 512k chunk, algorithm 2 [4/3] [UUU_]
```

4. Удаляю сломанный диск

```bash
[root@otuslinux ~]# mdadm /dev/md0 --remove /dev/sde
mdadm: hot removed /dev/sde from /dev/md0
[root@otuslinux ~]# cat /proc/mdstat
Personalities : [raid6] [raid5] [raid4]
md0 : active raid6 sdb[0] sdd[2] sdc[1]
      200704 blocks super 1.2 level 6, 512k chunk, algorithm 2 [4/3] [UUU_]
```

5. Восстановлю RAID6 добавив диск

```bash
[root@otuslinux ~]# mdadm /dev/md0 --add /dev/sde
mdadm: added /dev/sde
[root@otuslinux ~]# cat /proc/mdstat
Personalities : [raid6] [raid5] [raid4]
md0 : active raid6 sde[4] sdb[0] sdd[2] sdc[1]
      200704 blocks super 1.2 level 6, 512k chunk, algorithm 2 [4/4] [UUUU]

unused devices: <none>
[root@otuslinux ~]# mdadm -D /dev/md0
/dev/md0:
           Version : 1.2
     Creation Time : Mon Nov 14 14:29:28 2022
        Raid Level : raid6
        Array Size : 200704 (196.00 MiB 205.52 MB)
     Used Dev Size : 100352 (98.00 MiB 102.76 MB)
      Raid Devices : 4
     Total Devices : 4
       Persistence : Superblock is persistent

       Update Time : Mon Nov 14 15:01:09 2022
             State : clean
    Active Devices : 4
   Working Devices : 4
    Failed Devices : 0
     Spare Devices : 0

            Layout : left-symmetric
        Chunk Size : 512K

Consistency Policy : resync

              Name : otuslinux:0  (local to host otuslinux)
              UUID : 8c5e782c:2beea270:8ae363b0:a7a98660
            Events : 39

    Number   Major   Minor   RaidDevice State
       0       8       16        0      active sync   /dev/sdb
       1       8       32        1      active sync   /dev/sdc
       2       8       48        2      active sync   /dev/sdd
       4       8       64        3      active sync   /dev/sde
```

6. Удаляю RAID

```bash
[root@otuslinux ~]# mdadm -S /dev/md0
mdadm: stopped /dev/md0

[root@otuslinux ~]# mdadm --zero-superblock --force /dev/sd{b,c,d,e}

[root@otuslinux ~]# lsblk
NAME   MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda      8:0    0   40G  0 disk
└─sda1   8:1    0   40G  0 part /
sdb      8:16   0  100M  0 disk
sdc      8:32   0  100M  0 disk
sdd      8:48   0  100M  0 disk
sde      8:64   0  100M  0 disk
[root@otuslinux ~]# cat /proc/mdstat
Personalities : [raid6] [raid5] [raid4]
unused devices: <none>
```

7. Т.к. оказалось что в задании надо собрать любой RAID кроме 6, то создам RAID10

```bash
 mdadm --zero-superblock --force /dev/sd{b,c,d,e}
 
 mdadm --create --verbose /dev/md/raid10 -l 10 -n 4 /dev/sd{b,c,d,e}
 
 [root@otuslinux ~]# cat /proc/mdstat
Personalities : [raid10]
md127 : active raid10 sde[3] sdd[2] sdc[1] sdb[0]
      200704 blocks super 1.2 512K chunks 2 near-copies [4/4] [UUUU]
```

8. Сломаю один диск и восстановлю обратно.

```bash
[root@otuslinux ~]# mdadm /dev/md/raid10 --fail /dev/sdc
mdadm: set /dev/sdc faulty in /dev/md/raid10

[root@otuslinux ~]# cat /proc/mdstat
Personalities : [raid10]
md127 : active raid10 sdc[1](F) sdb[0] sdd[2] sde[3]
      200704 blocks super 1.2 512K chunks 2 near-copies [4/3] [U_UU]

unused devices: <none>
[root@otuslinux ~]# mdadm -D /dev/md127
/dev/md127:
           Version : 1.2
     Creation Time : Mon Nov 14 15:22:10 2022
        Raid Level : raid10
        Array Size : 200704 (196.00 MiB 205.52 MB)
     Used Dev Size : 100352 (98.00 MiB 102.76 MB)
      Raid Devices : 4
     Total Devices : 4
       Persistence : Superblock is persistent

       Update Time : Mon Nov 14 15:50:03 2022
             State : clean, degraded
    Active Devices : 3
   Working Devices : 3
    Failed Devices : 1
     Spare Devices : 0

            Layout : near=2
        Chunk Size : 512K

Consistency Policy : resync

              Name : otuslinux:raid10  (local to host otuslinux)
              UUID : cde09b47:b5c644c0:110819f2:04042599
            Events : 19

    Number   Major   Minor   RaidDevice State
       0       8       16        0      active sync set-A   /dev/sdb
       -       0        0        1      removed
       2       8       48        2      active sync set-A   /dev/sdd
       3       8       64        3      active sync set-B   /dev/sde

       1       8       32        -      faulty   /dev/sdc


[root@otuslinux ~]# mdadm /dev/md/raid10 --remove /dev/sdc
mdadm: hot removed /dev/sdc from /dev/md/raid10

[root@otuslinux ~]# cat /proc/mdstat
Personalities : [raid10]
md127 : active raid10 sdb[0] sdd[2] sde[3]
      200704 blocks super 1.2 512K chunks 2 near-copies [4/3] [U_UU]

[root@otuslinux ~]# mdadm /dev/md/raid10 --add /dev/sdc

[root@otuslinux ~]# mdadm -D /dev/md127
/dev/md127:
           Version : 1.2
     Creation Time : Mon Nov 14 15:22:10 2022
        Raid Level : raid10
        Array Size : 200704 (196.00 MiB 205.52 MB)
     Used Dev Size : 100352 (98.00 MiB 102.76 MB)
      Raid Devices : 4
     Total Devices : 4
       Persistence : Superblock is persistent

       Update Time : Mon Nov 14 15:54:17 2022
             State : clean
    Active Devices : 4
   Working Devices : 4
    Failed Devices : 0
     Spare Devices : 0

            Layout : near=2
        Chunk Size : 512K

Consistency Policy : resync

              Name : otuslinux:raid10  (local to host otuslinux)
              UUID : cde09b47:b5c644c0:110819f2:04042599
            Events : 39

    Number   Major   Minor   RaidDevice State
       0       8       16        0      active sync set-A   /dev/sdb
       4       8       32        1      active sync set-B   /dev/sdc
       2       8       48        2      active sync set-A   /dev/sdd
       3       8       64        3      active sync set-B   /dev/sde
```

9. Сделаем файл mdadm.conf

```bash
[root@otuslinux ~]# cd /etc
[root@otuslinux etc]# mkdir mdadm
[root@otuslinux etc]# cd mdadm
[root@otuslinux mdadm]# touch mdadm.conf
[root@otuslinux mdadm]# echo "DEVICE partitions" > /etc/mdadm/mdadm.conf
[root@otuslinux mdadm]# mdadm --detail --scan --verbose | awk '/ARRAY/ {print}' >> /etc/mdadm/mdadm.conf
```

После reboot RAID собран:

```bash
[vagrant@otuslinux ~]$ lsblk
NAME    MAJ:MIN RM  SIZE RO TYPE   MOUNTPOINT
sda       8:0    0   40G  0 disk
└─sda1    8:1    0   40G  0 part   /
sdb       8:16   0  100M  0 disk
└─md127   9:127  0  196M  0 raid10
sdc       8:32   0  100M  0 disk
└─md127   9:127  0  196M  0 raid10
sdd       8:48   0  100M  0 disk
└─md127   9:127  0  196M  0 raid10
sde       8:64   0  100M  0 disk
└─md127   9:127  0  196M  0 raid10
```

10. Создаем раздел GPT на RAID и 5 партиций.

```bash
[root@otuslinux ~]# parted -s /dev/md/raid10 mklabel gpt

parted /dev/md127 mkpart primary ext4 0% 20%
parted /dev/md127 mkpart primary ext4 20% 40%
parted /dev/md127 mkpart primary ext4 40% 60%
parted /dev/md127 mkpart primary ext4 60% 80%
parted /dev/md127 mkpart primary ext4 80% 100%

[root@otuslinux ~]# lsblk
NAME        MAJ:MIN RM  SIZE RO TYPE   MOUNTPOINT
sda           8:0    0   40G  0 disk
└─sda1        8:1    0   40G  0 part   /
sdb           8:16   0  100M  0 disk
└─md127       9:127  0  196M  0 raid10
  ├─md127p1 259:5    0 39.2M  0 md
  ├─md127p2 259:6    0   38M  0 md
  ├─md127p3 259:7    0   40M  0 md
  ├─md127p4 259:8    0   39M  0 md
  └─md127p5 259:9    0   39M  0 md
sdc           8:32   0  100M  0 disk
└─md127       9:127  0  196M  0 raid10
  ├─md127p1 259:5    0 39.2M  0 md
  ├─md127p2 259:6    0   38M  0 md
  ├─md127p3 259:7    0   40M  0 md
  ├─md127p4 259:8    0   39M  0 md
  └─md127p5 259:9    0   39M  0 md
sdd           8:48   0  100M  0 disk
└─md127       9:127  0  196M  0 raid10
  ├─md127p1 259:5    0 39.2M  0 md
  ├─md127p2 259:6    0   38M  0 md
  ├─md127p3 259:7    0   40M  0 md
  ├─md127p4 259:8    0   39M  0 md
  └─md127p5 259:9    0   39M  0 md
sde           8:64   0  100M  0 disk
└─md127       9:127  0  196M  0 raid10
  ├─md127p1 259:5    0 39.2M  0 md
  ├─md127p2 259:6    0   38M  0 md
  ├─md127p3 259:7    0   40M  0 md
  ├─md127p4 259:8    0   39M  0 md
  └─md127p5 259:9    0   39M  0 md
```


11. Создаем на партициях файловую систему

```bash
for i in $(seq 1 5); do sudo mkfs.ext4 /dev/md127p$i; done
```

12. Монтируем по каталогам.

```bash
[root@otuslinux ~]# mkdir -p /raid/part{1,2,3,4,5}
[root@otuslinux ~]#
[root@otuslinux ~]#
[root@otuslinux ~]# for i in $(seq 1 5); do mount /dev/md127p$i /raid/part$i; done
[root@otuslinux ~]#
[root@otuslinux ~]# df -h
Filesystem      Size  Used Avail Use% Mounted on
devtmpfs        489M     0  489M   0% /dev
tmpfs           496M     0  496M   0% /dev/shm
tmpfs           496M  6.7M  489M   2% /run
tmpfs           496M     0  496M   0% /sys/fs/cgroup
/dev/sda1        40G  3.7G   37G  10% /
tmpfs           100M     0  100M   0% /run/user/1000
/dev/md127p1     34M  782K   31M   3% /raid/part1
/dev/md127p2     33M  782K   30M   3% /raid/part2
/dev/md127p3     35M  782K   32M   3% /raid/part3
/dev/md127p4     34M  782K   31M   3% /raid/part4
/dev/md127p5     34M  782K   31M   3% /raid/part5
```

# Урок 04. "ZFS"

## Домашнее задание.

Запустил ВМ используя vagrantfile https://github.com/nixuser/zfs, только добавил создание 8 дисков вместо 6.

### 1. Определение алгоритма с наилучшим сжатием.

````bash
[vagrant@server ~]$ lsblk
NAME   MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda      8:0    0   64G  0 disk 
├─sda1   8:1    0  2.1G  0 part [SWAP]
└─sda2   8:2    0 61.9G  0 part /
sdb      8:16   0    1G  0 disk 
sdc      8:32   0    1G  0 disk 
sdd      8:48   0    1G  0 disk 
sde      8:64   0    1G  0 disk 
sdf      8:80   0    1G  0 disk 
sdg      8:96   0    1G  0 disk 
sdh      8:112  0    1G  0 disk 
sdi      8:128  0    1G  0 disk 

[vagrant@server ~]$ zfs version
zfs-2.0.7-1
zfs-kmod-2.0.7-1
````

[root@server ~]# zpool create otus1 mirror /dev/sdb /dev/sdc
[root@server ~]# zpool create otus2 mirror /dev/sdd /dev/sde
[root@server ~]# zpool create otus3 mirror /dev/sdf /dev/sdg
[root@server ~]# zpool create otus4 mirror /dev/sdh /dev/sdi

[root@server ~]# zpool list
NAME    SIZE  ALLOC   FREE  CKPOINT  EXPANDSZ   FRAG    CAP  DEDUP    HEALTH  ALTROOT
otus1   960M   105K   960M        -         -     0%     0%  1.00x    ONLINE  -
otus2   960M   105K   960M        -         -     0%     0%  1.00x    ONLINE  -
otus3   960M    99K   960M        -         -     0%     0%  1.00x    ONLINE  -
otus4   960M   105K   960M        -         -     0%     0%  1.00x    ONLINE  -


[root@server ~]# zfs set compression=lzjb otus1
[root@server ~]# zfs set compression=lz4 otus2
[root@server ~]# zfs set compression=gzip-9 otus3
[root@server ~]# zfs set compression=zle otus4

[root@server ~]# zfs get all | grep compression
otus1  compression           lzjb                   local
otus2  compression           lz4                    local
otus3  compression           gzip-9                 local
otus4  compression           zle                    local


[root@server ~]# ls -l /otus*
/otus1:
total 2443
-rw-r--r--. 1 root root 3359372 Dec 13 14:34 pg2600.txt

/otus2:
total 2041
-rw-r--r--. 1 root root 3359372 Dec 13 14:34 pg2600.txt

/otus3:
total 1239
-rw-r--r--. 1 root root 3359372 Dec 13 14:34 pg2600.txt

/otus4:
total 3287
-rw-r--r--. 1 root root 3359372 Dec 13 14:34 pg2600.txt

[root@server ~]# zfs list
NAME    USED  AVAIL     REFER  MOUNTPOINT
otus1  2.53M   829M     2.41M  /otus1
otus2  2.13M   830M     2.02M  /otus2
otus3  1.34M   831M     1.23M  /otus3
otus4  3.35M   829M     3.23M  /otus4
[root@server ~]# 
[root@server ~]# zfs get all | grep compressratio | grep -v ref
otus1  compressratio         1.35x                  -
otus2  compressratio         1.61x                  -
otus3  compressratio         2.63x                  -
otus4  compressratio         1.01x                  -


Вывод: алгоритм gzip-9 самый эффективный по сжатию. 

2. Определение настроек пула

Скачал архив https://drive.google.com/u/0/uc?id=1KRBNW33QWqbvbVHa3hLJivOAt60yukkg и распаковал его.


[root@server ~]# ll zpoolexport/
total 1024000
-rw-r--r--. 1 root root 524288000 May 15  2020 filea
-rw-r--r--. 1 root root 524288000 May 15  2020 fileb


[root@server ~]# zpool import -d zpoolexport/
   pool: otus
     id: 6554193320433390805
  state: ONLINE
status: Some supported features are not enabled on the pool.
 action: The pool can be imported using its name or numeric identifier, though
	some features will not be available without an explicit 'zpool upgrade'.
 config:

	otus                         ONLINE
	  mirror-0                   ONLINE
	    /root/zpoolexport/filea  ONLINE
	    /root/zpoolexport/fileb  ONLINE


[root@server ~]# zpool import -d zpoolexport/ otus

[root@server ~]# zpool list
NAME    SIZE  ALLOC   FREE  CKPOINT  EXPANDSZ   FRAG    CAP  DEDUP    HEALTH  ALTROOT
otus    480M  2.18M   478M        -         -     0%     0%  1.00x    ONLINE  -
otus1   960M  2.53M   957M        -         -     0%     0%  1.00x    ONLINE  -
otus2   960M  2.13M   958M        -         -     0%     0%  1.00x    ONLINE  -
otus3   960M  1.34M   959M        -         -     0%     0%  1.00x    ONLINE  -
otus4   960M  3.35M   957M        -         -     0%     0%  1.00x    ONLINE  -


[root@server ~]# zfs get all otus
NAME  PROPERTY              VALUE                  SOURCE
otus  type                  filesystem             -
otus  creation              Fri May 15  4:00 2020  -
otus  used                  2.04M                  -
otus  available             350M                   -
otus  referenced            24K                    -
otus  compressratio         1.00x                  -
otus  mounted               yes                    -
otus  quota                 none                   default
otus  reservation           none                   default
otus  recordsize            128K                   local
otus  mountpoint            /otus                  default
otus  sharenfs              off                    default
otus  checksum              sha256                 local
otus  compression           zle                    local
otus  atime                 on                     default
otus  devices               on                     default
otus  exec                  on                     default
otus  setuid                on                     default
otus  readonly              off                    default
otus  zoned                 off                    default
otus  snapdir               hidden                 default
otus  aclmode               discard                default
otus  aclinherit            restricted             default
otus  createtxg             1                      -
otus  canmount              on                     default
otus  xattr                 on                     default
otus  copies                1                      default
otus  version               5                      -
otus  utf8only              off                    -
otus  normalization         none                   -
otus  casesensitivity       sensitive              -
otus  vscan                 off                    default
otus  nbmand                off                    default
otus  sharesmb              off                    default
otus  refquota              none                   default
otus  refreservation        none                   default
otus  guid                  14592242904030363272   -
otus  primarycache          all                    default
otus  secondarycache        all                    default
otus  usedbysnapshots       0B                     -
otus  usedbydataset         24K                    -
otus  usedbychildren        2.01M                  -
otus  usedbyrefreservation  0B                     -
otus  logbias               latency                default
otus  objsetid              54                     -
otus  dedup                 off                    default
otus  mlslabel              none                   default
otus  sync                  standard               default
otus  dnodesize             legacy                 default
otus  refcompressratio      1.00x                  -
otus  written               24K                    -
otus  logicalused           1020K                  -
otus  logicalreferenced     12K                    -
otus  volmode               default                default
otus  filesystem_limit      none                   default
otus  snapshot_limit        none                   default
otus  filesystem_count      none                   default
otus  snapshot_count        none                   default
otus  snapdev               hidden                 default
otus  acltype               off                    default
otus  context               none                   default
otus  fscontext             none                   default
otus  defcontext            none                   default
otus  rootcontext           none                   default
otus  relatime              off                    default
otus  redundant_metadata    all                    default
otus  overlay               on                     default
otus  encryption            off                    default
otus  keylocation           none                   default
otus  keyformat             none                   default
otus  pbkdf2iters           0                      default
otus  special_small_blocks  0                      default
[root@server ~]# 
[root@server ~]# 
[root@server ~]# 
[root@server ~]# 
[root@server ~]# zpool get all otus
NAME  PROPERTY                       VALUE                          SOURCE
otus  size                           480M                           -
otus  capacity                       0%                             -
otus  altroot                        -                              default
otus  health                         ONLINE                         -
otus  guid                           6554193320433390805            -
otus  version                        -                              default
otus  bootfs                         -                              default
otus  delegation                     on                             default
otus  autoreplace                    off                            default
otus  cachefile                      -                              default
otus  failmode                       wait                           default
otus  listsnapshots                  off                            default
otus  autoexpand                     off                            default
otus  dedupratio                     1.00x                          -
otus  free                           478M                           -
otus  allocated                      2.09M                          -
otus  readonly                       off                            -
otus  ashift                         0                              default
otus  comment                        -                              default
otus  expandsize                     -                              -
otus  freeing                        0                              -
otus  fragmentation                  0%                             -
otus  leaked                         0                              -
otus  multihost                      off                            default
otus  checkpoint                     -                              -
otus  load_guid                      8466488305464193471            -
otus  autotrim                       off                            default
otus  feature@async_destroy          enabled                        local
otus  feature@empty_bpobj            active                         local
otus  feature@lz4_compress           active                         local
otus  feature@multi_vdev_crash_dump  enabled                        local
otus  feature@spacemap_histogram     active                         local
otus  feature@enabled_txg            active                         local
otus  feature@hole_birth             active                         local
otus  feature@extensible_dataset     active                         local
otus  feature@embedded_data          active                         local
otus  feature@bookmarks              enabled                        local
otus  feature@filesystem_limits      enabled                        local
otus  feature@large_blocks           enabled                        local
otus  feature@large_dnode            enabled                        local
otus  feature@sha512                 enabled                        local
otus  feature@skein                  enabled                        local
otus  feature@edonr                  enabled                        local
otus  feature@userobj_accounting     active                         local
otus  feature@encryption             enabled                        local
otus  feature@project_quota          active                         local
otus  feature@device_removal         enabled                        local
otus  feature@obsolete_counts        enabled                        local
otus  feature@zpool_checkpoint       enabled                        local
otus  feature@spacemap_v2            active                         local
otus  feature@allocation_classes     enabled                        local
otus  feature@resilver_defer         enabled                        local
otus  feature@bookmark_v2            enabled                        local
otus  feature@redaction_bookmarks    disabled                       local
otus  feature@redacted_datasets      disabled                       local
otus  feature@bookmark_written       disabled                       local
otus  feature@log_spacemap           disabled                       local
otus  feature@livelist               disabled                       local
otus  feature@device_rebuild         disabled                       local
otus  feature@zstd_compress          disabled                       local


[root@server ~]# zfs get available otus
NAME  PROPERTY   VALUE  SOURCE
otus  available  350M   -

[root@server ~]# zfs get readonly otus
NAME  PROPERTY  VALUE   SOURCE
otus  readonly  off     default

[root@server ~]# zfs get recordsize otus
NAME  PROPERTY    VALUE    SOURCE
otus  recordsize  128K     local

[root@server ~]# zfs get compression otus
NAME  PROPERTY     VALUE           SOURCE
otus  compression  zle             local

[root@server ~]# zfs get checksum otus
NAME  PROPERTY  VALUE      SOURCE
otus  checksum  sha256     local


3. Работа со снапшотом, поиск сообщения от преподавателя

Скачал файл

[root@server ~]# wget -O otus_task2.file --no-check-certificate https://drive.google.com/u/0/uc?id=1gH8gCL9y7Nd5Ti3IRmplZPF1XjzxeRAG

Восстановим файловую систему из снапшота


zfs receive otus/test@today < otus_task2.file

[root@server ~]# zfs list
NAME             USED  AVAIL     REFER  MOUNTPOINT
otus            4.97M   347M       25K  /otus
otus/hometask2  1.88M   347M     1.88M  /otus/hometask2
otus/test       2.84M   347M     2.83M  /otus/test
otus1           2.53M   829M     2.41M  /otus1
otus2           2.13M   830M     2.02M  /otus2
otus3           1.34M   831M     1.23M  /otus3
otus4           3.35M   829M     3.23M  /otus4


[root@server ~]# find /otus/test -name "secret_message"
/otus/test/task1/file_mess/secret_message


[root@server ~]# cat /otus/test/task1/file_mess/secret_message
https://github.com/sindresorhus/awesome


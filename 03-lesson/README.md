# Урок 03. "Файловые системы и LVM"

## Домашнее задание

1.  Уменьшить том под / до 8G.
3.  Выделить том под /home.
4.  Выделить том под /var (/var - сделать в mirror).
5.  Для /home - сделать том для снэпшотов.
6.  Прописать монтирование в fstab (попробовать с разными опциями и разными файловыми системами на выбор).
7.  Работа со снапшотами.


Результат выполнения домашнего задания приведен в созданном утилитой script лог-файле my_log.


### 1. Уменьшить том под / до 8G.

```bash
[root@lvm ~]# lsblk
NAME                    MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda                       8:0    0   40G  0 disk 
├─sda1                    8:1    0    1M  0 part 
├─sda2                    8:2    0    1G  0 part /boot
└─sda3                    8:3    0   39G  0 part 
  ├─VolGroup00-LogVol00 253:0    0 37.5G  0 lvm  /
  └─VolGroup00-LogVol01 253:1    0  1.5G  0 lvm  [SWAP]
sdb                       8:16   0   10G  0 disk 
sdc                       8:32   0    2G  0 disk 
sdd                       8:48   0    1G  0 disk 
sde                       8:64   0    1G  0 disk 
```


[root@lvm ~]# pvcreate /dev/sdb
  Physical volume "/dev/sdb" successfully created.
[root@lvm ~]# vgcreate vg_root /dev/sdb
  Volume group "vg_root" successfully created
[root@lvm ~]# lvcreate -n lv_root -l +100%FREE /dev/vg_root
  Logical volume "lv_root" created.
[root@lvm ~]# 
[root@lvm ~]# 
[root@lvm ~]# 
[root@lvm ~]# 
[root@lvm ~]# pvs
  PV         VG         Fmt  Attr PSize   PFree
  /dev/sda3  VolGroup00 lvm2 a--  <38.97g    0 
  /dev/sdb   vg_root    lvm2 a--  <10.00g    0 
[root@lvm ~]# 
[root@lvm ~]# vgs
  VG         #PV #LV #SN Attr   VSize   VFree
  VolGroup00   1   2   0 wz--n- <38.97g    0 
  vg_root      1   1   0 wz--n- <10.00g    0 
[root@lvm ~]# 
[root@lvm ~]# 
[root@lvm ~]# lvs
  LV       VG         Attr       LSize   Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
  LogVol00 VolGroup00 -wi-ao---- <37.47g                                                    
  LogVol01 VolGroup00 -wi-ao----   1.50g                                                    
  lv_root  vg_root    -wi-a----- <10.00g           









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

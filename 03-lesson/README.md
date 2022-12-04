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

Создаю временный том для корневого раздела:

```bash
[root@lvm ~]# pvcreate /dev/sdb
  Physical volume "/dev/sdb" successfully created.
  
[root@lvm ~]# vgcreate vg_root /dev/sdb
  Volume group "vg_root" successfully created
  
[root@lvm ~]# lvcreate -n lv_root -l +100%FREE /dev/vg_root
  Logical volume "lv_root" created.
```

Проверяю создание:

```bash
[root@lvm ~]# pvs
  PV         VG         Fmt  Attr PSize   PFree
  /dev/sda3  VolGroup00 lvm2 a--  <38.97g    0 
  /dev/sdb   vg_root    lvm2 a--  <10.00g    0 

[root@lvm ~]# vgs
  VG         #PV #LV #SN Attr   VSize   VFree
  VolGroup00   1   2   0 wz--n- <38.97g    0 
  vg_root      1   1   0 wz--n- <10.00g    0 

[root@lvm ~]# lvs
  LV       VG         Attr       LSize   Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
  LogVol00 VolGroup00 -wi-ao---- <37.47g                                                    
  LogVol01 VolGroup00 -wi-ao----   1.50g                                                    
  lv_root  vg_root    -wi-a----- <10.00g           
```

Cоздал файловую систему и смонтировал раздел:

```bash
[root@lvm ~]# mkfs.xfs /dev/vg_root/lv_root
meta-data=/dev/vg_root/lv_root   isize=512    agcount=4, agsize=655104 blks
         =                       sectsz=512   attr=2, projid32bit=1
         =                       crc=1        finobt=0, sparse=0
data     =                       bsize=4096   blocks=2620416, imaxpct=25
         =                       sunit=0      swidth=0 blks
naming   =version 2              bsize=4096   ascii-ci=0 ftype=1
log      =internal log           bsize=4096   blocks=2560, version=2
         =                       sectsz=512   sunit=0 blks, lazy-count=1
realtime =none                   extsz=4096   blocks=0, rtextents=0
[root@lvm ~]# mount /dev/vg_root/lv_root /mnt
[root@lvm ~]# 
[root@lvm ~]# 
[root@lvm ~]# 
[root@lvm ~]# df -Th
Filesystem                      Type      Size  Used Avail Use% Mounted on
/dev/mapper/VolGroup00-LogVol00 xfs        38G  839M   37G   3% /
devtmpfs                        devtmpfs  109M     0  109M   0% /dev
tmpfs                           tmpfs     118M     0  118M   0% /dev/shm
tmpfs                           tmpfs     118M  4.5M  114M   4% /run
tmpfs                           tmpfs     118M     0  118M   0% /sys/fs/cgroup
/dev/sda2                       xfs      1014M   63M  952M   7% /boot
tmpfs                           tmpfs      24M     0   24M   0% /run/user/1000
/dev/mapper/vg_root-lv_root     xfs        10G   33M   10G   1% /mnt
```

Копирую все файлы в /mnt
```bash
[root@lvm ~]#  xfsdump -J - /dev/VolGroup00/LogVol00 | xfsrestore -J - /mnt
```

Сделал chroot в /mnt и переконфигурирован загрузчик и обновлен initrd, в /boot/grub2/grub.cfg заменен rd.lvm.lv=VolGroup00/LogVol00 на rd.lvm.lv=vg_root/lv_root

```bash
[root@lvm ~]#  for i in /proc/ /sys/ /dev/ /run/ /boot/; do mount --bind $i /mnt/$i; done
[root@lvm ~]# chroot /mnt/
[root@lvm /]# grub2-mkconfig -o /boot/grub2/grub.cfg
Generating grub configuration file ...
Found linux image: /boot/vmlinuz-3.10.0-862.2.3.el7.x86_64
Found initrd image: /boot/initramfs-3.10.0-862.2.3.el7.x86_64.img
done
[root@lvm /]# cd /boot ; for i in `ls initramfs-*img`; do dracut -v $i `echo $i|sed "s/initramfs-//g;
> s/.img//g"` --force; done
[root@lvm boot]# nano /boot/grub2/grub.cfg 
```
После перезагрузки:

```bash
[vagrant@lvm ~]$ lsblk
NAME                    MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda                       8:0    0   40G  0 disk 
├─sda1                    8:1    0    1M  0 part 
├─sda2                    8:2    0    1G  0 part /boot
└─sda3                    8:3    0   39G  0 part 
  ├─VolGroup00-LogVol00 253:1    0 37.5G  0 lvm  
  └─VolGroup00-LogVol01 253:2    0  1.5G  0 lvm  [SWAP]
sdb                       8:16   0   10G  0 disk 
└─vg_root-lv_root       253:0    0   10G  0 lvm  /
sdc                       8:32   0    2G  0 disk 
sdd                       8:48   0    1G  0 disk 
sde                       8:64   0    1G  0 disk 
```

Удаляю старый раздел и создаю новый на 8Gb
```bash
[root@lvm ~]# lvremove /dev/VolGroup00/LogVol00
Do you really want to remove active logical volume VolGroup00/LogVol00? [y/n]: y
  Logical volume "LogVol00" successfully removed
  
[root@lvm ~]# lvcreate -n VolGroup00/LogVol00 -L 8G /dev/VolGroup00
WARNING: xfs signature detected on /dev/VolGroup00/LogVol00 at offset 0. Wipe it? [y/n]: y
  Wiping xfs signature on /dev/VolGroup00/LogVol00.
  Logical volume "LogVol00" created.
```

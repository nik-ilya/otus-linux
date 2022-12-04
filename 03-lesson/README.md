# Урок 03. "Файловые системы и LVM"

## Домашнее задание

1.  Уменьшить том под / до 8G.
2.  Выделить том под /home.
3.  Выделить том под /var (/var - сделать в mirror).
4.  Для /home - сделать том для снэпшотов.
5.  Прописать монтирование в fstab (попробовать с разными опциями и разными файловыми системами на выбор).
6.  Работа со снапшотами.


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

Удаляю старый раздел и создаю новый на 8Gb:
```bash
[root@lvm ~]# lvremove /dev/VolGroup00/LogVol00
Do you really want to remove active logical volume VolGroup00/LogVol00? [y/n]: y
  Logical volume "LogVol00" successfully removed
  
[root@lvm ~]# lvcreate -n VolGroup00/LogVol00 -L 8G /dev/VolGroup00
WARNING: xfs signature detected on /dev/VolGroup00/LogVol00 at offset 0. Wipe it? [y/n]: y
  Wiping xfs signature on /dev/VolGroup00/LogVol00.
  Logical volume "LogVol00" created.
```

Создаю файловую систему, монтирую и копирую данные:
```bash
[root@lvm ~]# mkfs.xfs /dev/VolGroup00/LogVol00
meta-data=/dev/VolGroup00/LogVol00 isize=512    agcount=4, agsize=524288 blks
         =                       sectsz=512   attr=2, projid32bit=1
         =                       crc=1        finobt=0, sparse=0
data     =                       bsize=4096   blocks=2097152, imaxpct=25
         =                       sunit=0      swidth=0 blks
naming   =version 2              bsize=4096   ascii-ci=0 ftype=1
log      =internal log           bsize=4096   blocks=2560, version=2
         =                       sectsz=512   sunit=0 blks, lazy-count=1
realtime =none                   extsz=4096   blocks=0, rtextents=0

[root@lvm ~]# mount /dev/VolGroup00/LogVol00 /mnt
[root@lvm ~]# df
Filesystem                      1K-blocks   Used Available Use% Mounted on
/dev/mapper/vg_root-lv_root      10471424 859480   9611944   9% /
devtmpfs                           111880      0    111880   0% /dev
tmpfs                              120692      0    120692   0% /dev/shm
tmpfs                              120692   4588    116104   4% /run
tmpfs                              120692      0    120692   0% /sys/fs/cgroup
/dev/sda2                         1038336  62212    976124   6% /boot
tmpfs                               24140      0     24140   0% /run/user/1000
/dev/mapper/VolGroup00-LogVol00   8378368  32944   8345424   1% /mnt

[root@lvm ~]# xfsdump -J - /dev/vg_root/lv_root | xfsrestore -J - /mnt
```

После чего опять переконфигурируем grub
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
```

### 2. Выделить том под /var (/var - сделать в mirror).

Создаем зеркало на новых дисках:

```bash
[root@lvm boot]# pvcreate /dev/sdc /dev/sdd
  Physical volume "/dev/sdc" successfully created.
  Physical volume "/dev/sdd" successfully created.

[root@lvm boot]# vgcreate vg_var /dev/sdc /dev/sdd
  Volume group "vg_var" successfully created

[root@lvm boot]# lvcreate -L 950M -m1 -n lv_var vg_var
  Rounding up size to full physical extent 952.00 MiB
  Logical volume "lv_var" created.
```
    
Создаем файловую систему, монтируем и копируем данные:  
    
```bash
[root@lvm boot]# mkfs.ext4 /dev/vg_var/lv_var
mke2fs 1.42.9 (28-Dec-2013)
Filesystem label=
OS type: Linux
Block size=4096 (log=2)
Fragment size=4096 (log=2)
Stride=0 blocks, Stripe width=0 blocks
60928 inodes, 243712 blocks
12185 blocks (5.00%) reserved for the super user
First data block=0
Maximum filesystem blocks=249561088
8 block groups
32768 blocks per group, 32768 fragments per group
7616 inodes per group
Superblock backups stored on blocks: 
	32768, 98304, 163840, 229376

Allocating group tables: done                            
Writing inode tables: done                            
Creating journal (4096 blocks): done
Writing superblocks and filesystem accounting information: done

[root@lvm boot]# mount /dev/vg_var/lv_var /mnt

[root@lvm boot]#  cp -aR /var/* /mnt/

[root@lvm boot]# df -h
Filesystem                       Size  Used Avail Use% Mounted on
/dev/mapper/VolGroup00-LogVol00  8.0G  840M  7.2G  11% /
devtmpfs                         110M     0  110M   0% /dev
tmpfs                            118M  4.6M  114M   4% /run
/dev/sda2                       1014M   61M  954M   6% /boot
/dev/mapper/vg_var-lv_var        922M  213M  646M  25% /mnt

[root@lvm boot]# lsblk
NAME                     MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda                        8:0    0   40G  0 disk 
├─sda1                     8:1    0    1M  0 part 
├─sda2                     8:2    0    1G  0 part /boot
└─sda3                     8:3    0   39G  0 part 
  ├─VolGroup00-LogVol00  253:1    0    8G  0 lvm  /
  └─VolGroup00-LogVol01  253:2    0  1.5G  0 lvm  [SWAP]
sdb                        8:16   0   10G  0 disk 
└─vg_root-lv_root        253:0    0   10G  0 lvm  
sdc                        8:32   0    2G  0 disk 
├─vg_var-lv_var_rmeta_0  253:3    0    4M  0 lvm  
│ └─vg_var-lv_var        253:7    0  952M  0 lvm  /mnt
└─vg_var-lv_var_rimage_0 253:4    0  952M  0 lvm  
  └─vg_var-lv_var        253:7    0  952M  0 lvm  /mnt
sdd                        8:48   0    1G  0 disk 
├─vg_var-lv_var_rmeta_1  253:5    0    4M  0 lvm  
│ └─vg_var-lv_var        253:7    0  952M  0 lvm  /mnt
└─vg_var-lv_var_rimage_1 253:6    0  952M  0 lvm  
  └─vg_var-lv_var        253:7    0  952M  0 lvm  /mnt
sde                        8:64   0    1G  0 disk 

[root@lvm boot]# umount /mnt

[root@lvm boot]# mount /dev/vg_var/lv_var /var
```
Добавляем /var в fstab для автоматического монтирования после перезагрузки:
```bash
[root@lvm boot]# echo "`blkid | grep var: | awk '{print $2}'` /var ext4 defaults 0 0" >> /etc/fstab
```

### 3. Выделить том под /home.

Делается по такому же принципу что и для /var:

```bash
[root@lvm ~]# lvcreate -n LogVol_Home -L 2G /dev/VolGroup00
  Logical volume "LogVol_Home" created.
  
[root@lvm ~]# mkfs.xfs /dev/VolGroup00/LogVol_Home
meta-data=/dev/VolGroup00/LogVol_Home isize=512    agcount=4, agsize=131072 blks
         =                       sectsz=512   attr=2, projid32bit=1
         =                       crc=1        finobt=0, sparse=0
data     =                       bsize=4096   blocks=524288, imaxpct=25
         =                       sunit=0      swidth=0 blks
naming   =version 2              bsize=4096   ascii-ci=0 ftype=1
log      =internal log           bsize=4096   blocks=2560, version=2
         =                       sectsz=512   sunit=0 blks, lazy-count=1
realtime =none                   extsz=4096   blocks=0, rtextents=0

[root@lvm ~]# mount /dev/VolGroup00/LogVol_Home /mnt/

[root@lvm ~]# df
Filesystem                         1K-blocks   Used Available Use% Mounted on
/dev/mapper/VolGroup00-LogVol00      8378368 859600   7518768  11% /
devtmpfs                              111876      0    111876   0% /dev
tmpfs                                 120692      0    120692   0% /dev/shm
tmpfs                                 120692   4512    116180   4% /run
tmpfs                                 120692      0    120692   0% /sys/fs/cgroup
/dev/mapper/vg_var-lv_var             943128 217500    660504  25% /var
/dev/sda2                            1038336  62216    976120   6% /boot
/dev/mapper/VolGroup00-LogVol_Home   2086912  32944   2053968   2% /mnt

[root@lvm ~]# cp -aR /home/* /mnt/

[root@lvm ~]# rm -rf /home/*

[root@lvm ~]# umount /mnt

[root@lvm ~]# mount /dev/VolGroup00/LogVol_Home /home/

[root@lvm ~]# df
Filesystem                         1K-blocks   Used Available Use% Mounted on
/dev/mapper/VolGroup00-LogVol00      8378368 859540   7518828  11% /
devtmpfs                              111876      0    111876   0% /dev
tmpfs                                 120692      0    120692   0% /dev/shm
tmpfs                                 120692   4512    116180   4% /run
tmpfs                                 120692      0    120692   0% /sys/fs/cgroup
/dev/mapper/vg_var-lv_var             943128 217500    660504  25% /var
/dev/sda2                            1038336  62216    976120   6% /boot
/dev/mapper/VolGroup00-LogVol_Home   2086912  32996   2053916   2% /home

[root@lvm ~]# echo "`blkid | grep Home | awk '{print $2}'` /home xfs defaults 0 0" >> /etc/fstab
```

### 4.  Для /home - сделать том для снэпшотов.

Сгенерировал файлы в /home:

```bash
[root@lvm ~]# touch /home/file{1..20}

[root@lvm ~]# ll /home
total 0
-rw-r--r--. 1 root    root     0 Dec  4 12:42 file1
-rw-r--r--. 1 root    root     0 Dec  4 12:42 file10
-rw-r--r--. 1 root    root     0 Dec  4 12:42 file11
-rw-r--r--. 1 root    root     0 Dec  4 12:42 file12
-rw-r--r--. 1 root    root     0 Dec  4 12:42 file13
-rw-r--r--. 1 root    root     0 Dec  4 12:42 file14
-rw-r--r--. 1 root    root     0 Dec  4 12:42 file15
-rw-r--r--. 1 root    root     0 Dec  4 12:42 file16
-rw-r--r--. 1 root    root     0 Dec  4 12:42 file17
-rw-r--r--. 1 root    root     0 Dec  4 12:42 file18
-rw-r--r--. 1 root    root     0 Dec  4 12:42 file19
-rw-r--r--. 1 root    root     0 Dec  4 12:42 file2
-rw-r--r--. 1 root    root     0 Dec  4 12:42 file20
-rw-r--r--. 1 root    root     0 Dec  4 12:42 file3
-rw-r--r--. 1 root    root     0 Dec  4 12:42 file4
-rw-r--r--. 1 root    root     0 Dec  4 12:42 file5
-rw-r--r--. 1 root    root     0 Dec  4 12:42 file6
-rw-r--r--. 1 root    root     0 Dec  4 12:42 file7
-rw-r--r--. 1 root    root     0 Dec  4 12:42 file8
-rw-r--r--. 1 root    root     0 Dec  4 12:42 file9
drwx------. 3 vagrant vagrant 95 Dec  3 19:09 vagrant
```

Сделал снапшот:
```bash
[root@lvm ~]# lvcreate -L 100MB -s -n home_snap /dev/VolGroup00/LogVol_Home
  Rounding up size to full physical extent 128.00 MiB
  Logical volume "home_snap" created.

[root@lvm ~]# lvs
  LV          VG         Attr       LSize   Pool Origin      Data%  Meta%  Move Log Cpy%Sync Convert
  LogVol00    VolGroup00 -wi-ao----   8.00g                                                         
  LogVol01    VolGroup00 -wi-ao----   1.50g                                                         
  LogVol_Home VolGroup00 owi-aos---   2.00g                                                         
  home_snap   VolGroup00 swi-a-s--- 128.00m      LogVol_Home 0.00                                   
  lv_var      vg_var     rwi-aor--- 952.00m                                         100.00          
```

Удалил часть файлов:

```bash
[root@lvm ~]# rm -f /home/file{11..20}

[root@lvm ~]# ll /home
total 0
-rw-r--r--. 1 root    root     0 Dec  4 12:42 file1
-rw-r--r--. 1 root    root     0 Dec  4 12:42 file10
-rw-r--r--. 1 root    root     0 Dec  4 12:42 file2
-rw-r--r--. 1 root    root     0 Dec  4 12:42 file3
-rw-r--r--. 1 root    root     0 Dec  4 12:42 file4
-rw-r--r--. 1 root    root     0 Dec  4 12:42 file5
-rw-r--r--. 1 root    root     0 Dec  4 12:42 file6
-rw-r--r--. 1 root    root     0 Dec  4 12:42 file7
-rw-r--r--. 1 root    root     0 Dec  4 12:42 file8
-rw-r--r--. 1 root    root     0 Dec  4 12:42 file9
drwx------. 3 vagrant vagrant 95 Dec  3 19:09 vagrant
```

Восстановил файлы из снапшота:
```bash
[root@lvm ~]# umount /home

[root@lvm ~]# lvconvert --merge /dev/VolGroup00/home_snap
  Merging of volume VolGroup00/home_snap started.
  VolGroup00/LogVol_Home: Merged: 100.00%
  
[root@lvm ~]# mount /home

[root@lvm ~]# ll /home
total 0
-rw-r--r--. 1 root    root     0 Dec  4 12:42 file1
-rw-r--r--. 1 root    root     0 Dec  4 12:42 file10
-rw-r--r--. 1 root    root     0 Dec  4 12:42 file11
-rw-r--r--. 1 root    root     0 Dec  4 12:42 file12
-rw-r--r--. 1 root    root     0 Dec  4 12:42 file13
-rw-r--r--. 1 root    root     0 Dec  4 12:42 file14
-rw-r--r--. 1 root    root     0 Dec  4 12:42 file15
-rw-r--r--. 1 root    root     0 Dec  4 12:42 file16
-rw-r--r--. 1 root    root     0 Dec  4 12:42 file17
-rw-r--r--. 1 root    root     0 Dec  4 12:42 file18
-rw-r--r--. 1 root    root     0 Dec  4 12:42 file19
-rw-r--r--. 1 root    root     0 Dec  4 12:42 file2
-rw-r--r--. 1 root    root     0 Dec  4 12:42 file20
-rw-r--r--. 1 root    root     0 Dec  4 12:42 file3
-rw-r--r--. 1 root    root     0 Dec  4 12:42 file4
-rw-r--r--. 1 root    root     0 Dec  4 12:42 file5
-rw-r--r--. 1 root    root     0 Dec  4 12:42 file6
-rw-r--r--. 1 root    root     0 Dec  4 12:42 file7
-rw-r--r--. 1 root    root     0 Dec  4 12:42 file8
-rw-r--r--. 1 root    root     0 Dec  4 12:42 file9
drwx------. 3 vagrant vagrant 95 Dec  3 19:09 vagrant
```

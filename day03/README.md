Домашнее задание 3. Работа с LVM

Что нужно сделать?

уменьшить том под / до 8G
выделить том под /home
выделить том под /var (/var - сделать в mirror)
для /home - сделать том для снэпшотов
прописать монтирование в fstab (попробовать с разными опциями и разными файловыми системами на выбор)
Работа со снапшотами:
сгенерировать файлы в /home/
снять снэпшот
удалить часть файлов
восстановиться со снэпшота
(залоггировать работу можно утилитой script, скриншотами и т.п.)
Задание со звездочкой*
на нашей куче дисков попробовать поставить btrfs/zfs:
с кешем и снэпшотами
разметить здесь каталог /opt

```bash
Хостовая машина Debian 11.
Установлены: 
- Vagrant 2.3.4
- VirtualBox 6.1.44
- Packer 1.6.6.
- Ansible 2.10.1
```
- Для практических работ использую свой образ и свой Vagrantfile
- Для проверки необходимо из директории day03 выполнить:
```bash
$ vagrant up
$ vagrant ssh
Last login: Wed Jun 14 16:37:12 2023 from 10.0.2.2
```
Смотрим имеющиеся блочные устройства

```bash
vagrant@lvm:~\[vagrant@lvm ~]$ sudo -i
root@lvm:~\[root@lvm ~]# lsblk
NAME    MAJ:MIN RM SIZE RO TYPE MOUNTPOINT
sda    8:0 0 14.7G 0 disk 
├─sda1    8:1 0 1G 0 part /boot
└─sda2    8:2 0 13.7G 0 part 
 ├─centos_otus--dnik01-root 253:0 0 12.2G 0 lvm /
 └─centos_otus--dnik01-swap 253:1 0 1.5G 0 lvm [SWAP]
sdb    8:16 0 10G 0 disk 
sdc    8:32 0 2G 0 disk 
sdd    8:48 0 1G 0 disk 
sde    8:64 0 1G 0 disk 
sdf    8:80 0 2G 0 disk 
```
Создаем временный LVM том для переноса раздела

```bash
root@lvm:~\[root@lvm ~]# pvcreate /dev/sdb
 Physical volume "/dev/sdb" successfully created.

root@lvm:~\[root@lvm ~]# vgcreate v_root
 No command with matching syntax recognised. Run 'vgcreate --help' for more information.
 Correct command syntax is:
 vgcreate VG_new PV ...

root@lvm:~\[root@lvm ~]# vgcreate v_root /dev/sdb
 Volume group "v_root" successfully created
root@lvm:~\[root@lvm ~]# mkfs lvcreate -n l_root -l +100% FREE /dev/v_root
 Logical volume "l_root" created.
```
   Создаем на томе файловую систему и монтируем ее
```bash   
root@lvm:~\[root@lvm ~]# mkfs.xfs /dev/v_root/l_root 
meta-data=/dev/v_root/l_root isize=512 agcount=4, agsize=655104 blks
  =   sectsz=512 attr=2, projid32bit=1
  =   crc=1 finobt=0, sparse=0
data =   bsize=4096 blocks=2620416, imaxpct=25
  =   sunit=0 swidth=0 blks
naming =version 2  bsize=4096 ascii-ci=0 ftype=1
log =internal log  bsize=4096 blocks=2560, version=2
  =   sectsz=512 sunit=0 blks, lazy-count=1
realtime =none   extsz=4096 blocks=0, rtextents=0

root@lvm:~\[root@lvm ~]# mount /dev/vg_root/l_root /mnt

[root@lvm ~]#lsblk
NAME    MAJ:MIN RM SIZE RO TYPE MOUNTPOINT
sda    8:0 0 14.7G 0 disk 
├─sda1    8:1 0 1G 0 part /boot
└─sda2    8:2 0 13.7G 0 part 
 ├─centos_otus--dnik01-root 253:0 0 12.2G 0 lvm /
 └─centos_otus--dnik01-swap 253:1 0 1.5G 0 lvm [SWAP]
sdb    8:16 0 10G 0 disk 
└─v_root-l_root  253:2 0 10G 0 lvm /mnt
sdc    8:32 0 2G 0 disk 
sdd    8:48 0 1G 0 disk 
sde    8:64 0 1G 0 disk 
sdf    8:80 0 2G 0 disk 
```
Сдампим содержимое текущего корневого раздела в наш временный:
```bash 
root@lvm:~\[root@lvm ~]# xfsdump -J - /dev/centos_otus-dnik01/root | xfsrestoree -J - /mnt
xfsdump: using file dump (drive_simple) strategy
xfsrestore: using file dump (drive_simple) strategy
xfsdump: version 3.1.7 (dump format 3.0)
xfsrestore: version 3.1.7 (dump format 3.0)
xfsrestore: searching media for dump
xfsdump: level 0 dump of lvm:/
...
xfsrestore: directory post-processing
xfsrestore: restoring non-directory files
xfsdump: ending media file
xfsdump: media file size 1841195304 bytes
xfsdump: dump size (non-dir files) : 1807070000 bytes
xfsdump: dump complete: 42 seconds elapsed
xfsdump: Dump Status: SUCCESS
xfsrestore: restore complete: 43 seconds elapsed
xfsrestore: Restore Status: SUCCESS
```
Заходим в окружение chroot временного корня:
```bash 
root@lvm:~\[root@lvm ~]# for i in /proc/ /sys/ /dev/ /run/ /boot/; do mount --bind $i /mnt/$i; done
root@lvm:~\[root@lvm ~]# croot /mnt/
```
Запишем новый загрузчик:
```bash 
[root@lvm /]# grub2-mkconfig -o /boot/grub2/grub.cfg
Generating grub configuration file ...
Found linux image: /boot/vmlinuz-3.10.0-1160.90.1.el7.x86_64
Found initrd image: /boot/initramfs-3.10.0-1160.90.1.el7.x86_64.img
Found linux image: /boot/vmlinuz-3.10.0-1160.el7.x86_64
Found initrd image: /boot/initramfs-3.10.0-1160.el7.x86_64.img
Found linux image: /boot/vmlinuz-0-rescue-03cd44dbe759f841bae73f303352c92e
Found initrd image: /boot/initramfs-0-rescue-03cd44dbe759f841bae73f303352c92e.img
done
```
Обновляем образы загрузки:
```bash 
root@lvm:/\[root@lvm /]# cd /boot ; for i in `ls initramfs-*img`; do dracut -v $i `echo $i|sed "s/initramfs-//g 
; s/.img//g"` --force; done
Kernel version 0-rescue-03cd44dbe759f841bae73f303352c92e has no module directory /lib/modules/0-rescue-03cd44dbe759f841bae73f303352c92e
Executing: /sbin/dracut -v initramfs-0-rescue-03cd44dbe759f841bae73f303352c92e.img 0-rescue-03cd44dbe759f841bae73f303352c92e --force
dracut module 'modsign' will not be installed, because command 'keyctl' could not be found!
dracut module 'busybox' will not be installed, because command 'busybox' could not be found!
dracut module 'crypt' will not be installed, because command 'cryptsetup' could not be found!
dracut module 'dmraid' will not be installed, because command 'dmraid' could not be found!
dracut module 'dmsquash-live-ntfs' will not be installed, because command 'ntfs-3g' could not be found!
dracut module 'multipath' will not be installed, because command 'multipath' could not be found!
dracut module 'cifs' will not be installed, because command 'mount.cifs' could not be found!
dracut module 'iscsi' will not be installed, because command 'iscsistart' could not be found!
dracut module 'iscsi' will not be installed, because command 'iscsi-iname' could not be found!
95nfs: Could not find any command of 'rpcbind portmap'!
dracut module 'modsign' will not be installed, because command 'keyctl' could not be found!
dracut module 'busybox' will not be installed, because command 'busybox' could not be found!
dracut module 'crypt' will not be installed, because command 'cryptsetup' could not be found!
dracut module 'dmraid' will not be installed, because command 'dmraid' could not be found!
dracut module 'dmsquash-live-ntfs' will not be installed, because command 'ntfs-3g' could not be found!
dracut module 'multipath' will not be installed, because command 'multipath' could not be found!
dracut module 'cifs' will not be installed, because command 'mount.cifs' could not be found!
dracut module 'iscsi' will not be installed, because command 'iscsistart' could not be found!
dracut module 'iscsi' will not be installed, because command 'iscsi-iname' could not be found!
95nfs: Could not find any command of 'rpcbind portmap'!
*** Including module: bash ***
*** Including module: nss-softokn ***
*** Including module: i18n ***
*** Including module: network ***
*** Including module: ifcfg ***
*** Including module: drm ***
*** Including module: plymouth ***
*** Including module: dm ***
...
*** Creating image file ***
*** Creating microcode section ***
*** Created microcode section ***
*** Creating image file done ***
*** Creating initramfs image file '/boot/initramfs-3.10.0-1160.el7.x86_64kdump.img' done ***
```
Открываем конфигурационный файл grub.cfg и меняем **rd.lvm.lv=centos_otus-dnik01/root** на 
**rd.lvm.lv=v_root/l_root**

```bash 
root@lvm:/boot\[root@lvm boot]# vi /boot/grub.cfg 
```
Выходим из chroot и перегружаем виртуальную машину

```bash 
root@lvm:/boot\[root@lvm boot]# exit
root@lvm:~\[root@lvm ~]# reboot

Connection to 127.0.0.1 closed by remote host.
Connection to 127.0.0.1 closed.
```
После перезагрузки заходим в виртуальную машину и смотрим блочные устройства
```bash 
$ vagrant ssh
Last login: Thu Jun 15 07:01:25 2023 from 10.0.2.2

vagrant@lvm:~\[vagrant@lvm ~]$ sudo -i
root@lvm:~\[root@lvm ~]# lsblk
NAME                         MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda                            8:0    0 14.7G  0 disk 
├─sda1                         8:1    0    1G  0 part /boot
└─sda2                         8:2    0 13.7G  0 part 
  ├─centos_otus--dnik01-swap 253:1    0  1.5G  0 lvm  [SWAP]
  └─centos_otus--dnik01-root 253:2    0 12.2G  0 lvm  
sdb                            8:16   0   10G  0 disk 
└─v_root-l_root              253:0    0   10G  0 lvm  /
sdc                            8:32   0    2G  0 disk 
sdd                            8:48   0    1G  0 disk 
sde                            8:64   0    1G  0 disk 
sdf                            8:80   0    2G  0 disk 
```
Удаляем старый корневой раздел чтобы создать новый размером 8G
```bash 
[root@lvm ~]# lvremove /dev/centos_otus-dnik01/root 
Do you really want to remove active logical volume centos_otus-dnik01/root? [y/n]: y
  Logical volume "root" successfully removed
```
Создаем новый раздел размером 8G и файловую систему xfs на нем и смонтируем его в /mnt
```bash 
root@lvm:~\[root@lvm ~]# lvcreate -n centos_otus-dnik01/root -L 8G /dev/centos_otus-dnik01/
WARNING: xfs signature detected on /dev/centos_otus-dnik01/root at offset 0. Wipe it? [y/n]: y
  Wiping xfs signature on /dev/centos_otus-dnik01/root.
  Logical volume "root" created.

root@lvm:~\[root@lvm ~]# mkfs.xfs /dev/centos_otus-dnik01/root 
meta-data=/dev/centos_otus-dnik01/root isize=512    agcount=4, agsize=524288 blks
         =                       sectsz=512   attr=2, projid32bit=1
         =                       crc=1        finobt=0, sparse=0
data     =                       bsize=4096   blocks=2097152, imaxpct=25
         =                       sunit=0      swidth=0 blks
naming   =version 2              bsize=4096   ascii-ci=0 ftype=1
log      =internal log           bsize=4096   blocks=2560, version=2
         =                       sectsz=512   sunit=0 blks, lazy-count=1
realtime =none                   extsz=4096   blocks=0, rtextents=0

root@lvm:~\[root@lvm ~]# mount /dev/centos_otus-dnik01/root /mnt
```
Восстановим корневой раздел с временного на новый
```bash 
root@lvm:~\[root@lvm ~]# xfsdump -J - /dev/v_root/l_root | xfsrestore -J - /mnt
xfsdump: using file dump (drive_simple) strategy
xfsrestore: using file dump (drive_simple) strategy
xfsdump: version 3.1.7 (dump format 3.0)
xfsrestore: version 3.1.7 (dump format 3.0)
xfsdump: level 0 dump of lvm:/
xfsdump: dump date: Thu Jun 15 07:32:19 2023
xfsdump: session id: b50ae5a0-da95-4574-852f-9a2a495244e8
xfsdump: session label: ""
xfsrestore: searching media for dump
xfsdump: ino map phase 1: constructing initial dump list
xfsdump: ino map phase 2: skipping (no pruning necessary)
xfsdump: ino map phase 3: skipping (only one dump stream)
...
xfsrestore: searching media for directory dump
xfsrestore: reading directories
xfsdump: dumping non-directory files
xfsrestore: 9439 directories and 56516 entries processed
xfsrestore: directory post-processing
xfsrestore: restoring non-directory files
xfsdump: ending media file
xfsdump: media file size 1841175648 bytes
xfsdump: dump size (non-dir files) : 1807045000 bytes
xfsdump: dump complete: 55 seconds elapsed
xfsdump: Dump Status: SUCCESS
xfsrestore: restore complete: 55 seconds elapsed
xfsrestore: Restore Status: SUCCESS
```
Заходим в окружение chroot нового корня:
```bash 
root@lvm:~\[root@lvm ~]# for i in `ls initramfs-*img`; do dracut -v $i `echo $i|sed "s/initramfs-//g;
; s/.img//g"` --force; done
root@lvm:~\[root@lvm ~]# chroot /mnt/
```
Запишем новый загрузчик:
```bash 
[root@lvm /]# grub2-mkconfig -o /boot/grub2/grub.cfg 
Generating grub configuration file ...
Found linux image: /boot/vmlinuz-3.10.0-1160.90.1.el7.x86_64
Found initrd image: /boot/initramfs-3.10.0-1160.90.1.el7.x86_64.img
Found linux image: /boot/vmlinuz-3.10.0-1160.el7.x86_64
Found initrd image: /boot/initramfs-3.10.0-1160.el7.x86_64.img
Found linux image: /boot/vmlinuz-0-rescue-03cd44dbe759f841bae73f303352c92e
Found initrd image: /boot/initramfs-0-rescue-03cd44dbe759f841bae73f303352c92e.img
done
```
Обновляем образы загрузки:
```bash 
root@lvm:/\[root@lvm /]# cd /boot ; for i in `ls initramfs-*img`; do dracut -v $i `echo $i|sed "s/initramfs-//g 
; s/.img//g"` --force; done
Kernel version 0-rescue-03cd44dbe759f841bae73f303352c92e has no module directory /lib/modules/0-rescue-03cd44dbe759f841bae73f303352c92e
Executing: /sbin/dracut -v initramfs-0-rescue-03cd44dbe759f841bae73f303352c92e.img 0-rescue-03cd44dbe759f841bae73f303352c92e --force
dracut module 'modsign' will not be installed, because command 'keyctl' could not be found!
dracut module 'busybox' will not be installed, because command 'busybox' could not be found!
dracut module 'crypt' will not be installed, because command 'cryptsetup' could not be found!
dracut module 'dmraid' will not be installed, because command 'dmraid' could not be found!
...
*** Resolving executable dependencies ***
*** Resolving executable dependencies done***
*** Hardlinking files ***
*** Hardlinking files done ***
*** Stripping files ***
*** Stripping files done ***
*** Generating early-microcode cpio image contents ***
*** Constructing GenuineIntel.bin ****
*** Store current command line parameters ***
*** Creating image file ***
*** Creating microcode section ***
*** Created microcode section ***
*** Creating image file done ***
*** Creating initramfs image file '/boot/initramfs-3.10.0-1160.el7.x86_64kdump.img' done ***
```
создаем на двух свободных дисках зеркальный том для /var
```bash 
root@lvm:/boot\[root@lvm boot]# pvcreate /dev/sdc /dev/sdd
  Physical volume "/dev/sdc" successfully created.
  Physical volume "/dev/sdd" successfully created.

root@lvm:/boot\[root@lvm boot]# vgcreate v_var /dev/sdc /dev/sdd
  Volume group "v_var" successfully created

root@lvm:/boot\[root@lvm boot]# lvcreayte -L 950M -m1 -n l_var v_var
  Rounding up size to full physical extent 952.00 MiB
  Logical volume "l_var" created.

root@lvm:/boot\[root@lvm boot]# lsblk
NAME                         MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda                            8:0    0 14.7G  0 disk 
├─sda1                         8:1    0    1G  0 part /boot
└─sda2                         8:2    0 13.7G  0 part 
  ├─centos_otus--dnik01-swap 253:1    0  1.5G  0 lvm  [SWAP]
  └─centos_otus--dnik01-root 253:2    0    8G  0 lvm  /
sdb                            8:16   0   10G  0 disk 
└─v_root-l_root              253:0    0   10G  0 lvm  
sdc                            8:32   0    2G  0 disk 
├─v_var-l_var_rmeta_0        253:3    0    4M  0 lvm  
│ └─v_var-l_var              253:7    0  952M  0 lvm  
└─v_var-l_var_rimage_0       253:4    0  952M  0 lvm  
  └─v_var-l_var              253:7    0  952M  0 lvm  
sdd                            8:48   0    1G  0 disk 
├─v_var-l_var_rmeta_1        253:5    0    4M  0 lvm  
│ └─v_var-l_var              253:7    0  952M  0 lvm  
└─v_var-l_var_rimage_1       253:6    0  952M  0 lvm  
  └─v_var-l_var              253:7    0  952M  0 lvm  
sde                            8:64   0    1G  0 disk 
sdf                            8:80   0    2G  0 disk 
```
Создаем на томе файловую систему ext4

```bash
[root@lvm boot]# mkfs.ext4 /dev/v_var/l_var 
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

Allocating group tables: 0/8   done                            
Writing inode tables: 0/8   done                            
Creating journal (4096 blocks): done
Writing superblocks and filesystem accounting information: 0/8   done
```
Монтируем зеркальный том в каталог **/mnt** и копируем туда каталог **/var**
```bash
root@lvm:/boot\[root@lvm boot]# mount /dev/v_var/l_var /mnt/

root@lvm:/boot\[root@lvm boot]# rsync -avHPSAX /var/ /mnt/
```
Сохраняем содержимое сторого каталога /var

```bash
root@lvm:/boot\[root@lvm boot]# mkdir /tmp/oldvar

root@lvm:/boot\[root@lvm boot]# mv /var/*n /tmp/oldvar/
```
Размонтируем том из каталога **/mnt** и монтируем его в каталог **/var**

```bash
root@lvm:/boot\[root@lvm boot]# umount /mnt

root@lvm:/boot\[root@lvm boot]# mount /dev/v_root/var/l_var /var

```
Правим файл **fstab.cfg** для автоматического монтирования каталога **/var**

```bash
root@lvm:/boot\[root@lvm boot]# echo "`blkid | grep var: | awk '{print$2}'` /var ext4 defaults 0 0" >> /etc/fstab
```
Открываем конфигурационный файл grub.cfg и меняем **rd.lvm.lv=v_root/l_root** на **rd.lvm.lv=centos_otus-dnik01/root** 
```bash 
root@lvm:/boot\[root@lvm boot]# vi /etc/fstab 
  ```bash 
  # /etc/fstab
  # Created by anaconda on Wed Jun 14 20:09:38 2023
  #
  # Accessible filesystems, by reference, are maintained under '/dev/disk'
  # See man pages fstab(5), findfs(8), mount(8) and/or blkid(8) for more info
  #
  /dev/mapper/centos_otus--dnik01-root /[23Cxfs     defaults[8C0 0
  UUID=049f2be2-5dc9-4983-bf92-4592430245e1 /boot[19Cxfs     defaults[8C0 0
  /dev/mapper/centos_otus--dnik01-swap swap[20Cswap    defaults[8C0 0
  #VAGRANT-BEGIN
  # The contents below are automatically generated by Vagrant. Do not modify.
  #VAGRANT-END
  UUID="441485bf-1287-4129-b248-28938c774697" /var ext4 defaults 0 0
  ```
```
Выходим из режима chroot и перегружаемся
```bash                                                                                      
[root@lvm:/boot\[root@lvm boot]# exit
root@lvm:~\[root@lvm ~]# reboot
```
Заходим в машину после загрузки
```bash
$ vagrant ssh
Connection to 127.0.0.1 closed by remote host.

Connection to 127.0.0.1 closed.
```
Проверяем подключение томов, удаляем временный том
```bash
vagrant@lvm:~\[vagrant@lvm ~]$ sudo -i
root@lvm:~\[root@lvm ~]# lsblk
NAME                         MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda                            8:0    0 14.7G  0 disk 
├─sda1                         8:1    0    1G  0 part /boot
└─sda2                         8:2    0 13.7G  0 part 
  ├─centos_otus--dnik01-root 253:0    0    8G  0 lvm  /
  └─centos_otus--dnik01-swap 253:1    0  1.5G  0 lvm  [SWAP]
sdb                            8:16   0   10G  0 disk 
└─v_root-l_root              253:2    0   10G  0 lvm  
sdc                            8:32   0    2G  0 disk 
├─v_var-l_var_rmeta_0        253:3    0    4M  0 lvm  
│ └─v_var-l_var              253:7    0  952M  0 lvm  /var
└─v_var-l_var_rimage_0       253:4    0  952M  0 lvm  
  └─v_var-l_var              253:7    0  952M  0 lvm  /var
sdd                            8:48   0    1G  0 disk 
├─v_var-l_var_rmeta_1        253:5    0    4M  0 lvm  
│ └─v_var-l_var              253:7    0  952M  0 lvm  /var
└─v_var-l_var_rimage_1       253:6    0  952M  0 lvm  
  └─v_var-l_var              253:7    0  952M  0 lvm  /var
sde                            8:64   0    1G  0 disk 
sdf                            8:80   0    2G  0 disk 
root@lvm:~\[root@lvm ~]# lvremove /dev/vg_root/l_root 
Do you really want to remove active logical volume v_root/l_root? [y/n]: y
  Logical volume "l_root" successfully removed
root@lvm:~\[root@lvm ~]# vgremove /dev/v_root
  Volume group "v_root" successfully removed
[root@lvm ~]# pvremove /dev/sdb
  Labels on physical volume "/dev/sdb" successfully wiped.
```
Создаем временный том для переноса раздела /home
```bash
root@lvm:~\[root@lvm ~]# lvcreate -n l_home -L 2G /dev/centos_otus-dnik01/root 
  Volume group name expected (no slash)
  Run `lvcreate --help' for more information.
root@lvm:~\[root@lvm ~]# lvcreate -n l_home -L 2G /dev/centos_otus-dnik01/root 
Logical volume "l_home" created.
```
Создаем на томе файловую систему и cмонтируем ее в /mnt
```bash   
root@lvm:~\[root@lvm ~]# mkfs.xfs /dev/centos_otus-dnik01/l_home 
meta-data=/dev/centos_otus-dnik01/l_home isize=512    agcount=4, agsize=131072 blks
         =                       sectsz=512   attr=2, projid32bit=1
         =                       crc=1        finobt=0, sparse=0
data     =                       bsize=4096   blocks=524288, imaxpct=25
         =                       sunit=0      swidth=0 blks
naming   =version 2              bsize=4096   ascii-ci=0 ftype=1
log      =internal log           bsize=4096   blocks=2560, version=2
         =                       sectsz=512   sunit=0 blks, lazy-count=1
realtime =none                   extsz=4096   blocks=0, rtextents=0
root@lvm:~\[root@lvm ~]# mount /dev/centos_otus-dnik01/l_home /mnt
```
Скопируем содержимое текущего раздела /home в наш новый:
```bash
root@lvm:~\[root@lvm ~]# cp -aR /home/* /mnt/
root@lvm:~\[root@lvm ~]# rm -rf /home/*
root@lvm:~\[root@lvm ~]# umount /mnt
```
Cмонтируем новый раздел /home 
```bash
root@lvm:~\[root@lvm ~]# mount  /dev/centos_otus-dnik01/l_home /home/
```
Правим файл **fstab** для правильного монтирования раздела /home при следующей загрузке
```bash
root@lvm:~\[root@lvm ~]# echo "`blkid | grep var: | awk '{print $2}'` /var ext4 defaults 0 0" >> /etc/fstab
root@lvm:~\[root@lvm ~]# vi /etc/fstab 
  # /etc/fstab
  # Created by anaconda on Wed Jun 14 20:09:38 2023
  #
  # Accessible filesystems, by reference, are maintained under '/dev/disk'
  # See man pages fstab(5), findfs(8), mount(8) and/or blkid(8) for more info
  #
  /dev/mapper/centos_otus--dnik01-root /[23Cxfs     defaults[8C0 0
  UUID=049f2be2-5dc9-4983-bf92-4592430245e1 /boot[19Cxfs     defaults[8C0 0
  /dev/mapper/centos_otus--dnik01-swap swap[20Cswap    defaults[8C0 0
  #VAGRANT-BEGIN
  # The contents below are automatically generated by Vagrant. Do not modify.
  #VAGRANT-END
  UUID="441485bf-1287-4129-b248-28938c774697" /var ext4 defaults 0 0
  UUID="5a19c3a6-6014-4d92-a4d6-42e310f1c22b" /home xfs defaults 0 0
```
сгенерируем файлы в **/home** для тестирования восстановления
```bash
root@lvm:~\[root@lvm ~]# touch /home/file{1..20}
root@lvm:~\[root@lvm ~]# ls /home
file1   file11  file13  file15  file17  file19  file20  file4  file6  file8  vagrant
file10  file12  file14  file16  file18  file2   file3   file5  file7  file9
```
создаем снапшот
```bash
root@lvm:~\[root@lvm ~]# lvcreate -L 100Mb -s -n home_snap /dev/centos_otus-dnik01/l_home
  Logical volume "home_snap" created.
```
Тестово удаляем несколько файлов
```bash
root@lvm:~\[root@lvm ~]# rm -f /home/file{11..20}
root@lvm:~\[root@lvm ~]# ls /home
file1  file10  file2  file3  file4  file5  file6  file7  file8  file9  vagrant
```
восстанавливаем удаленные файлы из снашота
```bash
root@lvm:~\[root@lvm ~]# umount /home
root@lvm:~\[root@lvm ~]# lvconvert --merge /deb/centos_otus-dnik01/home_snap 
  Merging of volume centos_otus-dnik01/home_snap started.
  centos_otus-dnik01/l_home: Merged: 100.00%
root@lvm:~\[root@lvm ~]# mount /home/
```
проверяем что файлы восстановились
```bash
root@lvm:~\[root@lvm ~]# ls /home/
file1   file11  file13  file15  file17  file19  file20  file4  file6  file8  vagrant
file10  file12  file14  file16  file18  file2   file3   file5  file7  file9

root@lvm:~\[root@lvm ~]# exit
```

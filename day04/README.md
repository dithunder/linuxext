Домашнее задание 4. Практические навыки работы с ZFS

Что нужно сделать?

- Определить алгоритм с наилучшим сжатием.
- Зачем: отрабатываем навыки работы с созданием томов и установкой параметров. Находим наилучшее сжатие.
- Шаги:
- определить какие алгоритмы сжатия поддерживает zfs (gzip gzip-N, zle lzjb, lz4);
- создать 4 файловых системы на каждой применить свой алгоритм сжатия;
- Для сжатия использовать либо текстовый файл либо группу файлов:
скачать файл “Война и мир” и расположить на файловой системе wget -O War_and_Peace.txt http://www.gutenberg.org/ebooks/2600.txt.utf-8, либо скачать файл ядра распаковать и расположить на файловой системе.
Результат:
- список команд которыми получен результат с их выводами;
- вывод команды из которой видно какой из алгоритмов лучше.
- Определить настройки pool’a.
Зачем: 
- для переноса дисков между системами используется функция export/import. Отрабатываем навыки работы с файловой системой ZFS.
Шаги:
- загрузить архив с файлами локально. https://drive.google.com/open?id=1KRBNW33QWqbvbVHa3hLJivOAt60yukkg
- Распаковать.
- с помощью команды zfs import собрать pool ZFS;
- командами zfs определить настройки:
- размер хранилища;
- тип pool;
- значение recordsize;
- какое сжатие используется;
- какая контрольная сумма используется.
Результат:
- список команд которыми восстановили pool. Желательно с Output команд;
- файл с описанием настроек settings.

Найти сообщение от преподавателей.
Зачем: 
- для бэкапа используются технологии snapshot. Snapshot можно передавать между хостами и восстанавливать с помощью send/receive. Отрабатываем навыки восстановления snapshot и переноса файла.
Шаги:
- скопировать файл из удаленной директории. https://drive.google.com/file/d/1gH8gCL9y7Nd5Ti3IRmplZPF1XjzxeRAG/view?usp=sharing
- Файл был получен командой zfs send otus/storage@task2 > otus_task2.file
- восстановить файл локально. zfs receive
- найти зашифрованное сообщение в файле secret_message
Результат:
- список шагов которыми восстанавливали;
- зашифрованное сообщение.
  
```bash
Хостовая машина Debian 11.
Установлены: 
- Vagrant 2.3.4
- VirtualBox 6.1.44
- Packer 1.6.6.
- Ansible 2.10.1
```
- Для практических работ использую свой образ и свой Vagrantfile
- Для проверки необходимо из директории day04 выполнить:

```bash
$ vagrant up 
$ vagrant ssh
Last login: Mon Jun 19 07:40:06 2023 from 10.0.2.2
```
**1. Определение алгоритма с наилучшим сжатием**
- Смотрим список всех блочных устройств
```bash
vagrant@zfs:~\[vagrant@zfs ~]$ sudo -i
root@zfs:~\[root@zfs ~]# lsblk -f
NAME                      FSTYPE      LABEL UUID                                   MOUNTPOINT
sda                                                                                
├─sda1                    xfs               049f2be2-5dc9-4983-bf92-4592430245e1   /boot
└─sda2                    LVM2_member       9X2tcs-Zr89-jisU-wbbQ-gd2l-7hGG-znVDjy 
  ├─centos_otus--dnik01-root
                          xfs               de6b5177-6130-4467-b1ca-314099dbb889   /
  └─centos_otus--dnik01-swap
                          swap              e65b6e53-7282-446b-a441-9171023d2b9d   [SWAP]
sdb                                                                                
sdc                                                                                
sdd                                                                                
sde                                                                                
sdf                                                                                
sdg                                                                                
sdh                                                                                
sdi                                                                                
```
Создаем 4 пула в режиме RAID1
```bash
root@zfs:~\[root@zfs ~]# zpool create otus1 mirror /dev/sdb /dev/sdc
root@zfs:~\[root@zfs ~]# zpool create otus2 mirror /dev/sdd /dev/sde
root@zfs:~\[root@zfs ~]# zpool create otus3 mirror /dev/sdf /dev/sdg
root@zfs:~\[root@zfs ~]# zpool create otus4 mirror /dev/sdh /dev/sdi
root@zfs:~\[root@zfs ~]# zpool list
NAME    SIZE  ALLOC   FREE  CKPOINT  EXPANDSZ   FRAG    CAP  DEDUP    HEALTH  ALTROOT
otus1   480M   102K   480M        -         -     0%     0%  1.00x    ONLINE  -
otus2   480M  91.5K   480M        -         -     0%     0%  1.00x    ONLINE  -
otus3   480M   106K   480M        -         -     0%     0%  1.00x    ONLINE  -
otus4   480M   114K   480M        -         -     0%     0%  1.00x    ONLINE  -
```
Задаем разные режимы компрессии для пулов
```bash
root@zfs:~\[root@zfs ~]# zfs set compression=lzjb otus1
root@zfs:~\[root@zfs ~]# zfs set compression=lzjb otus2
root@zfs:~\[root@zfs ~]# zfs set compression=lz4 otus3
root@zfs:~\[root@zfs ~]# zfs set compression=gzip-9 otus4
```
Закачиваем файлик для проверки во все пулы
```bash
root@zfs:~\[root@zfs ~]# for i in {1..4}; do wget -P /otus$i https://gutenberg.org/cache/epub/2600/pg2600.converter.log; done
--2023-06-19 07:53:46--  https://gutenberg.org/cache/epub/2600/pg2600.converter.log
Resolving gutenberg.org (gutenberg.org)... 152.19.134.47, 2610:28:3090:3000:0:bad:cafe:47
Connecting to gutenberg.org (gutenberg.org)|152.19.134.47|:443... connected.
HTTP request sent, awaiting response... 200 OK
Length: 40941287 (39M) [text/plain]
Saving to: ‘/otus1/pg2600.converter.log’
 0% [                                                    ] 0           --.-K/s              
 0% [                                                    ] 104,379      360KB/s             
 1% [                                                    ] 441,311      775KB/s             
...
99% [==================================================> ] 40,713,183  5.56MB/s  eta 1s     
100%[===================================================>] 40,941,287  5.57MB/s   in 7.9s   

2023-06-19 07:53:55 (4.94 MB/s) - ‘/otus1/pg2600.converter.log’ saved [40941287/40941287]

--2023-06-19 07:53:55--  https://gutenberg.org/cache/epub/2600/pg2600.converter.log
Resolving gutenberg.org (gutenberg.org)... 152.19.134.47, 2610:28:3090:3000:0:bad:cafe:47
Connecting to gutenberg.org (gutenberg.org)|152.19.134.47|:443... connected.
HTTP request sent, awaiting response... 200 OK
Length: 40941287 (39M) [text/plain]
Saving to: ‘/otus2/pg2600.converter.log’Определение настроек пула

 0% [                                                    ] 0           --.-K/s              
 0% [                                                    ] 44,057       155KB/s             
...
99% [==================================================> ] 40,666,833  5.54MB/s  eta 1s     
100%[===================================================>] 40,941,287  5.52MB/s   in 7.3s   

2023-06-19 07:54:03 (5.33 MB/s) - ‘/otus2/pg2600.converter.log’ saved [40941287/40941287]

--2023-06-19 07:54:03--  https://gutenberg.org/cache/epub/2600/pg2600.converter.log
Resolving gutenberg.org (gutenberg.org)... 152.19.134.47, 2610:28:3090:3000:0:bad:cafe:47
Connecting to gutenberg.org (gutenberg.org)|152.19.134.47|:443... connected.
HTTP request sent, awaiting response... 200 OK
Length: 40941287 (39M) [text/plain]
Saving to: ‘/otus3/pg2600.converter.log’

 0% [                                                    ] 0           --.-K/s              
 0% [                                                    ] 44,035       149KB/s             
...
99% [==================================================> ] 40,847,111  4.00MB/s  eta 3s     
100%[===================================================>] 40,941,287  4.00MB/s   in 10s    

2023-06-19 07:54:14 (3.88 MB/s) - ‘/otus3/pg2600.converter.log’ saved [40941287/40941287]

--2023-06-19 07:54:14--  https://gutenberg.org/cache/epub/2600/pg2600.converter.log
Resolving gutenberg.org (gutenberg.org)... 152.19.134.47, 2610:28:3090:3000:0:bad:cafe:47
Connecting to gutenberg.org (gutenberg.org)|152.19.134.47|:443... connected.
HTTP request sent, awaiting response... 200 OK
Length: 40941287 (39M) [text/plain]
Saving to: ‘/otus4/pg2600.converter.log’

 0% [                                                    ] 0           --.-K/s              
 0% [                                                    ] 44,057       144KB/s             
...
99% [==================================================> ] 40,535,761  3.84MB/s  eta 1s     
100%[===================================================>] 40,941,287  3.90MB/s   in 16s    

2023-06-19 07:54:30 (2.49 MB/s) - ‘/otus4/pg2600.converter.log’ saved [40941287/40941287]
```
Просмотрим созданные файлы и их параметры
```bash
root@zfs:~\[root@zfs ~]# ls -l /otus*
/otus1:
total 22050
-rw-r--r--. 1 root root 40941287 Jun  2 04:18 pg2600.converter.log

/otus2:
total 17986
-rw-r--r--. 1 root root 40941287 Jun  2 04:18 pg2600.converter.log

/otus3:
total 10956
-rw-r--r--. 1 root root 40941287 Jun  2 04:18 pg2600.converter.log

/otus4:
total 40010
-rw-r--r--. 1 root root 40941287 Jun  2 04:18 pg2600.converter.log
```
Как видим размер их одинаков, но из-за разной степени компрессии - занимают разный объем. Следующая команда просмотра занятости на пулах это наглядно показывает
```bash
root@zfs:~\[root@zfs ~]# zfs list
NAME    USED  AVAIL     REFER  MOUNTPOINT
otus1  21.6M   330M     21.6M  /otus1
otus2  17.7M   334M     17.6M  /otus2
otus3  10.8M   341M     10.7M  /otus3
otus4  39.2M   313M     39.1M  /otus4
```
Максимальное сжатие получилось с алгоритмом gzip-9 на пуле otus3 
```bash
root@zfs:~\[root@zfs ~]# zfs get all | grep compressratio | grep -v ref
otus1  compressratio         1.81x                  -
otus2  compressratio         2.22x                  -
otus3  compressratio         3.65x                  -
otus4  compressratio         1.00x                  -
```
**2. Определение настроек пула**
- Теперь посмотрим на параметры пулов. Скачиваем и распаковываем в домашнем каталоге архив
```bash
root@zfs:~\[root@zfs ~]# wget -O archive.tar.gz --no-check-certificate 'https://drive.google.com/u/0/uc? 
id=1KRBNW33QWqbvbVHa3hLJivOAt60yukkg&export=download'
--2023-06-19 07:58:32--  https://drive.google.com/u/0/uc?id=1KRBNW33QWqbvbVHa3hLJivOAt60yukkg&export=download
Resolving drive.google.com (drive.google.com)... 108.177.14.194, 2a00:1450:4010:c08::c2
Connecting to drive.google.com (drive.google.com)|108.177.14.194|:443... connected.
HTTP request sent, awaiting response... 302 Found
Location: https://drive.google.com/uc?id=1KRBNW33QWqbvbVHa3hLJivOAt60yukkg&export=download [following]
--2023-06-19 07:58:32--  https://drive.google.com/uc?id=1KRBNW33QWqbvbVHa3hLJivOAt60yukkg&export=download
Reusing existing connection to drive.google.com:443.
HTTP request sent, awaiting response... 303 See Other
Location: https://doc-0c-bo-docs.googleusercontent.com/docs/securesc/ha0ro937gcuc7l7deffksulhg5h7mbp1/74pmlduo034l8c35h1f9a24tapmva9c8/1687175850000/16189157874053420687/*/1KRBNW33QWqbvbVHa3hLJivOAt60yukkg?e=download&uuid=bbd0e239-4389-4d66-a4f4-f6681ee1ceb4 [following]
Warning: wildcards not supported in HTTP.
--2023-06-19 07:58:39--  https://doc-0c-bo-docs.googleusercontent.com/docs/securesc/ha0ro937gcuc7l7deffksulhg5h7mbp1/74pmlduo034l8c35h1f9a24tapmva9c8/1687175850000/16189157874053420687/*/1KRBNW33QWqbvbVHa3hLJivOAt60yukkg?e=download&uuid=bbd0e239-4389-4d66-a4f4-f6681ee1ceb4
Resolving doc-0c-bo-docs.googleusercontent.com (doc-0c-bo-docs.googleusercontent.com)... 64.233.164.132, 2a00:1450:4010:c07::84
Connecting to doc-0c-bo-docs.googleusercontent.com (doc-0c-bo-docs.googleusercontent.com)|64.233.164.132|:443... connected.
HTTP request sent, awaiting response... 200 OK
Length: 7275140 (6.9M) [application/x-gzip]
Saving to: ‘archive.tar.gz’

 0% [                                                    ] 0           --.-K/s              
15% [=======>                                            ] 1,150,466   5.45MB/s             
40% [===================>                                ] 2,936,057   6.97MB/s             
67% [==================================>                 ] 4,901,845   7.77MB/s             
91% [==============================================>     ] 6,660,034   7.92MB/s             
100%[===================================================>] 7,275,140   7.98MB/s   in 0.9s   

2023-06-19 07:58:40 (7.98 MB/s) - ‘archive.tar.gz’ saved [7275140/7275140]

root@zfs:~\[root@zfs ~]# ls
anaconda-ks.cfg  archive.tar.gz  original-ks.cfg  post_install.log
root@zfs:~\[root@zfs ~]# tar -xzvf archive.tar.gz 
zpoolexport/
zpoolexport/filea
zpoolexport/fileb
```
Проверяем возможность импорта данного каталога в пул
```bash

root@zfs:~\[root@zfs ~]# zpool import -d zpoolexport/
   pool: otus
     id: 6554193320433390805
  state: ONLINE
 action: The pool can be imported using its name or numeric identifier.
 config:

	otus                         ONLINE
	  mirror-0                   ONLINE
	    /root/zpoolexport/filea  ONLINE
	    /root/zpoolexport/fileb  ONLINE
```
Импортируем пул
```bash		
root@zfs:~\[root@zfs ~]# zpool import -d zpoolexport/ otus
root@zfs:~\[root@zfs ~]# zpool status otus
  pool: otus
 state: ONLINE
  scan: none requested
config:

	NAME                         STATE     READ WRITE CKSUM
	otus                         ONLINE       0     0     0
	  mirror-0                   ONLINE       0     0     0
	    /root/zpoolexport/filea  ONLINE       0     0     0
	    /root/zpoolexport/fileb  ONLINE       0     0     0

errors: No known data errors
```
Можно узнать все параметры файловой системы пула
```bash	
root@zfs:~\[root@zfs ~]# zpool get all otus
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
otus  dedupditto                     0                              default
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
otus  load_guid                      12588550499684231227           -
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
```
С помощью **get** можно узнать определенные параметры
```bash	
root@zfs:~\[root@zfs ~]# zfs get available otus
NAME  PROPERTY   VALUE  SOURCE
otus  available  350M   -
root@zfs:~\[root@zfs ~]# zfs get readonly otus
NAME  PROPERTY  VALUE   SOURCE
otus  readonly  off     default
root@zfs:~\[root@zfs ~]# zfs get recordsize otus
NAME  PROPERTY    VALUE    SOURCE
otus  recordsize  128K     local
root@zfs:~\[root@zfs ~]# zfs get compression otus
NAME  PROPERTY     VALUE     SOURCE
otus  compression  zle       local
root@zfs:~\[root@zfs ~]# zfs get shecksum otus
NAME  PROPERTY  VALUE      SOURCE
otus  checksum  sha256     local
```
**3. Работа со снапшотом, поиск сообщения от преподавателя**
- Скачаем файл, указанный в задании:
```bash	
root@zfs:~\[root@zfs ~]# wget -O otus_task2.file --no-check-certificate "https://drive.google.com/u/0/uc 
?id=1gH8gCL9y7Nd5Ti3IRmplZPF1XjzxeRAG&export=download"
--2023-06-19 08:10:59--  https://drive.google.com/u/0/uc?id=1gH8gCL9y7Nd5Ti3IRmplZPF1XjzxeRAG&export=download
Resolving drive.google.com (drive.google.com)... 64.233.165.194, 2a00:1450:4010:c08::c2
Connecting to drive.google.com (drive.google.com)|64.233.165.194|:443... connected.
HTTP request sent, awaiting response... 302 Found
Location: https://drive.google.com/uc?id=1gH8gCL9y7Nd5Ti3IRmplZPF1XjzxeRAG&export=download [following]
--2023-06-19 08:10:59--  https://drive.google.com/uc?id=1gH8gCL9y7Nd5Ti3IRmplZPF1XjzxeRAG&export=download
Reusing existing connection to drive.google.com:443.
HTTP request sent, awaiting response... 303 See Other
Location: https://doc-00-bo-docs.googleusercontent.com/docs/securesc/ha0ro937gcuc7l7deffksulhg5h7mbp1/o1v0jmqcslch6al8aq7n092u5uqj8du4/1687176600000/16189157874053420687/*/1gH8gCL9y7Nd5Ti3IRmplZPF1XjzxeRAG?e=download&uuid=d8c42182-df1c-48fb-9859-5035802e9ba8 [following]
Warning: wildcards not supported in HTTP.
--2023-06-19 08:11:06--  https://doc-00-bo-docs.googleusercontent.com/docs/securesc/ha0ro937gcuc7l7deffksulhg5h7mbp1/o1v0jmqcslch6al8aq7n092u5uqj8du4/1687176600000/16189157874053420687/*/1gH8gCL9y7Nd5Ti3IRmplZPF1XjzxeRAG?e=download&uuid=d8c42182-df1c-48fb-9859-5035802e9ba8
Resolving doc-00-bo-docs.googleusercontent.com (doc-00-bo-docs.googleusercontent.com)... 64.233.164.132, 2a00:1450:4010:c07::84
Connecting to doc-00-bo-docs.googleusercontent.com (doc-00-bo-docs.googleusercontent.com)|64.233.164.132|:443... connected.
HTTP request sent, awaiting response... 200 OK
Length: 5432736 (5.2M) [application/octet-stream]
Saving to: ‘otus_task2.file’

 0% [                                                    ] 0           --.-K/s              
24% [===========>                                        ] 1,347,059   6.38MB/s             
57% [============================>                       ] 3,099,879   7.36MB/s             
85% [===========================================>        ] 4,656,144   7.38MB/s             
100%[===================================================>] 5,432,736   7.36MB/s   in 0.7s   

2023-06-19 08:11:07 (7.36 MB/s) - ‘otus_task2.file’ saved [5432736/5432736]

root@zfs:~\[root@zfs ~]# ls otus_task2.file -la
-rw-r--r--. 1 root root 5432736 Jun 19 08:11 otus_task2.file
```	
Восстановим файловую систему из снапшота: 
```bash	
root@zfs:~\[root@zfs ~]# zfs receive otus/test@today < otus_task2.file
```	
ищем серетное сообщение от преподавателя 
```bash	
root@zfs:~\[root@zfs ~]# find /otus/test -name "secret_message"
/otus/test/task1/file_mess/secret_message
```	
Смотрим секретное сообщение 
```bash	
root@zfs:~\[root@zfs ~]# cat /otus/test/task1/file_mess/secret_message
```	
В нем ссылка на гитхаб 
```bash	
https://github.com/sindresorhus/awesome
```	
Просматриваем размещенное по ссылке. И выходим из машины 
```bash	
root@zfs:~\[root@zfs ~]# exit
logout
vagrant@zfs:~\[vagrant@zfs ~]$ exit
logout
Connection to 127.0.0.1 closed.
```	

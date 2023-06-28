Домашнее задание 5. Стенд Vagrant с NFS 
## Цель домашнего задания 
- Научиться самостоятельно развернуть сервис NFS и подключить к нему клиента 
## Описание домашнего задания 
Основная часть: 
- `vagrant up` должен поднимать 2 настроенных виртуальных машины (сервер NFS и клиента) без дополнительных ручных действий; - на сервере NFS должна быть подготовлена и экспортирована директория; 
- в экспортированной директории должна быть поддиректория с именем __upload__ с правами на запись в неё; 
- экспортированная директория должна автоматически монтироваться на клиенте при старте виртуальной машины (systemd, autofs или fstab -  любым способом); 
- монтирование и работа NFS на клиенте должна быть организована с использованием NFSv3 по протоколу UDP; 
- firewall должен быть включен и настроен как на клиенте, так и на сервере. 
Для самостоятельной реализации: 
- настроить аутентификацию через KERBEROS с использованием NFSv4. ## 

```bash
Хостовая машина Debian 11.
Установлены: 
- Vagrant 2.3.4
- VirtualBox 6.1.44
- Packer 1.6.6.
- Ansible 2.10.1
```
- Для практических работ использую свой образ
- Запускаем vagrant из директории day05:

```bash
$ vagrant up 
```
Заходим в сервер nfss, поднимаем себе права
```bash
$ vagrant ssh nfss
Last login: Wed Jun 28 08:11:40 2023 from 10.0.2.2

vagrant@nfscs:~\[vagrant@nfss ~]$ sudo -i
```
Добавляем утилиты (они у нас уже проинсталлированы)
```bash
root@nfss:~\[root@nfss ~]# yum install nfs-utils 
Загружены модули: fastestmirror
Loading mirror speeds from cached hostfile
 * base: mirror.surf
 * epel: mirror.yandex.ru
 * extras: mirrors.datahouse.ru
 * updates: mirror.corbina.net
Пакет 1:nfs-utils-1.3.0-0.68.el7.2.x86_64 уже установлен, и это последняя версия.
Выполнять нечего
```
Включаем firewall и проверяем, что он работает
```bash
root@nfss:~\[root@nfss ~]# systemctl enable firewalld --now
root@nfss:~\[root@nfss ~]# systemctl status firewalld
 firewalld.service - firewalld - dynamic firewall daemon
   Loaded: loaded (/usr/lib/systemd/system/firewalld.service; enabled; vendor preset: enabled)
   Active: mactive (running)[0m since Ср 2023-06-28 08:08:12 EDT; 1h 26min ago
     Docs: man:firewalld(1)
 Main PID: 14968 (firewalld)
   CGroup: /system.slice/firewalld.service
           └─14968 /usr/bin/python2 -Es /usr/sbin/firewalld --nofork --nopid

июн 28 08:08:11 nfss systemd[1]: Starting firewalld - dynamic firewall d.....
июн 28 08:08:12 nfss systemd[1]: Started firewalld - dynamic firewall daemon.
июн 28 08:08:12 nfss firewalld[14968]: WARNING: AllowZoneDrifting is enab....[0m
июн 28 08:08:13 nfss firewalld[14968]: WARNING: ip6tables not usable, dis....[0m
июн 28 08:08:14 nfss firewalld[14968]: WARNING: AllowZoneDrifting is enab....[0m
Hint: Some lines were ellipsized, use -l to show in full.
```
Разрешаем в firewall доступ к сервисам NFS

```bash
root@nfss:~\[root@nfss ~]# firewall-cmd --add-service="nfs3" --add-service="rpc-bind" --add-service="mountd" --permanent
Warning: ALREADY_ENABLED: nfs3
Warning: ALREADY_ENABLED: rpc-bind
Warning: ALREADY_ENABLED: mountd
success
root@nfss:~\[root@nfss ~]# firewall-cmd --reload
success
```
Включаем сервер NFS (NFS3 over UDP не требует дополнительной настройки)
```bash
root@nfss:~\[root@nfss ~]# systemctl enable nfs --now 

```
Проверяем наличие слушаемых портов для nfs
```bash
root@nfss:~\[root@nfss ~]# ss -tnplu | grep 111
udp    UNCONN     0      0         *:111                  *:*                   users:(("rpcbind",pid=15556,fd=6))
tcp    LISTEN     0      128       *:111                  *:*                   users:(("rpcbind",pid=15556,fd=8))
root@nfss:~\[root@nfss ~]# ss -tnplu | grep 2049
udp    UNCONN     0      0         *:2049                 *:*                  
tcp    LISTEN     0      64        *:2049                 *:*                  
root@nfss:~\[root@nfss ~]# ss -tnplu | grep 20048
udp    UNCONN     0      0         *:20048                *:*                   users:(("rpc.mountd",pid=15595,fd=7))
tcp    LISTEN     0      128       *:20048                *:*                   users:(("rpc.mountd",pid=15595,fd=8))
```
Создаём и настраиваем директорию для сетевого доступа
```bash
root@nfss:~\[root@nfss ~]# mkdir -p /srv/share/upload
root@nfss:~\[root@nfss ~]# chown -R nfsnobody:nfsnobody /srv/share 
root@nfss:~\[root@nfss ~]# chmod 0777 /srv/share/upload 
```
Создаём в файле /etc/exports структуру, которая позволит экспортировать ранее созданную директорию
```bash
root@nfss:~\[root@nfss ~]# cat << EOF > /etc/exports 
> /srv/share 192.168.50.11/32(rw,sync,root_squash) 
> EOF
```
Экспортируем ранее созданную директорию
```bash
root@nfss:~\[root@nfss ~]# exportfs -r 
```
Проверяем экспортированную директорию 
```bash
root@nfss:~\[root@nfss ~]# exportfs -s 
/srv/share  192.168.50.11/32(sync,wdelay,hide,no_subtree_check,sec=sys,rw,secure,root_squash,no_all_squash)
```
Открываем еще одну консоль и заходим в сервер nfsc, настраиваем клиент NFS
```bash

$ vagrant ssh nfsc
Last login: Wed Jun 28 08:12:43 2023 from 10.0.2.2

vagrant@nfsc:~\[vagrant@nfsc ~]$ sudo -i
```
Добавляем утилиты (они у нас уже проинсталлированы)
```bash
root@nfsc:~\[root@nfsc ~]# yum install nfs-utils 
Загружены модули: fastestmirror
Loading mirror speeds from cached hostfile
 * base: mirror.surf
 * epel: mirror.yandex.ru
 * extras: mirrors.datahouse.ru
 * updates: mirror.corbina.net
Пакет 1:nfs-utils-1.3.0-0.68.el7.2.x86_64 уже установлен, и это последняя версия.
Выполнять нечего
```
Включаем firewall и проверяем, что он работает
```bash
root@nfsc:~\[root@nfsc ~]# systemctl enable firewalld --now
root@nfsc:~\[root@nfsc ~]# systemctl status firewalld
firewalld.service - firewalld - dynamic firewall daemon
   Loaded: loaded (/usr/lib/systemd/system/firewalld.service; enabled; vendor preset: enabled)
   Active: active (running)[0m since Ср 2023-06-28 08:11:23 EDT; 1h 35min ago
     Docs: man:firewalld(1)
 Main PID: 15622 (firewalld)
   CGroup: /system.slice/firewalld.service
           └─15622 /usr/bin/python2 -Es /usr/sbin/firewalld --nofork --nopid

июн 28 08:11:23 nfsc systemd[1]: Starting firewalld - dynamic firewall d.....
июн 28 08:11:23 nfsc systemd[1]: Started firewalld - dynamic firewall daemon.
июн 28 08:11:24 nfsc firewalld[15622]: WARNING: AllowZoneDrifting is enab....[0m
июн 28 08:11:24 nfsc firewalld[15622]: WARNING: ip6tables not usable, dis....[0m
Hint: Some lines were ellipsized, use -l to show in full.
```
- добавляем в /etc/fstab строку монтирования сетевого ресурса
```
root@nfsc:~\[root@nfsc ~]# echo "192.168.50.10:/srv/share/ /mnt nfs vers=3,proto=udp,noauto, 
x-systemd.automount 0 0" >> /etc/fstab
```
и выполняем
```bash
root@nfsc:~\[root@nfsc ~]# systemctl daemon-reload
root@nfsc:~\[root@nfsc ~]# systemctl restart remote-fs.target
```
Заходим в директорию `/mnt/` и проверяем успешность монтирования
```bash
root@nfsc:~\[root@nfsc ~]# mount | grep mnt 
systemd-1 on / type autofs (rw,relatime,fd=21,pgrp=1,timeout=0,minproto=5,maxproto=5,direct,pipe_ino=37810)
```
Заходим в директорию `/mnt/upload` создаем там файл test.txt
```bash
root@nfsc:~\[root@nfsc ~]# cd /mnt/upload
root@nfsc:/mnt/upload\[root@nfsc upload]# touch test.txt
```
Проверяем что файл создан
```bash
root@nfsc:/mnt/upload\[root@nfsc upload]# ls
test_srv.txt  test.txt
```
Заходим на сервер nfss, проверяем что файл создан
```bash
root@nfsc:~\[root@nfsc ~]# ssh nfss
vagrant@nfss:~\[vagrant@nfss ~]$ cd /srv/share/upload/

vagrant@nfss:/srv/share/upload\[vagrant@nfss upload]$ ls  ./test.txt 
test.txt
```
Перегружаем оба сервера, залогиниваемся на сервер nfss
```bash
shutdown -r
broadcast message from root@nfss (Wed 2023-06-28 10:00:28 EDT):

The system is going down for reboot at Wed 2023-06-28 10:01:28 EDT!

Connection to 127.0.0.1 closed by remote host.
Connection to 127.0.0.1 closed.

service@deb03:~/linuxext/day05$ vagrant ssh nfss
Last login: Wed Jun 28 09:31:59 2023 from 10.0.2.2
```
Создаем финальный файл для проверки final_check.txt
```bash
vagrant@nfss:~\[vagrant@nfss ~]$ cd /srv/share/upload/
vagrant@nfss:/srv/share/upload\[vagrant@nfss upload]$ touch ./final_check.txt
vagrant@nfss:/srv/share/upload\[vagrant@nfss upload]$ ls -la ./final_check.txt 
-rw-rw-r--. 1 vagrant vagrant 26 июн 28 10:03 ./final_check.txt
```
Залогиниваемся на сервер nfsс
```bash
service@deb03:~/linuxext/day05$ vagrant ssh nfsc
```
Проверяем доступность сетевого ресурса и созданного файла final_check.txt
```bash
vagrant@nfsc:/mnt/upload\[vagrant@nfsc upload]$ ls -la
итого 4
drwxrwxrwx. 2 nfsnobody nfsnobody 65 июн 28 10:03 [0m[34;42m.[0m
drwxr-xr-x. 3 nfsnobody nfsnobody 20 июн 28 08:08 [01;34m..[0m
-rw-rw-r--. 1 vagrant   vagrant   26 июн 28 10:03 final_check.txt
-rw-r--r--. 1 root      root       0 июн 28 09:56 test_srv.txt
-rw-r--r--. 1 nfsnobody nfsnobody  0 июн 28 09:53 test.txt
vagrant@nfsc:/mnt/upload\[vagrant@nfsc upload]$ exit
```
Сетевой ресурс доступен с клиента после перезагрузки, уничтожаем машины
```bash
service@deb03:~/linuxext/day05$ vagrant destroy
```

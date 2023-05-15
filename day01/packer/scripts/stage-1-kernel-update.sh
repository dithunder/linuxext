#!/bin/bash

# Установка репозитория elrepo
sudo yum install -y https://www.elrepo.org/elrepo-release-8.el8.elrepo.noarch.rpm 
# Установка нового ядра из репозитория elrepo-kernel
yum --enablerepo elrepo-kernel install kernel-ml -y

# Обновление параметров GRUB
grub2-mkconfig -o /boot/grub2/grub.cfg
grub2-set-default 0
echo "Grub update done."
# Перезагрузка ВМ
shutdown -r now
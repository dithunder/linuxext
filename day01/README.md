Домашнее задание:
1. Выполните действия, описанные в методичке.
2. Полученный в ходе выполнения ДЗ Vagrantfile залейте в ваш git-репозиторий.
3. Пришлите ссылку на него в чате для проверки ДЗ

Хостовая машина Debian 11.
Установлены: 
- Vagrant 2.3.4
- VirtualBox 6.1.44
- Packer 1.6.6.
- Ansible 2.10.1

Обновляем ядро в ручную в машине созданной из стандартного образа:
- $vi Vagrantfile
- Vagrant.configure("2") do |config|
-   config.vm.box = "centos/stream8"
- end
- :wq
- $ vagrant up
- $ vagrant ssh
- $ uname -r
- 4.18.0-489.el8.x86_64
- $ sudo yum install -y https://www.elrepo.org/elrepo-release-8.el8.elrepo.noarch.rpm
- $ sudo yum --enablerepo elrepo-kernel install kernel-ml -y
- $ sudo grub2-mkconfig -o /boot/grub2/grub.cfg
- $ sudo grub2-set-default 0
- $ sudo reboot
- $ vagrant ssh
- 6.3.2-1.el8.elrepo.x86_64
- ядро обновлено

Обнавляем ядро скриптом, упаковываем в образ, выкладываем в Vagrant облако:


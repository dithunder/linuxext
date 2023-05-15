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
- $ uname -r
- 6.3.2-1.el8.elrepo.x86_64
- ядро обновлено

Обнавляем ядро скриптом, упаковываем в образ, выкладываем в Vagrant облако:
- $ cd ~
- $ mkdir packer
- $ vi ./packer/centos.json
- заполняем centos.json, файл в репозитории
- $ mkdir ./packer/http
- $ vi ./packer/http/ks.cfg
- заполняем ks.cfg, файл в репозитории
- $ mkdir ./packer/scripts
- $ vi ./packer/scripts/stage-1-kernel-update.sh
- заполняем stage-1-kernel-update.sh файл в репозитории
- $ vi ./packer/scripts/stage-2-clean.sh
- заполняем stage-2-clean.sh файл в репозитории

Запускаем сборку
- $ cd ./packer
- $ packer build centos.json
- ждем и на выходе в директории /packer получаем файл сentos-8-kernel-6-x86_64-Minimal.box
- $ vagrant box add centos8-kernel6 centos-8-kernel-6-x86_64-Minimal.box
Создаем виртуальную машину
- $ vagrant init centos8-kernel6
- $ vagrant up
- $ vagrant ssh
- проверяем ядро
- $ uname -r
- 6.3.2-1.el8.elrepo.x86_64
- $ exit
- Удаляем ненужную виртуальную машину: 
- $ vagrant destroy --force

Загрузка образа в Vagrant cloud
- $ vagrant cloud auth login --token <token>
- $ vagrant cloud publish --release dimkan/centos8-kernel6 1.0 virtualbox centos-8-kernel-6-x86_64-Minimal.box

Загружаем файлы в git

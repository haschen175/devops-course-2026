# Конфигурация виртуальной машины devops-vm

## 1. Параметры машины
- Наименование: devops-vm
- ОС: Linux / Ubuntu Server 24.04 LTS (64-bit)
- ОЗУ: 2048 МБ
- Процессор: 2 ядра
- Диск: 25 ГБ, динамически расширяемый

## 2. Сетевые интерфейсы
- Адаптер 1 (enp0s3): NAT, адрес 10.0.2.15/24 — доступ в Интернет и проброс порта SSH.
- Адаптер 2 (enp0s8): Host-only, адрес 192.168.56.102/24 — прямой доступ с хоста к ВМ.

## 3. Правило проброса портов
- Правило: ssh (TCP), Хост: 127.0.0.1:2222 -> Гость: 2222.

## 4. Учётные записи
- student (группы: student, sudo) — первичная учётная запись, вход по SSH закрыт.
- devops (группы: devops, sudo) — основная учётная запись, вход по ключу ~/.ssh/devops_vm.

## 5. Служба SSH
- Файл конфигурации: /etc/ssh/sshd_config.d/99-hardening.conf (бэкап: /etc/ssh/sshd_config.backup)
- Директивы: Port 2222, PermitRootLogin no, PasswordAuthentication no, PubkeyAuthentication yes, PermitEmptyPasswords no, MaxAuthTries 3, LoginGraceTime 30, AllowUsers devops, X11Forwarding no, ClientAliveInterval 300, ClientAliveCountMax 2.
- Отключён ssh.socket, активирован ssh.service.

## 6. Правила межсетевого экрана
- Политики по умолчанию: deny (incoming), allow (outgoing). Логирование: medium.
- Правила: 2222/tcp (LIMIT IN), 80/tcp (ALLOW IN), 443/tcp (ALLOW IN).

## 7. Снимки состояния
- 01-clean-install — чистая ОС после установки и обновления.
- 02-keys-configured — настроен пользователь devops и вход по SSH-ключу.
- 03-ssh-hardened — выполнен харденинг SSH на порту 2222.

## 10. Ansible
- Проект: каталог ansible/ этого репозитория. Управляющий узел — WSL Ubuntu (не PowerShell и не /mnt/c). Управляемый узел — devops-vm, 192.168.56.102.
- inventory/bootstrap.ini: пользователь student, порт 22. Пароль в файл не записывается, на первом запуске он передаётся только через --extra-vars.
- inventory/prod.ini: пользователь devops, порт 22, ключ ~/.ssh/devops_vm.
- Роли: base — пакеты и Docker; ssh — учётка devops, ключ, sudo, запрет входа по паролю и root, UFW (22 и 80); nginx — reverse proxy на приложение; app — скачивание образа и контейнер.
- Образ: ghcr.io/haschen175/devops-ci-app
- Полный SHA: f598351cea7a5b8ac3c1b16c9b1c887b8b0520cd
- Порт контейнера на ВМ: 127.0.0.1:5000. Снаружи страница открывается через Nginx на порту 80.
- Health: http://192.168.56.102/health
- Первый запуск на чистой ВМ: ansible-playbook -i inventory/bootstrap.ini site.yml
- Повторный запуск: ansible-playbook site.yml
- Проверка без изменений: ansible-playbook verify.yml

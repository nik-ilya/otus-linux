# Домашнее задание 19. "PXE"

## Домашнее задание.

1. Следуя шагам из документа https://docs.centos.org/en-US/8-docs/advanced-install/assembly_preparing-for-a-network-install установить и настроить загрузку по сети для дистрибутива CentOS8.
В качестве шаблона воспользуйтесь репозиторием https://github.com/nixuser/virtlab/tree/main/centos_pxe.
2. Поменять установку из репозитория NFS на установку из репозитория HTTP.
3. Настроить автоматическую установку для созданного kickstart файла (*) Файл загружается по HTTP.
Задание со звездочкой *
4. Автоматизировать процесс установки Cobbler cледуя шагам из документа https://cobbler.github.io/quickstart/.
Формат сдачи ДЗ - vagrant + ansible



## Выполнение.

1. Так как ссылка в документации недоступна, используем CentOS Stream 8 (http://centos1.hti.pl/8-stream/isos/x86_64/CentOS-Stream-8-20230429.0-x86_64-dvd1.iso).

2. Создаем [инфраструктуру](Vagrantfile).

3. Создаем [ansible playbook для PXEServer](ansible/provision.yml).

4. Проверяем результат:

- Поднимаем PXE-сервер:   
    ```sh
    vagrant up pxeserver
    ``` 

- Ждем выполнение ansible playbook.

- Поднимаем клиента:
    ```sh
    vagrant up pxeclient
    ``` 
 - Получаем меню загрузки по PXE.

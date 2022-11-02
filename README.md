# Урок 01. "С чего начинается Linux"

# Домашнее задание

## Цель домашнего задания
Научиться обновлять ядро в ОС Linux. Получение навыков работы с Vagrant, Packer и публикацией готовых образов в Vagrant Cloud. 

## Результаты:

 1) Обновил ядро ОС из репозитория ELRepo

- Выполнил форк репозитория https://github.com/erlong15/otus-linux.
- Склонировал на рабочую машину.
- Создал ВМ с имеющимся файлом Vagrantfile.
- Подключил репозитории elrepo-kernel, обновил ядро.
- После перезагрузки убедился в обновлении ядра до версии 6.0.6.


 2) Создал Vagrant box c помощью Packer

- Установил packer.
- Форкнул и склонировал репозиторий https://github.com/dmitry-lyutenko/manual_kernel_update/tree/master/packer
- Запустил создание образа используя файл настроек centos.json.
- По итогу получился образ centos-7.7.1908-kernel-60-x86_64-Minimal.box.


 4) Загрузил Vagrant box в Vagrant Cloud

- Зарегистрировался в Vagrant Cloud.
- Загрузил образ командой:

```vagrant cloud publish --release nik-ilya/centos-7.7-kernel-60 1.0 virtualbox centos-7.7.1908-kernel-60-x86_64-Minimal.box
```

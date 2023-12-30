# netology_diplom

Zabbix - http://51.250.30.77 login: Netology pass: Ohkie3Oozoug

Kibana - http://51.250.31.81:5601

Сам сайт доступен по ссылке - http://158.160.141.49 - тестовая страница, имитирующая сайт

Описание выполнения Дипломного задания.

Для подключения к облаку необходимо подключиться к провайдеру и получить oAuth_token. Данные облака и ключ указываются в  файле .tf.

Шаг 1: Развертывание инфраструктуры. Устанавливаем Terraform

Шаг 2: Пишем код - он представлен в файле diplom.tf 

Шаг 3: Подготовка подготовка файлов конфигурации. Все файлы лежат в папке cfg.

Шаг 3: Подготовка Ansible. 
       - Нужно подготовить inventory. inventory-файл находится в папке cfg, под именем hosts.
       - Нужно скачать коллекции и роли. Для тех машин, где нет связи с внешней сеть, подготовить дистрибутивы софта и конфиги.

Шаг 4: Установка ПО на машины из плэйбуков Ansible. Все плэйбуки находятся в папке playbook.
Шаг 5: Настройка мониторинга Zabbix

    -Добавляем хосты в веб-интерфейсе, дожидаемся отчета об их доступности
    -Подключаем к хостам шаблон Linux by Zabbix-agent
    -К хостам с nginx подключаем шаблон Nginx by Zabbix-agent
    -Создаем дэшборды по нужным метрикам.
Все дашборды можно увидеть в заббиксе, по предоставленным кредам.

Скриншоты:
![ВМ](https://github.com/d-nikolaev-cybersec/netology_diplom/assets/107998187/62843753-da7b-4b67-b3c6-3f5a54cf0d96)
![Балансер](https://github.com/d-nikolaev-cybersec/netology_diplom/assets/107998187/d9cd5f07-35cd-48f2-a5e0-aa54972eba11)
![Сеть](https://github.com/d-nikolaev-cybersec/netology_diplom/assets/107998187/881a6f70-1f07-4f67-8efc-ef7792fb46e8)
![Роутер](https://github.com/d-nikolaev-cybersec/netology_diplom/assets/107998187/0d0d6b34-3d0f-4c33-b4c5-227d419c8a93)
![Группа бэков](https://github.com/d-nikolaev-cybersec/netology_diplom/assets/107998187/ea2af7cb-1db2-47d1-b508-973a9d9aefdc)
![Целевая группа](https://github.com/d-nikolaev-cybersec/netology_diplom/assets/107998187/b0f5adb5-c849-452b-842e-f5a588426051)
![Группа безопасности](https://github.com/d-nikolaev-cybersec/netology_diplom/assets/107998187/cb153fca-1c18-4621-9e5c-37fecd14b6d7)








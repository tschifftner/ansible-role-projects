# Ansible Role: Projects

[![Build Status](https://travis-ci.org/tschifftner/ansible-role-projects.svg)](https://travis-ci.org/tschifftner/ansible-role-projects)

Installs Projects on Debian/Ubuntu linux servers.

## Requirements

The following programs need to be installed prior running this role:

 - [awscli](https://github.com/tschifftner/ansible-role-awscli)
 - [nginx](https://github.com/tschifftner/ansible-role-nginx)
 - [php5-fpm](https://github.com/tschifftner/ansible-role-php5-fpm)
 - [mariadb](https://github.com/tschifftner/ansible-role-mariadb)
 - [composer](https://github.com/tschifftner/ansible-role-composer)

_Manual Installation:_
```
  sudo apt-get update -qq
  sudo apt-get install -y curl nginx php5 php5-cli php5-fpm php5-curl php5-imap php5-xmlrpc php5-mysqlnd mariadb-server-10.1 mariadb-client-10.1 python-mysqldb software-properties-common
  curl -sS https://getcomposer.org/installer | sudo php -- --install-dir=/usr/local/bin --filename=composer
```
## Role Variables

Available variables are listed below, along with default values (see `defaults/main.yml`):

### Default project user

```
project_default_owner: ''
project_default_group: ''
```

## Projects

### Magento Project

```
# file ansible/group_vars/devbox/example.yml
demo_project:
    name: demo
    root: pub/
    environment: devbox
    server_alias: dev2.local
    databases: ['dev2_local', 'dev3_local']
    #remove: true
    awscli:
      - profilename: 'demo'
        aws_access_key_id: 'XXXXXXXXXX'
        aws_secret_access_key: 'XXXXXXXXXXXXXXXXXX'
        region: 'eu-central-1'
    helper:
      - name: fullsync
        info: 'Synchronizes full media in projectstorage folder with aws s3'
        command: 'aws --profile demo s3 cp --recursive s3://bucket/demo/backup/production /home/projectstorage/demo/backup/production'
    
      - name: fastsync
        info: 'Synchronises database but only files timestamp file'
        command: >
          aws --profile demo s3 cp --recursive s3://bucket/demo/backup/production/database /home/projectstorage/demo/backup/production/database &&
          aws --profile demo s3 cp s3://bucket/demo/backup/production/files/created.txt /home/projectstorage/demo/backup/production/files/created.txt
    
      - name: reset
        info: 'Imports latest database and synchronises media files with projectstorage'
        command:  '/home/projectstorage/demo/bin/deploy/project_reset.sh -p /var/www/demo/devbox/releases/current/htdocs/ -s /home/projectstorage/demo/backup/production'
    
      - name: cleanup
        info: 'Removes all releases except for current'
        command: '/home/projectstorage/demo/bin/deploy/cleanup.sh -r /var/www/demo/devbox/releases -n 1'
    
      - name: install
        info: 'deploys full project including database import and media synchronisation'
        command: '/home/projectstorage/demo/bin/deploy/deploy.sh -d -e devbox -a demo -r s3://bucket/demo/builds/demo.de.tar.gz -t /var/www/demo/devbox'
```
### Magento 2 Project

```
# file ansible/group_vars/devbox/demo2.yml
demo2_project:
    name: demo2
    type: magento
    environment: devbox
    server_alias: demo2.local
    databases: ['demo2']
    deploy_scripts: 'https://github.com/ambimax/magento-deployscripts.git'
    awscli:
      - profilename: 'demo2'
        aws_access_key_id: 'XXXXXXXXXX'
        aws_secret_access_key: 'XXXXXXXXXXXXXXXXXXXX'
        region: 'eu-central-1'
    motd: |
      Demo Project
      ====
      Update systemstorage
      aws --profile demo2 s3 cp --recursive s3://bucket/demo2/backup/production /home/projectstorage/demo2/backup/production

      Install
      /home/projectstorage/demo2/bin/deploy/deploy.sh -d -e devbox -a demo2 -r s3://bucket/demo2/builds/demo2.de.tar.gz -t /var/www/demo2/devbox
```

### Enable projects

To enable a project just add it to the list of `projects`

```
# file ansible/group_vars/devbox/_projects.yml
projects:
  - '{{ demo_project }}'
  - '{{ demo2_project }}'
#  - '{{ any_other_repo }}'
```


## Dependencies

None.

## Example Playbook

    - hosts: server
      roles:
        - { role: tschifftner.awscli }
        - { role: tschifftner.nginx }
        - { role: tschifftner.php5-fpm }
        - { role: tschifftner.composer }
        - { role: tschifftner.mariadb }
        - { role: tschifftner.roundcube }

## Supported OS

Ansible          | Debian Jessie    | Ubuntu 14.04    | Ubuntu 12.04
:--------------: | :--------------: | :-------------: | :-------------: 
2.1              | Yes              | Yes             | Yes

## License

[MIT License](http://choosealicense.com/licenses/mit/)

## Author Information

 - [Tobias Schifftner](https://twitter.com/tschifftner), [ambimax® GmbH](https://www.ambimax.de)
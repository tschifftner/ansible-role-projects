#!/usr/bin/env bash
#
# Helper for {{ project.name }} ({{ project.environment }})
# @author Tobias Schifftner, @tschifftner, ambimax® GmbH
# @copyright © 2017

PROJECT='{{ project.name }}'
ENVIRONMENT='{{ project.environment }}'
S3BUCKET='{{ project.s3_bucket | default(projects_s3_bucket) }}'
PROJECTSTORAGE='{{ project.projectstorage | default(project_storage_home) }}'
#RELEASE_FOLDER='{{ project.release_folder | default("/var/www/" + project.name + "/" + project.environment + "/releases") }}'
RELEASE_FOLDER="{{ project.release_folder | default('/var/www/${PROJECT}/${ENVIRONMENT}/releases') }}"
INSTALL_EXTRA_PACKAGE='{{ project.install_extra_package | default(false) }}'

BUILD_FILE="${S3BUCKET}/${PROJECT}/builds/${PROJECT}.tar.gz"
RELEASE_DIR="${RELEASE_FOLDER}/.."

AWS_PROFILE="{{ project.awscli.0.profilename | default(project.name) }}"

AWS_PROFILE_PARAM=""
INSTALL_AWS_PROFILE=""
if [ ! -z "${AWS_PROFILE}" ] ; then
    AWS_PROFILE_PARAM="--profile ${AWS_PROFILE}"
    INSTALL_AWS_PROFILE="-a ${AWS_PROFILE}"
fi

_INSTALL_EXTRA_PACKAGE=""
if [[ "${_INSTALL_EXTRA_PACKAGE}" = true ]]; then
    _INSTALL_EXTRA_PACKAGE="-d"
fi

function error_exit {
	echo "$1" 1>&2
	exit 1
}

function run {
    echo "$1" 1>&2
    $1
}

function install {
    run "$PROJECTSTORAGE/$PROJECT/bin/deploy/deploy.sh -e $ENVIRONMENT -r $BUILD_FILE -t $RELEASE_DIR ${_INSTALL_EXTRA_PACKAGE} $INSTALL_AWS_PROFILE"  || error_exit "Installation failed"
}

function cleanup {
    $PROJECTSTORAGE/$PROJECT/bin/deploy/cleanup.sh -r $RELEASE_FOLDER  || error_exit "Cleanup failed"
}

function info {
    echo "Project: $PROJECT"
    echo "Environemnt: $ENVIRONMENT"
    echo "Releases: $RELEASE_FOLDER"
    echo "Storage: $PROJECTSTORAGE"
    echo "s3: $S3BUCKET/$PROJECT/"
    echo "DB Date: " `date -r $(cat $PROJECTSTORAGE/$PROJECT/backup/production/database/created.txt) '+%d.%m.%Y %H:%M:%S'`
    echo "Files Date: " `date -r $(cat $PROJECTSTORAGE/$PROJECT/backup/production/files/created.txt) '+%d.%m.%Y %H:%M:%S'`
}

function setup {
    mkdir -p $RELEASE_FOLDER
    mkdir -p "$RELEASE_FOLDER/../shared/media"
    mkdir -p "$RELEASE_FOLDER/../shared/var"
    mkdir -p $PROJECTSTORAGE/$PROJECT/bin
    if [ ! -d $PROJECTSTORAGE/$PROJECT/bin/deploy ]; then
        git clone https://github.com/ambimax/magento-deployscripts.git $PROJECTSTORAGE/$PROJECT/bin/deploy
    else
        (cd $PROJECTSTORAGE/$PROJECT/bin/deploy && git pull)
    fi
    fastsync
    gzip -dc $PROJECTSTORAGE/$PROJECT/backup/production/database/combined_dump.sql.gz | mysql $PROJECT
    install
}


# run script
if [ `type -t $1`"" == 'function' ]; then
    current=$(pwd)
    echo -e "\e[93m" && $@ && echo -e "\e[0m"
    cd $current
else
echo -e "
    \e[91m{{ project.name }} ({{ project.environment }})\e[0m - helper script

    USAGE:

    \e[0;32minstall \e[0m
    deploys full project including database import and media synchronisation

    \e[0;32mreset \e[0m
    Imports latest database and synchronises media files with projectstorage

    \e[0;32mcleanup \e[0m
    Removes old installed builds from releases folder




    \e[0;32msetup \e[0m
    Initial setup full project

"
fi
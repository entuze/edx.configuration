#!/bin/bash
#---------------------------------------------------------
# written by: lawrence mcdaniel
#             https://lawrencemcdaniel.com
#             https://blog.lawrencemcdaniel.com
#
# date:       feb-2018
#
# usage:      backup MySQL and MongoDB data stores
#             combine into a single tarball, store in "backups" folders in user directory
#
# reference:  https://github.com/edx/edx-documentation/blob/master/en_us/install_operations/source/platform_releases/ginkgo.rst
#---------------------------------------------------------

#------------------------------ SUPER IMPORTANT!!!!!!!! -- initialize these variables
MYSQL_PWD=""      #Add your MySQL admin password, if one is set. Otherwise set to a null string
MONGODB_PWD="T972FnumUezgE01U9IfnAhvRtk79edq3Hgn"    #Add your MongoDB admin password from your my-passwords.yml file in the ubuntu home folder.

S3_BUCKET="CHANGE-ME!!!"  #For this script to work you'll first need the following:
                                            # - create an AWS S3 Bucket
                                            # - create an AWS IAM user with programatic access and S3 Full Access privileges
                                            # - install AWS Command Line Tools in your Ubuntu EC2 instance
                                            # run aws configure to add your IAM key and secret token
#------------------------------------------------------------------------------------------------------------------------

BACKUPS_DIRECTORY="/root/backups/"
WORKING_DIRECTORY="/root/backup-tmp/"
NUMBER_OF_BACKUPS_TO_RETAIN="30"      #Note: this only regards local storage (ie on the ubuntu server). All backups are retained in the S3 bucket forever.

#Check to see if a working folder exists. if not, create it.
if [ ! -d ${WORKING_DIRECTORY} ]; then
    mkdir ${WORKING_DIRECTORY}
    echo "created backup working folder ${WORKING_DIRECTORY}"
fi

#Check to see if anything is currently in the working folder. if so, delete it all.
if [ -f "$WORKING_DIRECTORY/*" ]; then
  sudo rm -r "$WORKING_DIRECTORY/*"
fi

#Check to see if a backups/ folder exists. if not, create it.
if [ ! -d ${BACKUPS_DIRECTORY} ]; then
    mkdir ${BACKUPS_DIRECTORY}
    echo "created backups folder ${BACKUPS_DIRECTORY}"
fi


cd ${WORKING_DIRECTORY}

#Backup MySQL databases
MYSQL_CONN="-uroot"
echo "Backing up MySQL databases"
echo "Reading MySQL database names..."
mysql ${MYSQL_CONN} -ANe "SELECT schema_name FROM information_schema.schemata WHERE schema_name NOT IN ('mysql','information_schema','performance_schema')" > /tmp/db.txt
DBS="--databases $(cat /tmp/db.txt)"
NOW="$(date +%Y%m%dT%H%M%S)"
SQL_FILE="mysql-data-${NOW}.sql"
echo "Dumping MySQL structures..."
mysqldump ${MYSQL_CONN} --add-drop-database --no-data ${DBS} > ${SQL_FILE}
echo "Dumping MySQL data..."
# If there is table data you don't need, add --ignore-table=tablename
mysqldump ${MYSQL_CONN} --no-create-info ${DBS} >> ${SQL_FILE}
echo "Done backing up MySQL"

#Backup Mongo
echo "Backing up MongoDB"
for db in edxapp cs_comment_service_development; do
    echo "Dumping Mongo db ${db}..."
    mongodump -u admin -p"$MONGODB_PWD" -h localhost --authenticationDatabase admin -d ${db} --out mongo-dump-${NOW}
done
echo "Done backing up MongoDB"

#Tarball all of our backup files
echo "Compressing backups into a single tarball archive"
tar -czf ${BACKUPS_DIRECTORY}openedx-data-${NOW}.tgz ${SQL_FILE} mongo-dump-${NOW}
sudo chown root ${BACKUPS_DIRECTORY}openedx-data-${NOW}.tgz
sudo chgrp root ${BACKUPS_DIRECTORY}openedx-data-${NOW}.tgz
echo "Created tarball of backup data openedx-data-${NOW}.tgz"

#Prune the Backups/ folder by eliminating all but the 30 most recent tarball files
echo "Pruning the local backup folder archive"
if [ -d ${BACKUPS_DIRECTORY} ]; then
  cd ${BACKUPS_DIRECTORY}
  ls -1tr | head -n -${NUMBER_OF_BACKUPS_TO_RETAIN} | xargs -d '\n' rm -f --
fi

#Remove the working folder
echo "Cleaning up"
sudo rm -r ${WORKING_DIRECTORY}

echo "Sync backup to AWS S3 backup folder"
/usr/local/bin/aws s3 sync ${BACKUPS_DIRECTORY} s3://${S3_BUCKET}
echo "Done!"

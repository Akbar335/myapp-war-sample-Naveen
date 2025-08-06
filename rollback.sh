#!/bin/bash
set -e
TOMCAT_WEBAPPS="/opt/tomcat/webapps"
BACKUP_DIR="/opt/tomcat/backup"
cp $BACKUP_DIR/myapp.war $TOMCAT_WEBAPPS/myapp.war
rm -rf $TOMCAT_WEBAPPS/myapp
systemctl restart tomcat
echo "Rollback done and Tomcat restarted."

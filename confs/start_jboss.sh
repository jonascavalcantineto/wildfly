#!/bin/bash


if [ ! -f ${JBOSS_HOME}/bin/add-user.sh ]
then
    cp -rv ${JBOSS_DIR_TEMP}/wildfly-$WILDFLY_VERSION /opt 
fi

chmod 777 ${JBOSS_HOME}/ -R

${JBOSS_HOME}/bin/add-user.sh admin ${JBOSS_ADMIN_PASS} --silent

sleep 5

${JBOSS_HOME}/bin/standalone.sh -b 0.0.0.0 -bmanagement 0.0.0.0

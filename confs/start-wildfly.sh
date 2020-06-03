#!/bin/bash


if [ ! -f ${WILDFLY_HOME}/bin/add-user.sh ]
then
    cp -rv ${WILDFLY_DIR_TEMP}/wildfly-$WILDFLY_VERSION /opt 
fi

chmod 777 ${WILDFLY_HOME}/ -R

${WILDFLY_HOME}/bin/add-user.sh admin ${WILDFLY_ADMIN_PASS} --silent

sleep 5

${WILDFLY_HOME}/bin/standalone.sh -b 0.0.0.0 -bmanagement 0.0.0.0

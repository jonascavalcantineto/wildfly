FROM centos:7
LABEL MAINTAINER="Jonas Cavalcanti <jonascavalcantineto@gmail.com>"

# Install packages necessary to run EAP
RUN yum update -y && yum -y \ 
						install \
						java-1.8.0-openjdk-devel.x86_64 \
						xmlstarlet \
						python-setuptools \
						vim \
						saxon \
						augeas \
						telnet \
						bsdtar \
						unzip && yum clean all

# Create a user and group used to launch processes
# The user ID 1000 is the default for the first "regular" user on Fedora/RHEL,
# so there is a high chance that this ID will be equal to the current user
# making it easier to use volumes (no permission issues)

ENV TZ=America/Fortaleza
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN groupadd -r jboss -g 1000 && useradd -u 1000 -r -g jboss -m -d /opt/jboss -s /sbin/nologin -c "JBoss user" jboss && \
    chmod 755 /opt/jboss

#Instalação e configuração do Supervisor
RUN easy_install supervisor
ADD confs/supervisord.conf /etc/supervisord.conf

# Set the WILDFLY_VERSION env variable
ENV WILDFLY_VERSION="10.1.0.Final"
#ENV WILDFLY_SHA1 0e89fe0860a87bfd6b09379ee38d743642edfcfb
ENV JBOSS_DIR_TEMP="/tmp"
ENV JBOSS_HOME="/opt/wildfly-$WILDFLY_VERSION"
ENV JBOSS_ADMIN_PASS='1q2w3e4r'

# Add the WildFly distribution to /opt, and make wildfly the owner of the extracted tar content
# Make sure the distribution is available from a well-known place
RUN cd ${JBOSS_DIR_TEMP} \
    && curl -O https://download.jboss.org/wildfly/$WILDFLY_VERSION/wildfly-$WILDFLY_VERSION.tar.gz \
    && tar xf wildfly-$WILDFLY_VERSION.tar.gz

ADD wars/postgresql-9.4.1208.jre7.jar ${JBOSS_DIR_TEMP}/wildfly-$WILDFLY_VERSION/standalone/deployments/postgresql-9.4.1208.jre7.jar
ADD confs/create_infinity_datasources.cli ${JBOSS_DIR_TEMP}/wildfly-$WILDFLY_VERSION/bin/create_infinity_datasources.cli
ADD confs/standalone.conf ${JBOSS_DIR_TEMP}/wildfly-$WILDFLY_VERSION/bin/standalone.conf

RUN set -ex \
    && cp -rv ${JBOSS_DIR_TEMP}/wildfly-$WILDFLY_VERSION $JBOSS_HOME \
    && chmod -R g+rw ${JBOSS_HOME}


RUN ${JBOSS_HOME}/bin/add-user.sh admin ${JBOSS_ADMIN_PASS} --silent

# Ensure signals are forwarded to the JVM process correctly for graceful shutdown
ENV LAUNCH_JBOSS_IN_BACKGROUND true
					
# Set the workdir
WORKDIR $JBOSS_HOME

# Expose Ports
EXPOSE 8080 9999 9990

# Start Jboss
ADD confs/start_jboss.sh /start_jboss.sh
RUN chmod +x /start_jboss.sh

# Start Supervisord
ADD confs/start.sh /start.sh
RUN chmod +x /start.sh

# Start Supervisord
CMD ["/start.sh"]




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

#Instalação e configuração do Supervisor
RUN easy_install supervisor
ADD confs/supervisord.conf /etc/supervisord.conf

# Set the WILDFLY_VERSION env variable
ENV WILDFLY_VERSION="10.1.0.Final"
#ENV WILDFLY_SHA1 0e89fe0860a87bfd6b09379ee38d743642edfcfb
ENV WILDFLY_DIR_TEMP="/tmp"
ENV WILDFLY_HOME="/opt/wildfly-$WILDFLY_VERSION"
ENV WILDFLY_ADMIN_PASS='1q2w3e4r'

RUN set -ex \
	&& groupadd -r wildfly \
	&& useradd wildfly -g wildfly -m -d ${WILDFLY_HOME} 

# Add the WildFly distribution to /opt, and make wildfly the owner of the extracted tar content
# Make sure the distribution is available from a well-known place
RUN cd ${WILDFLY_DIR_TEMP} \
    && curl -O https://download.jboss.org/wildfly/$WILDFLY_VERSION/wildfly-$WILDFLY_VERSION.tar.gz \
    && tar xf wildfly-$WILDFLY_VERSION.tar.gz

COPY wars/*.jar ${WILDFLY_DIR_TEMP}/wildfly-$WILDFLY_VERSION/standalone/deployments/
#ADD confs/create_infinity_datasources.cli ${WILDFLY_DIR_TEMP}/wildfly-$WILDFLY_VERSION/bin/create_infinity_datasources.cli
ADD confs/standalone.conf ${WILDFLY_DIR_TEMP}/wildfly-$WILDFLY_VERSION/bin/standalone.conf

RUN set -ex \
    && cp -rv ${WILDFLY_DIR_TEMP}/wildfly-$WILDFLY_VERSION/* ${WILDFLY_HOME}/ \
    && chmod -R g+rw ${WILDFLY_HOME}

RUN set -ex \
		&& chmod 755 ${WILDFLY_HOME} \
		&& chown -R wildfly:wildfly ${WILDFLY_HOME}

RUN ${WILDFLY_HOME}/bin/add-user.sh admin ${WILDFLY_ADMIN_PASS} --silent

# Ensure signals are forwarded to the JVM process correctly for graceful shutdown
ENV LAUNCH_WILDFLY_IN_BACKGROUND true

# Set the workdir
WORKDIR $WILDFLY_HOME

# Expose Ports
EXPOSE 8080 9999 9990

# Start Jboss
ADD confs/start-wildfly.sh /start-wildfly.sh
RUN chmod +x /start-wildfly.sh

# Start Supervisord
ADD confs/start.sh /start.sh
RUN chmod +x /start.sh

#USER wildfly

# Start Supervisord
CMD ["/start.sh"]




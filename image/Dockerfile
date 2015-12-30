FROM ingensi/oracle-jdk:latest
MAINTAINER Viktor Larionov <larionov@viktor.ee>

VOLUME [ "/var/atlassian/bamboo" ]

# Install required utilities.
RUN /usr/bin/yum install -y gzip   && \
    /usr/bin/yum install -y tar    && \
    /usr/bin/yum install -y bzip2

# Import certificates to JVM truststore.
ADD support-files/install.certificates /var/tmp/install.certificates
RUN for certificate_url in $(/bin/cat /var/tmp/install.certificates); do                                                   \
        certificate=/var/tmp/$(/bin/basename ${certificate_url});                                                          \
        /usr/bin/wget --progress=bar:force ${certificate_url} -O ${certificate};                                           \
        alias=$(/bin/basename ${certificate} | /bin/sed s/'\.pem'/''/g | /bin/sed s/'\.crt'/''/g);                         \
        /usr/java/default/bin/keytool -importcert -trustcacerts -file ${certificate} -alias ${alias} -keystore /etc/pki/ca-trust/extracted/java/cacerts -storepass changeit -storetype JKS -noprompt; \
        /usr/java/default/bin/keytool -importcert -trustcacerts -file ${certificate} -alias ${alias} -keystore /usr/java/default/jre/lib/security/cacerts -storepass changeit -storetype JKS -noprompt; \
        /bin/rm -f ${certificate};                                                                                         \
    done                                                                                                                && \
    /bin/rm -f /var/tmp/install.certificates

# Prepare the directory layout.
RUN /bin/mkdir -p /usr/local/atlassian/bamboo && \
    /bin/mkdir -p /var/atlassian/bamboo

# Creating user and group.
RUN /sbin/groupadd -g 9997 bamboo                                                                                            && \
    /sbin/useradd -u 9997 -d /usr/local/atlassian/bamboo -c "Atlassian Bamboo" -g bamboo -M -s /bin/bash bamboo

# Install Bamboo binaries from package.
ADD support-files/BAMBOO.VERSION /usr/local/atlassian/bamboo/BAMBOO.VERSION
RUN VERSION=$(/bin/cat /usr/local/atlassian/bamboo/BAMBOO.VERSION)                              && \
    /usr/bin/wget --progress=bar:force https://downloads.atlassian.com/software/bamboo/downloads/atlassian-bamboo-${VERSION}.tar.gz -O /var/tmp/atlassian-bamboo-${VERSION}.tar.gz && \
    cd /var/tmp                                                                                          && \
    /usr/bin/tar -xvzf /var/tmp/atlassian-bamboo-${VERSION}.tar.gz                                       && \
    /bin/cp -rfa /var/tmp/atlassian-bamboo-${VERSION}/atlassian-bamboo /usr/local/atlassian/bamboo/      && \
    /bin/cp -rfa /var/tmp/atlassian-bamboo-${VERSION}/bin /usr/local/atlassian/bamboo/                   && \
    /bin/cp -rfa /var/tmp/atlassian-bamboo-${VERSION}/conf /usr/local/atlassian/bamboo/                  && \
    /bin/cp -rfa /var/tmp/atlassian-bamboo-${VERSION}/lib /usr/local/atlassian/bamboo/                   && \
    /bin/cp -rfa /var/tmp/atlassian-bamboo-${VERSION}/scripts /usr/local/atlassian/bamboo/               && \
    /bin/cp -rfa /var/tmp/atlassian-bamboo-${VERSION}/webapps /usr/local/atlassian/bamboo/               && \
    /bin/cp -rfa /var/tmp/atlassian-bamboo-${VERSION}/work /usr/local/atlassian/bamboo/                  && \
    /bin/rm -rf /var/tmp/atlassian-bamboo-${VERSION}                                                     && \
    /bin/rm -rf /var/tmp/atlassian-bamboo-${VERSION}.tar.gz

# Install Bamboo RC scripts.
ADD support-files/install.hosts /etc/hosts.install
ADD support-files/bamboo-init.sh /sbin/bamboo-init.sh

# Create symlinks for correct layout.
RUN /bin/ln -s /var/tmp /usr/local/atlassian/bamboo/temp                         && \
    /bin/ln -s /var/atlassian/bamboo/logs /usr/local/atlassian/bamboo/logs   && \
    /bin/ln -s /var/atlassian/bamboo/logs /var/atlassian/bamboo/log

# Install configuration overlay.
ADD conf-overlay/logging.properties /usr/local/atlassian/bamboo/conf/
ADD conf-overlay/bamboo-init.properties /usr/local/atlassian/bamboo/atlassian-bamboo/WEB-INF/classes/bamboo-init.properties
ADD conf-overlay/setenv.sh /usr/local/atlassian/bamboo/bin/setenv.sh.template
ADD conf-overlay/server.xml /usr/local/atlassian/bamboo/conf/server.xml.template
ADD conf-overlay/atlassian-user.xml /var/atlassian/bamboo/xml-data/configuration/atlassian-user.xml.template

# ENTRYPOINT
RUN /bin/chown root:root /sbin/bamboo-init.sh && \
    /bin/chmod 755 /sbin/bamboo-init.sh
CMD /sbin/bamboo-init.sh

# Expose default ports for Bamboo.
EXPOSE 8085

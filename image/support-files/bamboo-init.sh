#!/bin/bash

# Prerequisities and checks start.

# --- Add /etc/hosts records
if [ -f /etc/hosts.install ]; then
    /bin/cat /etc/hosts.install >>/etc/hosts
fi

# --- Fix file permissions.
/usr/bin/find /var/atlassian/bamboo -type d -exec /bin/chmod 750 '{}' ';'
/usr/bin/find /var/atlassian/bamboo -type f -exec /bin/chmod 640 '{}' ';'
/usr/bin/find /usr/local/atlassian/bamboo -type d -exec /bin/chmod 750 '{}' ';' 
/usr/bin/find /usr/local/atlassian/bamboo -type f -exec /bin/chmod 640 '{}' ';'
/bin/chmod 755 /var/atlassian
/bin/chmod 755 /usr/local/atlassian
/bin/chmod 750 /usr/local/atlassian/bamboo/bin/*
/bin/chown root:root /var/atlassian
/bin/chown root:root /usr/local/atlassian
/bin/chown -R bamboo:bamboo /var/atlassian/bamboo
/bin/chown -R bamboo:bamboo /usr/local/atlassian/bamboo

# --- Clean up the logs.
if [ ! -d /var/atlassian/bamboo/logs ]; then
    /bin/rm -f /var/atlassian/bamboo/logs >/dev/null 2>&1
    /bin/mkdir /var/atlassian/bamboo/logs
    /bin/chown bamboo:bamboo /var/atlassian/bamboo/logs
    /bin/chmod 750 /var/atlassian/bamboo/logs
fi

if [ ! -e /var/atlassian/bamboo/log ]; then
    /bin/ln -s /var/atlassian/bamboo/logs /var/atlassian/bamboo/log
    /bin/chown -h bamboo:bamboo /var/atlassian/bamboo/log
fi

cd /var/atlassian/bamboo/logs

for logfile in $(/usr/bin/find /var/atlassian/bamboo/logs -type f | /bin/grep -Eiv '\.gz$'); do
    /usr/bin/gzip ${logfile}
    /bin/mv ${logfile}.gz ${logfile}-$(/usr/bin/date +%d%m%Y-%H%M%S).gz
done

for logfile in $(/usr/bin/find /var/atlassian/bamboo/logs -type f -mtime +7); do
    /bin/echo "Startup logfile ${logfile} is older than 7 days. Removing it."
    /bin/rm -f ${logfile}
done

# --- Prepare environment variables.
if [ -f /usr/local/atlassian/bamboo/conf/server.xml.template ]; then
    export BAMBOO_DB_DRIVER_ESCAPED=$(/bin/echo ${BAMBOO_DB_DRIVER} | sed s/'\\'/'\\\\'/g | sed s/'\/'/'\\\/'/g | sed s/'('/'\\('/g | sed s/')'/'\\)'/g | sed s/'&'/'\\&'/g)
    export BAMBOO_DB_URL_ESCAPED=$(/bin/echo ${BAMBOO_DB_URL} | sed s/'\\'/'\\\\'/g | sed s/'\/'/'\\\/'/g | sed s/'('/'\\('/g | sed s/')'/'\\)'/g | sed s/'&'/'\\&'/g)
    export BAMBOO_DB_USER_ESCAPED=$(/bin/echo ${BAMBOO_DB_USER} | sed s/'\\'/'\\\\'/g | sed s/'\/'/'\\\/'/g | sed s/'('/'\\('/g | sed s/')'/'\\)'/g | sed s/'&'/'\\&'/g)
    export BAMBOO_DB_PASSWORD_ESCAPED=$(/bin/echo ${BAMBOO_DB_PASSWORD} | sed s/'\\'/'\\\\'/g | sed s/'\/'/'\\\/'/g | sed s/'('/'\\('/g | sed s/')'/'\\)'/g | sed s/'&'/'\\&'/g)
    export BAMBOO_FE_NAME_ESCAPED=$(/bin/echo ${BAMBOO_FE_NAME} | sed s/'\\'/'\\\\'/g | sed s/'\/'/'\\\/'/g | sed s/'('/'\\('/g | sed s/')'/'\\)'/g | sed s/'&'/'\\&'/g)
    export BAMBOO_FE_PORT_ESCAPED=$(/bin/echo ${BAMBOO_FE_PORT} | sed s/'\\'/'\\\\'/g | sed s/'\/'/'\\\/'/g | sed s/'('/'\\('/g | sed s/')'/'\\)'/g | sed s/'&'/'\\&'/g)
    export BAMBOO_FE_PROTO_ESCAPED=$(/bin/echo ${BAMBOO_FE_PROTO} | sed s/'\\'/'\\\\'/g | sed s/'\/'/'\\\/'/g | sed s/'('/'\\('/g | sed s/')'/'\\)'/g | sed s/'&'/'\\&'/g)
    export CONFIGURE_FRONTEND_ESCAPED=$(/bin/echo ${CONFIGURE_FRONTEND} | sed s/'\\'/'\\\\'/g | sed s/'\/'/'\\\/'/g | sed s/'('/'\\('/g | sed s/')'/'\\)'/g | sed s/'&'/'\\&'/g | sed -r s/'[ ]+'/''/g)
    export CONFIGURE_SQL_DATASOURCE_ESCAPED=$(/bin/echo ${CONFIGURE_SQL_DATASOURCE} | sed s/'\\'/'\\\\'/g | sed s/'\/'/'\\\/'/g | sed s/'('/'\\('/g | sed s/')'/'\\)'/g | sed s/'&'/'\\&'/g | sed -r s/'[ ]+'/''/g)
    
    if [ "${CONFIGURE_FRONTEND_ESCAPED}" != "TRUE" -a "${CONFIGURE_FRONTEND_ESCAPED}" != "true" ]; then 
        /bin/sed -r s/'proxyName="[^"]+" proxyPort="[^"]+" scheme="[^"]+" '//g /usr/local/atlassian/bamboo/conf/server.xml.template >/usr/local/atlassian/bamboo/conf/server.xml.template.2
        /bin/mv /usr/local/atlassian/bamboo/conf/server.xml.template.2 /usr/local/atlassian/bamboo/conf/server.xml.template
    fi
    
    if [ "${CONFIGURE_SQL_DATASOURCE_ESCAPED}" != "TRUE" -a "${CONFIGURE_SQL_DATASOURCE_ESCAPED}" != "true" ]; then 
        /bin/sed -r s/'<Resource name="jdbc\/bamboo"'/'<!-- <Resource name="jdbc\/bamboo" '/g /usr/local/atlassian/bamboo/conf/server.xml.template | /bin/sed -r s/'validationQuery="Select 1" \/>'/'validationQuery="Select 1" \/> -->'/g >/usr/local/atlassian/bamboo/conf/server.xml.template.2
        /bin/mv /usr/local/atlassian/bamboo/conf/server.xml.template.2 /usr/local/atlassian/bamboo/conf/server.xml.template
    fi
    
    /bin/cat /usr/local/atlassian/bamboo/conf/server.xml.template | /bin/sed s/'\%BAMBOO_DB_DRIVER\%'/"${BAMBOO_DB_DRIVER_ESCAPED}"/g      \
                                                                  | /bin/sed s/'\%BAMBOO_DB_URL\%'/"${BAMBOO_DB_URL_ESCAPED}"/g            \
                                                                  | /bin/sed s/'\%BAMBOO_DB_USER\%'/"${BAMBOO_DB_USER_ESCAPED}"/g          \
                                                                  | /bin/sed s/'\%BAMBOO_DB_PASSWORD\%'/"${BAMBOO_DB_PASSWORD_ESCAPED}"/g  \
                                                                  | /bin/sed s/'\%BAMBOO_FE_NAME\%'/"${BAMBOO_FE_NAME_ESCAPED}"/g          \
                                                                  | /bin/sed s/'\%BAMBOO_FE_PORT\%'/"${BAMBOO_FE_PORT_ESCAPED}"/g          \
                                                                  | /bin/sed s/'\%BAMBOO_FE_PROTO\%'/"${BAMBOO_FE_PROTO_ESCAPED}"/g        \
                                                                  >/usr/local/atlassian/bamboo/conf/server.xml
    
    /bin/chown bamboo:bamboo /usr/local/atlassian/bamboo/conf/server.xml
    /bin/chmod 640 /usr/local/atlassian/bamboo/conf/server.xml
    /bin/rm -f /usr/local/atlassian/bamboo/conf/server.xml.template
fi

if [ -f /usr/local/atlassian/bamboo/bin/setenv.sh.template ]; then
    export JAVA_MEM_MAX_ESCAPED=$(/bin/echo ${JAVA_MEM_MAX} | sed s/'\\'/'\\\\'/g | sed s/'\/'/'\\\/'/g | sed s/'('/'\\('/g | sed s/')'/'\\)'/g | sed s/'&'/'\\&'/g)
    export JAVA_MEM_MIN_ESCAPED=$(/bin/echo ${JAVA_MEM_MIN} | sed s/'\\'/'\\\\'/g | sed s/'\/'/'\\\/'/g | sed s/'('/'\\('/g | sed s/')'/'\\)'/g | sed s/'&'/'\\&'/g)

    /bin/cat /usr/local/atlassian/bamboo/bin/setenv.sh.template | /bin/sed s/'\%JAVA_MEM_MIN\%'/"${JAVA_MEM_MIN_ESCAPED}"/g      \
                                                                | /bin/sed s/'\%JAVA_MEM_MAX\%'/"${JAVA_MEM_MAX_ESCAPED}"/g      \
                                                                >/usr/local/atlassian/bamboo/bin/setenv.sh
    
    /bin/chown bamboo:bamboo /usr/local/atlassian/bamboo/bin/setenv.sh
    /bin/chmod 750 /usr/local/atlassian/bamboo/bin/setenv.sh
    /bin/rm -f /usr/local/atlassian/bamboo/bin/setenv.sh.template
fi

if [ -f /var/atlassian/bamboo/xml-data/configuration/atlassian-user.xml.template ]; then
    export CONFIGURE_LDAP_AUTH_ESCAPED=$(/bin/echo ${CONFIGURE_LDAP_AUTH} | sed s/'\\'/'\\\\'/g | sed s/'\/'/'\\\/'/g | sed s/'('/'\\('/g | sed s/')'/'\\)'/g | sed s/'&'/'\\&'/g | sed -r s/'[ ]+'/''/g)
    export LDAP_HOST_ESCAPED=$(/bin/echo ${LDAP_HOST} | sed s/'\\'/'\\\\'/g | sed s/'\/'/'\\\/'/g | sed s/'('/'\\('/g | sed s/')'/'\\)'/g | sed s/'&'/'\\&'/g)
    export LDAP_PORT_ESCAPED=$(/bin/echo ${LDAP_PORT} | sed s/'\\'/'\\\\'/g | sed s/'\/'/'\\\/'/g | sed s/'('/'\\('/g | sed s/')'/'\\)'/g | sed s/'&'/'\\&'/g)
    export LDAP_BIND_DN_ESCAPED=$(/bin/echo ${LDAP_BIND_DN} | sed s/'\\'/'\\\\'/g | sed s/'\/'/'\\\/'/g | sed s/'('/'\\('/g | sed s/')'/'\\)'/g | sed s/'&'/'\\&'/g)
    export LDAP_BIND_DN_PW_ESCAPED=$(/bin/echo ${LDAP_BIND_DN_PW} | sed s/'\\'/'\\\\'/g | sed s/'\/'/'\\\/'/g | sed s/'('/'\\('/g | sed s/')'/'\\)'/g | sed s/'&'/'\\&'/g)
    export LDAP_BASE_DN_ESCAPED=$(/bin/echo ${LDAP_BASE_DN} | sed s/'\\'/'\\\\'/g | sed s/'\/'/'\\\/'/g | sed s/'('/'\\('/g | sed s/')'/'\\)'/g | sed s/'&'/'\\&'/g)
    export LDAP_PEOPLE_NS_ESCAPED=$(/bin/echo ${LDAP_PEOPLE_NS} | sed s/'\\'/'\\\\'/g | sed s/'\/'/'\\\/'/g | sed s/'('/'\\('/g | sed s/')'/'\\)'/g | sed s/'&'/'\\&'/g)
    export LDAP_GROUP_NS_ESCAPED=$(/bin/echo ${LDAP_GROUP_NS} | sed s/'\\'/'\\\\'/g | sed s/'\/'/'\\\/'/g | sed s/'('/'\\('/g | sed s/')'/'\\)'/g | sed s/'&'/'\\&'/g)
    export LDAP_USERNAME_ATTR_ESCAPED=$(/bin/echo ${LDAP_USERNAME_ATTR} | sed s/'\\'/'\\\\'/g | sed s/'\/'/'\\\/'/g | sed s/'('/'\\('/g | sed s/')'/'\\)'/g | sed s/'&'/'\\&'/g)
    export LDAP_USERSEARCH_FILTER_ESCAPED=$(/bin/echo ${LDAP_USERSEARCH_FILTER} | sed s/'\\'/'\\\\'/g | sed s/'\/'/'\\\/'/g | sed s/'('/'\\('/g | sed s/')'/'\\)'/g | sed s/'&'/'\\&'/g)

    if [ "${CONFIGURE_LDAP_AUTH_ESCAPED}" == "TRUE" -o "${CONFIGURE_LDAP_AUTH_ESCAPED}" == "true" ]; then
        /bin/cat /var/atlassian/bamboo/xml-data/configuration/atlassian-user.xml.template | /bin/sed s/'\%LDAP_HOST\%'/"${LDAP_HOST_ESCAPED}"/g                                     \
                                                                                          | /bin/sed s/'\%LDAP_PORT\%'/"${LDAP_PORT_ESCAPED}"/g                                     \
                                                                                          | /bin/sed s/'\%LDAP_BIND_DN\%'/"${LDAP_BIND_DN_ESCAPED}"/g                               \
                                                                                          | /bin/sed s/'\%LDAP_BIND_DN_PW\%'/"${LDAP_BIND_DN_PW_ESCAPED}"/g                         \
                                                                                          | /bin/sed s/'\%LDAP_BASE_DN\%'/"${LDAP_BASE_DN_ESCAPED}"/g                               \
                                                                                          | /bin/sed s/'\%LDAP_PEOPLE_NS\%'/"${LDAP_PEOPLE_NS_ESCAPED}"/g                           \
                                                                                          | /bin/sed s/'\%LDAP_GROUP_NS\%'/"${LDAP_GROUP_NS_ESCAPED}"/g                             \
                                                                                          | /bin/sed s/'\%LDAP_USERNAME_ATTR\%'/"${LDAP_USERNAME_ATTR_ESCAPED}"/g                   \
                                                                                          | /bin/sed s/'\%LDAP_USERSEARCH_FILTER\%'/"${LDAP_USERSEARCH_FILTER_ESCAPED}"/g           \
                                                                                          > /var/atlassian/bamboo/xml-data/configuration/atlassian-user.xml
    fi
    
    /bin/chown bamboo:bamboo /var/atlassian/bamboo/xml-data/configuration/atlassian-user.xml
    /bin/chmod 640 /var/atlassian/bamboo/xml-data/configuration/atlassian-user.xml
fi

# --- Prerequisities finished, all clear for takeoff.

# --- Environment variables.
export APP=bamboo
export USER=bamboo
export CONF_USER=bamboo
export BASE=/usr/local/atlassian/bamboo
export CATALINA_HOME="/usr/local/atlassian/bamboo"
export CATALINA_BASE="/usr/local/atlassian/bamboo"
export LANG=en_GB.UTF-8

# --- Start Bamboo
/usr/bin/su -m ${USER} -c "ulimit -n 63536 && cd $BASE && $BASE/bin/start-bamboo.sh -fg"

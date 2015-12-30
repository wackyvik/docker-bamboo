# Container parameters
NAME = larionov/bamboo
VERSION = $(shell /bin/cat BAMBOO.VERSION)
JAVA_OPTS = -Djava.io.tmpdir=/var/tmp -XX:-UseAESIntrinsics -Dcom.sun.net.ssl.checkRevocation=false
MEMORY_LIMIT = 8192
CONFIGURE_SQL_DATASOURCE = FALSE
CONFIGURE_FRONTEND = FALSE
CONFIGURE_LDAP_AUTH = FALSE
BAMBOO_DB_DRIVER = org.postgresql.Driver
BAMBOO_DB_URL = jdbc:postgresql://docker0:5432/bamboo?useUnicode=true&amp;characterEncoding=utf8
BAMBOO_DB_USER = bamboo
BAMBOO_DB_PASSWORD = bamboo
BAMBOO_FE_NAME = bamboo.local
BAMBOO_FE_PORT = 443
BAMBOO_FE_PROTO = https
CPU_LIMIT_CPUS = 5-7
CPU_LIMIT_LOAD = 100
IO_LIMIT = 500
LDAP_HOST = docker0
LDAP_PORT = 389
LDAP_BIND_DN = uid=bamboo,ou=services,dc=atlassian,dc=com
LDAP_BIND_DN_PW = bamboo
LDAP_BASE_DN = dc=atlassian,dc=com
LDAP_PEOPLE_NS = ou=people,dc=atlassian,dc=com
LDAP_GROUP_NS = ou=groups,dc=atlassian,dc=com
LDAP_USERNAME_ATTR = uid
LDAP_USERSEARCH_FILTER = (objectClass=inetorgperson)

# Calculated parameters.
VOLUMES_FROM = $(shell if [ $$(/usr/bin/docker ps -a | /bin/grep -i "$(NAME)" | /bin/wc -l) -gt 0 ]; then /bin/echo -en "--volumes-from="$$(/usr/bin/docker ps -a | /bin/grep -i "$(NAME)" | /bin/tail -n 1 | /usr/bin/awk "{print \$$1}"); fi)
SWAP_LIMIT = $(shell /bin/echo $$[$(MEMORY_LIMIT)*2])
JAVA_MEM_MAX = $(shell /bin/echo $$[$(MEMORY_LIMIT)-32+$(SWAP_LIMIT)])m
JAVA_MEM_MIN = $(shell /bin/echo $$[$(MEMORY_LIMIT)/4])m
CPU_LIMIT_LOAD_THP = $(shell /bin/echo $$[$(CPU_LIMIT_LOAD)*1000])
IMAGE_ID = $(shell /usr/bin/docker images | /bin/grep "$(NAME)" | /bin/grep $(VERSION) | /bin/awk "{print \$$3}")

.PHONY: all build install

all: build install

build:
	/usr/bin/docker build -t $(NAME):$(VERSION) --rm image

install:
	/usr/bin/docker run --publish 8093:8085 --name=bamboo-$(VERSION) $(VOLUMES_FROM)                          \
						-e CONFIGURE_SQL_DATASOURCE="$(CONFIGURE_SQL_DATASOURCE)"         \
						-e CONFIGURE_FRONTEND="$(CONFIGURE_FRONTEND)"                     \
						-e CONFIGURE_LDAP_AUTH="$(CONFIGURE_LDAP_AUTH)"                   \
						-e JAVA_OPTS="$(JAVA_OPTS)"                                       \
						-e JAVA_MEM_MAX="$(JAVA_MEM_MAX)"                                 \
						-e JAVA_MEM_MIN="$(JAVA_MEM_MIN)"                                 \
						-e BAMBOO_DB_DRIVER="$(BAMBOO_DB_DRIVER)"                         \
						-e BAMBOO_DB_URL="$(BAMBOO_DB_URL)"                               \
						-e BAMBOO_DB_USER="$(BAMBOO_DB_USER)"                             \
						-e BAMBOO_DB_PASSWORD="$(BAMBOO_DB_PASSWORD)"                     \
						-e BAMBOO_FE_NAME="$(BAMBOO_FE_NAME)"                             \
						-e BAMBOO_FE_PORT="$(BAMBOO_FE_PORT)"                             \
						-e BAMBOO_FE_PROTO="$(BAMBOO_FE_PROTO)"                           \
                                                -e LDAP_HOST="$(LDAP_HOST)"                                       \
                                                -e LDAP_PORT="$(LDAP_PORT)"                                       \
                                                -e LDAP_BIND_DN="$(LDAP_BIND_DN)"                                 \
                                                -e LDAP_BIND_DN_PW="$(LDAP_BIND_DN_PW)"                           \
                                                -e LDAP_BASE_DN="$(LDAP_BASE_DN)"                                 \
                                                -e LDAP_PEOPLE_NS="$(LDAP_PEOPLE_NS)"                             \
                                                -e LDAP_GROUP_NS="$(LDAP_GROUP_NS)"                               \
                                                -e LDAP_USERNAME_ATTR="$(LDAP_USERNAME_ATTR)"                     \
                                                -e LDAP_USERSEARCH_FILTER="$(LDAP_USERSEARCH_FILTER)"             \
						-m $(MEMORY_LIMIT)M --memory-swap $(JAVA_MEM_MAX)                 \
						--oom-kill-disable=false                                          \
						--cpuset-cpus=$(CPU_LIMIT_CPUS) --cpu-quota=$(CPU_LIMIT_LOAD_THP) \
						--blkio-weight=$(IO_LIMIT)                                        \
						-d larionov/bamboo:$(VERSION)

tag_version:
	@if [ -z "$(IMAGE_ID)" ]; then /bin/echo "Image is not yet built. Please run 'make build' before attempting once again."; false; fi
	/usr/bin/docker tag $(IMAGE_ID) $(NAME):$(VERSION)

tag_latest:
	@if [ -z "$(IMAGE_ID)" ]; then /bin/echo "Image is not yet built. Please run 'make build' before attempting once again."; false; fi
	/usr/bin/docker tag $(IMAGE_ID) $(NAME):latest

push:
	/usr/bin/docker push $(NAME)

release: tag_version tag_latest push


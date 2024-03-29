VERSION = 0.3.0
PROJECT_NAME = ovena

DIST = ./dist/$(PROJECT_NAME)

# Location for Orthanc configuration
OVENA_CONFIG = /usr/local/etc/ovena

# Name of docker image of PostgreSQL
DATABASE_DOCKER_IMAGE = database

# Name of PostgreSQL Database to use for orthanc
DATABASE_NAME = orthanc

# Name of PostgreSQL Database to use for orthanc
DATABASE_USERNAME = orthanc

$(shell if [ ! -e .env ]; then cp dot-env .env; fi)

include .env
export $(shell sed 's/=.*//' .env)

TARBALL = $(dir $(DIST))/$(PROJECT_NAME)-$(VERSION).tgz
INSTALLER = bin/ovena-install.sh

.PHONY: clean all substitution deploy github-release tarball

clean:
	rm -rf $(dir $(DIST))

all: $(DIST)/bin $(DIST)/docker substitution

$(DIST):
	mkdir -p $(DIST)

$(DIST)/bin: $(DIST)
	cp -Rv bin $@
	mv $(DIST)/$(INSTALLER) $(DIST)

$(DIST)/docker: $(DIST)
	cp -Rv docker $@

substitution:
# Substitute all $<> variables
	find $(DIST) -type f -exec sed -i'' -e "s#\$$<DATABASE_DOCKER_IMAGE>#${DATABASE_DOCKER_IMAGE}#g" {} \;
	find $(DIST) -type f -exec sed -i'' -e "s#\$$<DATABASE_NAME>#${DATABASE_NAME}#g" {} \;
	find $(DIST) -type f -exec sed -i'' -e "s#\$$<DATABASE_USERNAME>#${DATABASE_USERNAME}#g" {} \;
	find $(DIST) -type f -exec sed -i'' -e "s#\$$<OVENA_CONFIG>#${OVENA_CONFIG}#g" {} \;
	find $(DIST) -type f -exec sed -i'' -e "s#\$$<ORTHANC_IP>#${ORTHANC_IP}#g" {} \;
	find $(DIST) -type f -exec sed -i'' -e "s#\$$<SMB_USER>#${SMB_USER}#g" {} \;
	find $(DIST) -type f -exec sed -i'' -e "s#\$$<SMB_PASS>#${SMB_PASS}#g" {} \;
	find $(DIST) -type f -exec sed -i'' -e "s#\$$<SMB_DOMAIN>#${SMB_DOMAIN}#g" {} \;
	find $(DIST) -type f -exec sed -i'' -e "s#\$$<SMB_SERVER>#${SMB_SERVER}#g" {} \;
	find $(DIST) -type f -exec sed -i'' -e "s#\$$<SMB_SHARE>#${SMB_SHARE}#g" {} \;
	find $(DIST) -type f -exec sed -i'' -e "s#\$$<SMB_SHARE_DB_BACKUP>#${SMB_SHARE_DB_BACKUP}#g" {} \;
	find $(DIST) -type f -exec sed -i'' -e "s#\$$<PROJECT_NAME>#${PROJECT_NAME}#g" {} \;

tarball: $(TARBALL)

$(TARBALL): all
	cd $(DIST)/.. && tar zcvf ../$(notdir $@) --exclude='$(notdir $@)' ./
	rm -rf $(DIST)
	mv $(notdir $@) $@

deploy: $(TARBALL)
# Fully expanded rsync options. Same as -auv, except without --time --perms
	scp "$(TARBALL)" "$(DEST_SERVER):/tmp" 
	echo "WARNING!! Next step will prompt for root password, and restart orthanc server !!"
	echo "Ctrl-C to interrupt"
	read A
	ssh -t "$(DEST_SERVER)" "cd /tmp && rm -rf ovena && tar zxvf $(notdir $(TARBALL)) && cd $(PROJECT_NAME) && ./$(notdir $(INSTALLER))"

github-release:
	gh release create v$(VERSION) $(TARBALL) --generate-notes --title "$(PROJECT_NAME)-$(VERSION)" 
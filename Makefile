USE_BRANDING := yes
IMPORT_BRANDING := yes
ifdef B_BASE
include $(B_BASE)/common.mk
include $(B_BASE)/rpmbuild.mk
else
COMPONENT := nova
include ../../mk/easy-config.mk
endif

REPO := $(call hg_loc,$(COMPONENT))
VPX_REPO := $(call hg_loc,os-vpx)


LP_NOVA_BRANCH ?= lp:nova


NOVA_UPSTREAM := $(shell test -d /repos/nova && \
			 readlink -f /repos/nova || \
			 readlink -f $(REPO)/upstream)
NOVACLIENT_UPSTREAM := $(shell test -d /repos/python-novaclient && \
			 readlink -f /repos/python-novaclient || \
			 readlink -f $(REPO)/python-novaclient)


NOVA_VERSION := $(shell sh -c "(cat $(NOVA_UPSTREAM)/nova/version.py; \
                                echo 'print canonical_version_string()') | \
                               python")
NOVA_FULLNAME := openstack-nova-$(NOVA_VERSION)-$(BUILD_NUMBER)
NOVA_SPEC := $(MY_OBJ_DIR)/openstack-nova.spec
NOVA_TARBALL := $(MY_OBJ_DIR)/SOURCES/$(NOVA_FULLNAME).tar.gz
NOVA_RPM := $(MY_OUTPUT_DIR)/RPMS/noarch/$(NOVA_FULLNAME).noarch.rpm
NOVA_SRPM := $(MY_OUTPUT_DIR)/SRPMS/$(NOVA_FULLNAME).src.rpm

NOVACLIENT_VERSION := $(shell sed -ne 's,^.*version="\(.*\)".*$$,\1,p' \
                                      $(NOVACLIENT_UPSTREAM)/setup.py)
NOVACLIENT_FULLNAME := python-novaclient-$(NOVACLIENT_VERSION)-$(BUILD_NUMBER)
NOVACLIENT_SPEC := $(MY_OBJ_DIR)/python-novaclient.spec
NOVACLIENT_TARBALL := $(MY_OBJ_DIR)/SOURCES/$(NOVACLIENT_FULLNAME).tar.gz
NOVACLIENT_RPM := $(MY_OUTPUT_DIR)/RPMS/noarch/$(NOVACLIENT_FULLNAME).noarch.rpm
NOVACLIENT_SRPM := $(MY_OUTPUT_DIR)/SRPMS/$(NOVACLIENT_FULLNAME).src.rpm

EPEL_RPM_DIR := $(CARBON_DISTFILES)/epel5
EPEL_YUM_DIR := $(MY_OBJ_DIR)/epel5

EPEL_REPOMD_XML := $(EPEL_YUM_DIR)/repodata/repomd.xml
REPOMD_XML := $(MY_OUTPUT_DIR)/repodata/repomd.xml

DEB_NOVA_VERSION := $(shell head -1 $(REPO)/upstream/debian/changelog | \
                          sed -ne 's,^.*(\(.*\)).*$$,\1,p')
PYTHON_NOVA_DEB := $(MY_OUTPUT_DIR)/python-nova_$(DEB_NOVA_VERSION)_all.deb
NOVA_AJAX_CONSOLE_PROXY_DEB := $(MY_OUTPUT_DIR)/nova-ajax-console-proxy_$(DEB_NOVA_VERSION)_all.deb
NOVA_API_DEB := $(MY_OUTPUT_DIR)/nova-api_$(DEB_NOVA_VERSION)_all.deb
NOVA_COMMON_DEB := $(MY_OUTPUT_DIR)/nova-common_$(DEB_NOVA_VERSION)_all.deb
NOVA_COMPUTE_DEB := $(MY_OUTPUT_DIR)/nova-compute_$(DEB_NOVA_VERSION)_all.deb
NOVA_DOC_DEB := $(MY_OUTPUT_DIR)/nova-doc_$(DEB_NOVA_VERSION)_all.deb
NOVA_NETWORK_DEB := $(MY_OUTPUT_DIR)/nova-network_$(DEB_NOVA_VERSION)_all.deb
NOVA_SCHEDULER_DEB := $(MY_OUTPUT_DIR)/nova-scheduler_$(DEB_NOVA_VERSION)_all.deb
NOVA_VNCPROXY_DEB := $(MY_OUTPUT_DIR)/nova-vncproxy_$(DEB_NOVA_VERSION)_all.deb
NOVA_VOLUME_DEB := $(MY_OUTPUT_DIR)/nova-volume_$(DEB_NOVA_VERSION)_all.deb

DEBS := $(PYTHON_NOVA_DEB) $(NOVA_AJAX_CONSOLE_PROXY_DEB) $(NOVA_API_DEB) \
	$(NOVA_COMMON_DEB) $(NOVA_COMPUTE_DEB) $(NOVA_DOC_DEB) \
	$(NOVA_NETWORK_DEB) $(NOVA_SCHEDULER_DEB) $(NOVA_VNCPROXY_DEB) \
	$(NOVA_VOLUME_DEB)
RPMS := $(NOVA_RPM) $(NOVA_SRPM) $(NOVACLIENT_RPM) $(NOVACLIENT_SRPM)
OUTPUT := $(RPMS) $(REPOMD_XML)

.PHONY: build
build: $(OUTPUT)

.PHONY: debs
debs: $(DEBS)

$(NOVA_AJAX_CONSOLE_PROXY_DEB): $(PYTHON_NOVA_DEB)
$(NOVA_API_DEB): $(PYTHON_NOVA_DEB)
$(NOVA_COMMON_DEB): $(PYTHON_NOVA_DEB)
$(NOVA_COMPUTE_DEB): $(PYTHON_NOVA_DEB)
$(NOVA_DOC_DEB): $(PYTHON_NOVA_DEB)
$(NOVA_NETWORK_DEB): $(PYTHON_NOVA_DEB)
$(NOVA_SCHEDULER_DEB): $(PYTHON_NOVA_DEB)
$(NOVA_VNCPROXY_DEB): $(PYTHON_NOVA_DEB)
$(NOVA_VOLUME_DEB): $(PYTHON_NOVA_DEB)
$(PYTHON_NOVA_DEB): $(shell find $(REPO)/upstream -type f)
	@if ls $(REPO)/*.deb >/dev/null 2>&1; \
	then \
	  echo "Refusing to run with .debs in $(REPO)." >&2; \
	  exit 1; \
	fi
	cd $(REPO)/upstream; \
	  DEB_BUILD_OPTIONS=nocheck dpkg-buildpackage -us -uc -d -b
	rm nova-compute-*.deb
	rm nova-objectstore*.deb
	mv $(REPO)/*.deb $(@D)
	rm $(REPO)/*.changes
	# The log files end up newer than the .debs, so we never reach a
	# fixed point given this rule's dependency unless we remove them.
	rm $(REPO)/upstream/debian/*.debhelper.log

$(NOVA_SRPM): $(NOVA_RPM)
$(NOVA_RPM): $(NOVA_SPEC) $(NOVA_TARBALL) $(EPEL_REPOMD_XML) \
	     $(shell find $(REPO)/openstack-nova -type f)
	cp -f $(REPO)/openstack-nova/* $(MY_OBJ_DIR)/SOURCES
	sh build-nova.sh $@ $< $(MY_OBJ_DIR)/SOURCES

$(MY_OBJ_DIR)/%.spec: $(REPO)/openstack-nova/%.spec.in
	mkdir -p $(dir $@)
	$(call brand,$^) >$@
	sed -e 's,@NOVA_VERSION@,$(NOVA_VERSION),g' -i $@

$(NOVA_TARBALL): $(shell find $(NOVA_UPSTREAM) -type f)
	rm -rf $@ $(MY_OBJ_DIR)/openstack-nova-$(NOVA_VERSION)
	mkdir -p $(@D)
	cp -a $(NOVA_UPSTREAM) $(MY_OBJ_DIR)/openstack-nova-$(NOVA_VERSION)
	tar -C $(MY_OBJ_DIR) -czf $@ openstack-nova-$(NOVA_VERSION)

$(NOVACLIENT_SRPM): $(NOVACLIENT_RPM)
$(NOVACLIENT_RPM): $(NOVACLIENT_SPEC) $(NOVACLIENT_TARBALL) \
	     $(shell find $(REPO)/python-novaclient-packages -type f)
	cp -f $(REPO)/python-novaclient-packages/* $(MY_OBJ_DIR)/SOURCES
	sh build-nova.sh $@ $< $(MY_OBJ_DIR)/SOURCES

$(MY_OBJ_DIR)/%.spec: $(REPO)/python-novaclient-packages/%.spec.in
	mkdir -p $(dir $@)
	$(call brand,$^) >$@
	sed -e 's,@NOVACLIENT_VERSION@,$(NOVACLIENT_VERSION),g' -i $@

$(NOVACLIENT_TARBALL): $(shell find $(NOVACLIENT_UPSTREAM) -type f)
	rm -rf $@ $(MY_OBJ_DIR)/python-novaclient-$(NOVACLIENT_VERSION)
	mkdir -p $(@D)
	cp -a $(NOVACLIENT_UPSTREAM) \
              $(MY_OBJ_DIR)/python-novaclient-$(NOVACLIENT_VERSION)
	tar -C $(MY_OBJ_DIR) -czf $@ python-novaclient-$(NOVACLIENT_VERSION)

$(REPOMD_XML): $(RPMS)
	createrepo $(MY_OUTPUT_DIR)

$(EPEL_REPOMD_XML): $(wildcard $(EPEL_RPM_DIR)/%)
	$(call mkdir_clean,$(EPEL_YUM_DIR))
	cp -s $(EPEL_RPM_DIR)/* $(EPEL_YUM_DIR)
	createrepo $(EPEL_YUM_DIR)

.PHONY: rebase
rebase:
	@sh $(VPX_REPO)/rebase.sh $(LP_NOVA_BRANCH) $(REPO)/upstream

.PHONY: clean
clean:
	rm -f $(OUTPUT)
	rm -rf $(MY_OBJ_DIR)/*

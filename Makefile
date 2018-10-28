# Copyright 2017 Sandvine
# Copyright 2017-2018 Telefonica
# All Rights Reserved.
# 
#    Licensed under the Apache License, Version 2.0 (the "License"); you may
#    not use this file except in compliance with the License. You may obtain
#    a copy of the License at
# 
#         http://www.apache.org/licenses/LICENSE-2.0
# 
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#    WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#    License for the specific language governing permissions and limitations
#    under the License.

# NOTE: pyang and pyangbind are required for build

PYANG:= pyang
PYBINDPLUGIN:=$(shell /usr/bin/env python3 -c \
	            'import pyangbind; import os; print("{}/plugin".format(os.path.dirname(pyangbind.__file__)))')

YANG_DESC_MODELS := vnfd nsd
YANG_RECORD_MODELS := vnfr nsr
PYTHON_MODELS := $(addsuffix .py, $(YANG_DESC_MODELS))
YANG_DESC_TREES := $(addsuffix .tree.txt, $(YANG_DESC_MODELS))
YANG_DESC_JSTREES := $(addsuffix .html, $(YANG_DESC_MODELS))
YANG_RECORD_TREES := $(addsuffix .rec.tree.txt, $(YANG_RECORD_MODELS))
YANG_RECORD_JSTREES := $(addsuffix .rec.html, $(YANG_RECORD_MODELS))

OUT_DIR := osm_im
TREES_DIR := osm_im_trees
MODEL_DIR := models/yang
RW_PB_EXT := build/yang/rw-pb-ext.yang
Q?=@

PYANG_OPTIONS := -Werror

all: $(PYTHON_MODELS) trees
	$(MAKE) package

trees: $(YANG_DESC_TREES) $(YANG_DESC_JSTREES) $(YANG_RECORD_TREES) $(YANG_RECORD_JSTREES)

$(OUT_DIR):
	$(Q)mkdir -p $(OUT_DIR)
	$(Q)touch $(OUT_DIR)/__init__.py

$(TREES_DIR):
	$(Q)mkdir -p $(TREES_DIR)

%.py: $(OUT_DIR) $(RW_PB_EXT)
	$(Q)echo generating $@ from $*.yang
	$(Q)pyang $(PYANG_OPTIONS) --path build/yang --path $(MODEL_DIR) --plugindir $(PYBINDPLUGIN) -f pybind -o $(OUT_DIR)/$@ $(MODEL_DIR)/$*.yang

%.tree.txt: $(TREES_DIR)
	$(Q)echo generating $@ from $*.yang
	$(Q)pyang $(PYANG_OPTIONS) --path build/yang --path $(MODEL_DIR) -f tree -o $(TREES_DIR)/$@ $(MODEL_DIR)/$*.yang

%.html: $(TREES_DIR)
	$(Q)echo generating $@ from $*.yang
	$(Q)pyang $(PYANG_OPTIONS) --path build/yang --path $(MODEL_DIR) -f jstree -o $(TREES_DIR)/$@ $(MODEL_DIR)/$*.yang
	$(Q)sed -r -i 's|data\:image/gif\;base64,R0lGODlhS.*RCAA7|https://osm.etsi.org/images/OSM-logo.png\" width=\"175\" height=\"60|g' $(TREES_DIR)/$@
	$(Q)sed -r -i 's|<a href=\"http://www.tail-f.com">|<a href="http://osm.etsi.org">|g' $(TREES_DIR)/$@

%.rec.tree.txt: $(TREES_DIR)
	$(Q)echo generating $@ from $*.yang
	$(Q)pyang $(PYANG_OPTIONS) --path build/yang --path $(MODEL_DIR) -f tree -o $(TREES_DIR)/$@ $(MODEL_DIR)/$*.yang
	$(Q)mv $(TREES_DIR)/$@ $(TREES_DIR)/$*.tree.txt

%.rec.html: $(TREES_DIR)
	$(Q)echo generating $@ from $*.yang
	$(Q)pyang $(PYANG_OPTIONS) --path build/yang --path $(MODEL_DIR) -f jstree -o $(TREES_DIR)/$@ $(MODEL_DIR)/rw-project.yang $(MODEL_DIR)/$*.yang
	$(Q)sed -r -i 's|data\:image/gif\;base64,R0lGODlhS.*RCAA7|https://osm.etsi.org/images/OSM-logo.png\" width=\"175\" height=\"60|g' $(TREES_DIR)/$@
	$(Q)sed -r -i 's|<a href=\"http://www.tail-f.com">|<a href="http://osm.etsi.org">|g' $(TREES_DIR)/$@
	$(Q)mv $(TREES_DIR)/$@ $(TREES_DIR)/$*.html

$(RW_PB_EXT):
	$(Q)mkdir -p $$(dirname $@)
	$(Q)wget -q https://raw.githubusercontent.com/RIFTIO/RIFT.ware/RIFT.ware-4.4.1/modules/core/util/yangtools/yang/rw-pb-ext.yang -O $@

package:
	tox -e build
	tox -e build3
	./build-docs.sh

clean:
	$(Q)rm -rf build dist osm_im.egg-info deb deb_dist *.gz $(OUT_DIR) $(TREES_DIR)

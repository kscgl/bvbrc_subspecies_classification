TOP_DIR = ../..
include $(TOP_DIR)/tools/Makefile.common

DEPLOY_RUNTIME ?= /kb/runtime
TARGET ?= /kb/deployment

APP_SERVICE = app_service

SRC_PERL = $(wildcard scripts/*.pl)
BIN_PERL = $(addprefix $(BIN_DIR)/,$(basename $(notdir $(SRC_PERL))))
DEPLOY_PERL = $(addprefix $(TARGET)/bin/,$(basename $(notdir $(SRC_PERL))))

WRAP_PYTHON_TOOL = wrap_python3
WRAP_PYTHON_SCRIPT = bash $(TOOLS_DIR)/$(WRAP_PYTHON3_TOOL).sh

SRC_PYTHON = $(wildcard scripts/*.py)
BIN_PYTHON = $(addprefix $(BIN_DIR)/,$(basename $(notdir $(SRC_PYTHON))))
DEPLOY_PYTHON = $(addprefix $(TARGET)/bin/,$(basename $(notdir $(SRC_PYTHON))))

SRC_SERVICE_PERL = $(wildcard service-scripts/*.pl)
BIN_SERVICE_PERL = $(addprefix $(BIN_DIR)/,$(basename $(notdir $(SRC_SERVICE_PERL))))
DEPLOY_SERVICE_PERL = $(addprefix $(SERVICE_DIR)/bin/,$(basename $(notdir $(SRC_SERVICE_PERL))))

CLIENT_TESTS = $(wildcard t/client-tests/*.t)
SERVER_TESTS = $(wildcard t/server-tests/*.t)
PROD_TESTS = $(wildcard t/prod-tests/*.t)

STARMAN_WORKERS = 8
STARMAN_MAX_REQUESTS = 100

TPAGE_BUILD_ARGS =  \
	--define kb_top=$(realpath $(TOP_DIR)) \
	--define kb_runtime=$(KB_RUNTIME) \
	--define module_lib=$(realpath $(TOP_DIR))/modules/bvbrc_subspecies_classification/lib

TPAGE_DEPLOY_ARGS =  \
	--define kb_top=$(TARGET) \
	--define kb_runtime=$(DEPLOY_RUNTIME) \
	--define module_lib=$(TARGET)/lib


TPAGE_ARGS = --define kb_service_name=$(SERVICE) \
	--define kb_service_port=$(SERVICE_PORT) --define kb_service_dir=$(SERVICE_DIR) \
	--define kb_sphinx_port=$(SPHINX_PORT) --define kb_sphinx_host=$(SPHINX_HOST) \
	--define kb_starman_workers=$(STARMAN_WORKERS) \
	--define kb_starman_max_requests=$(STARMAN_MAX_REQUESTS)

all: build-libs bin 

bin: $(BIN_PERL) $(BIN_SERVICE_PERL) $(BIN_PYTHON) $(BIN_SH)

#
# The embedded vigor3 needs to have symlinks to tools created.
#
build-libs:
	$(TPAGE) $(TPAGE_BUILD_ARGS) $(TPAGE_ARGS) rotaAGenotyper.config.tt > lib/rota-a-genotyper/rotaAGenotyper.config
	for tool in perl blastall bl2seq formatdb fastacmd clustalw muscle; do \
	    tpath=lib/rota-a-genotyper/VIGOR3/prod3/$$tool; \
	    rm $$tpath; \
	    ln -s $(KB_RUNTIME)/bin/$$tool $$tpath; \
	done


deploy: deploy-all
deploy-all: deploy-client 
deploy-client: deploy-libs deploy-scripts deploy-docs deploy-config

deploy-config:
	$(TPAGE) $(TPAGE_DEPLOY_ARGS) $(TPAGE_ARGS) rotaAGenotyper.config.tt > $(TARGET)/lib/rota-a-genotyper/rotaAGenotyper.config
	for tool in perl blastall bl2seq formatdb fastacmd clustalw muscle; do \
	    tpath=$(TARGET)/lib/rota-a-genotyper/VIGOR3/prod3/$$tool; \
	    rm $$tpath; \
	    ln -s $(DEPLOY_RUNTIME)/bin/$$tool $$tpath; \
	done
	rm -rf $(TARGET)/lib/rota-a-genotyper/VIGOR3/prod3/vigorscratch
	ln -s /tmp $(TARGET)/lib/rota-a-genotyper/VIGOR3/prod3/vigorscratch

deploy-service: deploy-libs deploy-scripts deploy-service-scripts deploy-specs



deploy-dir:
	if [ ! -d $(SERVICE_DIR) ] ; then mkdir $(SERVICE_DIR) ; fi
	if [ ! -d $(SERVICE_DIR)/bin ] ; then mkdir $(SERVICE_DIR)/bin ; fi

deploy-docs: 


clean:

include $(TOP_DIR)/tools/Makefile.common.rules

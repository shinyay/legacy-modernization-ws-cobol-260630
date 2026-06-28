SUBSYSTEM := 20-integrationout
SRC := src
TESTS := tests/unit
BIN := bin

COBC := cobc
COBCFLAGS := -free -O2 -W -Wno-terminator \
    -I copy/api -I copy/private \
    -I /workspace/shared/copy
LDFLAGS := -L/workspace/shared/util/mq-publish/bin -lmq-publish \
    -Q -Wl,--no-as-needed -Q -Wl,-rpath,/workspace/shared/util/mq-publish/bin

.PHONY: build test-unit clean

MODULES := $(BIN)/INTO-PUBLISH-EVENT.so $(BIN)/INTO-DRAIN-QUEUE.so

AUD_BIN := /workspace/shared/util/aud-write/bin
LOG_BIN := /workspace/shared/util/shared-log/bin
MQ_BIN := /workspace/shared/util/mq-publish/bin

build: $(MODULES)

$(BIN)/INTO-PUBLISH-EVENT.so: $(SRC)/into-publish-event.cob | $(BIN)
	$(COBC) -m $(COBCFLAGS) -o $@ $< $(LDFLAGS)

$(BIN)/INTO-DRAIN-QUEUE.so: $(SRC)/into-drain-queue.cob | $(BIN)
	$(COBC) -m $(COBCFLAGS) -o $@ $<

$(BIN):
	mkdir -p $@

TEST_DRIVER := $(BIN)/into-driver
test-unit: build $(TEST_DRIVER)
	@COB_LIBRARY_PATH=$(BIN):$(AUD_BIN):$(LOG_BIN) \
	 LD_LIBRARY_PATH=$(MQ_BIN):$$LD_LIBRARY_PATH \
	 LD_PRELOAD=/usr/local/lib/libocesql.so \
	 PGHOST=postgres PGUSER=cobol PGPASSWORD=cobol PGDATABASE=banking \
	 bash $(TESTS)/into-test.sh

$(TEST_DRIVER): $(TESTS)/into-driver.cob $(MODULES) | $(BIN)
	$(COBC) -x $(COBCFLAGS) -o $@ $<

clean:
	rm -rf $(BIN)

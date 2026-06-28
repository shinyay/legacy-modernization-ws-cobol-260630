SUBSYSTEM := 19-integrationin
SRC := src
TESTS := tests/unit
BIN := bin

COBC := cobc
COBCFLAGS := -free -O2 -W -Wno-terminator \
    -I copy/api -I copy/private \
    -I /workspace/shared/copy
LDFLAGS := -L/workspace/shared/util/ebc-to-ascii/bin -lebc-to-ascii

.PHONY: build test-unit clean

MODULES := $(BIN)/INTI-DECODE-BATCH.so

AUD_BIN := /workspace/shared/util/aud-write/bin
LOG_BIN := /workspace/shared/util/shared-log/bin
EBC_BIN := /workspace/shared/util/ebc-to-ascii/bin

build: $(MODULES)

$(BIN)/INTI-DECODE-BATCH.so: $(SRC)/inti-decode-batch.cob | $(BIN)
	$(COBC) -m $(COBCFLAGS) -o $@ $< $(LDFLAGS)

$(BIN):
	mkdir -p $@

TEST_DRIVER := $(BIN)/inti-driver
test-unit: build $(TEST_DRIVER)
	@COB_LIBRARY_PATH=$(BIN):$(AUD_BIN):$(LOG_BIN) \
	 LD_LIBRARY_PATH=$(EBC_BIN):$$LD_LIBRARY_PATH \
	 LD_PRELOAD=/usr/local/lib/libocesql.so \
	 PGHOST=postgres PGUSER=cobol PGPASSWORD=cobol PGDATABASE=banking \
	 bash $(TESTS)/inti-test.sh

$(TEST_DRIVER): $(TESTS)/inti-driver.cob $(MODULES) | $(BIN)
	$(COBC) -x $(COBCFLAGS) -o $@ $<

clean:
	rm -rf $(BIN)

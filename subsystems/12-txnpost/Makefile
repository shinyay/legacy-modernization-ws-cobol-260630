SUBSYSTEM := 12-txnpost
SRC := src
TESTS := tests/unit
BIN := bin

COBC := cobc
OCESQL := ocesql
COBCFLAGS_OCESQL := -fixed -O2 -W -Wno-terminator -I copy/api -I copy/private -I/workspace/shared/copy
COBCFLAGS_FREE   := -free  -O2 -W -Wno-terminator -I copy/api -I copy/private -I/workspace/shared/copy
LDFLAGS_OCESQL   := -L/usr/local/lib -locesql -lpq

.PHONY: build test-unit clean

MODULES := $(BIN)/TXPOST-RUN-BATCH.so \
           $(BIN)/TXPOST-REVERSE.so \
           $(BIN)/TXPOST-REPORT-SUMMARY.so

GEN_RUN := $(SRC)/txpost-run-batch.cob.gen
GEN_REV := $(SRC)/txpost-reverse.cob.gen

build: $(MODULES)

$(GEN_RUN): $(SRC)/txpost-run-batch.sqb
	$(OCESQL) $< $@ /tmp/txpost-run-batch.sqlerr

$(GEN_REV): $(SRC)/txpost-reverse.sqb
	$(OCESQL) $< $@ /tmp/txpost-reverse.sqlerr

$(BIN)/TXPOST-RUN-BATCH.so: $(GEN_RUN) | $(BIN)
	$(COBC) -m $(COBCFLAGS_OCESQL) -o $@ $< $(LDFLAGS_OCESQL)
$(BIN)/TXPOST-REVERSE.so: $(GEN_REV) | $(BIN)
	$(COBC) -m $(COBCFLAGS_OCESQL) -o $@ $< $(LDFLAGS_OCESQL)
$(BIN)/TXPOST-REPORT-SUMMARY.so: $(SRC)/txpost-report-summary.cob | $(BIN)
	$(COBC) -m $(COBCFLAGS_FREE) -o $@ $<

$(BIN):
	mkdir -p $@

CAL_BIN := /workspace/subsystems/01-calendar/bin
ACCT_BIN := /workspace/subsystems/08-account/bin
AUD_BIN := /workspace/shared/util/aud-write/bin
LOG_BIN := /workspace/shared/util/shared-log/bin

TEST_DRIVER := $(BIN)/txpost-test
test-unit: build $(TEST_DRIVER)
	@COB_LIBRARY_PATH=$(BIN):$(CAL_BIN):$(ACCT_BIN):$(AUD_BIN):$(LOG_BIN) \
	 LD_PRELOAD=/usr/local/lib/libocesql.so \
	 PGHOST=postgres PGUSER=cobol PGPASSWORD=cobol PGDATABASE=banking \
	 ./$(TEST_DRIVER)

$(TEST_DRIVER): $(TESTS)/txpost-test.cob $(MODULES) | $(BIN)
	$(COBC) -x $(COBCFLAGS_FREE) -o $@ $<

clean:
	rm -rf $(BIN) $(GEN_RUN) $(GEN_REV) /tmp/txpost-*.sqlerr

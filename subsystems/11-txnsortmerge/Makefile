SRC := src
TESTS := tests/unit
BIN := bin
COBC := cobc
COBCFLAGS := -free -O2 -W -I copy/api -I copy/private -I /workspace/shared/copy

.PHONY: build test-unit clean

MODULES := $(BIN)/TXSM-SORT-BATCH.so \
           $(BIN)/TXSM-MERGE-BATCH.so \
           $(BIN)/TXSM-REPORT-SUMMARY.so

build: $(MODULES)

$(BIN)/TXSM-SORT-BATCH.so: $(SRC)/txsm-sort-batch.cob | $(BIN)
	$(COBC) -m $(COBCFLAGS) -o $@ $<
$(BIN)/TXSM-MERGE-BATCH.so: $(SRC)/txsm-merge-batch.cob | $(BIN)
	$(COBC) -m $(COBCFLAGS) -o $@ $<
$(BIN)/TXSM-REPORT-SUMMARY.so: $(SRC)/txsm-report-summary.cob | $(BIN)
	$(COBC) -m $(COBCFLAGS) -o $@ $<

$(BIN):
	mkdir -p $@

LOG_BIN := /workspace/shared/util/shared-log/bin

TEST_DRIVER := $(BIN)/txsm-test
test-unit: build $(TEST_DRIVER)
	@COB_LIBRARY_PATH=$(BIN):$(LOG_BIN) \
	 LD_PRELOAD=/usr/local/lib/libocesql.so \
	 ./$(TEST_DRIVER)

$(TEST_DRIVER): $(TESTS)/txsm-test.cob $(MODULES) | $(BIN)
	$(COBC) -x $(COBCFLAGS) -o $@ $<

clean:
	rm -rf $(BIN) data

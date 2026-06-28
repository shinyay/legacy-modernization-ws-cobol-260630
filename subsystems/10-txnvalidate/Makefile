SRC := src
TESTS := tests/unit
BIN := bin
COBC := cobc
COBCFLAGS := -free -O2 -W -I copy/api -I copy/private -I /workspace/shared/copy

.PHONY: build test-unit clean

MODULES := $(BIN)/TXVAL-VALIDATE-BATCH.so \
           $(BIN)/TXVAL-CHECKPOINT-RECOVER.so \
           $(BIN)/TXVAL-REPORT-SUMMARY.so

build: $(MODULES)

$(BIN)/TXVAL-VALIDATE-BATCH.so: $(SRC)/txval-validate-batch.cob | $(BIN)
	$(COBC) -m $(COBCFLAGS) -o $@ $<
$(BIN)/TXVAL-CHECKPOINT-RECOVER.so: $(SRC)/txval-checkpoint-recover.cob | $(BIN)
	$(COBC) -m $(COBCFLAGS) -o $@ $<
$(BIN)/TXVAL-REPORT-SUMMARY.so: $(SRC)/txval-report-summary.cob | $(BIN)
	$(COBC) -m $(COBCFLAGS) -o $@ $<

$(BIN):
	mkdir -p $@

CAL_BIN := /workspace/subsystems/01-calendar/bin
BR_BIN  := /workspace/subsystems/02-branch/bin
PROD_BIN := /workspace/subsystems/05-product/bin
AUD_BIN := /workspace/shared/util/aud-write/bin
LOG_BIN := /workspace/shared/util/shared-log/bin

TEST_DRIVER := $(BIN)/txval-test
test-unit: build $(TEST_DRIVER)
	@COB_LIBRARY_PATH=$(BIN):$(CAL_BIN):$(BR_BIN):$(PROD_BIN):$(AUD_BIN):$(LOG_BIN) \
	 LD_PRELOAD=/usr/local/lib/libocesql.so \
	 ./$(TEST_DRIVER)

$(TEST_DRIVER): $(TESTS)/txval-test.cob $(MODULES) | $(BIN)
	$(COBC) -x $(COBCFLAGS) -o $@ $<

clean:
	rm -rf $(BIN) data/work data/.checkpoint

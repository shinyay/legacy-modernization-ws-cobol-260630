SRC := src
TESTS := tests/unit
BIN := bin
COBC := cobc
COBCFLAGS := -free -O2 -W -I copy/api -I copy/private -I /workspace/shared/copy

MODULES := $(BIN)/ALC-OPEN.so $(BIN)/ALC-CHANGE-STATE.so \
           $(BIN)/ALC-DORMANCY-SCAN.so $(BIN)/ALC-REACTIVATION-SCAN.so

.PHONY: build test-unit clean
build: $(MODULES)

$(BIN)/ALC-OPEN.so: $(SRC)/alc-open.cob | $(BIN)
	$(COBC) -m $(COBCFLAGS) -o $@ $<
$(BIN)/ALC-CHANGE-STATE.so: $(SRC)/alc-change-state.cob | $(BIN)
	$(COBC) -m $(COBCFLAGS) -o $@ $<
$(BIN)/ALC-DORMANCY-SCAN.so: $(SRC)/alc-dormancy-scan.cob | $(BIN)
	$(COBC) -m $(COBCFLAGS) -o $@ $<
$(BIN)/ALC-REACTIVATION-SCAN.so: $(SRC)/alc-reactivation-scan.cob | $(BIN)
	$(COBC) -m $(COBCFLAGS) -o $@ $<

$(BIN):
	mkdir -p $@

TEST_DRIVER := $(BIN)/alc-test
ACCT_BIN := /workspace/subsystems/08-account/bin
AUD_BIN := /workspace/shared/util/aud-write/bin
LOG_BIN := /workspace/shared/util/shared-log/bin

test-unit: build $(TEST_DRIVER)
	@COB_LIBRARY_PATH=$(BIN):$(ACCT_BIN):$(AUD_BIN):$(LOG_BIN) \
	 LD_PRELOAD=/usr/local/lib/libocesql.so \
	 ./$(TEST_DRIVER)

$(TEST_DRIVER): $(TESTS)/alc-test.cob $(MODULES) | $(BIN)
	$(COBC) -x $(COBCFLAGS) -o $@ $<

clean:
	rm -rf $(BIN)

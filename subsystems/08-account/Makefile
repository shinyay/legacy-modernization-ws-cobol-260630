SRC := src
TESTS := tests/unit
BIN := bin
COBC := cobc
COBCFLAGS := -free -O2 -W -I copy/api -I copy/private -I /workspace/shared/copy

.PHONY: build test-unit clean load-idx

LOADER := $(BIN)/acct-load
MODULES := $(BIN)/ACCT-LOOKUP.so $(BIN)/ACCT-EXISTS.so \
           $(BIN)/ACCT-LOOKUP-BY-CUSTOMER.so \
           $(BIN)/ACCT-UPDATE-DORMANCY-DATE.so

build: $(LOADER) $(MODULES)

$(LOADER): $(SRC)/acct-load.cob | $(BIN)
	$(COBC) -x $(COBCFLAGS) -o $@ $<
$(BIN)/ACCT-LOOKUP.so: $(SRC)/acct-lookup.cob | $(BIN)
	$(COBC) -m $(COBCFLAGS) -o $@ $<
$(BIN)/ACCT-EXISTS.so: $(SRC)/acct-exists.cob | $(BIN)
	$(COBC) -m $(COBCFLAGS) -o $@ $<
$(BIN)/ACCT-LOOKUP-BY-CUSTOMER.so: $(SRC)/acct-lookup-by-customer.cob | $(BIN)
	$(COBC) -m $(COBCFLAGS) -o $@ $<
$(BIN)/ACCT-UPDATE-DORMANCY-DATE.so: $(SRC)/acct-update-dormancy-date.cob | $(BIN)
	$(COBC) -m $(COBCFLAGS) -o $@ $<

$(BIN):
	mkdir -p $@

load-idx: $(LOADER)
	@COB_LIBRARY_PATH=/workspace/shared/util/shared-log/bin ./$<
	@# F-31 fix (Phase 4.5-1): re-seed system accounts that acct-load
	@# OPEN OUTPUT just truncated. ops-seed-system-isam is idempotent.
	@# Phase 11.2.2 hardening: stop masking errors with `tail -3`;
	@# fail this target if ISAM seed fails so CI catches regression.
	@cobc -x -free -W -o /tmp/ops-seed-system-isam \
	    /workspace/subsystems/22-operations/src/ops-seed-system-isam.cob \
	    || { echo "load-idx: failed to compile ops-seed-system-isam" >&2 ; exit 1; }
	@/tmp/ops-seed-system-isam \
	    || { echo "load-idx: ops-seed-system-isam returned non-zero" >&2 ; exit 1; }

TEST_DRIVER := $(BIN)/acct-test
test-unit: build load-idx $(TEST_DRIVER)
	@COB_LIBRARY_PATH=$(BIN):/workspace/shared/util/shared-log/bin ./$(TEST_DRIVER)

$(TEST_DRIVER): $(TESTS)/acct-test.cob $(MODULES) | $(BIN)
	$(COBC) -x $(COBCFLAGS) -o $@ $<

clean:
	rm -rf $(BIN) data/account.idx*

SRC := src
TESTS := tests/unit
BIN := bin
COBC := cobc
CUST_BIN := /workspace/subsystems/03-customer/bin
COBCFLAGS := -free -O2 -W -I copy/api -I /workspace/shared/copy

MODULES := $(BIN)/CSRCH-AND.so $(BIN)/CSRCH-BY-ADDRESS.so $(BIN)/CSRCH-LIST-PAGED.so

.PHONY: build test-unit clean
build: $(MODULES)

$(BIN)/CSRCH-AND.so: $(SRC)/csrch-and.cob | $(BIN)
	$(COBC) -m $(COBCFLAGS) -o $@ $<
$(BIN)/CSRCH-BY-ADDRESS.so: $(SRC)/csrch-by-address.cob | $(BIN)
	$(COBC) -m $(COBCFLAGS) -o $@ $<
$(BIN)/CSRCH-LIST-PAGED.so: $(SRC)/csrch-list-paged.cob | $(BIN)
	$(COBC) -m $(COBCFLAGS) -o $@ $<
$(BIN):
	mkdir -p $@

TEST_DRIVER := $(BIN)/csrch-test
test-unit: build $(TEST_DRIVER)
	@COB_LIBRARY_PATH=$(BIN):$(CUST_BIN):/workspace/shared/util/shared-log/bin \
	 ./$(TEST_DRIVER)
$(TEST_DRIVER): $(TESTS)/csrch-test.cob $(MODULES) | $(BIN)
	$(COBC) -x $(COBCFLAGS) -o $@ $<
clean:
	rm -rf $(BIN)

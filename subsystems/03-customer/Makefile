SRC := src
TESTS := tests/unit
BIN := bin
COBC := cobc
COBCFLAGS := -free -O2 -W -I copy/api -I copy/private -I /workspace/shared/copy

LOADER := $(BIN)/cust-load
MODULES := $(BIN)/CUST-LOOKUP.so $(BIN)/CUST-SEARCH-BY-KANA.so \
           $(BIN)/CUST-SEARCH-BY-PHONE.so $(BIN)/CUST-LIST-ALL.so \
           $(BIN)/CUST-STATUS-CHANGE.so

.PHONY: build test-unit clean load-idx
build: $(LOADER) $(MODULES)

$(LOADER): $(SRC)/cust-load.cob | $(BIN)
	$(COBC) -x $(COBCFLAGS) -o $@ $<

$(BIN)/CUST-LOOKUP.so: $(SRC)/cust-lookup.cob | $(BIN)
	$(COBC) -m $(COBCFLAGS) -o $@ $<
$(BIN)/CUST-SEARCH-BY-KANA.so: $(SRC)/cust-search-by-kana.cob | $(BIN)
	$(COBC) -m $(COBCFLAGS) -o $@ $<
$(BIN)/CUST-SEARCH-BY-PHONE.so: $(SRC)/cust-search-by-phone.cob | $(BIN)
	$(COBC) -m $(COBCFLAGS) -o $@ $<
$(BIN)/CUST-LIST-ALL.so: $(SRC)/cust-list-all.cob | $(BIN)
	$(COBC) -m $(COBCFLAGS) -o $@ $<
$(BIN)/CUST-STATUS-CHANGE.so: $(SRC)/cust-status-change.cob | $(BIN)
	$(COBC) -m $(COBCFLAGS) -o $@ $<

$(BIN):
	mkdir -p $@

load-idx: $(LOADER)
	@COB_LIBRARY_PATH=/workspace/shared/util/shared-log/bin ./$<

TEST_DRIVER := $(BIN)/cust-test
test-unit: build load-idx $(TEST_DRIVER)
	@COB_LIBRARY_PATH=$(BIN):/workspace/shared/util/aud-write/bin:/workspace/shared/util/shared-log/bin \
	 LD_PRELOAD=/usr/local/lib/libocesql.so \
	 ./$(TEST_DRIVER)

$(TEST_DRIVER): $(TESTS)/cust-test.cob $(MODULES) | $(BIN)
	$(COBC) -x $(COBCFLAGS) -o $@ $<

clean:
	rm -rf $(BIN) data/customer.idx*

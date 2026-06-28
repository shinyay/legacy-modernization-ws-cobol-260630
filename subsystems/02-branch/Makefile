SUBSYSTEM := 02-branch
SRC := src
TESTS := tests/unit
BIN := bin
COBC := cobc
COBCFLAGS := -free -O2 -W -I copy/api -I copy/private -I /workspace/shared/copy

LOADER := $(BIN)/br-load
LOOKUP := $(BIN)/BR-LOOKUP.so
LISTREG := $(BIN)/BR-LIST-BY-REGION.so
LISTALL := $(BIN)/BR-LIST-ALL.so

.PHONY: build test-unit clean load-idx

build: $(LOADER) $(LOOKUP) $(LISTREG) $(LISTALL)

$(LOADER): $(SRC)/br-load.cob | $(BIN)
	$(COBC) -x $(COBCFLAGS) -o $@ $<
$(LOOKUP): $(SRC)/br-lookup.cob | $(BIN)
	$(COBC) -m $(COBCFLAGS) -o $@ $<
$(LISTREG): $(SRC)/br-list-by-region.cob | $(BIN)
	$(COBC) -m $(COBCFLAGS) -o $@ $<
$(LISTALL): $(SRC)/br-list-all.cob | $(BIN)
	$(COBC) -m $(COBCFLAGS) -o $@ $<

$(BIN):
	mkdir -p $@

load-idx: $(LOADER)
	@COB_LIBRARY_PATH=/workspace/shared/util/shared-log/bin ./$(LOADER)

TEST_DRIVER := $(BIN)/br-test
test-unit: build load-idx $(TEST_DRIVER)
	@COB_LIBRARY_PATH=$(BIN):/workspace/shared/util/shared-log/bin ./$(TEST_DRIVER)

$(TEST_DRIVER): $(TESTS)/br-test.cob $(LOOKUP) $(LISTREG) $(LISTALL) | $(BIN)
	$(COBC) -x $(COBCFLAGS) -o $@ $<

clean:
	rm -rf $(BIN) data/branch.idx*

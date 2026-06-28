SRC := src
TESTS := tests/unit
BIN := bin
COBC := cobc
COBCFLAGS := -free -O2 -W -I copy/api -I copy/private -I /workspace/shared/copy

.PHONY: build test-unit clean load-idx
build: $(BIN)/irate-load $(BIN)/IRATE-LOOKUP.so
$(BIN)/irate-load: $(SRC)/irate-load.cob | $(BIN)
	$(COBC) -x $(COBCFLAGS) -o $@ $<
$(BIN)/IRATE-LOOKUP.so: $(SRC)/irate-lookup.cob | $(BIN)
	$(COBC) -m $(COBCFLAGS) -o $@ $<
$(BIN):
	mkdir -p $@
load-idx: $(BIN)/irate-load
	@./$<
test-unit: build load-idx $(BIN)/irate-test
	@COB_LIBRARY_PATH=$(BIN) ./$(BIN)/irate-test
$(BIN)/irate-test: $(TESTS)/irate-test.cob $(BIN)/IRATE-LOOKUP.so | $(BIN)
	$(COBC) -x $(COBCFLAGS) -o $@ $<
clean:
	rm -rf $(BIN) data/interestrate.idx*

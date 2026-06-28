SRC := src
TESTS := tests/unit
BIN := bin
COBC := cobc
COBCFLAGS := -free -O2 -W -I copy/api -I copy/private -I /workspace/shared/copy
.PHONY: build test-unit clean load-idx
build: $(BIN)/fee-load $(BIN)/FEE-LOOKUP-BY-TIER.so
$(BIN)/fee-load: $(SRC)/fee-load.cob | $(BIN)
	$(COBC) -x $(COBCFLAGS) -o $@ $<
$(BIN)/FEE-LOOKUP-BY-TIER.so: $(SRC)/fee-lookup-by-tier.cob | $(BIN)
	$(COBC) -m $(COBCFLAGS) -o $@ $<
$(BIN): ; mkdir -p $@
load-idx: $(BIN)/fee-load ; @./$<
test-unit: build load-idx $(BIN)/fee-test
	@COB_LIBRARY_PATH=$(BIN) ./$(BIN)/fee-test
$(BIN)/fee-test: $(TESTS)/fee-test.cob $(BIN)/FEE-LOOKUP-BY-TIER.so | $(BIN)
	$(COBC) -x $(COBCFLAGS) -o $@ $<
clean: ; rm -rf $(BIN) data/feeschedule.idx*

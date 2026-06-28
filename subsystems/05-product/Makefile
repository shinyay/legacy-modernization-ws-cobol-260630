SRC := src
TESTS := tests/unit
BIN := bin
COBC := cobc
COBCFLAGS := -free -O2 -W -I copy/api -I copy/private -I /workspace/shared/copy

.PHONY: build test-unit clean load-idx
build: $(BIN)/prod-load $(BIN)/PROD-LOOKUP.so
$(BIN)/prod-load: $(SRC)/prod-load.cob | $(BIN)
	$(COBC) -x $(COBCFLAGS) -o $@ $<
$(BIN)/PROD-LOOKUP.so: $(SRC)/prod-lookup.cob | $(BIN)
	$(COBC) -m $(COBCFLAGS) -o $@ $<
$(BIN):
	mkdir -p $@
load-idx: $(BIN)/prod-load
	@COB_LIBRARY_PATH=/workspace/shared/util/shared-log/bin ./$<
test-unit: build load-idx $(BIN)/prd-test
	@COB_LIBRARY_PATH=$(BIN):/workspace/shared/util/shared-log/bin ./$(BIN)/prd-test
$(BIN)/prd-test: $(TESTS)/prd-test.cob $(BIN)/PROD-LOOKUP.so | $(BIN)
	$(COBC) -x $(COBCFLAGS) -o $@ $<
clean:
	rm -rf $(BIN) data/product.idx*

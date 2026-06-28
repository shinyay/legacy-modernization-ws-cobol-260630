COBC := cobc
COBCFLAGS := -x -free -O2 -W -I/workspace/shared/copy
SRC_DIR := src
BIN_DIR := bin

.PHONY: build test-unit clean cpchk wsdate-test deh-test

TESTS := $(BIN_DIR)/cpchk $(BIN_DIR)/wsdate-test $(BIN_DIR)/deh-test

build: $(TESTS)

test-unit: build
	@echo "=== Phase 1b cpchk (copybook compile check) ==="
	@./$(BIN_DIR)/cpchk
	@echo
	@echo "=== Phase 1c ws-date-validate unit tests ==="
	@./$(BIN_DIR)/wsdate-test
	@echo
	@echo "=== Phase 1g double-entry-helper unit tests ==="
	@./$(BIN_DIR)/deh-test

$(BIN_DIR)/%: $(SRC_DIR)/%.cob | $(BIN_DIR)
	$(COBC) $(COBCFLAGS) -o $@ $<

$(BIN_DIR):
	mkdir -p $@

clean:
	rm -rf $(BIN_DIR)

cpchk: $(BIN_DIR)/cpchk
	@./$<

wsdate-test: $(BIN_DIR)/wsdate-test
	@./$<

deh-test: $(BIN_DIR)/deh-test
	@./$<

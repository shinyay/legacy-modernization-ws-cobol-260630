SUBSYSTEM := shared-log
SRC_DIR := src
TESTS_DIR := tests
BIN_DIR := bin

COBC := cobc
COBCFLAGS := -free -O2 -W -I/workspace/shared/copy

.PHONY: build test-unit clean module test-driver

MODULE := $(BIN_DIR)/SHARED-LOG.so

build: $(MODULE)

$(MODULE): $(SRC_DIR)/shared-log.cob | $(BIN_DIR)
	$(COBC) -m $(COBCFLAGS) -o $@ $<

$(BIN_DIR):
	mkdir -p $@

TEST_DRIVER := $(BIN_DIR)/shared-log-test

test-driver: $(TEST_DRIVER)

$(TEST_DRIVER): $(TESTS_DIR)/shared-log-test.cob $(MODULE)
	$(COBC) -x $(COBCFLAGS) -o $@ $< -L$(BIN_DIR)

test-unit: test-driver
	@COB_LIBRARY_PATH=$(BIN_DIR) ./$(TEST_DRIVER)

clean:
	rm -rf $(BIN_DIR)

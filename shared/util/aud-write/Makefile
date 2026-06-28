SUBSYSTEM := aud-write
SRC_DIR := src
TESTS_DIR := tests
BIN_DIR := bin

COBC := cobc
OCESQL := ocesql
COBCFLAGS := -fixed -O2 -W -I/workspace/shared/copy
LDFLAGS := -L/usr/local/lib -locesql -lpq

MODULE := $(BIN_DIR)/AUD-WRITE.so
GEN := $(SRC_DIR)/aud-write.cob.gen

.PHONY: build test-unit clean test-driver idem-test

build: $(MODULE)

$(GEN): $(SRC_DIR)/aud-write.sqb
	$(OCESQL) $< $@ /tmp/aud-write.sqlerr

$(MODULE): $(GEN) | $(BIN_DIR)
	$(COBC) -m $(COBCFLAGS) -o $@ $(GEN) $(LDFLAGS)

$(BIN_DIR):
	mkdir -p $@

TEST_DRIVER := $(BIN_DIR)/aud-write-test
test-driver: $(TEST_DRIVER)

$(TEST_DRIVER): $(TESTS_DIR)/aud-write-test.cob $(MODULE) | $(BIN_DIR)
	$(COBC) -x -free -O2 -W \
	    -I/workspace/shared/copy \
	    -o $@ $< -L$(BIN_DIR)

test-unit: test-driver
	@COB_LIBRARY_PATH=$(BIN_DIR):/workspace/shared/util/shared-log/bin \
	 LD_PRELOAD=/usr/local/lib/libocesql.so \
	 ./$(TEST_DRIVER)

idem-test: test-driver
	@bash $(TESTS_DIR)/aud-idem-test.sh

clean:
	rm -rf $(BIN_DIR) $(GEN) /tmp/aud-write.sqlerr

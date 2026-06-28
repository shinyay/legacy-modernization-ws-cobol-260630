SRC := src
BIN := bin
COBC := cobc
COBCFLAGS := -free -O2 -W -Wno-terminator -I /workspace/shared/copy

.PHONY: build test-unit clean

TEST_DRIVER := $(BIN)/deh-test

build: $(TEST_DRIVER)

$(TEST_DRIVER): $(SRC)/deh-test.cob | $(BIN)
	$(COBC) -x $(COBCFLAGS) -o $@ $<

$(BIN):
	mkdir -p $@

test-unit: build
	@./$(TEST_DRIVER)

clean:
	rm -rf $(BIN)

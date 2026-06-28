SUBSYSTEM := aud-drain
SRC_DIR := src
TESTS_DIR := tests
BIN_DIR := bin

COBC := cobc
OCESQL := ocesql
COBCFLAGS := -fixed -O2 -W -I/workspace/shared/copy
LDFLAGS := -L/usr/local/lib -locesql -lpq

MAIN := $(BIN_DIR)/aud-drain-main
GEN := $(SRC_DIR)/aud-drain.cob.gen

.PHONY: build test-unit clean

build: $(MAIN)

$(GEN): $(SRC_DIR)/aud-drain.sqb
	$(OCESQL) $< $@ /tmp/aud-drain.sqlerr

$(MAIN): $(GEN) | $(BIN_DIR)
	$(COBC) -x $(COBCFLAGS) -o $@ $(GEN) $(LDFLAGS)

$(BIN_DIR):
	mkdir -p $@

test-unit: build
	@bash $(TESTS_DIR)/aud-drain-test.sh

clean:
	rm -rf $(BIN_DIR) $(GEN) /tmp/aud-drain.sqlerr

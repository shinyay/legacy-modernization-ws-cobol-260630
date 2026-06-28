SUBSYSTEM := 01-calendar
SRC_DIR := src
TESTS_DIR := tests/unit
BIN_DIR := bin
DATA_DIR := data

COBC := cobc
COBCFLAGS := -free -O2 -W -I copy/api -I copy/private \
             -I /workspace/shared/copy

LOADER     := $(BIN_DIR)/cal-load
LOOKUP_MOD := $(BIN_DIR)/CAL-LOOKUP.so
NEXTBD_MOD := $(BIN_DIR)/CAL-NEXT-BD.so
PREVBD_MOD := $(BIN_DIR)/CAL-PREV-BD.so

.PHONY: build test-unit clean load-idx

build: $(LOADER) $(LOOKUP_MOD) $(NEXTBD_MOD) $(PREVBD_MOD)

$(LOADER): $(SRC_DIR)/cal-load.cob | $(BIN_DIR)
	$(COBC) -x $(COBCFLAGS) -o $@ $<

$(LOOKUP_MOD): $(SRC_DIR)/cal-lookup.cob | $(BIN_DIR)
	$(COBC) -m $(COBCFLAGS) -o $@ $<

$(NEXTBD_MOD): $(SRC_DIR)/cal-next-bd.cob | $(BIN_DIR)
	$(COBC) -m $(COBCFLAGS) -o $@ $<

$(PREVBD_MOD): $(SRC_DIR)/cal-prev-bd.cob | $(BIN_DIR)
	$(COBC) -m $(COBCFLAGS) -o $@ $<

$(BIN_DIR):
	mkdir -p $@

load-idx: $(LOADER)
	@COB_LIBRARY_PATH=/workspace/shared/util/shared-log/bin ./$(LOADER)

TEST_DRIVER := $(BIN_DIR)/cal-test
test-unit: build $(TEST_DRIVER) load-idx
	@COB_LIBRARY_PATH=$(BIN_DIR):/workspace/shared/util/shared-log/bin \
	 ./$(TEST_DRIVER)

$(TEST_DRIVER): $(TESTS_DIR)/cal-test.cob $(LOOKUP_MOD) $(NEXTBD_MOD) $(PREVBD_MOD) | $(BIN_DIR)
	$(COBC) -x $(COBCFLAGS) -o $@ $<

clean:
	rm -rf $(BIN_DIR) $(DATA_DIR)/calendar.idx*

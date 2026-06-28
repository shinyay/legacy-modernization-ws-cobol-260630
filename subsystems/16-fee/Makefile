SUBSYSTEM := 16-fee
SRC := src
TESTS := tests/unit
BIN := bin

COBC := cobc
OCESQL := ocesql
COBCFLAGS_OCESQL := -fixed -O2 -W -Wno-terminator \
    -I copy/api -I copy/private \
    -I /workspace/subsystems/07-feeschedule/copy/api \
    -I /workspace/subsystems/08-account/copy/api \
    -I /workspace/shared/copy
COBCFLAGS_FREE := -free -O2 -W -Wno-terminator \
    -I copy/api -I copy/private \
    -I /workspace/subsystems/07-feeschedule/copy/api \
    -I /workspace/subsystems/08-account/copy/api \
    -I /workspace/shared/copy
LDFLAGS_OCESQL := -L/usr/local/lib -locesql -lpq

.PHONY: build test-unit retry-test clean

MODULES := $(BIN)/FEE-CHARGE.so $(BIN)/FEE-REPORT-SUMMARY.so

GEN_CHG := $(SRC)/fee-charge.cob.gen
GEN_RPT := $(SRC)/fee-report-summary.cob.gen

build: $(MODULES)

$(GEN_CHG): $(SRC)/fee-charge.sqb
	$(OCESQL) $< $@ /tmp/fee-charge.sqlerr

$(GEN_RPT): $(SRC)/fee-report-summary.sqb
	$(OCESQL) $< $@ /tmp/fee-report-summary.sqlerr

$(BIN)/FEE-CHARGE.so: $(GEN_CHG) | $(BIN)
	$(COBC) -m $(COBCFLAGS_OCESQL) -o $@ $< $(LDFLAGS_OCESQL)
$(BIN)/FEE-REPORT-SUMMARY.so: $(GEN_RPT) | $(BIN)
	$(COBC) -m $(COBCFLAGS_OCESQL) -o $@ $< $(LDFLAGS_OCESQL)

$(BIN):
	mkdir -p $@

FS_BIN := /workspace/subsystems/07-feeschedule/bin
ACCT_BIN := /workspace/subsystems/08-account/bin
AUD_BIN := /workspace/shared/util/aud-write/bin
LOG_BIN := /workspace/shared/util/shared-log/bin

TEST_DRIVER := $(BIN)/fee-test
test-unit: build $(TEST_DRIVER)
	@COB_LIBRARY_PATH=$(BIN):$(FS_BIN):$(ACCT_BIN):$(AUD_BIN):$(LOG_BIN) \
	 LD_PRELOAD=/usr/local/lib/libocesql.so \
	 PGHOST=postgres PGUSER=cobol PGPASSWORD=cobol PGDATABASE=banking \
	 ./$(TEST_DRIVER)

$(TEST_DRIVER): $(TESTS)/fee-test.cob $(MODULES) | $(BIN)
	$(COBC) -x $(COBCFLAGS_FREE) -o $@ $<

retry-test: build $(TEST_DRIVER)
	@bash $(TESTS)/fee-retry-test.sh

clean:
	rm -rf $(BIN) $(GEN_CHG) $(GEN_RPT) /tmp/fee-*.sqlerr

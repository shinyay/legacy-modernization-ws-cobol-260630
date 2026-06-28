SUBSYSTEM := 15-autodebit
SRC := src
TESTS := tests/unit
BIN := bin

COBC := cobc
OCESQL := ocesql
COBCFLAGS_OCESQL := -fixed -O2 -W -Wno-terminator \
    -I copy/api -I copy/private \
    -I /workspace/subsystems/01-calendar/copy/api \
    -I /workspace/subsystems/08-account/copy/api \
    -I /workspace/shared/copy
COBCFLAGS_FREE := -free -O2 -W -Wno-terminator \
    -I copy/api -I copy/private \
    -I /workspace/subsystems/01-calendar/copy/api \
    -I /workspace/subsystems/08-account/copy/api \
    -I /workspace/shared/copy
LDFLAGS_OCESQL := -L/usr/local/lib -locesql -lpq

.PHONY: build test-unit retry-test clean

MODULES := $(BIN)/AD-RUN-DAILY.so $(BIN)/AD-REPORT-SUMMARY.so

GEN_RUN := $(SRC)/ad-run-daily.cob.gen
GEN_RPT := $(SRC)/ad-report-summary.cob.gen

build: $(MODULES)

$(GEN_RUN): $(SRC)/ad-run-daily.sqb
	$(OCESQL) $< $@ /tmp/ad-run-daily.sqlerr

$(GEN_RPT): $(SRC)/ad-report-summary.sqb
	$(OCESQL) $< $@ /tmp/ad-report-summary.sqlerr

$(BIN)/AD-RUN-DAILY.so: $(GEN_RUN) | $(BIN)
	$(COBC) -m $(COBCFLAGS_OCESQL) -o $@ $< $(LDFLAGS_OCESQL)
$(BIN)/AD-REPORT-SUMMARY.so: $(GEN_RPT) | $(BIN)
	$(COBC) -m $(COBCFLAGS_OCESQL) -o $@ $< $(LDFLAGS_OCESQL)

$(BIN):
	mkdir -p $@

CAL_BIN := /workspace/subsystems/01-calendar/bin
ACCT_BIN := /workspace/subsystems/08-account/bin
AUD_BIN := /workspace/shared/util/aud-write/bin
LOG_BIN := /workspace/shared/util/shared-log/bin

TEST_DRIVER := $(BIN)/ad-test
test-unit: build $(TEST_DRIVER)
	@COB_LIBRARY_PATH=$(BIN):$(CAL_BIN):$(ACCT_BIN):$(AUD_BIN):$(LOG_BIN) \
	 LD_PRELOAD=/usr/local/lib/libocesql.so \
	 PGHOST=postgres PGUSER=cobol PGPASSWORD=cobol PGDATABASE=banking \
	 ./$(TEST_DRIVER)

$(TEST_DRIVER): $(TESTS)/ad-test.cob $(MODULES) | $(BIN)
	$(COBC) -x $(COBCFLAGS_FREE) -o $@ $<

retry-test: build $(TEST_DRIVER)
	@bash $(TESTS)/ad-retry-test.sh

clean:
	rm -rf $(BIN) $(GEN_RUN) $(GEN_RPT) /tmp/ad-*.sqlerr

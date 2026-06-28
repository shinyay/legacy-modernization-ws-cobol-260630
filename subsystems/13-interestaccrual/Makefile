SUBSYSTEM := 13-interestaccrual
SRC := src
TESTS := tests/unit
BIN := bin

COBC := cobc
OCESQL := ocesql
COBCFLAGS_OCESQL := -fixed -O2 -W -Wno-terminator \
    -I copy/api -I copy/private \
    -I /workspace/subsystems/01-calendar/copy/api \
    -I /workspace/subsystems/05-product/copy/api \
    -I /workspace/subsystems/06-interestrate/copy/api \
    -I /workspace/subsystems/08-account/copy/api \
    -I /workspace/shared/copy
COBCFLAGS_FREE := -free -O2 -W -Wno-terminator \
    -I copy/api -I copy/private \
    -I /workspace/subsystems/01-calendar/copy/api \
    -I /workspace/subsystems/05-product/copy/api \
    -I /workspace/subsystems/06-interestrate/copy/api \
    -I /workspace/subsystems/08-account/copy/api \
    -I /workspace/shared/copy
LDFLAGS_OCESQL := -L/usr/local/lib -locesql -lpq

.PHONY: build test-unit clean

MODULES := $(BIN)/IACR-RUN-DAILY.so $(BIN)/IACR-REPORT-SUMMARY.so

GEN_RUN := $(SRC)/iacr-run-daily.cob.gen
GEN_RPT := $(SRC)/iacr-report-summary.cob.gen

build: $(MODULES)

$(GEN_RUN): $(SRC)/iacr-run-daily.sqb
	$(OCESQL) $< $@ /tmp/iacr-run-daily.sqlerr

$(GEN_RPT): $(SRC)/iacr-report-summary.sqb
	$(OCESQL) $< $@ /tmp/iacr-report-summary.sqlerr

$(BIN)/IACR-RUN-DAILY.so: $(GEN_RUN) | $(BIN)
	$(COBC) -m $(COBCFLAGS_OCESQL) -o $@ $< $(LDFLAGS_OCESQL)
$(BIN)/IACR-REPORT-SUMMARY.so: $(GEN_RPT) | $(BIN)
	$(COBC) -m $(COBCFLAGS_OCESQL) -o $@ $< $(LDFLAGS_OCESQL)

$(BIN):
	mkdir -p $@

CAL_BIN := /workspace/subsystems/01-calendar/bin
PROD_BIN := /workspace/subsystems/05-product/bin
IRATE_BIN := /workspace/subsystems/06-interestrate/bin
ACCT_BIN := /workspace/subsystems/08-account/bin
AUD_BIN := /workspace/shared/util/aud-write/bin
LOG_BIN := /workspace/shared/util/shared-log/bin

TEST_DRIVER := $(BIN)/iacr-test
test-unit: build $(TEST_DRIVER)
	@COB_LIBRARY_PATH=$(BIN):$(CAL_BIN):$(PROD_BIN):$(IRATE_BIN):$(ACCT_BIN):$(AUD_BIN):$(LOG_BIN) \
	 LD_PRELOAD=/usr/local/lib/libocesql.so \
	 PGHOST=postgres PGUSER=cobol PGPASSWORD=cobol PGDATABASE=banking \
	 ./$(TEST_DRIVER)

$(TEST_DRIVER): $(TESTS)/iacr-test.cob $(MODULES) | $(BIN)
	$(COBC) -x $(COBCFLAGS_FREE) -o $@ $<

clean:
	rm -rf $(BIN) $(GEN_RUN) $(GEN_RPT) /tmp/iacr-*.sqlerr

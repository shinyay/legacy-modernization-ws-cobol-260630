SUBSYSTEM := 21-audit
SRC := src
TESTS := tests/unit
BIN := bin

COBC := cobc
OCESQL := ocesql
COBCFLAGS_OCESQL := -fixed -O2 -W -Wno-terminator \
    -I copy/api -I copy/private \
    -I /workspace/shared/copy
COBCFLAGS_FREE := -free -O2 -W -Wno-terminator \
    -I copy/api -I copy/private \
    -I /workspace/shared/copy
LDFLAGS_OCESQL := -L/usr/local/lib -locesql -lpq

.PHONY: build test-unit clean

MODULES := $(BIN)/AUDIT-QUERY-FORENSIC.so \
           $(BIN)/AUDIT-PARTITION-ROLLOVER.so \
           $(BIN)/AUDIT-SUMMARY-REPORT.so

GEN_FORENSIC := $(SRC)/audit-query-forensic.cob.gen
GEN_ROLLOVER := $(SRC)/audit-partition-rollover.cob.gen
GEN_SUMMARY  := $(SRC)/audit-summary-report.cob.gen

AUD_BIN := /workspace/shared/util/aud-write/bin
LOG_BIN := /workspace/shared/util/shared-log/bin

build: $(MODULES)

$(GEN_FORENSIC): $(SRC)/audit-query-forensic.sqb
	$(OCESQL) $< $@ /tmp/audit-query-forensic.sqlerr
$(GEN_ROLLOVER): $(SRC)/audit-partition-rollover.sqb
	$(OCESQL) $< $@ /tmp/audit-partition-rollover.sqlerr
$(GEN_SUMMARY): $(SRC)/audit-summary-report.sqb
	$(OCESQL) $< $@ /tmp/audit-summary-report.sqlerr

$(BIN)/AUDIT-QUERY-FORENSIC.so: $(GEN_FORENSIC) | $(BIN)
	$(COBC) -m $(COBCFLAGS_OCESQL) -o $@ $< $(LDFLAGS_OCESQL)
$(BIN)/AUDIT-PARTITION-ROLLOVER.so: $(GEN_ROLLOVER) | $(BIN)
	$(COBC) -m $(COBCFLAGS_OCESQL) -o $@ $< $(LDFLAGS_OCESQL)
$(BIN)/AUDIT-SUMMARY-REPORT.so: $(GEN_SUMMARY) | $(BIN)
	$(COBC) -m $(COBCFLAGS_OCESQL) -o $@ $< $(LDFLAGS_OCESQL)

$(BIN):
	mkdir -p $@

TEST_DRIVER := $(BIN)/audit-driver
test-unit: build $(TEST_DRIVER)
	@COB_LIBRARY_PATH=$(BIN):$(AUD_BIN):$(LOG_BIN) \
	 LD_PRELOAD=/usr/local/lib/libocesql.so \
	 PGHOST=postgres PGUSER=cobol PGPASSWORD=cobol PGDATABASE=banking \
	 bash $(TESTS)/audit-test.sh

$(TEST_DRIVER): $(TESTS)/audit-driver.cob $(MODULES) | $(BIN)
	$(COBC) -x $(COBCFLAGS_FREE) -o $@ $<

clean:
	rm -rf $(BIN) $(GEN_FORENSIC) $(GEN_ROLLOVER) $(GEN_SUMMARY) /tmp/audit-*.sqlerr

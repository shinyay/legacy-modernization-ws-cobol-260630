SUBSYSTEM := 14-interestpost
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

MODULES := $(BIN)/IPST-RUN-MONTHEND.so $(BIN)/IPST-REPORT-SUMMARY.so

GEN_RUN := $(SRC)/ipst-run-monthend.cob.gen
GEN_RPT := $(SRC)/ipst-report-summary.cob.gen

build: $(MODULES)

$(GEN_RUN): $(SRC)/ipst-run-monthend.sqb
	$(OCESQL) $< $@ /tmp/ipst-run-monthend.sqlerr

$(GEN_RPT): $(SRC)/ipst-report-summary.sqb
	$(OCESQL) $< $@ /tmp/ipst-report-summary.sqlerr

$(BIN)/IPST-RUN-MONTHEND.so: $(GEN_RUN) | $(BIN)
	$(COBC) -m $(COBCFLAGS_OCESQL) -o $@ $< $(LDFLAGS_OCESQL)
$(BIN)/IPST-REPORT-SUMMARY.so: $(GEN_RPT) | $(BIN)
	$(COBC) -m $(COBCFLAGS_OCESQL) -o $@ $< $(LDFLAGS_OCESQL)

$(BIN):
	mkdir -p $@

AUD_BIN := /workspace/shared/util/aud-write/bin
LOG_BIN := /workspace/shared/util/shared-log/bin

TEST_DRIVER := $(BIN)/ipst-test
test-unit: build $(TEST_DRIVER)
	@COB_LIBRARY_PATH=$(BIN):$(AUD_BIN):$(LOG_BIN) \
	 LD_PRELOAD=/usr/local/lib/libocesql.so \
	 PGHOST=postgres PGUSER=cobol PGPASSWORD=cobol PGDATABASE=banking \
	 ./$(TEST_DRIVER)

$(TEST_DRIVER): $(TESTS)/ipst-test.cob $(MODULES) | $(BIN)
	$(COBC) -x $(COBCFLAGS_FREE) -o $@ $<

clean:
	rm -rf $(BIN) $(GEN_RUN) $(GEN_RPT) /tmp/ipst-*.sqlerr

SUBSYSTEM := 17-statement
SRC := src
TESTS := tests/unit
BIN := bin

COBC := cobc
OCESQL := ocesql
COBCFLAGS_OCESQL := -fixed -O2 -W -Wno-terminator \
    -I copy/api -I copy/private \
    -I /workspace/subsystems/01-calendar/copy/api \
    -I /workspace/subsystems/02-branch/copy/api \
    -I /workspace/subsystems/03-customer/copy/api \
    -I /workspace/subsystems/08-account/copy/api \
    -I /workspace/shared/copy
COBCFLAGS_FREE := -free -O2 -W -Wno-terminator \
    -I copy/api -I copy/private \
    -I /workspace/subsystems/01-calendar/copy/api \
    -I /workspace/subsystems/02-branch/copy/api \
    -I /workspace/subsystems/03-customer/copy/api \
    -I /workspace/subsystems/08-account/copy/api \
    -I /workspace/shared/copy
LDFLAGS_OCESQL := -L/usr/local/lib -locesql -lpq

.PHONY: build test-unit clean

MODULES := $(BIN)/STMT-GENERATE-BATCH.so

GEN_STMT := $(SRC)/stmt-generate-batch.cob.gen

build: $(MODULES)

$(GEN_STMT): $(SRC)/stmt-generate-batch.sqb
	$(OCESQL) $< $@ /tmp/stmt-generate-batch.sqlerr

$(BIN)/STMT-GENERATE-BATCH.so: $(GEN_STMT) | $(BIN)
	$(COBC) -m $(COBCFLAGS_OCESQL) -o $@ $< $(LDFLAGS_OCESQL)

$(BIN):
	mkdir -p $@

CAL_BIN := /workspace/subsystems/01-calendar/bin
BR_BIN := /workspace/subsystems/02-branch/bin
CUST_BIN := /workspace/subsystems/03-customer/bin
ACCT_BIN := /workspace/subsystems/08-account/bin
AUD_BIN := /workspace/shared/util/aud-write/bin
LOG_BIN := /workspace/shared/util/shared-log/bin

TEST_DRIVER := $(BIN)/stmt-test
test-unit: build $(TEST_DRIVER)
	@COB_LIBRARY_PATH=$(BIN):$(CAL_BIN):$(BR_BIN):$(CUST_BIN):$(ACCT_BIN):$(AUD_BIN):$(LOG_BIN) \
	 LD_PRELOAD=/usr/local/lib/libocesql.so \
	 PGHOST=postgres PGUSER=cobol PGPASSWORD=cobol PGDATABASE=banking \
	 ./$(TEST_DRIVER)

$(TEST_DRIVER): $(TESTS)/stmt-test.cob $(MODULES) | $(BIN)
	$(COBC) -x $(COBCFLAGS_FREE) -o $@ $<

clean:
	rm -rf $(BIN) $(GEN_STMT) /tmp/stmt-*.sqlerr

SUBSYSTEM := 18-inquiry
SRC := src
TESTS := tests/unit
BIN := bin

COBC := cobc
OCESQL := ocesql

COBCFLAGS := -fixed -O2 -W -Wno-terminator \
    -I copy/api -I copy/private \
    -I /workspace/subsystems/02-branch/copy/api \
    -I /workspace/subsystems/03-customer/copy/api \
    -I /workspace/subsystems/04-customersearch/copy/api \
    -I /workspace/subsystems/08-account/copy/api \
    -I /workspace/shared/copy
LDFLAGS := -lncursesw -L/usr/local/lib -locesql -lpq

.PHONY: build test-unit run-screen clean

BR_BIN := /workspace/subsystems/02-branch/bin
CUST_BIN := /workspace/subsystems/03-customer/bin
CSRCH_BIN := /workspace/subsystems/04-customersearch/bin
ACCT_BIN := /workspace/subsystems/08-account/bin
AUD_BIN := /workspace/shared/util/aud-write/bin
LOG_BIN := /workspace/shared/util/shared-log/bin

INQ_BIN := $(BIN)/inq

build: $(INQ_BIN)

GEN_MAIN := $(SRC)/inq-main.cob.gen

$(GEN_MAIN): $(SRC)/inq-main.sqb
	$(OCESQL) $< $@ /tmp/inq-main.sqlerr

$(INQ_BIN): $(GEN_MAIN) | $(BIN)
	$(COBC) -x $(COBCFLAGS) -o $@ $< $(LDFLAGS)

$(BIN):
	mkdir -p $@

run-screen: build
	@COB_LIBRARY_PATH=$(BR_BIN):$(CUST_BIN):$(CSRCH_BIN):$(ACCT_BIN):$(AUD_BIN):$(LOG_BIN) \
	 LD_PRELOAD=/usr/local/lib/libocesql.so \
	 PGHOST=postgres PGUSER=cobol PGPASSWORD=cobol PGDATABASE=banking \
	 TERM=$${TERM:-xterm-256color} \
	 ./$(INQ_BIN) --screen

test-unit: build
	@COB_LIBRARY_PATH=$(BR_BIN):$(CUST_BIN):$(CSRCH_BIN):$(ACCT_BIN):$(AUD_BIN):$(LOG_BIN) \
	 LD_PRELOAD=/usr/local/lib/libocesql.so \
	 PGHOST=postgres PGUSER=cobol PGPASSWORD=cobol PGDATABASE=banking \
	 TERM=$${TERM:-xterm-256color} \
	 bash $(TESTS)/inq-test.sh

clean:
	rm -rf $(BIN) $(GEN_MAIN) /tmp/inq-*.sqlerr

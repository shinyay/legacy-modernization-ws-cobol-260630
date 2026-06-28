SUBSYSTEM := 22-operations
SRC := src
TESTS := tests/unit
BIN := bin

COBC := cobc
OCESQL := ocesql

COBCFLAGS_OCESQL := -fixed -O2 -W -Wno-terminator \
    -I copy/api \
    -I /workspace/shared/copy \
    -I /workspace/subsystems/20-integrationout/copy/api \
    -I /workspace/subsystems/21-audit/copy/api
COBCFLAGS_FREE := -free -O2 -W -Wno-terminator \
    -I copy/api \
    -I /workspace/shared/copy \
    -I /workspace/subsystems/20-integrationout/copy/api \
    -I /workspace/subsystems/21-audit/copy/api
LDFLAGS_OCESQL := -L/usr/local/lib -locesql -lpq

AUD_BIN     := /workspace/shared/util/aud-write/bin
LOG_BIN     := /workspace/shared/util/shared-log/bin
INTO_BIN    := /workspace/subsystems/20-integrationout/bin
AUDIT_BIN   := /workspace/subsystems/21-audit/bin
MQ_BIN      := /workspace/shared/util/mq-publish/bin

.PHONY: build test-unit clean run-seed \
    batch-daily batch-monthly partition-rollover drain-queues \
    ops-finalize flock-test scan-dormancy \
    master-load-calendar master-load-branches master-load-customers \
    master-load-products master-load-interestrates \
    master-load-feeschedules master-load-accounts

MODULES := \
    $(BIN)/ops-seed-audit \
    $(BIN)/OPS-PARTITION-ROLLOVER.so \
    $(BIN)/OPS-DRAIN-QUEUES.so \
    $(BIN)/OPS-FINALIZE.so \
    $(BIN)/OPS-BATCH-DAILY.so \
    $(BIN)/OPS-BATCH-MONTHLY.so

GEN_FINALIZE       := $(SRC)/ops-finalize.cob.gen
GEN_BATCH_DAILY    := $(SRC)/ops-batch-daily.cob.gen
GEN_BATCH_MONTHLY  := $(SRC)/ops-batch-monthly.cob.gen

build: $(MODULES)

$(BIN)/ops-seed-audit: $(SRC)/ops-seed-audit.cob | $(BIN)
	$(COBC) -x $(COBCFLAGS_FREE) -o $@ $<

$(BIN)/OPS-PARTITION-ROLLOVER.so: $(SRC)/ops-partition-rollover.cob | $(BIN)
	$(COBC) -m $(COBCFLAGS_FREE) -o $@ $<

$(BIN)/OPS-DRAIN-QUEUES.so: $(SRC)/ops-drain-queues.cob | $(BIN)
	$(COBC) -m $(COBCFLAGS_FREE) -o $@ $<

$(GEN_FINALIZE): $(SRC)/ops-finalize.sqb
	$(OCESQL) $< $@ /tmp/ops-finalize.sqlerr

$(GEN_BATCH_DAILY): $(SRC)/ops-batch-daily.sqb
	$(OCESQL) $< $@ /tmp/ops-batch-daily.sqlerr

$(GEN_BATCH_MONTHLY): $(SRC)/ops-batch-monthly.sqb
	$(OCESQL) $< $@ /tmp/ops-batch-monthly.sqlerr

$(BIN)/OPS-FINALIZE.so: $(GEN_FINALIZE) | $(BIN)
	$(COBC) -m $(COBCFLAGS_OCESQL) -o $@ $< $(LDFLAGS_OCESQL)

$(BIN)/OPS-BATCH-DAILY.so: $(GEN_BATCH_DAILY) | $(BIN)
	$(COBC) -m $(COBCFLAGS_OCESQL) -o $@ $< $(LDFLAGS_OCESQL)

$(BIN)/OPS-BATCH-MONTHLY.so: $(GEN_BATCH_MONTHLY) | $(BIN)
	$(COBC) -m $(COBCFLAGS_OCESQL) -o $@ $< $(LDFLAGS_OCESQL)

$(BIN):
	mkdir -p $@

TEST_DRIVER := $(BIN)/ops-driver
$(TEST_DRIVER): $(TESTS)/ops-driver.cob $(MODULES) | $(BIN)
	$(COBC) -x $(COBCFLAGS_FREE) -o $@ $<

test-unit: build $(TEST_DRIVER)
	@COB_LIBRARY_PATH=$(BIN):$(AUDIT_BIN):$(INTO_BIN):$(AUD_BIN):$(LOG_BIN) \
	 LD_LIBRARY_PATH=$(MQ_BIN):$$LD_LIBRARY_PATH \
	 LD_PRELOAD=/usr/local/lib/libocesql.so \
	 PGHOST=postgres PGUSER=cobol PGPASSWORD=cobol PGDATABASE=banking \
	 bash $(TESTS)/ops-test.sh

PB_BATCH_ID      ?= MVP-$(shell date +%Y%m%d-%H%M)
PB_BUSINESS_DATE ?= $(shell date +%Y%m%d)
PB_DRY_RUN       ?= Y

batch-daily: build
	@COB_LIBRARY_PATH=$(BIN):$(AUDIT_BIN):$(INTO_BIN):$(AUD_BIN):$(LOG_BIN) \
	 LD_LIBRARY_PATH=$(MQ_BIN):$$LD_LIBRARY_PATH \
	 LD_PRELOAD=/usr/local/lib/libocesql.so \
	 PGHOST=postgres PGUSER=cobol PGPASSWORD=cobol PGDATABASE=banking \
	 PB_BATCH_ID=$(PB_BATCH_ID) PB_BUSINESS_DATE=$(PB_BUSINESS_DATE) \
	 PB_DRY_RUN=$(PB_DRY_RUN) \
	 bash $(TESTS)/run-batch-daily.sh

batch-monthly: build
	@COB_LIBRARY_PATH=$(BIN):$(AUDIT_BIN):$(INTO_BIN):$(AUD_BIN):$(LOG_BIN) \
	 LD_LIBRARY_PATH=$(MQ_BIN):$$LD_LIBRARY_PATH \
	 LD_PRELOAD=/usr/local/lib/libocesql.so \
	 PGHOST=postgres PGUSER=cobol PGPASSWORD=cobol PGDATABASE=banking \
	 PB_BATCH_ID=$(PB_BATCH_ID) PB_BUSINESS_DATE=$(PB_BUSINESS_DATE) \
	 PB_DRY_RUN=$(PB_DRY_RUN) \
	 bash $(TESTS)/run-batch-monthly.sh

partition-rollover: build
	@COB_LIBRARY_PATH=$(BIN):$(AUDIT_BIN):$(AUD_BIN):$(LOG_BIN) \
	 LD_PRELOAD=/usr/local/lib/libocesql.so \
	 PGHOST=postgres PGUSER=cobol PGPASSWORD=cobol PGDATABASE=banking \
	 bash $(TESTS)/run-partition-rollover.sh

drain-queues: build
	@COB_LIBRARY_PATH=$(BIN):$(INTO_BIN):$(AUD_BIN):$(LOG_BIN) \
	 LD_LIBRARY_PATH=$(MQ_BIN):$$LD_LIBRARY_PATH \
	 LD_PRELOAD=/usr/local/lib/libocesql.so \
	 PGHOST=postgres PGUSER=cobol PGPASSWORD=cobol PGDATABASE=banking \
	 bash $(TESTS)/run-drain-queues.sh

ops-finalize: build
	@COB_LIBRARY_PATH=$(BIN):$(AUD_BIN):$(LOG_BIN) \
	 LD_PRELOAD=/usr/local/lib/libocesql.so \
	 PGHOST=postgres PGUSER=cobol PGPASSWORD=cobol PGDATABASE=banking \
	 PB_BATCH_ID=$(PB_BATCH_ID) PB_BUSINESS_DATE=$(PB_BUSINESS_DATE) \
	 bash $(TESTS)/run-ops-finalize.sh

master-load-calendar:
	@bash $(SRC)/ops-master-load.sh calendar

master-load-branches:
	@bash $(SRC)/ops-master-load.sh branches

master-load-customers:
	@bash $(SRC)/ops-master-load.sh customers

master-load-products:
	@bash $(SRC)/ops-master-load.sh products

master-load-interestrates:
	@bash $(SRC)/ops-master-load.sh interestrates

master-load-feeschedules:
	@bash $(SRC)/ops-master-load.sh feeschedules

master-load-accounts:
	@bash $(SRC)/ops-master-load.sh accounts

master-load-all: master-load-calendar master-load-branches \
                 master-load-customers master-load-products \
                 master-load-interestrates master-load-feeschedules \
                 master-load-accounts
	@echo "[master-load-all] all 7 masters loaded"

scan-dormancy:
	@bash $(SRC)/ops-scan-dormancy.sh

run-seed: $(BIN)/ops-seed-audit
	@bash $(SRC)/ops-seed-system-accounts.sh
	@COB_LIBRARY_PATH=$(AUD_BIN):$(LOG_BIN) \
	 LD_PRELOAD=/usr/local/lib/libocesql.so \
	 ./$(BIN)/ops-seed-audit

clean:
	rm -rf $(BIN) \
	    $(GEN_FINALIZE) $(GEN_BATCH_DAILY) $(GEN_BATCH_MONTHLY) \
	    /tmp/ops-*.sqlerr /tmp/pb-locks

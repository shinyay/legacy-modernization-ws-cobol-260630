SUBSYSTEMS := \
	01-calendar \
	02-branch \
	03-customer \
	04-customersearch \
	05-product \
	06-interestrate \
	07-feeschedule \
	08-account \
	09-accountlifecycle \
	10-txnvalidate \
	11-txnsortmerge \
	12-txnpost \
	13-interestaccrual \
	14-interestpost \
	15-autodebit \
	16-fee \
	17-statement \
	18-inquiry \
	19-integrationin \
	20-integrationout \
	21-audit \
	22-operations

SHARED_UTILS := aud-write shared-log ebc-to-ascii mq-publish aud-drain

MASTER_SUBSYS := \
	01-calendar \
	02-branch \
	03-customer \
	05-product \
	06-interestrate \
	07-feeschedule \
	08-account

SPIKES := \
	01-hello-world \
	02-ocesql-select-one \
	03-rabbitmq-publish \
	04-ebcdic-code-set \
	05-report-writer \
	06-screen-section

FLYWAY        ?= flyway
FLYWAY_URL    ?= jdbc:postgresql://$(PGHOST):$(PGPORT)/$(PGDATABASE)
FLYWAY_USER   ?= $(PGUSER)
FLYWAY_PASS   ?= $(PGPASSWORD)
FLYWAY_LOC    ?= filesystem:db/migration

.PHONY: help setup build-all test-all test-int migrate migrate-info clean-all \
        spike-all build-shared test-shared seed-gen load-all-idx seed-system

help:
	@echo "Available targets:"
	@echo "  setup          One-shot fresh-env setup: migrate + build-all +"
	@echo "                 load-all-idx + seed-system (then: cd console && make run-screen)"
	@echo "  build-all      Build every subsystem + shared util"
	@echo "  load-all-idx   Load master ISAM indexes (calendar/branch/product/...)"
	@echo "  seed-system    Seed PG system accounts (cash/clearing/...)"
	@echo "  test-all       Run every subsystem's unit tests"
	@echo "  test-int       Run integration tests under tests/integration/"
	@echo "  migrate        Apply Flyway PG migrations (db/migration/)"
	@echo "  migrate-info   Show Flyway migration status"
	@echo "  spike-all      Run all Phase 0 spike tests (spikes/)"
	@echo "  seed-gen       Regenerate all 6 seed data .dat files (Python)"
	@echo "  clean-all      Clean every subsystem"

setup:
	@echo "[setup 1/4] Flyway migrate (PG schema)"
	@$(MAKE) migrate
	@echo "[setup 2/4] build all subsystems + shared utils"
	@$(MAKE) build-all
	@echo "[setup 3/4] load master ISAM indexes"
	@$(MAKE) load-all-idx
	@echo "[setup 4/4] seed PG system accounts"
	@$(MAKE) seed-system
	@echo "✓ setup complete — try:  cd console && make run-screen   (or: make test)"

load-all-idx:
	@for s in $(MASTER_SUBSYS); do \
	    if [ -d subsystems/$$s ]; then \
	        $(MAKE) -C subsystems/$$s load-idx || exit 1; \
	    fi; \
	done

seed-system:
	@bash subsystems/22-operations/src/ops-seed-system-accounts.sh

seed-gen:
	@scripts/gen-seed/gen-all-seed.sh

build-shared:
	@for u in $(SHARED_UTILS); do \
	    if [ -d shared/util/$$u ]; then \
	        $(MAKE) -C shared/util/$$u build || exit 1; \
	    else \
	        echo "[skip] shared/util/$$u not implemented yet"; \
	    fi; \
	done

test-shared:
	@for u in $(SHARED_UTILS); do \
	    if [ -d shared/util/$$u ]; then \
	        $(MAKE) -C shared/util/$$u test-unit || exit 1; \
	    fi; \
	done
	@if [ -d tests/unit/shared ]; then \
	    $(MAKE) -C tests/unit/shared test-unit || exit 1; \
	fi

build-all: build-shared
	@for s in $(SUBSYSTEMS); do \
	    if [ -d subsystems/$$s ]; then \
	        $(MAKE) -C subsystems/$$s build || exit 1; \
	    else \
	        echo "[skip] subsystems/$$s not implemented yet"; \
	    fi; \
	done

test-all: build-all test-shared
	@for s in $(SUBSYSTEMS); do \
	    if [ -d subsystems/$$s ]; then \
	        $(MAKE) -C subsystems/$$s test-unit || exit 1; \
	    fi; \
	done

test-int:
	@if [ -d tests/integration ] && [ -f tests/integration/run-all.sh ]; then \
	    bash tests/integration/run-all.sh; \
	else \
	    echo "[skip] tests/integration/run-all.sh not yet present"; \
	fi

migrate:
	$(FLYWAY) -url=$(FLYWAY_URL) -user=$(FLYWAY_USER) -password=$(FLYWAY_PASS) \
	    -locations=$(FLYWAY_LOC) migrate

migrate-info:
	$(FLYWAY) -url=$(FLYWAY_URL) -user=$(FLYWAY_USER) -password=$(FLYWAY_PASS) \
	    -locations=$(FLYWAY_LOC) info

spike-all:
	@for sp in $(SPIKES); do \
	    if [ -d spikes/$$sp ]; then \
	        echo "==> spikes/$$sp"; \
	        $(MAKE) -C spikes/$$sp run || exit 1; \
	    else \
	        echo "[skip] spikes/$$sp not implemented yet"; \
	    fi; \
	done

clean-all:
	@for s in $(SUBSYSTEMS); do \
	    if [ -d subsystems/$$s ]; then \
	        $(MAKE) -C subsystems/$$s clean 2>/dev/null || true; \
	    fi; \
	done
	@for u in $(SHARED_UTILS); do \
	    if [ -d shared/util/$$u ]; then \
	        $(MAKE) -C shared/util/$$u clean 2>/dev/null || true; \
	    fi; \
	done
	@for sp in $(SPIKES); do \
	    if [ -d spikes/$$sp ]; then \
	        $(MAKE) -C spikes/$$sp clean 2>/dev/null || true; \
	    fi; \
	done

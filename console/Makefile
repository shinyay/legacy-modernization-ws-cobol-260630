SRC := src
MSG := msg
TESTS := tests
BIN := bin

COBC := cobc
OCESQL := ocesql

COBCFLAGS := -fixed -O2 -W -Wno-terminator -Wno-possible-truncate -I /workspace/shared/copy
LDFLAGS := -lncursesw -L/usr/local/lib -locesql -lpq

E2E := /workspace/tests/e2e

RUN_ENV := \
  LD_PRELOAD=/usr/local/lib/libocesql.so \
  PGHOST=$${PGHOST:-postgres} PGUSER=$${PGUSER:-cobol} \
  PGPASSWORD=$${PGPASSWORD:-cobol} PGDATABASE=$${PGDATABASE:-banking} \
  LANG=$${LANG:-en_US.UTF-8} LC_ALL=$${LC_ALL:-en_US.UTF-8} \
  CONSOLE_MSG_DIR=$(CURDIR)/$(MSG) \
  CONSOLE_STAGE_SCRIPT=$(CURDIR)/scripts/run-stage.sh \
  CONSOLE_REVS_SCRIPT=$(CURDIR)/scripts/run-reverse.sh \
  CONSOLE_POST_SCRIPT=$(CURDIR)/scripts/run-post.sh \
  CONSOLE_SCENARIO_SCRIPT=$(CURDIR)/scripts/run-scenario.sh

.PHONY: build e2e-deps run-screen run-screen-en test clean demo-audit demo-audit-clear demo-batch demo-batch-clear

CON_BIN := $(BIN)/oper-console
REV_BIN := $(BIN)/con-reverse
POSTGEN_BIN := $(BIN)/con-post-gen
AUDITDEMO_BIN := $(BIN)/con-audit-demo

build: $(CON_BIN) $(REV_BIN) $(POSTGEN_BIN) $(AUDITDEMO_BIN)

e2e-deps:
	@$(MAKE) -C $(E2E) build >/dev/null

GEN_MAIN := $(SRC)/oper-console.cob.gen

$(GEN_MAIN): $(SRC)/oper-console.sqb
	$(OCESQL) $< $@ /tmp/oper-console.sqlerr

$(CON_BIN): $(GEN_MAIN) | $(BIN)
	$(COBC) -x $(COBCFLAGS) -o $@ $< $(LDFLAGS)

$(REV_BIN): $(SRC)/con-reverse.cob | $(BIN)
	$(COBC) -x -fixed -O2 -W -Wno-terminator -Wno-possible-truncate \
	  -I /workspace/subsystems/12-txnpost/copy/api \
	  -I /workspace/shared/copy -o $@ $<

POSTGEN_GEN := $(SRC)/con-post-gen.cob.gen
$(POSTGEN_GEN): $(SRC)/con-post-gen.sqb
	$(OCESQL) $< $@ /tmp/con-post-gen.sqlerr
$(POSTGEN_BIN): $(POSTGEN_GEN) | $(BIN)
	$(COBC) -x -fixed -O2 -W -Wno-terminator -Wno-possible-truncate \
	  -I /workspace/shared/copy -o $@ $< -L/usr/local/lib -locesql -lpq

$(AUDITDEMO_BIN): $(SRC)/con-audit-demo.cob | $(BIN)
	$(COBC) -x -fixed -O2 -W -Wno-terminator -Wno-possible-truncate \
	  -I /workspace/shared/copy -o $@ $<

$(BIN):
	mkdir -p $@

run-screen: build e2e-deps
	@$(RUN_ENV) TERM=$${TERM:-xterm-256color} \
	 CONSOLE_ALLOW_DESTRUCTIVE_DEMO_RESET=YES \
	 CONSOLE_ALLOW_WRITE=$${CONSOLE_ALLOW_WRITE:-YES} \
	 CONSOLE_OPERATOR_ID=$${CONSOLE_OPERATOR_ID:-$$USER} \
	 ./$(CON_BIN) --screen --lang=ja

run-screen-en: build e2e-deps
	@$(RUN_ENV) TERM=$${TERM:-xterm-256color} \
	 CONSOLE_ALLOW_DESTRUCTIVE_DEMO_RESET=YES \
	 CONSOLE_ALLOW_WRITE=$${CONSOLE_ALLOW_WRITE:-YES} \
	 CONSOLE_OPERATOR_ID=$${CONSOLE_OPERATOR_ID:-$$USER} \
	 ./$(CON_BIN) --screen --lang=en

demo-audit: build
	@$(RUN_ENV) WS=/workspace bash scripts/seed-audit-demo.sh $(BDATE)

demo-audit-clear:
	@$(RUN_ENV) WS=/workspace bash scripts/seed-audit-demo.sh --clear

demo-batch: build
	@$(RUN_ENV) bash scripts/seed-batch-demo.sh

demo-batch-clear:
	@$(RUN_ENV) bash scripts/seed-batch-demo.sh --clear

test: build e2e-deps
	@$(RUN_ENV) CONSOLE_ALLOW_DESTRUCTIVE_DEMO_RESET=YES \
	 bash $(TESTS)/console-test.sh

clean:
	rm -rf $(BIN) $(SRC)/*.cob.gen

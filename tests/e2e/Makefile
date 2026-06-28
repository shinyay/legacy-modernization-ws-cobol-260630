SRC := src
BIN := bin
SCRIPTS := scripts

COBC := cobc

GEN_BIN := $(BIN)/e2e-fixture-gen
RECON_BIN := $(BIN)/e2e-recon-gen
CONC_BIN := $(BIN)/e2e-conc-gen
SEED_BIN := $(BIN)/e2e-seed-isam
DRIVER_BIN := $(BIN)/e2e-driver

COPY_DIRS := \
  -I /workspace/subsystems/10-txnvalidate/copy/api \
  -I /workspace/subsystems/11-txnsortmerge/copy/api \
  -I /workspace/subsystems/12-txnpost/copy/api \
  -I /workspace/shared/copy

.PHONY: build smoke perf recon concurrent ser-retry rev-retry outbox-loss clean

build: $(GEN_BIN) $(RECON_BIN) $(CONC_BIN) $(SEED_BIN) $(DRIVER_BIN)

$(GEN_BIN): $(SRC)/e2e-fixture-gen.cob | $(BIN)
	$(COBC) -x -free -O2 -W -o $@ $<

$(RECON_BIN): $(SRC)/e2e-recon-gen.cob | $(BIN)
	$(COBC) -x -free -O2 -W -o $@ $<

$(CONC_BIN): $(SRC)/e2e-conc-gen.cob | $(BIN)
	$(COBC) -x -free -O2 -W -o $@ $<

$(SEED_BIN): $(SRC)/e2e-seed-isam.cob | $(BIN)
	$(COBC) -x -free -O2 -W -o $@ $<

$(DRIVER_BIN): $(SRC)/e2e-driver.cob | $(BIN)
	$(COBC) -x -free -O2 -W $(COPY_DIRS) -o $@ $<

$(BIN):
	mkdir -p $@

smoke: build
	@bash $(SCRIPTS)/e2e-run.sh smoke

perf: build
	@bash $(SCRIPTS)/e2e-run.sh perf

recon: build
	@bash $(SCRIPTS)/e2e-run.sh recon

concurrent: build
	@bash $(SCRIPTS)/e2e-concurrent.sh

ser-retry: build
	@bash $(SCRIPTS)/e2e-serial-retry.sh

rev-retry: build
	@bash $(SCRIPTS)/e2e-reverse-retry.sh

outbox-loss: build
	@bash $(SCRIPTS)/e2e-outbox-loss.sh

clean:
	rm -rf $(BIN) /tmp/e2e

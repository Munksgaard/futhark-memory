.PHONY: all clean

HOST ?= gpu04

FUTHARK_MASTER_SHA ?= c323a902640a92cb9ba23eb484e7948eb64a9403
FUTHARK_MEM_SHA ?= 520a821d04aaa251922a5a9fbf0e692885854f7e

FUTHARK_MASTER_BIN ?= bin/futhark-master
FUTHARK_MEM_BIN ?= bin/futhark-mem

BENCHMARKS = LocVolCalib bfast

BENCHMARK_TARGETS = $(BENCHMARKS:%=benchmarks/%.fut)

MASTER_JSON = $(BENCHMARKS:%=results-$(HOST)/%-master.json)
MEM_JSON = $(BENCHMARKS:%=results-$(HOST)/%-mem.json)

all: $(MASTER_JSON) $(MEM_JSON)

bin/futhark-master:
	mkdir -p bin
	cd futhark && git checkout $(FUTHARK_MASTER_SHA) && stack --local-bin-path ../bin install
	mv bin/futhark $@

bin/futhark-mem:
	mkdir -p bin
	cd futhark && git checkout $(FUTHARK_MEM_SHA) && stack --local-bin-path ../bin install
	mv bin/futhark $@

.PRECIOUS: results-$(HOST)/%.tuning

results-$(HOST)/%-mem.tuning: benchmarks/%.fut $(FUTHARK_MEM_BIN)
	mkdir -p results-$(HOST)
	$(FUTHARK_MEM_BIN) autotune \
	  --backend=opencl \
	  --pass-option=--default-tile-size=8 \
	  --pass-option=--default-reg-tile-size=3 \
	  $<
	mv $<.tuning $@

results-$(HOST)/%-master.tuning: benchmarks/%.fut $(FUTHARK_MASTER_BIN)
	mkdir -p results-$(HOST)
	$(FUTHARK_MASTER_BIN) autotune \
	  --backend=opencl \
	  --pass-option=--default-tile-size=8 \
	  --pass-option=--default-reg-tile-size=3 \
	  $<
	mv $<.tuning $@

results-$(HOST)/%-mem.json: results-$(HOST)/%-mem.tuning benchmarks/%.fut $(FUTHARK_MEM_BIN)
	mkdir -p results-$(HOST)
	$(FUTHARK_MEM_BIN) bench \
	  --backend=opencl \
	  --pass-option=--default-tile-size=8 \
	  --pass-option=--default-reg-tile-size=3 \
          --runs=10 \
	  --json $@ \
	  $$(python tools/tuning_to_options.py < $<) \
	  benchmarks/$*.fut

results-$(HOST)/%-master.json: results-$(HOST)/%-master.tuning benchmarks/%.fut $(FUTHARK_MASTER_BIN)
	mkdir -p results-$(HOST)
	$(FUTHARK_MASTER_BIN) bench \
	  --backend=opencl \
	  --pass-option=--default-tile-size=8 \
	  --pass-option=--default-reg-tile-size=3 \
          --runs=10 \
	  --json $@ \
	  $$(python tools/tuning_to_options.py < $<) \
	  benchmarks/$*.fut

clean:
	rm -rf bin results-$(HOST)

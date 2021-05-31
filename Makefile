.PHONY: all clean clean-all

HOST ?= gpu04

PYTHON ?= python3

FUTHARK_MASTER_SHA ?= 9bc2f7ff27c7d16b8c36db875da7c047762e53ae
FUTHARK_MEM_SHA ?= a3ca0e7f50d9e679757b8463fae5eb329df66726

FUTHARK_MASTER_BIN ?= bin/futhark-master
FUTHARK_MEM_BIN ?= bin/futhark-mem

BENCHMARKS = LocVolCalib LocVolCalib32 bfast ocean-sim ocean-sim64 OptionPricing OptionPricing64

BENCHMARK_TARGETS = $(BENCHMARKS:%=benchmarks/%.fut)

MASTER_JSON = $(BENCHMARKS:%=results-$(HOST)/%-master.json)
MEM_JSON = $(BENCHMARKS:%=results-$(HOST)/%-mem.json)

all: benchmarks/lib $(MASTER_JSON) $(MEM_JSON)

benchmarks/lib:
	cd benchmarks && futhark pkg sync

bin/futhark-master:
	mkdir -p bin
	cd futhark && git checkout $(FUTHARK_MASTER_SHA) && nix-build
	tar xvf futhark/result/futhark-nightly.tar.xz -O futhark-nightly/bin/futhark  > $@
	chmod +x $@

bin/futhark-mem:
	mkdir -p bin
	cd futhark && git checkout $(FUTHARK_MASTER_SHA) && nix-build
	tar xvf futhark/result/futhark-nightly.tar.xz -O futhark-nightly/bin/futhark  > $@
	chmod +x $@

.PRECIOUS: tunings-$(HOST)/%-mem.tuning tunings-$(HOST)/%-master.tuning

tunings-$(HOST)/%-mem.tuning: benchmarks/%.fut
	mkdir -p tunings-$(HOST)
	$(FUTHARK_MEM_BIN) autotune \
	  --backend=opencl \
	  --pass-option=--default-tile-size=8 \
	  --pass-option=--default-reg-tile-size=3 \
          --runs=500 \
	  $<
	mv $<.tuning $@

tunings-$(HOST)/%-master.tuning: benchmarks/%.fut
	mkdir -p tunings-$(HOST)
	$(FUTHARK_MASTER_BIN) autotune \
	  --backend=opencl \
	  --pass-option=--default-tile-size=8 \
	  --pass-option=--default-reg-tile-size=3 \
          --runs=500 \
	  $<
	mv $<.tuning $@

results-$(HOST)/%-mem.json: tunings-$(HOST)/%-mem.tuning benchmarks/%.fut
	mkdir -p results-$(HOST)
	$(FUTHARK_MEM_BIN) bench \
	  --backend=opencl \
	  --pass-option=--default-tile-size=8 \
	  --pass-option=--default-reg-tile-size=3 \
          --runs=500 \
	  --json $@ \
	  $$($(PYTHON) tools/tuning_to_options.py < $<) \
	  benchmarks/$*.fut

results-$(HOST)/%-master.json: tunings-$(HOST)/%-master.tuning benchmarks/%.fut
	mkdir -p results-$(HOST)
	$(FUTHARK_MASTER_BIN) bench \
	  --backend=opencl \
	  --pass-option=--default-tile-size=8 \
	  --pass-option=--default-reg-tile-size=3 \
          --runs=500 \
	  --json $@ \
	  $$($(PYTHON) tools/tuning_to_options.py < $<) \
	  benchmarks/$*.fut

clean:
	rm -rf results-$(HOST)

clean-all: clean
	rm -rf tunings-$(HOST) bin

.PHONY: all clean clean-all

HOST ?= gpu04

PYTHON ?= python3

FUTHARK_MASTER_SHA ?= 9fee490902a0bbab1eaa1c777591da83d213667b
FUTHARK_MEM_SHA ?= b129106ad33e7429e736ccc7dd9eecda8226fab4

FUTHARK_MASTER_BIN ?= bin/futhark-master
FUTHARK_MEM_BIN ?= bin/futhark-mem

BENCHMARKS = LocVolCalib LocVolCalib32 bfast bfast64 ocean-sim ocean-sim64 OptionPricing OptionPricing64

BENCHMARK_TARGETS = $(BENCHMARKS:%=benchmarks/%.fut)

MASTER_JSON = $(BENCHMARKS:%=results-$(HOST)/%-master.json)
MEM_JSON = $(BENCHMARKS:%=results-$(HOST)/%-mem.json)

all: $(MASTER_JSON) $(MEM_JSON)

bin/futhark-master:
	mkdir -p bin
	cd futhark && git checkout $(FUTHARK_MASTER_SHA) && nix-build
	tar xvf futhark/result/futhark-nightly.tar.xz -O futhark-nightly/bin/futhark  > $@
	chmod +x $@

bin/futhark-mem:
	mkdir -p bin
	cd futhark && git checkout $(FUTHARK_MEM_SHA) && nix-build
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

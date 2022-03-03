BENCHMARKS = lud bfast hotspot lbm LocVolCalib LocVolCalib-seq OptionPricing

.PHONY: all
all:
	for b in $(BENCHMARKS); do \
	  make -C $$b ; \
	done

.PHONY: clean
clean:
	for b in $(BENCHMARKS); do \
	  make -C $$b clean ; \
	done

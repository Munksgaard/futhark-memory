BENCHMARKS = lud hotspot lbm LocVolCalib LocVolCalib-seq OptionPricing nw

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

.PHONY: clean-futhark
clean-futhark:
	for b in $(BENCHMARKS); do\
	  make -C $$b clean-futhark ; \
	done

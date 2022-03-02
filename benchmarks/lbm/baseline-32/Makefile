RUNS ?= 10

EXTERNALS_DIR = ../../../externals
PARBOIL_DIR = $(EXTERNALS_DIR)/parboil

results.json:
	make -C $(EXTERNALS_DIR) parboil.patched
	cd $(PARBOIL_DIR)
	for i in $(shell seq 0 $(RUNS)); do (cd $(PARBOIL_DIR); ./parboil run lbm opencl_nvidia long); done \
	  | grep "Kernel  " \
	  | tail -n +2 \
	  | cut -d: -f2 \
	  | jq -nR '{"../data/f32.data": { "runtimes": [inputs | select(length>0) | tonumber | . * 1000000]}}' \
	  > $@

clean:
	rm -f results.json

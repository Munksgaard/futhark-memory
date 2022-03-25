#C compiler
CC = g++

CC_FLAGS = -g -O3 -Wall

EXE = nw

RUNS ?= 10

KERNEL_DIM ?= -DRD_WG_SIZE_0=16

results.json: nw
	./$< 2048 10 ./nw.cl $(RUNS) \
	  | jq -nR '{"mk_input 2048i64": { "runtimes": [inputs | select(length>0) | tonumber]}}' \
	  > $@

	./$< 4096 10 ./nw.cl $(RUNS) \
	  | jq -nR '{"mk_input 4096i64": { "runtimes": [inputs | select(length>0) | tonumber]}}' \
	  | jq -s '.[0] + .[1]' - $@ \
	  | sponge $@

	./$< 8192 10 ./nw.cl $(RUNS) \
	  | jq -nR '{"mk_input 8192i64": { "runtimes": [inputs | select(length>0) | tonumber]}}' \
	  | jq -s '.[0] + .[1]' - $@ \
	  | sponge $@

	./$< 16384 10 ./nw.cl $(RUNS) \
	  | jq -nR '{"mk_input 16384i64": { "runtimes": [inputs | select(length>0) | tonumber]}}' \
	  | jq -s '.[0] + .[1]' - $@ \
	  | sponge $@

	./$< 32768 10 ./nw.cl $(RUNS) \
	  | jq -nR '{"mk_input 32768i64": { "runtimes": [inputs | select(length>0) | tonumber]}}' \
	  | jq -s '.[0] + .[1]' - $@ \
	  | sponge $@

$(EXE): nw.c
	$(CC) ${KERNEL_DIM} $(CC_FLAGS) -o $(EXE) nw.c -lOpenCL -std=c11

clean:
	rm -f $(EXE)

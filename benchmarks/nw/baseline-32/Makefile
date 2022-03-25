#C compiler
CC = g++

CC_FLAGS = -g -O3 -Wall

EXE = nw

RUNS ?= 10

KERNEL_DIM ?= -DRD_WG_SIZE_0=16

results.json: nw
	./$< 4096 10 ./nw.cl $(RUNS) \
	  | jq -nR '{"mk_input 4198401i64": { "runtimes": [inputs | select(length>0) | tonumber]}}' \
	  > $@

	./$< 8192 10 ./nw.cl $(RUNS) \
	  | jq -nR '{"mk_input 67125249i64": { "runtimes": [inputs | select(length>0) | tonumber]}}' \
	  | jq -s '.[0] + .[1]' - $@ \
	  | sponge $@

	./$< 16384 10 ./nw.cl $(RUNS) \
	  | jq -nR '{"mk_input 268468225i64": { "runtimes": [inputs | select(length>0) | tonumber]}}' \
	  | jq -s '.[0] + .[1]' - $@ \
	  | sponge $@

	./$< 32768 10 ./nw.cl $(RUNS) \
	  | jq -nR '{"mk_input 1073807361i64": { "runtimes": [inputs | select(length>0) | tonumber]}}' \
	  | jq -s '.[0] + .[1]' - $@ \
	  | sponge $@

$(EXE): nw.c
	$(CC) ${KERNEL_DIM} $(CC_FLAGS) -o $(EXE) nw.c -lOpenCL -std=c11

clean:
	rm -f $(EXE)

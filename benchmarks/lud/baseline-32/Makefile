CC = g++
CC_FLAGS = -g -O3 -Wall

RUNS ?= 10

results.json: lud
	./$< -s 2048 -r $(RUNS) \
	  | jq -nR '{"2048": { "runtimes": [inputs | select(length>0) | tonumber]}}' \
	  > $@

	./$< -s 4096 -r $(RUNS) \
	  | jq -nR '{"4096": { "runtimes": [inputs | select(length>0) | tonumber]}}' \
	  | jq -s '.[0] + .[1]' - $@ \
	  | sponge $@

	./$< -s 8192 -r $(RUNS) \
	  | jq -nR '{"8192": { "runtimes": [inputs | select(length>0) | tonumber]}}' \
	  | jq -s '.[0] + .[1]' - $@ \
	  | sponge $@

	./$< -s 16384 -r $(RUNS) \
	  | jq -nR '{"16384": { "runtimes": [inputs | select(length>0) | tonumber]}}' \
	  | jq -s '.[0] + .[1]' - $@ \
	  | sponge $@

	./$< -s 32768 -r $(RUNS) \
	  | jq -nR '{"32768": { "runtimes": [inputs | select(length>0) | tonumber]}}' \
	  | jq -s '.[0] + .[1]' - $@ \
	  | sponge $@

lud: lud.cpp common.c common.h
	$(CC) $(CC_FLAGS) -o $@ lud.cpp common.c -lOpenCL

clean:
	rm -f lud

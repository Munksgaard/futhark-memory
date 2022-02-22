CC = gcc
CC_FLAGS = -g -O3 -Wall

RUNS ?= 10

results.json: hotspot
	./$< 2048 2 360 ../data/temp_2048.data ../data/power_2048.data /dev/null 10 \
	  | jq -nR '{"2048": { "runtimes": [inputs | select(length>0) | tonumber]}}' \
	  > $@

	./$< 4096 2 360 ../data/temp_4096.data ../data/power_4096.data /dev/null 10 \
	  | jq -nR '{"4096": { "runtimes": [inputs | select(length>0) | tonumber]}}' \
	  | jq -s '.[0] + .[1]' - $@ \
	  | sponge $@

	./$< 8192 2 360 ../data/temp_8192.data ../data/power_8192.data /dev/null 10 \
	  | jq -nR '{"8192": { "runtimes": [inputs | select(length>0) | tonumber]}}' \
	  | jq -s '.[0] + .[1]' - $@ \
	  | sponge $@

	./$< 16384 2 360 ../data/temp_16384.data ../data/power_16384.data /dev/null 10 \
	  | jq -nR '{"16384": { "runtimes": [inputs | select(length>0) | tonumber]}}' \
	  | jq -s '.[0] + .[1]' - $@ \
	  | sponge $@

	./$< 32768 2 360 ../data/temp_32768.data ../data/power_32768.data /dev/null 10 \
	  | jq -nR '{"32768": { "runtimes": [inputs | select(length>0) | tonumber]}}' \
	  | jq -s '.[0] + .[1]' - $@ \
	  | sponge $@

hotspot: hotspot.c hotspot_kernel.cl ../../common/common.h
	$(CC) $(CC_FLAGS) -o $@ $< -lm -lOpenCL

clean:
	rm -f hotspot results.json

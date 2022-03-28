CC = gcc
CC_FLAGS = -g -O3 -Wall -std=c99

RUNS ?= 10

results.json: hotspot
	./$< 2048 2 10 ../data/temp_2048.data ../data/power_2048.data /dev/null 10 \
	  | jq -nR '{"10i32 [2048][2048]f32 [2048][2048]f32": { "runtimes": [inputs | select(length>0) | tonumber]}}' \
	  > $@

	./$< 4096 2 10 ../data/temp_4096.data ../data/power_4096.data /dev/null 10 \
	  | jq -nR '{"10i32 [4096][4096]f32 [4096][4096]f32": { "runtimes": [inputs | select(length>0) | tonumber]}}' \
	  | jq -s '.[0] + .[1]' - $@ \
	  | sponge $@

	./$< 8192 2 10 ../data/temp_8192.data ../data/power_8192.data /dev/null 10 \
	  | jq -nR '{"10i32 [8192][8192]f32 [8192][8192]f32": { "runtimes": [inputs | select(length>0) | tonumber]}}' \
	  | jq -s '.[0] + .[1]' - $@ \
	  | sponge $@

	./$< 16384 2 10 ../data/temp_16384.data ../data/power_16384.data /dev/null 10 \
	  | jq -nR '{"10i32 [16384][16384]f32 [16384][16384]f32": { "runtimes": [inputs | select(length>0) | tonumber]}}' \
	  | jq -s '.[0] + .[1]' - $@ \
	  | sponge $@

	./$< 32768 2 10 ../data/temp_32768.data ../data/power_32768.data /dev/null 10 \
	  | jq -nR '{"10i32 [32768][32768]f32 [32768][32768]f32": { "runtimes": [inputs | select(length>0) | tonumber]}}' \
	  | jq -s '.[0] + .[1]' - $@ \
	  | sponge $@

hotspot: hotspot.c hotspot_kernel.cl ../../common/common.h
	$(CC) $(CC_FLAGS) -o $@ $< -lm -lOpenCL

clean:
	rm -f hotspot results.json

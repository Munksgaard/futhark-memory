CC = g++
CC_FLAGS = -g -O3 -Wall

results.txt: lud
	./$< -s 2048

lud: lud.cpp common.c common.h
	$(CC) $(CC_FLAGS) -o $@ lud.cpp common.c -lOpenCL

clean:
	rm -f lud

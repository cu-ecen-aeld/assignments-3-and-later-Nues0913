CC=$(CROSS_COMPILE)gcc
CFLAGS=-Wall -Werror

.PHONY: all clean

all: aesdsocket

aesdsocket: aesdsocket.c
	$(CC) -o aesdsocket aesdsocket.c $(CFLAGS)

clean:
	rm -f ./*.o aesdsocket

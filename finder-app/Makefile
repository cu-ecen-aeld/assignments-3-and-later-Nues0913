CC = gcc
CROSS_COMPILE ?=
TARGET = writer
SRC = writer.c
OBJ = $(SRC:.c=.o)

all: $(TARGET)

$(TARGET): $(SRC)
	$(CROSS_COMPILE)$(CC) -o $@ $^

clean:
	rm -f $(TARGET) $(OBJ)

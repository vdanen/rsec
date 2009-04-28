CC = gcc
NAME = promisc_check
DESTDIR =
BINDIR = /usr/bin

CFLAGS = -ggdb -Wall -Wmissing-prototypes -Wmissing-declarations \
-Wpointer-arith -O2 -finline-functions -fkeep-inline-functions

OBJ=promisc_check.o

promisc_check: $(OBJ)
	$(CC) $(OBJ) -o $(NAME)

install:
	mkdir -p $(DESTDIR)$(BINDIR)
	install -m 0750 $(NAME) $(DESTDIR)$(BINDIR)

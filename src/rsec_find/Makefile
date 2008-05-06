CC = gcc
NAME = rsec_find
BINDIR = /usr/bin

CFLAGS = -ggdb -Wall -Wmissing-prototypes -Wmissing-declarations \
-Wpointer-arith -m486 -O2 -finline-functions -fkeep-inline-functions

OBJ=find.o

rsec_find: $(OBJ)
	$(CC) -D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64 $(OBJ) -o $(NAME)

install:
	mkdir -p $(RPM_BUILD_ROOT)$(BINDIR)
	install -m 0644 $(NAME) $(RPM_BUILD_ROOT)$(BINDIR)

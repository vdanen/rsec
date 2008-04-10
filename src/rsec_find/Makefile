CC=gcc
NAME=rsec_find

CFLAGS = -ggdb -Wall -Wmissing-prototypes -Wmissing-declarations \
-Wpointer-arith -m486 -O2 -finline-functions -fkeep-inline-functions

OBJ=find.o

msec_find: $(OBJ)
	$(CC) -D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64 $(OBJ) -o $(NAME)

install:
	mkdir -p $(RPM_BUILD_ROOT)/usr/bin
	cp $(NAME) $(RPM_BUILD_ROOT)/usr/bin

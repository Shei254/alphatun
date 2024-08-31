service     ?= localhost:51820
outside     ?= jump.example.com:51820
listen      ?= 51820
prefix      ?= /usr/local

name        = alphatun
version     = 1.3
objs        = main.o connlist.o args.o sha-256.o mac.o misc.o main-inside.o main-outside.o
deps        = $(patsubst %.o,%.d,$(objs))
CFLAGS      = -O3 -flto -Wall -Wextra
unit_dir    = /etc/systemd/system

CFLAGS     += -DVERSION=$(version)

all: $(name)

clean:
	rm -f $(name) $(objs) $(deps)

install:
	install -m 755 alphatun $(prefix)/bin/

install-inside: install
	install -m 644 alphatun-inside.service $(unit_dir)/
	sed -ie 's/{{SERVICE}}/$(service)/g' $(unit_dir)/alphatun-inside.service
	sed -ie 's/{{OUTSIDE}}/$(outside)/g' $(unit_dir)/alphatun-inside.service
	systemctl daemon-reload

install-outside: install
	install -m 644 alphatun-outside.service $(unit_dir)/
	sed -i 's/{{LISTEN}}/$(listen)/g' $(unit_dir)/alphatun-outside.service
	systemctl daemon-reload

uninstall:
	-systemctl stop alphatun-outside.service
	-systemctl stop alphatun-inside.service
	rm -f $(unit_dir)/alphatun-outside.service
	rm -f $(unit_dir)/alphatun-inside.service
	rm -f $(prefix)/bin/alphatun
	systemctl daemon-reload

# compile the modules
%.o: %.c
	$(CC) -MMD $(CFLAGS) -c $< -o $@

# link the executable
$(name): $(objs)
	$(CC) -o $@ $(CFLAGS) $(LFLAGS) $^

# also depend on changes in the makefile
$(objs): Makefile

# try to include compiler generated dependency makefile snippets *.d
-include $(deps)

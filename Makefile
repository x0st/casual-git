PREFIX=/usr/local
NAME=gh
PWD=$(shell pwd)

install: uninstall
	mkdir -p $(PREFIX)/bin
	ln -s $(PWD)/gh.sh $(PREFIX)/bin/$(NAME)

uninstall:
	rm -f $(PREFIX)/bin/$(NAME)

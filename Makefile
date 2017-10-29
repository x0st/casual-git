PREFIX=/usr/local
NAME=gh

install: uninstall
	cp gh.sh $(NAME)
	chmod +x $(NAME)
	mkdir -p $(PREFIX)/bin
	install $(NAME) $(PREFIX)/bin/
	rm -f $(NAME)

uninstall:
	rm -f $(PREFIX)/bin/$(NAME)

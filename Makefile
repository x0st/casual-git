DUMMY_REBASE_EDITOR_NAME=casual-git-dummy-rebase-editor
PREFIX=/usr/local
NAME=gh
PWD=$(shell pwd)

install: uninstall
	mkdir -p $(PREFIX)/bin
	ln -s $(PWD)/gh.sh $(PREFIX)/bin/$(NAME)
	ln -s $(PWD)/casual-git-dummy-rebase-editor.sh $(PREFIX)/bin/$(DUMMY_REBASE_EDITOR_NAME)

uninstall:
	rm -f $(PREFIX)/bin/$(NAME)
	rm -f $(PREFIX)/bin/$(DUMMY_REBASE_EDITOR_NAME)

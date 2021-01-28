export PREFIX := /usr/

.PHONY: all
all:
	$(info Usage: make install [PREFIX=/usr/])
	true

.PHONY: install
install: imenu.sh
	$(info "INFO: install PREFIX: $(PREFIX)")
	mkdir -p $(DESTDIR)$(PREFIX)bin
	install -Dm 775 imenu.sh $(DESTDIR)$(PREFIX)bin/imenu

.PHONY: uninstall
uninstall:
	rm $(DESTDIR)$(PREFIX)bin/imenu

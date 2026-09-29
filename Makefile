PREFIX ?= $(HOME)/.local
BINARY := aeroplace

.PHONY: build check install clean

build:
	swift build -c release

check: build
	bash test/host.sh .build/release/$(BINARY)
	AEROPLACE_LUA=$(CURDIR)/test .build/release/$(BINARY)
	AEROPLACE_LUA=$(CURDIR)/lua .build/release/$(BINARY) stages

install: build
	install -d $(PREFIX)/bin $(PREFIX)/share/$(BINARY)
	install -m 755 .build/release/$(BINARY) $(PREFIX)/bin/$(BINARY)
	install -m 644 lua/*.lua $(PREFIX)/share/$(BINARY)/

clean:
	swift package clean
	rm -rf .build

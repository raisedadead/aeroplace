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
	install -d $(PREFIX)/bin
	install -m 755 .build/release/$(BINARY) $(PREFIX)/bin/$(BINARY)

clean:
	swift package clean
	rm -rf .build

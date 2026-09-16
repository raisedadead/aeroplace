PREFIX ?= $(HOME)/.local
BINARY := aeroplace

.PHONY: build install clean

build:
	swift build -c release

install: build
	install -d $(PREFIX)/bin
	install -m 755 .build/release/$(BINARY) $(PREFIX)/bin/$(BINARY)

clean:
	swift package clean
	rm -rf .build

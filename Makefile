PREFIX ?= $(HOME)/.local
BINARY := aeroplace
TEST_ENV := PATH="$(CURDIR)/test/bin:$$PATH"

.PHONY: build check install clean

build:
	swift build -c release

check: build
	$(TEST_ENV) bash test/host.sh .build/release/$(BINARY)
	$(TEST_ENV) AEROPLACE_LUA=$(CURDIR)/test .build/release/$(BINARY)
	$(TEST_ENV) AEROPLACE_LUA=$(CURDIR)/lua .build/release/$(BINARY) stages

install: build
	install -d $(PREFIX)/bin $(PREFIX)/share/$(BINARY)
	install -m 755 .build/release/$(BINARY) $(PREFIX)/bin/$(BINARY)
	install -m 644 lua/*.lua $(PREFIX)/share/$(BINARY)/

clean:
	swift package clean
	rm -rf .build

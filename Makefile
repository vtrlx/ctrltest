PREFIX = /app

CSRCS = ctrltest.c
LSRCS = ctrltest.lua

BIN = ctrltest
OBJS = $(patsubst %.lua, %_bytecode.o, $(LSRCS))
LIBS = -llua -ldl -lm -Wl,-E
CFLAGS = -L$(PREFIX)/lib $(LIBS)

APPID = ca.vlacroix.ControlTester
ifdef DEVEL
CFLAGS += -DDEVEL
APPID = ca.vlacroix.ControlTester.Devel
endif

DESKTOP_FILE = $(APPID).desktop
ICON = $(APPID).svg
SYMBOLIC = $(APPID)-symbolic.svg
METAINFO = $(APPID).metainfo.xml

all: $(BIN)

$(BIN): $(CSRCS) $(OBJS)
	cc -o $@ $^ -L/app/lib $(CFLAGS)

%_bytecode.o: %.bytecode
	ld -r -b binary -o $@ $^

%.bytecode: %.lua
	luac -o $@ -- $^

.PHONY: clean install

clean:
	rm -f ctrltest ctrltest_bytecode.o ctrltest.bytecode

install: $(BIN)
	install -D -m 0755 -t $(PREFIX)/bin $<
	install -D -m 0644 -t $(PREFIX)/share/applications $(DESKTOP_FILE)
#	install -D -m 0644 -t $(PREFIX)/share/icons/hicolor/scalable/apps icons/$(ICON)
#	install -D -m 0644 -t $(PREFIX)/share/icons/hicolor/symbolic/apps icons/$(SYMBOLIC)
#	install -D -m 0644 -t $(PREFIX)/share/metainfo $(METAINFO)
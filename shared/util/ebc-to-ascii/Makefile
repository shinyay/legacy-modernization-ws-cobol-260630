LIB := bin/libebc-to-ascii.so

.PHONY: build clean test-unit

build: $(LIB)

test-unit:
	@echo "[ebc-to-ascii] no unit tests (= C lib; exercised via 19-integrationin)"

$(LIB): src/ebc_conv.c | bin
	gcc -O2 -fPIC -shared -o $@ $< -liconv 2>/dev/null || \
	gcc -O2 -fPIC -shared -o $@ $<

bin:
	mkdir -p $@

clean:
	rm -rf bin

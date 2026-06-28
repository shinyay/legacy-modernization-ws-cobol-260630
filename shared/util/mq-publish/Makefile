LIB := bin/libmq-publish.so

.PHONY: build clean test-unit

build: $(LIB)

test-unit:
	@echo "[mq-publish] no unit tests (= C lib; exercised via 20-integrationout)"

$(LIB): src/rmq_pub.c | bin
	gcc -O2 -fPIC -shared -o $@ $< -lrabbitmq

bin:
	mkdir -p $@

clean:
	rm -rf bin

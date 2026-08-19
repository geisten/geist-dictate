# geist-dictate — system-wide local dictation on the geist engine.
#
# geistlib is a pinned submodule; this Makefile mirrors geistlib's own
# examples/Makefile so dictate links with exactly the flags the engine
# was built with — no duplicated platform knowledge.
#
#   make            # build ./dictate (builds the pinned libgeist.a on demand)
#   make setup      # fetch model (~3.1 GB) + audio tower (~590 MB), SHA-pinned
#   make test       # smoke test (full transcript check when fixtures exist)

GEISTLIB := geistlib
TARGET ?= $(shell $(GEISTLIB)/mk/detect-target.sh)
MODE   ?= release

include $(GEISTLIB)/mk/target-$(TARGET).mk

GEMM_PROVIDER ?= native
include $(GEISTLIB)/mk/gemm-$(GEMM_PROVIDER).mk

LIB := $(GEISTLIB)/lib/$(TARGET)/$(MODE)/libgeist.a

CFLAGS  := -std=c23 -O2 -Wall -Wextra -I$(GEISTLIB)/include $(CFLAGS_TARGET) $(GEMM_CFLAGS)
LDFLAGS := $(LDFLAGS_TARGET)
LDLIBS  := $(LDLIBS_TARGET) $(GEMM_LDLIBS)

.PHONY: all setup test clean

all: dictate

dictate: src/dictate.c $(LIB)
	$(CC) $(CFLAGS) -o $@ $< $(LIB) $(LDFLAGS) $(LDLIBS)

$(LIB):
	$(MAKE) -C $(GEISTLIB) lib TARGET=$(TARGET) MODE=$(MODE)

# Model + tower land inside the submodule (gguf_artifacts/, audio_bench/)
# where the engine's default search paths find them. Idempotent: both are
# real file targets in geistlib's Makefile.
setup:
	$(MAKE) -C $(GEISTLIB) fetch-model fetch-audio-tower

test: dictate
	sh tests/smoke.sh

clean:
	rm -f dictate

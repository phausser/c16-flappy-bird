ACME ?= acme
VICE ?= xplus4

# Release 0.97 (Homebrew) has no --strict. The CI builds svn r446, which
# does, and there warnings fail the build. -Wtype-mismatch stays off: the
# zero-page names are plain values, so that check warns on every store.
ACME_FLAGS = --format cbm --cpu 6502 --strict-segments
ifneq ($(shell $(ACME) --help 2>&1 | grep -c -e '--strict '),0)
ACME_FLAGS += --strict
endif

BUILD_DIR := build
PRG := $(BUILD_DIR)/flappy.prg
SYMBOLS := $(BUILD_DIR)/flappy.sym
SOURCE := src/font.inc src/gradient.asm src/obstacles.asm src/bird_masks.inc src/collision.asm src/main.asm src/video.asm src/render.asm src/score.asm src/bird.asm src/input.asm src/sound.asm src/hardware.inc src/memory.inc src/constants.inc

.PHONY: all run lint clean

all: $(PRG)

$(PRG): $(SOURCE) | $(BUILD_DIR)
	$(ACME) $(ACME_FLAGS) --outfile $@ --symbollist $(SYMBOLS) src/main.asm

$(BUILD_DIR):
	mkdir -p $@

run: $(PRG)
	$(VICE) -model c16pal -ramsize 16 -autostartprgmode 1 -autostart-delay 1 -autostart-warp -autostart $(PRG)

lint: $(PRG)
	python3 -m py_compile tools/lint.py
	python3 tools/lint.py

clean:
	rm -rf $(BUILD_DIR)

ACME ?= acme
VICE ?= xplus4

BUILD_DIR := build
PRG := $(BUILD_DIR)/flappy.prg
SYMBOLS := $(BUILD_DIR)/flappy.sym
SOURCE := src/main.asm src/video.asm src/render.asm src/bird.asm src/hardware.inc src/memory.inc src/constants.inc

.PHONY: all run clean

all: $(PRG)

$(PRG): $(SOURCE) | $(BUILD_DIR)
	$(ACME) --format cbm --outfile $@ --symbollist $(SYMBOLS) src/main.asm

$(BUILD_DIR):
	mkdir -p $@

run: $(PRG)
	$(VICE) -model c16pal -ramsize 16 -autostartprgmode 1 -autostart-delay 1 -autostart-warp -autostart $(PRG)

clean:
	rm -rf $(BUILD_DIR)

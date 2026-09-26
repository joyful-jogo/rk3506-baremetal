# =====================================================================
# Makefile —— RK3506 裸机 LED（只保留 Thumb 版）
#
# 用法：
#   make           默认：led_thumb.s -> led_thumb.bin（Thumb-2，能跑）
#   make dump      反汇编到 led_thumb.dis + 指令集自检
#   make bytes     十六进制查看 led_thumb.bin
#   make mw        生成 U-Boot 的 mw 命令 -> mw.txt 并打印
#   make clean     删除生成物（保留 led_thumb.s 源码）
#   make help      打印本帮助
#
# 说明：
#   所有 # 注释单独占一行，避免 GNU Make 把行内注释前空格并入变量值。
# =====================================================================

# ---------------------------------------------------------------------
# 1. 变量
# ---------------------------------------------------------------------
CROSS ?= arm-none-eabi-

CC      := $(CROSS)gcc
LD      := $(CROSS)ld
OBJCOPY := $(CROSS)objcopy
OBJDUMP := $(CROSS)objdump
READELF := $(CROSS)readelf

SRC := led_thumb.s
OBJ := led_thumb.o
ELF := led_thumb.elf
BIN := led_thumb.bin
MAP := led_thumb.map
DIS := led_thumb.dis
MW  := mw.txt

LDSCRIPT ?=
LOAD     := 0x01000000
LDFLAGS  := $(if $(LDSCRIPT),-T $(LDSCRIPT),-Ttext=$(LOAD))

CPU   := -mcpu=cortex-a7
THUMB := -mthumb
CFLAGS := $(CPU) $(THUMB) -g -Wall

SIZE = stat -c%s

# ---------------------------------------------------------------------
# 2. 目标声明
# ---------------------------------------------------------------------
.DEFAULT_GOAL := all
.DELETE_ON_ERROR:
.PHONY: all dump bytes mw clean help

all: $(BIN)

# ---------------------------------------------------------------------
# 3. 规则
# ---------------------------------------------------------------------
$(OBJ): $(SRC)
	$(CC) $(CFLAGS) -c $< -o $@

$(ELF): $(OBJ)
	$(LD) $(LDFLAGS) -Map $(MAP) $< -o $@

$(BIN): $(ELF)
	$(OBJCOPY) -O binary $< $@
	@printf '  %-16s %s 字节\n' "$@" "$$($(SIZE) $@)"

# ---------------------------------------------------------------------
# 4. 反汇编 + 指令集自检
# ---------------------------------------------------------------------
dump: $(ELF)
	$(OBJDUMP) -d -S $< > $(DIS)
	@echo "反汇编 -> $(DIS)"
	@echo "===== 指令集自检 ====="
	@if $(READELF) -A $< | grep -q 'Tag_THUMB_ISA_use: Thumb-2'; then \
		echo "✓ Thumb-2"; \
	else \
		echo "⚠ 未检测到 Tag_THUMB_ISA_use: Thumb-2"; \
	fi

# ---------------------------------------------------------------------
# 5. 十六进制查看
# ---------------------------------------------------------------------
bytes: $(BIN)
	@od -Ax -tx1 -v $(BIN)

# ---------------------------------------------------------------------
# 6. 生成 U-Boot 的 mw 命令（内联 python，不再依赖 gen_mw.py）
#    - 按小端 4 字节一组转成 mw.l 地址 值
#    - 末尾不足 4 字节自动补 0
# ---------------------------------------------------------------------
mw: $(BIN)
	@python3 -c "import sys; d=open('$(BIN)','rb').read(); a=$(LOAD); [sys.stdout.write('mw.l 0x%08x 0x%08x\n' % (a+i, int.from_bytes(d[i:i+4].ljust(4, b'\x00'), 'little'))) for i in range(0, len(d), 4)]" > $(MW)
	@echo "已生成 $(MW)："
	@cat $(MW)

# ---------------------------------------------------------------------
# 7. 清理与帮助
# ---------------------------------------------------------------------
clean:
	rm -f $(OBJ) $(ELF) $(BIN) $(MAP) $(DIS) $(MW)
	@echo "已清理生成物（led_thumb.s 已保留）"

help:
	@sed -n '/^# 用法：/,/^# ===/p' $(firstword $(MAKEFILE_LIST)) | sed 's/^# *//'

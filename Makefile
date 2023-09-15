######################################
# target
######################################
TARGET = firmware


######################################
# building variables
######################################
# debug build?
DEBUG = 1
# optimization
OPT = -Og


#######################################
# paths
#######################################

BASE_DIR = $(PWD)

# Build path (quoted for compatibility with Windows)
BUILD_DIR = build

# Toolchain path (https://stackoverflow.com/a/12099167)
# Best guess defaults in case ARM_GNU_TOOLCHAIN_PATH is not specified
ifeq ($(OS),Windows_NT)
	ARM_GNU_TOOLCHAIN_PATH ?= C:/Program Files (x86)/Arm GNU Toolchain arm-none-eabi/current
else
	UNAME_S := $(shell uname -s)
	ifeq ($(UNAME_S),Darwin)
		ARM_GNU_TOOLCHAIN_PATH ?= /opt/homebrew/bin
	else
		ARM_GNU_TOOLCHAIN_PATH ?= /usr/bin
	endif
endif


######################################
# source
######################################

# ASM sources
ASM_SOURCES = $(sort \
	./support/startup.s \
	$(wildcard ./src/*.s) \
)


#######################################
# binaries
#######################################
PREFIX = arm-none-eabi-

CC = "$(ARM_GNU_TOOLCHAIN_PATH)/$(PREFIX)gcc"
AS = "$(ARM_GNU_TOOLCHAIN_PATH)/$(PREFIX)gcc" -x assembler-with-cpp
CP = "$(ARM_GNU_TOOLCHAIN_PATH)/$(PREFIX)objcopy"
SZ = "$(ARM_GNU_TOOLCHAIN_PATH)/$(PREFIX)size"

HEX = $(CP) -O ihex
BIN = $(CP) -O binary -S


#######################################
# CFLAGS
#######################################
# cpu
CPU = -mcpu=cortex-m4

# mcu
MCU = $(CPU) -mthumb $(FPU) $(FLOAT-ABI)

# macros for gcc
# AS defines
AS_DEFS = 

# C defines
C_DEFS =  \
-DUSE_HAL_DRIVER \
-DSTM32F303xC


# AS includes
AS_INCLUDES = 

# C includes
C_INCLUDES = 

# compile gcc flags
ASFLAGS = $(MCU) $(AS_DEFS) $(AS_INCLUDES) $(OPT) -Wall -fdata-sections -ffunction-sections

CFLAGS = $(MCU) $(C_DEFS) $(C_INCLUDES) $(OPT) -Wall -fdata-sections -ffunction-sections

ifeq ($(DEBUG), 1)
CFLAGS += -g -gdwarf-2 -Wa,-adhlns="$@.lst"
endif


# Generate dependency information
CFLAGS += -MMD -MP -MF"$(@:%.o=%.d)"


#######################################
# LDFLAGS
#######################################
# link script
LDSCRIPT = ./support/STM32F303VCTx_FLASH.ld
LDFLAGS = $(MCU) -nostdlib -nodefaultlibs -nostartfiles -T$(LDSCRIPT) -Wl,-Map=$(BUILD_DIR)/$(TARGET).map,--cref -Wl,--no-warn-rwx-segment,--whole-archive

# default build elf only
default: $(BUILD_DIR)/$(TARGET).elf

# build all
all: $(BUILD_DIR)/$(TARGET).elf $(BUILD_DIR)/$(TARGET).hex $(BUILD_DIR)/$(TARGET).bin


#######################################
# build the application
#######################################
# list of objects
OBJECTS = $(addprefix $(BUILD_DIR)/,$(notdir $(C_SOURCES:.c=.o)))
vpath %.c $(sort $(dir $(C_SOURCES)))
# list of ASM program objects
OBJECTS += $(addprefix $(BUILD_DIR)/,$(notdir $(ASM_SOURCES:.s=.o)))
vpath %.s $(sort $(dir $(ASM_SOURCES)))

$(BUILD_DIR)/%.o: %.c Makefile | $(BUILD_DIR)
	$(CC) -c $(CFLAGS) -Wa,-a,-ad,-alms=$(BUILD_DIR)/$(notdir $(<:.c=.lst)) $< -o $@

$(BUILD_DIR)/%.o: %.s Makefile | $(BUILD_DIR)
	$(AS) -c $(CFLAGS) $< -o $@

$(BUILD_DIR)/$(TARGET).elf: $(OBJECTS) Makefile
	$(CC) $(OBJECTS) $(LDFLAGS) -o $@
	$(SZ) $@

$(BUILD_DIR)/%.hex: $(BUILD_DIR)/%.elf | $(BUILD_DIR)
	$(HEX) $< $@
	
$(BUILD_DIR)/%.bin: $(BUILD_DIR)/%.elf | $(BUILD_DIR)
	$(BIN) $< $@	
	
$(BUILD_DIR):
	mkdir "$@"



#######################################
# clean up
#######################################
clean:
	-rm -fR "$(BUILD_DIR)"


#######################################
# dependencies
#######################################
-include $(wildcard $(BUILD_DIR)/*.d)


# *** EOF ***
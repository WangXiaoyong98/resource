#########################################################################
AL_SDK_ROOT		?= $(SDK_ROOT)
AL_PLAT_DIR		?= $(PLAT_DIR)
OBJ_DIR			?= $(AL_SDK_ROOT)/build/obj
LIB_OUTPUT_DIR	?= $(AL_SDK_ROOT)/build/lib

include $(AL_SDK_ROOT)/tools/make/config.mk
sinclude $(AL_PLAT_DIR)/board_cfg.mk

ifeq ($(AL_CHIP), dr1v90)
LIB_PREBUILD_DIR  ?= $(AL_SDK_ROOT)/prebuild/$(CHIP)
else
LIB_PREBUILD_DIR  ?= $(AL_SDK_ROOT)/prebuild/$(CHIP)/$(ARMv8_STATE)
endif

CC      = ${Q}$(COMPILE_PREFIX)gcc
CXX     = ${Q}$(COMPILE_PREFIX)g++
AR      = ${Q}$(COMPILE_PREFIX)ar
LD      = ${Q}$(COMPILE_PREFIX)ld
OBJCOPY = ${Q}$(COMPILE_PREFIX)objcopy
OBJDUMP = ${Q}$(COMPILE_PREFIX)objdump
NM      = ${Q}$(COMPILE_PREFIX)nm
AS      = ${Q}$(COMPILE_PREFIX)as
GDB     = ${Q}$(COMPILE_PREFIX)gdb
SIZE    = ${Q}$(COMPILE_PREFIX)size
ECHO  	= echo
MAKE    = make

ARFLAGS = crs

#########################################################################
ifeq ($(AL_CHIP),dr1v90)
CORE            := riscv
CHIP_ARCH       := rv64imafdc
ARCH_ABI        := lp64d
ARCH_EXT        := ext-nuclei
else ifeq ($(ARMv8_STATE),64)
CORE            := arm
CHIP_ARCH       := armv8-a
ARCH_ABI        := aarch64
MTUNE           := cortex-a35
ARCH_FLAG       := -mtune=$(MTUNE) -march=$(CHIP_ARCH) -mcpu=$(MTUNE)

ifeq ($(benchmark),)
ARCH_FLAG       += -mstrict-align
endif

else ifeq ($(ARMv8_STATE),32)
CORE            := arm
CHIP_ARCH       := armv8-a
MTUNE           := cortex-a35
ARCH_ABI        := aarch32
ARCH_FLAG       := -mtune=$(MTUNE) -march=$(CHIP_ARCH) -mcpu=$(MTUNE) -mfpu=vfpv4 -marm -mno-unaligned-access
endif

export CHIP_ARCH
export ARCH_EXT


#########################################################################
## HPF configure

ASCT_TOOL ?= $(AL_SDK_ROOT)/tools/ci/asct

PLAT_H_PATH ?= $(AL_PLAT_DIR)/inc/soc_plat.h

ifeq ($(CORE),arm)
HPF_PATH ?= $(AL_SDK_ROOT)/tools/ci/C11_PL_FullScale_AD101V20.hpf
else ifeq ($(CORE),riscv)
HPF_PATH ?= $(AL_SDK_ROOT)/tools/ci/C11_PL_FullScale_AD102V20.hpf
endif

#########################################################################
LINKER_SCRIPT ?= $(CHIP_DIR)/lds/gcc_$(AL_CHIP)_$(DOWNLOAD)_$(ARCH_ABI).ld

ifeq ($(DOWNLOAD), ocm)
AL_CFLAGS   += -DDOWNLOAD_MODE=0
else ifeq ($(DOWNLOAD), ddr)
AL_CFLAGS   += -DDOWNLOAD_MODE=1
else ifeq ($(DOWNLOAD), tcm)
AL_CFLAGS   += -DDOWNLOAD_MODE=2
else ifeq ($(DOWNLOAD), xip)
AL_CFLAGS   += -DDOWNLOAD_MODE=3
endif

ifeq ($(SMP),1)
AL_CFLAGS   += -DSMP
endif

ifeq ($(ENABLE_MMU),1)
AL_CFLAGS   += -DENABLE_MMU=1
ifeq ($(DDR_2M_MAPPING),1)
AL_CFLAGS   += -DDDR_2M_MAPPING=1
ifeq ($(CODE_READONLY),1)
AL_CFLAGS   += -DCODE_READONLY=1
endif
endif
endif

ifeq ($(ENABLE_ICACHE),1)
AL_CFLAGS   += -DENABLE_ICACHE=1
endif

ifeq ($(ENABLE_DCACHE),1)
AL_CFLAGS   += -DENABLE_DCACHE=1
endif


#########################################################################
# gcc arm option:   https://gcc.gnu.org/onlinedocs/gcc/ARM-Options.html
# gcc riscv option: https://gcc.gnu.org/onlinedocs/gcc/RISC-V-Options.html
#

#
# -mcpu=$(MTUNE)
ifeq ($(CORE), arm)
AL_CFLAGS   += $(ARCH_FLAG) $(GC_CFLAGS) -fno-common

ifeq ($(benchmark),)
AL_CFLAGS   += -fno-builtin
endif

else ifeq ($(CORE), riscv)
AL_CFLAGS   += -march=$(CHIP_ARCH) -mabi=$(ARCH_ABI) -mcmodel=medany \
               $(GC_CFLAGS) -fno-common

ifeq ($(NEWLIB),nano)
NEWLIB_LDFLAGS = --specs=nano.specs
endif

endif

MKDEP_OPT   = -MMD -MT $@ -MF $@.d

ifeq ($(RTOS), freertos)
AL_CFLAGS += -DUSE_RTOS
AL_CFLAGS += -DRTOS_FREERTOS
else ifeq ($(RTOS), rtthread)
AL_CFLAGS += -DUSE_RTOS
AL_CFLAGS += -DRTOS_RTTHREAD
endif

#########################################################################
# all public inc
PUBLIC_INC_DIR :=  $(BSP_DIR)/inc \
                   $(CHIP_DIR)/inc \
                   $(CHIP_DIR)/../common/inc \
                   $(wildcard $(BSP_DIR)/driver/pl_driver/*/inc) \
                   $(wildcard $(BSP_DIR)/driver/ps_driver/*/inc) \
                   $(patsubst %/Makefile, %, $(wildcard $(AL_SDK_ROOT)/3rdparty/lib/*/Makefile)) \
                   $(wildcard $(AL_SDK_ROOT)/3rdparty/lib/*/inc) \
                   $(wildcard $(AL_SDK_ROOT)/3rdparty/lib/*/*/inc) \
                   $(wildcard $(BSP_DIR)/lib/*/inc) \
                   $(wildcard $(BSP_DIR)/lib/*/api/inc) \
                   $(BSP_DIR)/arch/arm/armv8/aarch64/cortex-a/inc \
                   $(BSP_DIR)/arch/common/inc \


ifeq ($(AL_CHIP), dr1v90)
PUBLIC_INC_DIR +=   $(CHIP_DIR)/../../../arch/riscv/rv64/inc \
                    $(CHIP_DIR)/../../../arch/riscv/ext-nuclei/inc \
                    $(CHIP_DIR)/../../../arch/common/inc
endif

ifeq ($(RTOS), rtthread)
PUBLIC_INC_DIR +=   $(AL_SDK_ROOT)/3rdparty/os/RT-Thread/rt-thread/include \
                    $(AL_SDK_ROOT)/3rdparty/os/RT-Thread/rt-thread/components/finsh \
                    $(AL_SDK_ROOT)/3rdparty/os/RT-Thread
endif

ifeq ($(RTOS), freertos)
ifeq ($(AL_CHIP),dr1m90)
ifeq ($(SMP),1)

PUBLIC_INC_DIR +=   $(CHIP_DIR)/../../../arch/arm/armv8/aarch64/cortex-a/inc \
                    $(AL_SDK_ROOT)/3rdparty/os/FreeRTOS/FreeRTOS-Kernel-SMP/portable/GCC/ARM_CA53_64_BIT_SRE \
                    $(CHIP_DIR)/../../../arch/common/inc \
                    $(CHIP_DIR)/../../../arch/arm/common/gic_v3/inc \
                    $(AL_SDK_ROOT)/3rdparty/os/FreeRTOS/FreeRTOS-Kernel-SMP/include \
                    $(AL_SDK_ROOT)/3rdparty/os/FreeRTOS/FreeRTOS-Kernel-SMP \
                    $(CHIP_DIR)/../../../arch/riscv/ext-nuclei/inc

else
PUBLIC_INC_DIR +=   $(CHIP_DIR)/../../../arch/arm/armv8/aarch64/cortex-a/inc \
                    $(AL_SDK_ROOT)/3rdparty/os/FreeRTOS/FreeRTOS-Kernel/portable/GCC/ARM_CA53_64_BIT_SRE \
                    $(CHIP_DIR)/../../../arch/common/inc \
                    $(CHIP_DIR)/../../../arch/arm/common/gic_v3/inc \
                    $(AL_SDK_ROOT)/3rdparty/os/FreeRTOS/FreeRTOS-Kernel/include \
                    $(AL_SDK_ROOT)/3rdparty/os/FreeRTOS/FreeRTOS-Kernel \
                    $(CHIP_DIR)/../../../arch/riscv/ext-nuclei/inc
endif

else ifeq ($(AL_CHIP), dr1v90)
PUBLIC_INC_DIR +=   $(AL_SDK_ROOT)/fpsoc/arch/riscv/rv64/inc \
                    $(AL_SDK_ROOT)/fpsoc/arch/riscv/ext-nuclei/inc \
                    $(CHIP_DIR)/../../../arch/common/inc \
                    $(AL_SDK_ROOT)/3rdparty/os/FreeRTOS/FreeRTOS-Kernel/portable/GCC/RISC-V \
                    $(AL_SDK_ROOT)/3rdparty/os/FreeRTOS/FreeRTOS-Kernel/include \
                    $(AL_SDK_ROOT)/3rdparty/os/FreeRTOS/FreeRTOS-Kernel \
                    $(CHIP_DIR)/../../../arch/riscv/ext-nuclei/inc \
                    $(CHIP_DIR)/../../../arch/riscv/rv64/inc

CFLAGS += -D__SYSTIMER_PRESENT=1 -D__Vendor_SysTickConfig=0 -D__ECLIC_PRESENT=1

endif

endif

#lwip
PUBLIC_INC_DIR +=  $(AL_SDK_ROOT)/3rdparty/lwip-2.1.3/src/include \
                   $(AL_SDK_ROOT)/3rdparty/lwip-2.1.3/src/include/compat/posix \
                   $(AL_SDK_ROOT)/3rdparty/lwip-2.1.3/ports   \
                   $(AL_SDK_ROOT)/3rdparty/lwip-2.1.3/ports/netif

#CherryUSB
PUBLIC_INC_DIR +=  $(AL_SDK_ROOT)/3rdparty/lib/CherryUSB/common \
                   $(AL_SDK_ROOT)/3rdparty/lib/CherryUSB/port/dwc2 \
                   $(AL_SDK_ROOT)/3rdparty/lib/CherryUSB/core \
                   $(AL_SDK_ROOT)/3rdparty/lib/CherryUSB/class/cdc \
                   $(AL_SDK_ROOT)/3rdparty/lib/CherryUSB/class/hub \
                   $(AL_SDK_ROOT)/3rdparty/lib/CherryUSB/class/hid \
                   $(AL_SDK_ROOT)/3rdparty/lib/CherryUSB/class/msc \
                   $(AL_SDK_ROOT)/3rdparty/lib/CherryUSB/class/video \
                   $(AL_SDK_ROOT)/3rdparty/lib/CherryUSB/class/audio \
                   $(AL_SDK_ROOT)/3rdparty/lib/CherryUSB/config \
                   $(AL_SDK_ROOT)/3rdparty/lib/CherryUSB/osal

#NMSIS
PUBLIC_INC_DIR +=  $(AL_SDK_ROOT)/3rdparty/lib/NMSIS/NMSIS/DSP/Include \
                   $(AL_SDK_ROOT)/3rdparty/lib/NMSIS/NMSIS/Core/Include

#libmetal
PUBLIC_INC_DIR +=  $(AL_SDK_ROOT)/3rdparty/lib/libmetal/include/lib/include

#open-amp
PUBLIC_INC_DIR +=  $(AL_SDK_ROOT)/3rdparty/lib/open-amp/lib/include \
                   $(AL_SDK_ROOT)/3rdparty/lib/open-amp/lib/rpmsg \
                   $(AL_SDK_ROOT)/3rdparty/lib/open-amp/include/include/generated

#Fatfs
PUBLIC_INC_DIR +=  $(AL_SDK_ROOT)/3rdparty/lib/FATFS

#tinyusb
PUBLIC_INC_DIR +=  $(AL_SDK_ROOT)/3rdparty/tinyusb/class/audio \
                   $(AL_SDK_ROOT)/3rdparty/tinyusb/class/bth \
                   $(AL_SDK_ROOT)/3rdparty/tinyusb/class/dfu \
                   $(AL_SDK_ROOT)/3rdparty/tinyusb/class/hid \
                   $(AL_SDK_ROOT)/3rdparty/tinyusb/class/midi \
                   $(AL_SDK_ROOT)/3rdparty/tinyusb/class/msc \
                   $(AL_SDK_ROOT)/3rdparty/tinyusb/class/net \
                   $(AL_SDK_ROOT)/3rdparty/tinyusb/class/usbtmc \
                   $(AL_SDK_ROOT)/3rdparty/tinyusb/class/vendor \
                   $(AL_SDK_ROOT)/3rdparty/tinyusb/class/video \
                   $(AL_SDK_ROOT)/3rdparty/tinyusb/common \
                   $(AL_SDK_ROOT)/3rdparty/tinyusb/device \
                   $(AL_SDK_ROOT)/3rdparty/tinyusb/host \
                   $(AL_SDK_ROOT)/3rdparty/tinyusb/osal \
                   $(AL_SDK_ROOT)/3rdparty/tinyusb/portable/synopsys/dwc2 \
                   $(AL_SDK_ROOT)/3rdparty/tinyusb/typec \
                   $(AL_SDK_ROOT)/3rdparty/tinyusb/


PUBLIC_INC  :=  $(foreach subdir,$(sort $(PUBLIC_INC_DIR)), -I$(subdir))

## module inc
MODULE_INC  :=  $(foreach subdir,$(sort $(INC_DIR)), -I$(subdir)) $(foreach subdir,$(sort $(APP_INC_DIR)), -I$(subdir)) -I$(AL_PLAT_DIR)/inc -I$(AL_PLAT_DIR)

#########################################################################

ifeq ($(CORE),arm)
CFLAGS +=  -mcpu=cortex-a35 -gdwarf-2

ifeq ($(benchmark),)
CFLAGS += -ffreestanding -fno-omit-frame-pointer -fno-stack-protector
endif

endif


AL_CFLAGS  += $(CFLAGS) $(PUBLIC_INC) $(MODULE_INC) $(MKDEP_OPT) -Wall -Werror=implicit-function-declaration
#########################################################################
# ldflags
ifneq ($(NOGC),1)
GC_CFLAGS  =   -ffunction-sections -fdata-sections
endif

GC_LDFLAGS +=  -Wl,--gc-sections -Wl,--check-sections

ifeq ($(PFLOAT),1)
NEWLIB_LDFLAGS += -u _printf_float
endif

LIB_OPT  = $(addprefix -L, $(sort $(LIB_DIR)))

ifeq ($(CORE),arm)
LDFLAGS += -Wl,--no-warn-rwx-segments
endif
#########################################################################
# source

C_SRCS     += $(foreach subdir, $(SRC_DIR), $(wildcard $(subdir)/*.c $(subdir)/*.C))
ASM_SRCS   += $(foreach subdir, $(SRC_DIR), $(wildcard $(subdir)/*.s $(subdir)/*.S))
CXX_SRCS   += $(foreach subdir, $(SRC_DIR), $(wildcard $(subdir)/*.cpp $(subdir)/*.CPP))

APP_C_SRCS += $(foreach subdir, $(APP_SRC_DIR), $(wildcard $(subdir)/*.c $(subdir)/*.cpp $(subdir)/*.C $(subdir)/*.CPP))

C_SRCS_ABSPATH 		:= $(abspath $(C_SRCS))
ASM_SRCS_ABSPATH 	:= $(abspath $(ASM_SRCS))
CXX_SRCS_ABSPATH 	:= $(abspath $(CXX_SRCS))

APP_C_SRCS_ABSPATH 	:= $(abspath $(APP_C_SRCS))


ifneq ($(APP_TAR_DIR), )
	OBJ_DIR 		:= $(APP_TAR_DIR)/obj
	LIB_OUTPUT_DIR	:= $(APP_TAR_DIR)/lib
	TARGET_PATH 	:= $(APP_TAR_DIR)/
else
	TARGET_PATH		:= .
endif

C_OBJS     			:= $(patsubst $(AL_SDK_ROOT)/%,$(OBJ_DIR)/%.o, $(C_SRCS_ABSPATH))
ASM_OBJS   			:= $(patsubst $(AL_SDK_ROOT)/%,$(OBJ_DIR)/%.o, $(ASM_SRCS_ABSPATH))
CXX_OBJS   			:= $(patsubst $(AL_SDK_ROOT)/%,$(OBJ_DIR)/%.o, $(CXX_SRCS_ABSPATH))
APP_C_OBJS			:= $(patsubst $(APP_CUR_DIR)/%,$(APP_OBJ_DIR)/%.o, $(APP_C_SRCS_ABSPATH))


ALL_OBJS   			:= $(ASM_OBJS) $(C_OBJS) $(CXX_OBJS) $(APP_C_OBJS)
ALL_DEPS   			:= $(ALL_OBJS:=.d)


VPATH = $(dir $(C_SRCS_ABSPATH)) $(dir $(CXX_SRCS_ABSPATH)) $(dir $(ASM_SRCS_ABSPATH)) $(dir $(APP_C_SRCS_ABSPATH))

CLEAN_OBJS += $(TARGET).elf $(TARGET).map $(TARGET).bin $(TARGET).dump $(TARGET).dasm \
				 $(TARGET).hex $(TARGET).verilog $(AL_SDK_ROOT)/build $(APP_TAR_DIR)

REAL_CLEAN_OBJS = $(subst /,$(PS), $(CLEAN_OBJS))

#########################################################################
# Prerequesties
COMMON_PREREQS +=	$(AL_SDK_ROOT)/tools/make/rules.mk
COMMON_PREREQS +=	$(AL_SDK_ROOT)/tools/make/config.mk
COMMON_PREREQS +=	$(AL_CUR_DIR)/Makefile
COMMON_PREREQS +=   Makefile


#########################################################################
# target: build elf, or build libs
#
ifneq ($(TARGET),)

TARGET_ELF = $(TARGET_PATH)/$(TARGET).elf
$(TARGET): $(TARGET_ELF)

endif
#########################################################################
# Default goal, placed before dependency includes
#
all: info $(TARGET_ELF)

#########################################################################
# include dependency files of application
#
ifneq ($(MAKECMDGOALS),clean)
-include $(ALL_DEPS)
endif

.PHONY: all info help clean

info:
	@$(ECHO) AL_CHIP=$(AL_CHIP) CORE=$(CORE) BOARD=$(BOARD) V=$(V) RTOS=$(RTOS) PFLOAT=$(PFLOAT) NOGC:$(NOGC) DOWNLOAD: $(DOWNLOAD)

help:
	@$(ECHO) "Anlogic FPSoc Software Development Kit "
	@$(ECHO) "== Make variables used in FPSoc SDK =="
	@$(ECHO) "SOC:         Select SoC built in FPSoc SDK, will select board_dr1x90_emulation by default"
	@$(ECHO) "BOARD:       Select SoC's Board built in FPSoc SDK, will select nuclei_fpga_eval by default"
	@$(ECHO) "DOWNLOAD:    Select SoC's download mode, use ocm by default, optional ocm/ddr"
	@$(ECHO) "V:           V=1 verbose make, will print more information, by default V=0"
	@$(ECHO) "== Example Usage =="
	@$(ECHO) "cd $(AL_SDK_ROOT)/solutions/demo/baremetal/helloworld make DOWNLOAD=ocm"

#########################################################################
# Convenience function for verifying option has a boolean value
# $(eval $(call assert_boolean,FOO)) will assert FOO is 0 or 1
define assert_boolean
    $(if $(filter-out 0 1,$($1)),$(error $1 must be boolean))
endef

# Convenience function for verifying options have boolean values
# $(eval $(call assert_booleans,FOO BOO)) will assert FOO and BOO for 0 or 1 values
define assert_booleans
    $(foreach bool,$1,$(eval $(call assert_boolean,$(bool))))
endef

# Convenience function for verifying option has a right string
# $(eval $(call assert_option,option1 option2, FOO)) will assert FOO is string1 or string2
define assert_two_option
    $(if $(filter-out $1 $2, $3),$(error $4 must be $1 or $2))
endef

define assert_three_option
    $(if $(filter-out $1$2$3,$4),$(error$5must be $1 or $2 or $3))
endef

.PHONY: check

check:
	$(call assert_booleans, DDR_2M_MAPPING ENABLE_MMU CODE_READONLY VERBOSE SILENT PFLOAT NOGC)
	$(call assert_option_two_option, 32, 64, $(ARMv8_STATE), ARMv8_STATE)
	$(call assert_two_option,EL1, EL3, $(ARMv8_EL), ARMv8_EL)
	$(call assert_two_option,SECURE, NONSECURE, $(ARMv8_SECURE), ARMv8_SECURE)
	$(call assert_two_option,MASTER, SLAVE, $(ARMv8_CORE), ARMv8_CORE)
	$(call assert_two_option,dr1v90, dr1m90, $(AL_CHIP), AL_CHIP)
	$(call assert_two_option,freertos, rtthread, $(RTOS), RTOS)
	$(call assert_three_option,ocm,ddr,tcm $(DOWNLOAD), DOWNLOAD)
	@$(ECHO) "all parameters have been checked"

define make_target_dir
    @mkdir -p $(dir $@)
endef

#########################################################################
$(ASM_OBJS): $(OBJ_DIR)/%.o: $(AL_SDK_ROOT)/% $(COMMON_PREREQS)
	@$(ECHO) "Compling: " $(notdir $@)
	$(make_target_dir)
	$(CC) $(AL_CFLAGS) -c -o $@ $<

#########################################################################
$(C_OBJS) $(CXX_OBJS): $(OBJ_DIR)/%.o: $(AL_SDK_ROOT)/% $(COMMON_PREREQS)
	@$(ECHO) "Compling: " $(notdir $@)
	$(make_target_dir)
	$(CC) $(AL_CFLAGS) -c -o $@ $<

#########################################################################
$(APP_C_OBJS) $(APP_CPP_OBJS): $(APP_OBJ_DIR)/%.o: $(APP_CUR_DIR)/% $(COMMON_PREREQS)
	@$(ECHO) "Compling: " $(notdir $@)
	$(make_target_dir)
	$(CC) $(AL_CFLAGS) -c -o $@ $<


#########################################################################
#### if target is elf
####

ifeq ($(RTOS), freertos)
filterout_lib = %librtthread
else ifeq ($(RTOS), rtthread)
filterout_lib = %libfreertos
else
filterout_lib = %libfreertos %librtthread
endif


$(TARGET_ELF): bsp make_all_libs $(ALL_OBJS)
	$(eval ld_libs := $(shell find $(LIB_OUTPUT_DIR) $(LIB_PREBUILD_DIR) -name '*.a' 2>/dev/null | \
	  grep -v "$(filterout_lib)" | \
	  sed 's#.*/lib\(.*\)\.a#-l\1#' | tr '\n' ' '))
	$(CC) -Wl,--start-group -Wl,--whole-archive $(ALL_OBJS) $(ld_libs) $(LD_LIBS) -z noexecstack -Wl,--no-whole-archive -lgcc -lg -lc -lm -lstdc++ -u _write -Wl,--end-group -L$(LIB_OUTPUT_DIR) -L$(LIB_PREBUILD_DIR) $(LIB_OPT) \
	-T$(LINKER_SCRIPT) -nostartfiles -Wl,-M,-Map=$(TARGET_PATH)/$(TARGET).map \
    $(AL_CFLAGS) $(LDFLAGS) $(GC_LDFLAGS) $(NEWLIB_LDFLAGS) --specs=nosys.specs -Wl,--build-id=none -o $@
	$(OBJCOPY) $@ -O binary $(TARGET_PATH)/$(TARGET).bin
	$(SIZE) $@


########################################################################
# get bsp library path: bps folder name is different between
# sdk workspace and embedded workspace

.PHONY: bsp
bsp:
ifneq ($(BSP_DIR),)
	@$(MAKE) -C $(BSP_DIR) lib
endif

.PHONY: bsp_clean
bsp_clean:
ifneq ($(BSP_DIR),)
	@$(MAKE) -C $(BSP_DIR) lib.do.clean
endif

#########################################################################
# 3rdparty, libnpuruntime may not include in sdk workspace
#########################################################################
# LIBS_DIR = $(patsubst %/Makefile, %, $(wildcard $(AL_SDK_ROOT)/3rdparty/lib/*/Makefile $(BSP_DIR)/lib/*/Makefile))

LIBS_DIR += $(patsubst %/Makefile, %, $(wildcard $(AL_SDK_ROOT)/3rdparty/lib/FATFS/Makefile))
LIBS_DIR += $(patsubst %/Makefile, %, $(wildcard $(AL_SDK_ROOT)/3rdparty/lib/jpu_driver/Makefile))
LIBS_DIR += $(patsubst %/Makefile, %, $(wildcard $(AL_SDK_ROOT)/3rdparty/lib/libmetal/Makefile))
LIBS_DIR += $(patsubst %/Makefile, %, $(wildcard $(AL_SDK_ROOT)/3rdparty/lib/open-amp/Makefile))
LIBS_DIR += $(patsubst %/Makefile, %, $(wildcard $(AL_SDK_ROOT)/3rdparty/lwip-2.1.3/Makefile))

ifeq ($(AL_CHIP), dr1v90)
LIBS_DIR += $(patsubst %/Makefile, %, $(wildcard $(AL_SDK_ROOT)/3rdparty/lib/NMSIS/Makefile))
endif

ifneq ($(PLAT_DIR),)
LIBS_DIR += $(PLAT_DIR)
LIBS_DIR += $(patsubst %/Makefile, %, $(wildcard $(PLAT_DIR)/src/ddr_demo/Makefile))

endif


ifeq ($(RTOS), freertos)
    LIBS_DIR += $(patsubst %/Makefile, %, $(wildcard $(AL_SDK_ROOT)/3rdparty/os/FreeRTOS/Makefile))
else ifeq ($(RTOS), rtthread)
	LIBS_DIR += $(patsubst %/Makefile, %, $(wildcard $(AL_SDK_ROOT)/3rdparty/os/RT-Thread/Makefile))
endif

#lib_tinyusb
ifeq ($(USBLIB), tinyusb)
    LIBS_DIR += $(patsubst %/Makefile, %, $(wildcard $(AL_SDK_ROOT)/3rdparty/tinyusb/Makefile))
else ifeq ($(USBLIB), cherryusb)
    LIBS_DIR += $(patsubst %/Makefile, %, $(wildcard $(AL_SDK_ROOT)/3rdparty/lib/CherryUSB/Makefile))
endif


.PHONY: make_all_libs
make_all_libs: $(addsuffix /make.lib, $(LIBS_DIR))

.PHONY:
%/make.lib:
	$(MAKE) -C $(patsubst %/make.lib,%,$@) lib

.PHONY:
lib.do.clean:
	$(RM) -rf $(OBJ_DIR) $(LIB_OUTPUT_DIR)/lib$(LIBNAME).a

#########################################################################
#### if target is lib
####

lib: $(LIB_OUTPUT_DIR)/lib$(LIBNAME).a
$(LIB_OUTPUT_DIR)/lib$(LIBNAME).a: $(ALL_OBJS) $(SUB_LD_LIBS)
	@mkdir -p $(LIB_OUTPUT_DIR)
	$(AR) $(ARFLAGS) $@ $(C_OBJS) $(ASM_OBJS)

#########################################################################
dasm: $(TARGET_ELF)
	$(OBJDUMP) -S -d --all-headers --demangle --line-numbers --wide $< > $(TARGET_PATH)/$(TARGET).dump
	$(OBJDUMP) -d $< > $(TARGET_PATH)/$(TARGET).dasm
	$(OBJCOPY) $< -O ihex $(TARGET_PATH)/$(TARGET).hex
	$(OBJCOPY) $< -O verilog $(TARGET_PATH)/$(TARGET).verilog
	$(OBJCOPY) $< -O binary $(TARGET_PATH)/$(TARGET).bin


#########################################################################
hpf:
	@$(ECHO) "Update Platform header"
	$(Q)unzip -o $(HPF_PATH) -d $(AL_SDK_ROOT)/hpf_tmp
	$(Q)cp $(AL_SDK_ROOT)/hpf_tmp/HPFs/soc_plat.h $(AL_PLAT_DIR)/inc
	$(Q)cp $(AL_SDK_ROOT)/hpf_tmp/HPFs/soc_plat.c $(AL_PLAT_DIR)/src
	$(Q)export LD_LIBRARY_PATH=$(AL_SDK_ROOT)/tools/ci && export BSP_RESOURCE_PATH=$(AL_SDK_ROOT)/ && $(ASCT_TOOL) dr1x90_tool update_platform_header_from_hpf -plat_h $(PLAT_H_PATH) -hpf $(HPF_PATH)
	$(Q)rm -r $(AL_SDK_ROOT)/hpf_tmp/
	@$(ECHO) "Platform header updated successfully"

#########################################################################
clean:
	@$(ECHO) "Clean all build objects"
	$(RM) -rf $(CLEAN_OBJS)
# vim: syntax=make

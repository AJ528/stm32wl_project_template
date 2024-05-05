# while it is tempting to adjust this makefile so you can have a debug and release target
# I have been unable to find any elegant way to accomplish this.

# set debug to 0 or 1
# adjust optimization flag accordingly below
debug = 1

# set fpu to soft, softfp or hard
# soft is also for when you aren't using the FPU
# soft:   software fpu, soft abi
# softfp: hardware fpu, soft abi
# hard:   harwdare fpu, hard abi
fpu = soft
# IMPORTANT: none of the STM32WL microcontrollers have a hardware FPU,
# so this setting should always be set to "soft".

# names of directories for compiled objects
BIN_DIR = bin
OBJ_DIR = obj
DEP_DIR = dep

# name of the output image
TARGET_NAME := output
TARGET_ELF := $(BIN_DIR)/$(TARGET_NAME).elf
TARGET_BIN := $(BIN_DIR)/$(TARGET_NAME).bin

# locations of directories containing source files.
# these locations should be specified relative to the makefile location.
SRC_DIRS = \
	src \
	drivers \
	drivers/utilities \
	drivers/stm32wlxx_low_level

# locations of directories containing header files.
# these locations should be specified relative to the makefile location.
INC_DIRS = \
	inc \
	drivers/inc \
	drivers/CMSIS_inc \
	drivers/device_inc \
	drivers/stm32wlxx_ll_inc

# predefined macros
DEFINES = 		\
	STM32WL 	\
	STM32WL55xx	\
	CORE_CM4

# if you are going to use the low level drivers, define this value to expose init structures
DEFINES += USE_FULL_LL_DRIVER

# sets OPTIMIZE_FLAGS based on debug above
ifeq ($(debug), 1)
	DEFINES += DEBUG
	OPTIMIZE_FLAGS = -ggdb3 -Og
else
# change optimization options to whatever suits you
	DEFINES += RELEASE
	OPTIMIZE_FLAGS = -O2
endif


# sets FLOAT_FLAGS based on fpu above
ifeq ($(fpu), softfp)
	FLOAT_FLAGS = -mfloat-abi=softfp -mfpu=fpv5-sp-d16
else ifeq ($(fpu), hard)
	FLOAT_FLAGS = -mfloat-abi=hard -mfpu=fpv5-sp-d16
else
	FLOAT_FLAGS = -mfloat-abi=soft
endif

# creates the list of define flags to pass to the compiler
DEFINE_FLAGS := $(addprefix -D,$(DEFINES))
# creates the list of include flags to pass to the compiler
INC_FLAGS := $(addprefix -I,$(INC_DIRS))
# adds the source directories to Make's search path
VPATH = $(SRC_DIRS)

# compiler you want to use
CC = arm-none-eabi-gcc
# objcopy you want to use
OBJCOPY =  arm-none-eabi-objcopy

# cpu target and instruction set
COMMON_FLAGS = -mcpu=cortex-m4
# instruction set (all ARM Cortex-M only support thumb instruction sets)
COMMON_FLAGS += -mthumb
# floating point flags
COMMON_FLAGS += $(FLOAT_FLAGS)
# define flags
COMMON_FLAGS += $(DEFINE_FLAGS)
# use no system libraries
COMMON_FLAGS += --specs=nosys.specs
COMMON_FLAGS += -nostdlib
# use no builtin functions 
# this prevent gcc from optimizing printf() if you decide to roll your own
COMMON_FLAGS += -fno-builtin

# compiler, assembler, and linker flags all start with the same flags
CFLAGS = $(COMMON_FLAGS)
ASFLAGS = $(COMMON_FLAGS)
LDFLAGS = $(COMMON_FLAGS)

# add on compiler-specific flags
# optimization flags
CFLAGS += $(OPTIMIZE_FLAGS)
# C standard to compile against. gnu17 means use C17 standard and add GNU extensions
CFLAGS += -std=gnu17
# put functions and data into individual sections
CFLAGS += -ffunction-sections -fdata-sections
# enable all warning messages from the compiler
CFLAGS += -Wall
# enable some extra warnings from the compiler
CFLAGS += -Wextra

# add on compiler-specific flags
# optimization flags
ASFLAGS += $(OPTIMIZE_FLAGS)

# add on linker-specific flags
# specify the linker script to use
LDFLAGS += -T"STM32WL_FLASH.ld"
# if any system libraries are used, include their code with the executable by statically linking it
LDFLAGS += -static
# note: if you want to use the "-Wl" to pass options to the linker, there must be NO SPACES
# remove empty sections only if not for debug
LDFLAGS += -Wl,--gc-sections
# according to the datasheet, the flash page size is 0x800 bytes
LDFLAGS += -Wl,-z,max-page-size=0x800
# generate a map file about the output
LDFLAGS += -Xlinker -Map=$(OBJ_DIR)/$(TARGET_NAME).map
# link in libgcc to handle some low level arithmetic operations
LDFLAGS += -lgcc


# creates the list of .c source files by looking for every .c file in the source directories
CSRCS := $(foreach x, $(SRC_DIRS), $(wildcard $(addprefix $(x)/*,.c)))
# creates the list of .S (uppercase 'S') source files by looking for every .S file in the source directories
SSRCS := $(foreach x, $(SRC_DIRS), $(wildcard $(addprefix $(x)/*,.S)))
# creates the list of .s (lowercase 's') source files by looking for every .s file in the source directories
sSRCS := $(foreach x, $(SRC_DIRS), $(wildcard $(addprefix $(x)/*,.s)))

# creates a list of all .c, .S, and .s source files in one place
OBJ_SRCS := $(CSRCS) $(SSRCS) $(sSRCS)
# creates a list of object files by taking every source file, removing the file extension
# and replacing it with an "o"
OBJS := $(addprefix $(OBJ_DIR)/, $(addsuffix .o, $(notdir $(basename $(OBJ_SRCS)))))

# creates a list of all source files that need a dependency file
DEP_SRCS := $(CSRCS) $(SSRCS)
# creates a list of dependecy files by taking every .c and .S source file, removing the file extension
# and replacing it with a "d"
DEPS := $(addprefix $(DEP_DIR)/, $(addsuffix .d, $(notdir $(basename $(DEP_SRCS)))))


# rule for linking the overall image from object files. The prerequisites are the object
# files and the existence of the binary directory. Listing pdebug as a prerequisite means
# it gets called everytime this rule is ran.
$(TARGET_ELF): $(OBJS) pdebug | $(BIN_DIR)
	$(CC) -o $@ $(OBJS) $(LDFLAGS)

# rule for turning the .elf program into a binary.The prerequisites are the ELF file
# and the existence of the binary directory. 
$(TARGET_BIN): $(TARGET_ELF) | $(BIN_DIR)
	$(OBJCOPY) -O binary $(TARGET_ELF) $@

# rule to make object files from .c source files. The recipe to build the .o file is specified here. 
# the prerequisites listed here do not include the header (.h) files needed to compile each object file
# header file prerequisites are added by the dependency (.d) files.
$(OBJ_DIR)/%.o: %.c | $(OBJ_DIR)
	$(CC) $(CFLAGS) $(INC_FLAGS) -c $< -o $@

# rule to make the dependency files for .c source files. There is one dependency file per .c file.
# the dependency file lists all the prerequisite headers for each object (.o) file.
$(DEP_DIR)/%.d: %.c | $(DEP_DIR)
	@echo DEPEND: $(CC) -MM $(CFLAGS) $<
# The purpose of the sed command is to translate (for example):
# main.o : main.c defs.h
# into:
# main.o main.d : main.c defs.h
# "$$$$" turns into the process id, which is a quick way to make a unique file extension
	@set -e; rm -f $@; \
	$(CC) -MM $(CFLAGS) $(INC_FLAGS) $< > $@.$$$$; \
	sed 's,\($*\.o\)[ :]*,$(OBJ_DIR)/\1 $@ : ,g' < $@.$$$$ > $@; \
	rm -f $@.$$$$

# rule to make object files from .S (uppercase 'S') source files. The recipe to build the .o file is specified here.
# the prerequisites listed here do not include the header (.h) files needed to compile each object file
# header file prerequisites are added by the dependency (.d) files.
$(OBJ_DIR)/%.o: %.S | $(OBJ_DIR)
	$(CC) $(ASFLAGS) $(INC_FLAGS) -c $< -o $@

# rule to make the dependency files for .S source files. There is one dependency file per .S file.
# the dependency file lists all the prerequisite headers for each object (.o) file.
$(DEP_DIR)/%.d: %.S | $(DEP_DIR)
	@echo DEPEND: $(CC) -MM $(CFLAGS) $<
# The purpose of the sed command is to translate (for example):
# main.o : main.S defs.h
# into:
# main.o main.d : main.S defs.h
	@set -e; rm -f $@; \
	$(CC) -MM $(ASFLAGS) $(INC_FLAGS) $< > $@.$$$$; \
	sed 's,\($*\.o\)[ :]*,$(OBJ_DIR)/\1 $@ : ,g' < $@.$$$$ > $@; \
	rm -f $@.$$$$

# rule to make object files from .s (lowercase 's') source files 
# the prerequisites listed here do not include the header (.h) files needed to compile each object file
# header file prerequisites are added by the dependency (.d) files.
$(OBJ_DIR)/%.o: %.s | $(OBJ_DIR)
	$(CC) $(ASFLAGS) $(INC_FLAGS) -c $< -o $@

# no rule needed to make depdency files for .s source files
# .s (lowercase 's') cannot have "#include" or other c preprocessor stuff

# rule to make the build directories if they do not already exist
$(BIN_DIR) $(OBJ_DIR) $(DEP_DIR):
	mkdir -p $@


# .PHONY targets will be run every time they are called.
# any special recipes you want to run by name should be a phony target.
.PHONY: clean pdebug debug

debug: $(TARGET_ELF)
	./debug.sh

# recipe to print some debug information
pdebug:
	@echo "Source Directories = " $(SRC_DIRS)
	@echo "Include Directories = " $(INC_DIRS)

# recipe to remove the build directories and clean up the workspace
clean:
	rm -r $(BIN_DIR) $(OBJ_DIR) $(DEP_DIR)

# if we are not cleaning the workspace, include the dependency files.
# the rules in included files are combined with pre-existing rules to
# fully define the prerequisites for each target output.
ifneq ($(MAKECMDGOALS),clean)
-include $(DEPS)
endif

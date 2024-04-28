/* Entry Point */
/* 
 technically, I'm not sure if an entry point is necessary since this is an embedded system
 and the entry point is hardcoded to be the reset vector. However, if we want to compile an
 ELF, an entry point is needed
*/
ENTRY(Reset_Handler)

/* Highest address of the user mode stack */
_estack = ORIGIN(RAM) + LENGTH(RAM); /* end of RAM */

_Min_Heap_Size = 0x000; /* required amount of heap  */
_Min_Stack_Size = 0x400; /* required amount of stack */

/* Memories definition */
/* this information is given in the datasheet or other documentation */
/* if you are using multiple cores, you will want to divide up the flash
   and ram so each core gets an exclusive slice of ram and flash. */
MEMORY
{
  RAM    (xrw)   : ORIGIN = 0x20000000, LENGTH = 0x00008000
  RAM2   (xrw)   : ORIGIN = 0x20008000, LENGTH = 0x00008000
  FLASH   (rx)   : ORIGIN = 0x08000000, LENGTH = 0x00040000
}

/* Sections */
SECTIONS
{
  /* Interrupt Service Routines must be the first section placed in flash memory.
     This is because the interrupt vector table is located at address 0x00 by default.
     (technically, this table can be moved once the MCU is running) */
  .isr_vector :
  {
    . = ALIGN(4);
    KEEP(*(.isr_vector)) /* interrupt table */
    . = ALIGN(4);
  } >FLASH

  /* normal program code instructions is compiled into ".text" sections, and these
     sections should also be placed in flash memory */
  .text :
  {
    . = ALIGN(4);
    *(.text)           /* .text sections (code) */
    *(.text*)          /* .text* sections (code) */

    . = ALIGN(4);
    _etext = .;        /* define a global symbol at end of code */
  } >FLASH

  /* variables defined as constant and other unchanging data is compiled into
     ".rodata" sections, and these should also be placed in flash memory */
  .rodata :
  {
    . = ALIGN(4);
    *(.rodata)         /* .rodata sections (constants, strings, etc.) */
    *(.rodata*)        /* .rodata* sections (constants, strings, etc.) */
    . = ALIGN(4);
  } >FLASH

  /*
   based on my research, I believe .ARM.extab* and .ARM.exidx* sections are only 
   generated if code is compiled with the "-fexceptions" flag. This will keep a 
   record of your stack trace in case you want to use it to unwind the stack or
   print it because some exception failed (C doesn't really do exceptions, at 
   least not natively)
  */

  .ARM.extab :
  {
    . = ALIGN(4);
    *(.ARM.extab* .gnu.linkonce.armextab.*)
    . = ALIGN(4);
  } >FLASH
  
  .ARM :
  {
    . = ALIGN(4);
    __exidx_start = .;
    *(.ARM.exidx*)
    __exidx_end = .;
    . = ALIGN(4);
  } >FLASH


  /* Used by the startup function to initialize data */
  _sidata = LOADADDR(.data);

  /* 
   initialized global and static objects are put in the .data section.
   functions to be run in RAM are also put in the .data section.
  */
  .data :
  {
    . = ALIGN(4);
    _sdata = .;        /* create a global symbol at data start */
    *(.data)           /* .data sections */
    *(.data*)          /* .data* sections */
    *(.RamFunc)        /* .RamFunc sections */
    *(.RamFunc*)       /* .RamFunc* sections */

    . = ALIGN(4);
    _edata = .;        /* define a global symbol at data end */

/* 
 ">RAM AT> FLASH" means the data belongs in RAM but is stored in FLASH.
 the .data section is for initialized objects meant for RAM, but they cannot
 exist in RAM until the MCU is powered up. After power-up, but before calling
 main(), the objects are copied from FLASH to their correct location in RAM.
*/
  } >RAM AT> FLASH

  /* Uninitialized data section into "RAM" type memory */
/* 
 unitialized (and zero-initialized) global and static objects are put in the .bss section.
 the .bss section should be "stored" in RAM, but since RAM is volatile and these variables
 are 0, that just means we reserve space for these variables in RAM, and then at startup
 we initialize the data in the those reserved spaces to 0.
*/
  .bss :
  {
    . = ALIGN(4);
    /* This is used by the startup in order to initialize the .bss section */
    _sbss = .;         /* define a global symbol at bss start */
    *(.bss)
    *(.bss*)

    . = ALIGN(4);
    _ebss = .;         /* define a global symbol at bss end */
  } >RAM

  /* stack section, used to check that there is enough RAM left */
  .stack :
  {
    . = ALIGN(8);
    . = . + _Min_Heap_Size;
    . = . + _Min_Stack_Size;
    . = ALIGN(8);
  } >RAM

/* 
  contains metadata about the compiled object. 
  Things like CPU architecture, CPU name, etc...
*/
  .ARM.attributes 0 : { *(.ARM.attributes) }
}

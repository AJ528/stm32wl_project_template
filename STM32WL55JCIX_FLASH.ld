/*
******************************************************************************
**
**  File        : LinkerScript.ld
**
**  Author      : STM32CubeIDE
**
**  Abstract    : Linker script for STM32WL55xC Device
**                      256Kbytes FLASH
**                      64Kbytes RAM
**
**                Set heap size, stack size and stack location according
**                to application requirements.
**
**                Set memory bank area and size if external memory is used.
**
**  Target      : STMicroelectronics STM32
**
**  Distribution: The file is distributed as is without any warranty
**                of any kind.
**
*****************************************************************************
** @attention
**
** Copyright (c) 2024 STMicroelectronics.
** All rights reserved.
**
** This software is licensed under terms that can be found in the LICENSE file
** in the root directory of this software component.
** If no LICENSE file comes with this software, it is provided AS-IS.
**
*****************************************************************************
*/

/* Entry Point */
/* 
 technically, I'm not sure if an entry point is necessary since this is an embedded system
 and the entry point is hardcoded to be the reset vector. However, if we want to compile an
 ELF, an entry point is needed
*/
ENTRY(Reset_Handler)

/* Highest address of the user mode stack */
_estack = ORIGIN(RAM) + LENGTH(RAM); /* end of "RAM" Ram type memory */

_Min_Heap_Size = 0x000; /* required amount of heap  */

_Min_Stack_Size = 0x400; /* required amount of stack */

/* Memories definition */
MEMORY
{
  RAM    (xrw)   : ORIGIN = 0x20000000, LENGTH = 64K
  RAM2   (xrw)   : ORIGIN = 0x10000000, LENGTH = 32K
  FLASH   (rx)   : ORIGIN = 0x08000000, LENGTH = 256K
}

/* Sections */
SECTIONS
{
  /* The startup code into "FLASH" Rom type memory */
  .isr_vector :
  {
    . = ALIGN(4);
    KEEP(*(.isr_vector)) /* Startup code */
    . = ALIGN(4);
  } >FLASH

  /* The program code and other data into "FLASH" Rom type memory */
  .text :
  {
    . = ALIGN(4);
    *(.text)           /* .text sections (code) */
    *(.text*)          /* .text* sections (code) */

    . = ALIGN(4);
    _etext = .;        /* define a global symbols at end of code */
  } >FLASH

  /* Constant data into "FLASH" Rom type memory */
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




  /* Used by the startup to initialize data */
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

  /* Uninitialized data section into "RAM" Ram type memory */
/* 
 unitialized (and zero-initialized) global and static objects are put in the .bss section.
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

  /* User_heap_stack section, used to check that there is enough "RAM" Ram  type memory left */
  ._user_heap_stack :
  {
    . = ALIGN(8);
    . = . + _Min_Heap_Size;
    . = . + _Min_Stack_Size;
    . = ALIGN(8);
  } >RAM

  .ARM.attributes 0 : { *(.ARM.attributes) }
}

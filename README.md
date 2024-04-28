# stm32_project_template

initially, my goal for this repository was to make a project template for any STM32WL microcontroller project. Unfortunately, each microcontroller in the STM32WL family has a different list of processor cores (CM0 vs CM4, single vs dual core), interrupts, and memory size/layout. This means that each microcontroller needs a unique linker script, startup file, and device header.

I could try to get fancy and set up compiler options or predefined symbols to automatically pick the correct files based on some user input, but that would make this template far more complicated than it needs to be, and the reason I originally made this was because the project templates provided by ST were confusing and seemed overly complicated to me.

So, instead of complicating the project, here are the files you need to change in order to make this template work with other STM32WL microcontrollers:
1. Update the linker script so that the `LENGTH` of each piece of memory is accurate. Across the STM32WL family, the starting address for each piece of memory doesn't change*.
2. Swap the startup_stm32wl*.s assembly file for the one that matches your microcontroller. The list of startup assembly files can be found [here](https://github.com/STMicroelectronics/cmsis_device_wl/tree/f005e572c943bd4adf1efcc2fdc4d2f55bd6544c/Source/Templates/gcc). The biggest difference between all these startup assembly files is the interrupt vectors being defined.
3. Swap the device header `stm32wl55xx.h` in `drivers/device_inc` with the correct device header file. The list of device header files can be found [here](https://github.com/STMicroelectronics/cmsis_device_wl/tree/f005e572c943bd4adf1efcc2fdc4d2f55bd6544c/Include). Note: you don't actually include that file in any of your source files. Include `stm32wlxx.h` and that header will automatically include the correct device header file for you. Technically, you could keep all the device header files in `device_inc` all the time, but that feels messy to me, so I don't.
4. Update the list of predefined macros in the `Makefile`. Change `STM32WL55xx` to one of the options listed in drivers/device_inc/stm32wlxx.h:59 and change `CORE_CM4`** to `CORE_CM0PLUS` if compiling for that processor.

   \* while the starting address doesn't change (i.e. flash memory will always begin at 0x08000000), the origin address for the memory sections may not always be the memory's starting address. If you are booting dual cores, you will probably have 2 linker files and offset the origin in one of them so each core gets its own slice of memory.

   \** I don't think defining `CORE_M4` actually does anything...the code's logic is more "if `CORE_CM0PLUS` is defined then do special stuff, else do standard (CM4) stuff". But it certainly doesn't hurt to have it defined.
   

# stm32wl_project_template
A well-annotated template to start developing projects on the STM32WL series of microcontrollers

## Status
Does everything I need it to. Will fix bugs as I come across them.

## Requirements
To run this code, you will need the following packages on Linux:
- `make`
- `gcc-arm-none-eabi`
- `gdb-multiarch`
- [stlink](https://github.com/stlink-org/stlink)
- optionally `vscodium` with the [Cortex-Debug extension](https://github.com/Marus/cortex-debug)

## What is this?
This repository serves to be a good template to start developing an embedded project on the STM32WL series of microcontrollers. As it comes, the code will compile a `Hello World!` program to run on the STM32WL55XX microcontroller. Aside from the License files and stm32wlxx low level source files and header files (only a few are used), every file in this repository serves a purpose and is necessary.

## Details
Initially, my goal for this repository was to make a project template for any STM32WL microcontroller project. Unfortunately, each microcontroller in the STM32WL family has a different list of processor cores (CM0 vs CM4, single vs dual core), interrupts, and memory size/layout. This means that each microcontroller needs a unique linker script, startup file, and device header file.

Default options/assumptions used when creating this template:
1. The code is being compiled with the `arm-none-eabi-gcc` compiler. GCC-specific header files are used, and header files for other compilers were removed to keep the template small and simple. If you need portability, check out the [official STM32WL repo](https://github.com/STMicroelectronics/STM32CubeWL/tree/main).
2. The code being compiled is written in C and not C++.
3. The default options will compile code for the Cortex-M4 core of an STM32WL55XX microcontroller.
4. The STM32WL55XX is a dual-core microcontroller, but this template assumes the Cortex-M4 core is the only core being used, so the linker script allocates all flash and RAM to the one core. To make this work in a dual-core setup, I believe you need 2 individual projects and need to configure the 2 linker scripts so each core gets its own slice of memory.

I could try to get fancy and set up compiler options or predefined symbols to automatically pick the correct files based on some user input, but that would make this template more complicated than it needs to be, and the reason I originally made this was because the project templates provided by ST were confusing and seemed overly complicated to me.

T

So, instead of complicating the project, here are the files you need to change in order to make this template work with other STM32WL microcontrollers:
1. Update the linker script so that the `LENGTH` of each piece of memory is accurate. Across the STM32WL family, the starting address for each piece of memory doesn't change*.
2. Swap the startup_stm32wl*.s assembly file for the one that matches your microcontroller. The list of startup assembly files can be found [here](https://github.com/STMicroelectronics/cmsis_device_wl/tree/f005e572c943bd4adf1efcc2fdc4d2f55bd6544c/Source/Templates/gcc). The biggest difference between all these startup assembly files is the interrupt vectors being defined.
3. Swap the device header `stm32wl55xx.h` in `drivers/device_inc` with the correct device header file. The list of device header files can be found [here](https://github.com/STMicroelectronics/cmsis_device_wl/tree/f005e572c943bd4adf1efcc2fdc4d2f55bd6544c/Include). Note: you don't actually include that file in any of your source files. Include `stm32wlxx.h` and that header will automatically include the correct device header file for you. Technically, you could keep all the device header files in `device_inc` all the time, but that feels messy to me, so I don't.
4. Update the list of predefined macros in the `Makefile`, and change `STM32WL55xx` to one of the options listed on line 59 of [drivers/device_inc/stm32wlxx.h](https://github.com/AJ528/stm32wl_project_template/blob/32b9338611c9ce3aab69718e1f812dcbba01d56d/drivers/device_inc/stm32wlxx.h#L59). Also, if compiling for the Cortex-M0+ core, change `CORE_CM4`** to `CORE_CM0PLUS`and change the `cpu target` to `cortex-m0plus` in the `COMMON_FLAGS` in the Makefile.
5. If you are using VSCode/VSCodium + Cortex-Debug extension to debug your project, replace the `STM32WL5x_CM4.svd` file with an svd file that matches your microcontroller and update the "svdFile" name in `launch.json`. This lets you read the MCU peripheral registers from the debugger.

   \* while the starting address doesn't change (i.e. flash memory will always begin at 0x08000000), the origin address for the memory sections may not always be the memory's starting address. If you are booting dual cores, you will probably have 2 linker files and offset the origin in one of them so each core gets its own slice of memory.

   \** I don't think defining `CORE_M4` actually does anything...the code's logic is more "if `CORE_CM0PLUS` is defined then do special stuff, else do standard (CM4) stuff". But it certainly doesn't hurt to have it defined.
   

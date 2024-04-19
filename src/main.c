#include <stdint.h>
#include "printf.h"

int main(void)
{
    volatile uint8_t i;
    volatile uint8_t j = 0;
    i = 0;

    i = i >> 1;

    i = i + j;

    printf_("Hello world!\n");

    return (i);
}
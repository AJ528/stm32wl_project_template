
#include "mprintf.h"
#include "stm32wlxx_ll_bus.h"
#include "stm32wlxx_ll_rcc.h"
#include "stm32wlxx_ll_gpio.h"
#include "stm32wlxx_ll_lpuart.h"


#include <stdbool.h>
#include <stdint.h>


void UART_init(void)
{
    // set the LPUART clock source to the peripheral clock
    LL_RCC_SetLPUARTClockSource(LL_RCC_LPUART1_CLKSOURCE_PCLK1);

    // enable clocks for GPIOA and LPUART
    LL_AHB2_GRP1_EnableClock(LL_AHB2_GRP1_PERIPH_GPIOA);
    LL_APB1_GRP2_EnableClock(LL_APB1_GRP2_PERIPH_LPUART1);

    LL_GPIO_InitTypeDef GPIO_InitStruct = {
        .Pin = LL_GPIO_PIN_3 | LL_GPIO_PIN_2,
        .Mode = LL_GPIO_MODE_ALTERNATE,
        .Speed = LL_GPIO_SPEED_FREQ_HIGH,
        .OutputType = LL_GPIO_OUTPUT_PUSHPULL,
        .Pull = LL_GPIO_PULL_NO,
        .Alternate = LL_GPIO_AF_8
    };
    LL_GPIO_Init(GPIOA, &GPIO_InitStruct);

    LL_LPUART_InitTypeDef LPUART_InitStruct = {
        .PrescalerValue = LL_LPUART_PRESCALER_DIV1,
        .BaudRate = 115200,
        .DataWidth = LL_LPUART_DATAWIDTH_8B,
        .StopBits = LL_LPUART_STOPBITS_1,
        .Parity = LL_LPUART_PARITY_NONE,
        .TransferDirection = LL_LPUART_DIRECTION_TX_RX,
        .HardwareFlowControl = LL_LPUART_HWCONTROL_NONE
    };
    LL_LPUART_Init(LPUART1, &LPUART_InitStruct);
    LL_LPUART_Enable(LPUART1);

    // wait for the LPUART module to send an idle frame and finish initialization
    while(!(LL_LPUART_IsActiveFlag_TEACK(LPUART1)) || !(LL_LPUART_IsActiveFlag_REACK(LPUART1)));
}

int32_t putchar_(char c)
{
    // loop while the LPUART_TDR register is full
    while(LL_LPUART_IsActiveFlag_TXE_TXFNF(LPUART1) != 1);
    // once the LPUART_TDR register is empty, fill it with char c
    LL_LPUART_TransmitData8(LPUART1, (uint8_t)c);
    return (c);
}

int main(void)
{
    UART_init();

    printf_("Hello world!\n");

    return (0);
}

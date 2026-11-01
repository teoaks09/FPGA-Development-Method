/* Hardware access layer: the only platform-specific part of the driver. */
#ifndef HAL_H
#define HAL_H
#include <stdint.h>

uint32_t hal_read32(uintptr_t address);
void hal_write32(uintptr_t address, uint32_t value);
void hal_sleep_us(uint32_t microseconds);

#endif

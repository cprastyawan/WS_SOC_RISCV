#include <stdint.h>

void spi_init();
void flash_id(uint8_t* id);
void flash_page_program(uint32_t addr, const uint8_t *buf, int len);
void flash_read_data(uint32_t addr, uint8_t *buf, int len);
void flash_sector_erase(uint32_t addr);
void flash_read_fast(uint32_t addr, uint8_t *buf, int len);
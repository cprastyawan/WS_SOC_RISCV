#include "w25.h"

#define CMD_WRITE_ENABLE   0x06
#define CMD_READ_SR1       0x05
#define CMD_PAGE_PROGRAM   0x02
#define CMD_READ_DATA      0x03
#define CMD_SECTOR_ERASE   0x20

#define SPI_BASE   0x44A00000  // AXI Lite base address

#define SPI_CR     (*(volatile uint32_t *)(SPI_BASE + 0x60))
#define SPI_SR     (*(volatile uint32_t *)(SPI_BASE + 0x64))
#define SPI_DTR    (*(volatile uint32_t *)(SPI_BASE + 0x68))
#define SPI_DRR    (*(volatile uint32_t *)(SPI_BASE + 0x6C))
#define SPI_SSR    (*(volatile uint32_t *)(SPI_BASE + 0x70))

#define CMD_RDID   0x9F

static inline void spi_wait_tx_ready() {
    while (SPI_SR & (1 << 3)); // TX_FULL bit
}

static inline void spi_wait_rx_ready() {
    while (SPI_SR & 0x01); // RX_EMPTY bit
}

static uint8_t spi_transfer(uint8_t tx) {
    spi_wait_tx_ready();
    SPI_DTR = tx;
    //SPI_CR |= (1 << 0);
    spi_wait_rx_ready();
    return (uint8_t)SPI_DRR;
}

static void spi_select_slave(uint8_t slave) {
    SPI_SSR &= ~(1 << slave);

    return;
}

static void spi_deselect_slave(uint8_t slave) {
    SPI_SSR |= (1 << slave);

    return;
}

// Send 1 command (no address, no data)
static void spi_send_cmd(uint8_t cmd) {
    spi_select_slave(0);
    spi_transfer(cmd);
    spi_deselect_slave(0);
}

// Read Status Register 1
static uint8_t flash_read_status() {
    uint8_t status;
    spi_select_slave(0);
    spi_transfer(CMD_READ_SR1);
    status = spi_transfer(0x00);
    spi_deselect_slave(0);

    return status;
}

void spi_init() {
    SPI_CR = (1 << 5) | (1 << 6);

    // Reset + Master + Enable + Manual SS
    SPI_CR = (1 << 1) | (1 << 2) | (1 << 7);
}

// Wait until WIP bit clears
void flash_wait_ready() {
    while (flash_read_status() & 0x01);

    return;
}

void flash_id(uint8_t* id) {
    spi_select_slave(0);

    spi_transfer(CMD_RDID);

    id[0] = spi_transfer(0);
    id[1] = spi_transfer(0);
    id[2] = spi_transfer(0);

    spi_deselect_slave(0);

    return;
}

void flash_page_program(uint32_t addr, const uint8_t *buf, int len) {
    spi_send_cmd(CMD_WRITE_ENABLE);

    spi_select_slave(0);
    spi_transfer(CMD_PAGE_PROGRAM);
    spi_transfer((addr >> 16) & 0xFF);
    spi_transfer((addr >> 8) & 0xFF);
    spi_transfer(addr & 0xFF);

    for (int i = 0; i < len; i++) {
        spi_transfer(buf[i]);
    }
    spi_deselect_slave(0);

    flash_wait_ready();

    return;
}

void flash_read_data(uint32_t addr, uint8_t *buf, int len) {
    spi_select_slave(0);
    spi_transfer(CMD_READ_DATA);
    spi_transfer((addr >> 16) & 0xFF);
    spi_transfer((addr >> 8) & 0xFF);
    spi_transfer(addr & 0xFF);

    for (int i = 0; i < len; i++) {
        buf[i] = spi_transfer(0x00);
    }

    spi_deselect_slave(0);

    return;
}

void flash_sector_erase(uint32_t addr) {
    spi_send_cmd(CMD_WRITE_ENABLE);

    spi_select_slave(0);
    spi_transfer(CMD_SECTOR_ERASE);
    spi_transfer((addr >> 16) & 0xFF);
    spi_transfer((addr >> 8) & 0xFF);
    spi_transfer(addr & 0xFF);
    spi_deselect_slave(0);

    flash_wait_ready();

    return;
}

void flash_read_fast(uint32_t addr, uint8_t *buf, int len) {
    spi_select_slave(0);

    spi_transfer(0x0B);  // Fast Read command

    spi_transfer((addr >> 16) & 0xFF);  // 24-bit address
    spi_transfer((addr >> 8) & 0xFF);
    spi_transfer(addr & 0xFF);

    spi_transfer(0x00);  // dummy byte (8 cycles)

    for (int i = 0; i < len; i++) {
        buf[i] = spi_transfer(0x00);
    }

    spi_deselect_slave(0);
}
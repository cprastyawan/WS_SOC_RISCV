#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include "w25.h"
#include "program.h"

#define BYTES_PER_PROGRAM (256)
#define GPIO_CONFIG_ADDRESS (0x40010000)

int main() {
    uint8_t id[3];

    *((uint32_t*)GPIO_CONFIG_ADDRESS) = 1;

    printf("Programming the winbond chip...\r\n");

    spi_init();

    flash_id(id);

    printf("JEDEC ID = %02X %02X %02X\r\n", id[0], id[1], id[2]);

    uint32_t address = 0;
    uint8_t* pProgram = program_bin;
    uint8_t program_verification[BYTES_PER_PROGRAM];
    uint32_t length = program_bin_len;

    do {
        printf("Erase sector at address: %08X\r\n", address);
        flash_sector_erase(address);
        for(uint32_t i = 0; i < 16; i++) asm("nop");
        for(uint32_t j = 0; j < (4096 / BYTES_PER_PROGRAM); j++) {
            uint32_t length_write = length > BYTES_PER_PROGRAM ? BYTES_PER_PROGRAM : length;
            
            printf("Wrote %d bytes at address: %08X, left = %d\r\n", length_write, address, length);

            memset(program_verification, 0x00, length_write);

            flash_page_program(address, pProgram, length_write);
            for(uint32_t i = 0; i < 16; i++) asm("nop");
            flash_read_data(address, program_verification, length_write);

            if(memcmp(program_verification, pProgram, length_write) != 0) {
                printf("Verification error at %08X\r\n", address);
                
                return -1;
            }
            
            address += length_write;
            pProgram += length_write;

            length -= BYTES_PER_PROGRAM;
            if(address >= program_bin_len) break;
        }
    } while(address < program_bin_len);

    while(address < program_bin_len) {
        memset(program_verification, 0x00, BYTES_PER_PROGRAM);

        flash_read_data(address, program_verification, BYTES_PER_PROGRAM);

        uint32_t verif_length = program_bin_len - address > BYTES_PER_PROGRAM ? 
        BYTES_PER_PROGRAM : program_bin_len - address;
        
        if(memcmp(program_verification, pProgram, verif_length) != 0) {
            printf("Verification error at address = 0x%08X\r\n", address);
                
            return -1;
        }

        address += BYTES_PER_PROGRAM;
        pProgram += BYTES_PER_PROGRAM;
    }

    printf("Verification success! All data are same\r\n");

    printf("Done!\r\n");
    printf("Run the core\r\n");

    //bit[0] = select_spi
    //bit[1] = reset_mriscv

    for(uint32_t i = 0; i < 128; i++);
    *((uint32_t*)GPIO_CONFIG_ADDRESS) = 3;
    for(uint32_t i = 0; i < 128; i++);
    *((uint32_t*)GPIO_CONFIG_ADDRESS) = 2;
    for(uint32_t i = 0; i < 128; i++);
    *((uint32_t*)GPIO_CONFIG_ADDRESS) = 3;

    while(1);
    

    return 0;
}
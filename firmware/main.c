#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#define GPIO_ADDRESS 			((volatile uint32_t*)0x40000000)
#define UART_TRANSMIT_ADDRESS 	((volatile uint32_t*)(0x40600000 + 0x4))
#define UART_STATUS_ADDRESS 	((volatile uint32_t*)(0x40600000 + 0x8))

void print_char(char c) {
	while((*UART_STATUS_ADDRESS) & (1 << 3));
	*(UART_TRANSMIT_ADDRESS) = c;
	
	return;
}

void print_length(const char* str, uint16_t length) {
	while(length--) print_char(*(str++));
	
	return;
}

void print_string(const char* str) {
	while(*str != 0) print_char(*(str++));
	
	//for(uint32_t i = 0; i < 8; i++);
	
	return;
}

int main() {
	print_string("program start!\r\n");
	uint8_t count = 0;

	while(1) {
		*GPIO_ADDRESS = count++ & 0b1111;
		for(uint32_t i = 0; i < 4096; i++) asm("nop");
		print_string("test 123\r\n");
	}
	
	return 0;
}
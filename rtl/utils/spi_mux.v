`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
//
// Module:       spi_bus_mux (Final Version)
// Description:  A complete, self-contained 2-to-1 SPI bus multiplexer.
//
//               This module correctly handles AXI Quad SPI IPs where SCK, SS,
//               and data lines all use 3-signal tristate interfaces (_i, _o, _t).
//               It encapsulates all four required IOBUF primitives.
//
//////////////////////////////////////////////////////////////////////////////////
module spi_mux (
    // --- Global Control ---
    input wire select_b, // 0 = Select A (AXI), 1 = Select B (Custom)

    // --- Interface A (from AXI Quad SPI) ---
    input  wire sck_t, input  wire sck_o, output wire sck_i,
    input  wire ss_t,  input wire [0:0] ss_o,  output wire [0:0] ss_i,
    input  wire io0_t, input  wire io0_o, output wire io0_i,
    input  wire io1_t, input  wire io1_o, output wire io1_i,

    // --- Interface B (from your custom SPI) ---
    input  wire custom_spi_sck_o,
    input  wire custom_spi_ss_o,
    input  wire custom_spi_mosi_o, // MOSI, maps to IO0
    output wire custom_spi_miso_i, // MISO, maps to IO1

    // --- External SPI Bus (to FPGA pins) ---
    inout  wire ext_sck,
    inout  wire ext_ss,
    inout  wire ext_io0,           // Bidirectional IO0 / MOSI
    inout  wire ext_io1            // Bidirectional IO1 / MISO
);

    //---------------------------------------------------------------------
    // 1. Mux and Buffer for SCK Pin
    //---------------------------------------------------------------------
    wire selected_sck_o = select_b ? custom_spi_sck_o : sck_o;
    wire selected_sck_t = select_b ? 1'b0              : sck_t; // Custom master always drives SCK
    wire pin_sck_input_data;
    IOBUF sck_buf_inst (.I(selected_sck_o), .O(pin_sck_input_data), .T(selected_sck_t), .IO(ext_sck));
    assign sck_i = pin_sck_input_data;

    //---------------------------------------------------------------------
    // 2. Mux and Buffer for SS Pin
    //---------------------------------------------------------------------
    wire selected_ss_o = select_b ? custom_spi_ss_o : ss_o;
    wire selected_ss_t = select_b ? 1'b0             : ss_t; // Custom master always drives SS
    wire pin_ss_input_data;
    IOBUF ss_buf_inst (.I(selected_ss_o), .O(pin_ss_input_data), .T(selected_ss_t), .IO(ext_ss));
    assign ss_i = pin_ss_input_data;

    //---------------------------------------------------------------------
    // 3. Mux and Buffer for IO0 Pin (MOSI)
    //---------------------------------------------------------------------
    wire selected_io0_o = select_b ? custom_spi_mosi_o : io0_o;
    wire selected_io0_t = select_b ? 1'b0              : io0_t; // Custom master always drives MOSI
    wire pin_io0_input_data;
    IOBUF io0_buf_inst (.I(selected_io0_o), .O(pin_io0_input_data), .T(selected_io0_t), .IO(ext_io0));
    assign io0_i = pin_io0_input_data;

    //---------------------------------------------------------------------
    // 4. Mux and Buffer for IO1 Pin (MISO)
    //---------------------------------------------------------------------
    wire selected_io1_o = select_b ? 1'b0 : io1_o; // Custom master doesn't drive MISO
    wire selected_io1_t = select_b ? 1'b1 : io1_t; // Custom MISO is an input (high-Z)
    wire pin_io1_input_data;
    IOBUF io1_buf_inst (.I(selected_io1_o), .O(pin_io1_input_data), .T(selected_io1_t), .IO(ext_io1));
    assign io1_i   = pin_io1_input_data;
    assign custom_spi_miso_i = pin_io1_input_data;

endmodule
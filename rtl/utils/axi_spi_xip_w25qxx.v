/*******************************************************************************
 *
 * Module: spi_xip_axi_lite
 *
 * Description:
 * This module provides a read-only AXI4-Lite slave interface that wraps the
 * simple_spi_xip core logic. It translates AXI4-Lite read requests into the
 * simple control signals required by the core SPI controller.
 *
 * This modular design separates the bus interface logic from the peripheral
 * control logic, which is a good design practice.
 *
 * Features:
 * - AXI4-Lite slave interface (Read-only).
 * - Instantiates the verified 'simple_spi_xip' module.
 * - Handles the AXI read channel protocol (AR and R channels).
 *
 * Operation:
 * 1. An AXI master initiates a read by asserting S_AXI_ARVALID.
 * 2. This module accepts the request by asserting S_AXI_ARREADY, latches the
 * address, and triggers the internal simple_spi_xip controller.
 * 3. The module waits for the simple_spi_xip controller to finish (by
 * monitoring its 'busy' and 'data_valid' signals).
 * 4. Once the SPI transaction is complete and data is valid, this module
 * presents the data on S_AXI_RDATA and asserts S_AXI_RVALID.
 * 5. It waits for the AXI master to accept the data (S_AXI_RREADY) before
 * returning to the idle state to accept new requests.
 *
 ******************************************************************************/
module axi_spi_xip_w25qxx #(
    // --- Parameters ---
    parameter C_AXI_ADDR_WIDTH = 32,
    parameter C_AXI_DATA_WIDTH = 32,
    // Ratio to divide the AXI clock to generate the SPI clock (SCK).
    // This parameter is passed down to the simple_spi_xip instance.
    parameter CLK_DIV_RATIO    = 4
) (
    // --- AXI4-Lite Slave Interface ---
    input  wire                       S_AXI_ACLK,
    input  wire                       S_AXI_ARESETN,

    // Read Address Channel
    input  wire [C_AXI_ADDR_WIDTH-1:0] S_AXI_ARADDR,
    input  wire                       S_AXI_ARVALID,
    output wire                       S_AXI_ARREADY,

    // Read Data Channel
    output wire [C_AXI_DATA_WIDTH-1:0] S_AXI_RDATA,
    output wire [1:0]                  S_AXI_RRESP,
    output wire                       S_AXI_RVALID,
    input  wire                       S_AXI_RREADY,

    // --- Unused Write Channels (Tied off) ---
    input  wire [C_AXI_ADDR_WIDTH-1:0] S_AXI_AWADDR,
    input  wire                       S_AXI_AWVALID,
    output wire                       S_AXI_AWREADY,
    input  wire [C_AXI_DATA_WIDTH-1:0] S_AXI_WDATA,
    input  wire [C_AXI_DATA_WIDTH/8-1:0] S_AXI_WSTRB,
    input  wire                       S_AXI_WVALID,
    output wire                       S_AXI_WREADY,
    output wire [1:0]                  S_AXI_BRESP,
    output wire                       S_AXI_BVALID,
    input  wire                       S_AXI_BREADY,

    // --- SPI Master Interface (to Flash Memory) ---
    output wire                       spi_sck,
    output wire                       spi_cs_n,
    output wire                       spi_mosi,
    input  wire                       spi_miso
);

    //------------------------------------------------
    // Internal Signals and State Machine
    //------------------------------------------------

    // State machine for AXI transaction handling
    localparam [1:0]
        ST_IDLE = 2'h0,
        ST_READ = 2'h1,
        ST_RESP = 2'h2;

    reg [1:0] current_state, next_state;

    // Registers for AXI signals
    reg [C_AXI_DATA_WIDTH-1:0] axi_rdata_reg;
    reg                        axi_rvalid_reg;
    reg                        axi_arready_reg;

    // Wires and registers to connect to the simple_spi_xip core
    reg  [23:0] core_read_addr;
    reg         core_read_en;
    wire [31:0] core_data_out;
    wire        core_data_valid;
    wire        core_busy;

    //------------------------------------------------
    // Instantiate the Core SPI Logic
    //------------------------------------------------
    spi_xip_w25qxx #(
        .CLK_DIV_RATIO(CLK_DIV_RATIO)
    ) u_simple_spi_xip (
        .clk        (S_AXI_ACLK),
        .reset_n    (S_AXI_ARESETN),
        .read_addr  (core_read_addr),
        .read_en    (core_read_en),
        .data_out   (core_data_out),
        .data_valid (core_data_valid),
        .busy       (core_busy),
        .spi_sck    (spi_sck),
        .spi_cs_n   (spi_cs_n),
        .spi_mosi   (spi_mosi),
        .spi_miso   (spi_miso)
    );

    //------------------------------------------------
    // AXI Interface Logic
    //------------------------------------------------

    // Assign outputs from internal registers
    assign S_AXI_ARREADY = axi_arready_reg;
    assign S_AXI_RDATA   = axi_rdata_reg;
    assign S_AXI_RVALID  = axi_rvalid_reg;
    assign S_AXI_RRESP   = 2'b00; // OKAY response

    // Tie off unused write channels
    assign S_AXI_AWREADY = 1'b0;
    assign S_AXI_WREADY  = 1'b0;
    assign S_AXI_BRESP   = 2'b10; // SLVERR
    assign S_AXI_BVALID  = 1'b0;

    // Combinational logic for state transitions
    always @(*) begin
        next_state = current_state;
        case (current_state)
            ST_IDLE: begin
                if (S_AXI_ARVALID) begin
                    next_state = ST_READ;
                end
            end
            ST_READ: begin
                // Wait for the core to finish and provide data
                if (core_data_valid) begin
                    next_state = ST_RESP;
                end
            end
            ST_RESP: begin
                // Wait for the AXI master to accept the data
                if (S_AXI_RREADY && axi_rvalid_reg) begin
                    next_state = ST_IDLE;
                end
            end
            default: begin
                next_state = ST_IDLE;
            end
        endcase
    end

    // Sequential logic for state machine and control signals
    always @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) begin
            current_state   <= ST_IDLE;
            axi_arready_reg <= 1'b0;
            axi_rvalid_reg  <= 1'b0;
            axi_rdata_reg   <= 0;
            core_read_en    <= 1'b0;
            core_read_addr  <= 0;
        end else begin
            // Default assignments
            core_read_en    <= 1'b0;
            axi_arready_reg <= 1'b0;

            current_state <= next_state;

            case (current_state)
                ST_IDLE: begin
                    axi_rvalid_reg <= 1'b0; // Ensure RVALID is low in IDLE
                    if (S_AXI_ARVALID) begin
                        axi_arready_reg <= 1'b1; // Accept the request this cycle
                        core_read_addr  <= S_AXI_ARADDR[23:0];
                        core_read_en    <= 1'b1; // Pulse read_en for the core
                    end
                end

                ST_READ: begin
                    // The core is busy processing the SPI transaction.
                    // We simply wait in this state until core_data_valid is asserted.
                    // ARREADY will be low, stalling any new requests.
                end

                ST_RESP: begin
                    // CORRECTED LOGIC:
                    // On the first cycle we enter ST_RESP, RVALID is low. Assert it.
                    if (!axi_rvalid_reg) begin
                        axi_rdata_reg  <= core_data_out;
                        axi_rvalid_reg <= 1'b1;
                    end
                    // If the master accepts the data (handshake), de-assert RVALID for the next cycle
                    // when we transition back to IDLE.
                    else if (S_AXI_RREADY && axi_rvalid_reg) begin
                        axi_rvalid_reg <= 1'b0;
                    end
                end
            endcase
        end
    end

endmodule

/*******************************************************************************
 *
 * Module: simple_spi_xip
 *
 * Description:
 * This module provides a simple, direct interface to a Winbond W25Q128JV
 * SPI flash memory for eXecute-In-Place (XIP) functionality. It uses the
 * standard SPI "Fast Read" (0Bh) command.
 *
 * This design is intended to be a core logic block, abstracting away bus
 * protocols like AXI to focus on the correctness of the SPI transaction.
 *
 * Features:
 * - Simple control interface (address, enable, valid, busy).
 * - Standard 1-bit SPI master interface (MOSI/MISO).
 * - Implements the "Fast Read" (0Bh) command.
 * - Configurable SPI clock speed.
 *
 * Operation:
 * 1. The user provides a 24-bit `read_addr`.
 * 2. The user pulses `read_en` high for one clock cycle.
 * 3. The module asserts `busy`, latches the address, and begins the transaction.
 * 4. It sends the command, address, waits for dummy cycles, and reads the data.
 * 5. Once the 32-bit data is received, `busy` is de-asserted, `data_out` is
 * updated, and `data_valid` is asserted for one clock cycle.
 * 6. The module returns to the idle state, ready for the next read request.
 *
 ******************************************************************************/

module spi_xip_w25qxx #(
    // Ratio to divide the main clock to generate the SPI clock (SCK).
    // SCK Freq = CLK Freq / (2 * CLK_DIV_RATIO).
    parameter CLK_DIV_RATIO = 4
) (
    // --- Control Interface ---
    input  wire        clk,
    input  wire        reset_n,
    input  wire [23:0] read_addr,    // Byte address to read from
    input  wire        read_en,      // Pulse to start a read transaction
    output wire [31:0] data_out,     // 32-bit data read from flash
    output wire        data_valid,   // High for one cycle when data_out is valid
    output wire        busy,         // High while a transaction is in progress

    // --- SPI Master Interface (Standard SPI) ---
    output wire        spi_sck,
    output wire        spi_cs_n,
    output wire        spi_mosi,
    input  wire        spi_miso
);

    //------------------------------------------------
    // Internal Signals and Registers
    //------------------------------------------------

    // State machine definition
    localparam [2:0]
        ST_IDLE      = 3'h0,
        ST_CMD       = 3'h1,
        ST_ADDR      = 3'h2,
        ST_DUMMY     = 3'h3,
        ST_READ_DATA = 3'h4,
        ST_DONE      = 3'h5;

    reg [2:0] current_state, next_state;

    // Control signal registers
    reg [23:0] addr_reg;
    reg [31:0] data_out_reg;
    reg        data_valid_reg;
    reg        busy_reg;

    // SPI Clock Generation
    reg [CLK_DIV_RATIO-1:0] clk_divider_reg;
    reg sck_reg;

    // SPI control registers
    reg cs_n_reg;
    reg spi_mosi_reg;

    // Bit counter for SPI operations
    reg [6:0] bit_counter;
    
    // Temporary byte receiver
    reg [7:0] byte_receiver;

    // Shifters
    reg [31:0] data_shifter; // Combined command and address shifter

    // Constants for Winbond W25Q128JV
    localparam CMD_FAST_READ = 8'h0B;

    //------------------------------------------------
    // Control Logic
    //------------------------------------------------
    assign data_out   = data_out_reg;
    assign data_valid = data_valid_reg;
    assign busy       = busy_reg;

    //------------------------------------------------
    // SPI Interface Logic
    //------------------------------------------------
    assign spi_sck  = sck_reg;
    assign spi_cs_n = cs_n_reg;
    assign spi_mosi = spi_mosi_reg;

    // SPI Clock Generation - only runs when busy
    always @(posedge clk) begin
        if (!reset_n) begin
            clk_divider_reg <= 0;
            sck_reg <= 1'b0;
        end else if (busy_reg) begin
            if (clk_divider_reg == CLK_DIV_RATIO - 1) begin
                clk_divider_reg <= 0;
                sck_reg <= ~sck_reg;
            end else begin
                clk_divider_reg <= clk_divider_reg + 1;
            end
        end else begin
            sck_reg <= 1'b0;
        end
    end

    // Event trigger on the rising edge of the SPI clock
    wire sck_rising_edge = (sck_reg == 1'b1) && (clk_divider_reg == 0);

    //------------------------------------------------
    // Main State Machine
    //------------------------------------------------

    // Combinational logic for next state
    always @(*) begin
        next_state = current_state;
        case (current_state)
            ST_IDLE: begin
                if (read_en) begin
                    next_state = ST_CMD;
                end
            end
            ST_CMD: begin // 8 bits of command
                if (sck_rising_edge && bit_counter == 7) begin
                    next_state = ST_ADDR;
                end
            end
            ST_ADDR: begin // 24 bits of address
                if (sck_rising_edge && bit_counter == 31) begin
                    next_state = ST_DUMMY;
                end
            end
            ST_DUMMY: begin // 8 dummy cycles
                if (sck_rising_edge && bit_counter == 39) begin
                    next_state = ST_READ_DATA;
                end
            end
            ST_READ_DATA: begin // 32 bits of data
                if (sck_rising_edge && bit_counter == 71) begin
                    next_state = ST_DONE;
                end
            end
            ST_DONE: begin
                next_state = ST_IDLE;
            end
            default: begin
                next_state = ST_IDLE;
            end
        endcase
    end

    // Sequential logic for state transitions and outputs
    always @(posedge clk) begin
        if (!reset_n) begin
            current_state   <= ST_IDLE;
            cs_n_reg        <= 1'b1;
            spi_mosi_reg    <= 1'b0;
            bit_counter     <= 0;
            data_out_reg    <= 0;
            busy_reg        <= 1'b0;
            data_valid_reg  <= 1'b0;
        end else begin
            // Default assignments
            data_valid_reg <= 1'b0;

            current_state <= next_state;

            // Manage SPI signals based on state
            case (current_state)
                ST_IDLE: begin
                    busy_reg <= 1'b0;
                    cs_n_reg <= 1'b1;
                    if (read_en) begin
                        addr_reg <= read_addr;
                        bit_counter <= 0;
                        // Pre-load shifter with command and address
                        data_shifter <= {CMD_FAST_READ, read_addr[23:2], 2'b00};
                        busy_reg <= 1'b1;
                        cs_n_reg <= 1'b0; // Activate chip select
                    end
                end

                ST_CMD, ST_ADDR, ST_DUMMY: begin
                    if (sck_rising_edge) begin
                        bit_counter <= bit_counter + 1;
                        // Shift out command and address bits
                        if (bit_counter < 32) begin
                            data_shifter <= data_shifter << 1;
                            spi_mosi_reg <= data_shifter[30];
                        end else begin
                           spi_mosi_reg <= 1'b0; // Dummy cycles
                        end
                    end
                end

                ST_READ_DATA: begin
                    if (sck_rising_edge) begin
                        bit_counter <= bit_counter + 1;
                        byte_receiver <= {byte_receiver[6:0], spi_miso};
                        
                        if (bit_counter[2:0] == 3'b111 && bit_counter >= 47) begin
                            case (bit_counter[5:3])
                                3'b101: data_out_reg[7:0]   <= {byte_receiver[6:0], spi_miso}; // counter=47
                                3'b110: data_out_reg[15:8]  <= {byte_receiver[6:0], spi_miso}; // counter=55
                                3'b111: data_out_reg[23:16] <= {byte_receiver[6:0], spi_miso}; // counter=63
                                3'b000: data_out_reg[31:24] <= {byte_receiver[6:0], spi_miso}; // counter=71
                            endcase
                        end
                        // Capture data from MISO
                        //data_out_reg <= {data_out_reg[30:0], spi_miso};
                    end
                end

                ST_DONE: begin
                    cs_n_reg <= 1'b1; // De-assert chip select
                    busy_reg <= 1'b0;
                    data_valid_reg <= 1'b1; // Signal that data is ready
                end
            endcase
        end
    end

endmodule

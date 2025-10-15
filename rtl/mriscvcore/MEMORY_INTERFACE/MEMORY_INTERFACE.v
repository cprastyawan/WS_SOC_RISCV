`timescale 1ns / 1ps

module MEMORY_INTERFACE(
    input clock,
    input resetn,
    input [31:0] rs1,
    input [31:0] rs2,
    input [31:0] rdata_mem,
    input arready,
    input rvalid,
    input awready,
    input wready,
    input bvalid,
    input [31:0] imm, 
    input [1:0] W_R,
    input [1:0] wordsize,
    input enable,
    input [31:0] pc,
    input signo,
    
    output reg busy, 
    output reg done,
    output reg align, 
    output reg [31:0] awaddr,
    output reg [31:0] araddr,
    output reg [31:0] Wdata,
    output [31:0] rd,
    output reg [31:0] inst,
    output reg arvalid,
    output reg rready,
    output reg awvalid,
    output reg wvalid,
    output reg [2:0] arprot,
    output reg [2:0] awprot,
    output reg bready,
    output reg [3:0] Wstrb,
    output reg rd_en
    //output reg [3:0] Rstrb
    );
    
    
    reg [15:0] relleno16;
    reg [23:0] relleno24;
    reg [31:0] rdataq,Wdataq;
    reg [3:0] Wstrbq;
    reg [31:0] rdu;
    reg en_instr;
    reg en_read;
///////////////////////////////////////////////////////////////////////////////////
/////////////// BEGIN FSM
/////////////// FIX: CREATE THE MEALY FSM!
//////////////////////////////////////////////////////////////////////////////////    
    reg [3:0] state,nexstate;

    parameter reposo     = 4'd0;
    parameter inicioR     = 4'd1;
    parameter SR1         = 4'd2;
    parameter SR2         = 4'd3;
    parameter inicioW     = 4'd4;
    parameter SW0         = 4'd5;
    parameter SW1         = 4'd6;
    parameter SW2        = 4'd7;
    parameter SWB         = 4'd8;
    
    // Next state and output logic
    always @* begin
        arvalid    = 1'b0;
        rready     = 1'b0;
        awvalid    = 1'b0;
        wvalid    = 1'b0;
        bready    = 1'b0;
        busy    = 1'b0;
        en_read = 1'b0;
        nexstate = state;
        if(resetn == 1'b1) begin
            case (state)
                reposo : begin
                    // If reading or gathering instructions?
                    if ( (W_R[1]==1'b1 || W_R==2'b01) && enable==1'b1 ) begin
                        arvalid    = 1'b1;     // Pre-issue the arvalid
                        rready = 1'b1;      // There is no problem if this is issued since before
                        if(arready && rvalid) begin en_read = 1'b1; busy = 1'b0; end     // In the same cycle sync read
                        else if(arready && !rvalid) begin nexstate = SR2; busy = 1'b1; end // Wait for rvalid
                        else begin nexstate = SR1; busy = 1'b1; end
                    // If writing?
                    end else if (W_R==2'b00 && enable==1'b1) begin
                        awvalid    = 1'b1;     // Pre-issue awvalid
                        wvalid = 1'b1;      // Pre-issue wvalid
                        bready = 1'b1;      // There is no problem if this is issued since before
                        if(!awready && !wready) begin                    nexstate = SW0; busy = 1'b1;
                        end else if(awready && !wready) begin            nexstate = SW1; busy = 1'b1;
                        end else if(!awready && wready) begin            nexstate = SW2; busy = 1'b1;
                        end else if(awready && wready && !bvalid) begin  nexstate = SWB; busy = 1'b1;
                        end //else if(awready && wready && bvalid)  // Action not necesary
                    end else begin
                        nexstate = reposo;
                    end
                end

                SR1 : begin
                    rready = 1'b1;
                    arvalid    = 1'b1;
                    if(arready && rvalid) begin
                        en_read = 1'b1;     // In the same cycle sync read
                        nexstate = reposo;
                    end else if(arready && !rvalid) begin
                        nexstate = SR2;
                        busy = 1'b1;
                    end else begin
                        nexstate = SR1;
                        busy = 1'b1;
                    end
                end

                SR2 : begin
                    rready = 1'b1;
                    if(rvalid) begin
                        en_read = 1'b1;     // In the same cycle sync read
                        nexstate = reposo;
                    end else begin
                        nexstate = SR2;
                        busy = 1'b1;
                    end
                end

                SW0 : begin
                    awvalid = 1'b1;
                    wvalid = 1'b1;
                    bready = 1'b1;      // There is no problem if this is issued since before
                    if(awready && !wready) begin
                        nexstate = SW1;
                        busy = 1'b1;
                    end else if(!awready && wready) begin             
                        nexstate = SW2;
                        busy = 1'b1;
                    end else if(awready && wready && !bvalid) begin  
                        nexstate = SWB;
                        busy = 1'b1;
                    end else if(awready && wready && bvalid) begin   
                        nexstate = reposo;
                    end else begin
                        nexstate = SW0;
                        busy = 1'b1;
                    end
                end

                SW1 : begin
                    //awvalid = 1'b1;
                    wvalid = 1'b1;
                    bready = 1'b1;      // There is no problem if this is issued since before
                    if (wready && !bvalid) begin
                        nexstate=SWB;
                        busy = 1'b1;
                    end else if(wready && bvalid) begin
                        nexstate=reposo;
                    end else begin
                        nexstate=SW1;
                        busy = 1'b1;
                    end
                end

                SW2 : begin
                    awvalid = 1'b1;
                    //wvalid = 1'b1;
                    bready = 1'b1;      // There is no problem if this is issued since before
                    if (awready && !bvalid) begin
                        nexstate=SWB;
                        busy = 1'b1;
                    end else if(awready && bvalid) begin
                        nexstate=reposo;
                    end else begin
                        nexstate=SW2;
                        busy = 1'b1;
                    end
                end
            
                SWB : begin
                    bready = 1'b1;
                    if (bvalid) begin
                        nexstate=reposo;
                    end else begin
                        nexstate=SWB;
                        busy = 1'b1;
                    end
                end

                default : begin  // Fault Recovery
                    nexstate = reposo;
                end   
            endcase
        end
        
        done    = !busy;    // Because fuck this
    end

    // State Sync
    always @(posedge clock)
        if(resetn == 0) state <= reposo;
        else state <= nexstate;
        
/////////////////////////////////////////////////////////////////////////////////////////////////////////////    
////////////////////// END FSM
///////////////////////////////////////////////////////////////////////////////////////////
    
    always @* begin
        // Default values
        en_instr     = 0;
        rd_en        = 0;
        awprot       = 3'b000;
        awaddr       = rs1+imm;
        arprot       = 3'b000;
        araddr       = rs1+imm;
        align        = 1;
        Wdataq       = 0;
        Wstrbq       = 4'b0000;
        rdataq       = 0;
        relleno16    = 0;
        relleno24    = 0;
        
        case (W_R)
            2'b00  : begin
                en_instr = 0;
                awprot = 3'b000;
                awaddr = rs1+imm;
                case (wordsize)
                    2'b10  : begin
                        if(enable) align=(awaddr[1:0]==2'b00)? 1:0;
                        Wdataq=rs2;
                        Wstrbq=4'b1111;
                    end
                    2'b01  : begin
                        if(enable) align=(awaddr[0]==1'b0)? 1:0;
                        Wstrbq = awaddr[1] ? 4'b1100 : 4'b0011;
                        Wdataq={2{rs2[15:0]}};
                    end
                    2'b00  : begin
                        align=1;
                        Wstrbq = 4'b0001 << araddr[1:0];
                        Wdataq={4{rs2[7:0]}};
                    end
                endcase                        
            end

            2'b10,2'b11  : begin
                en_instr=1'b1;
                awaddr=pc;
                araddr=pc;
                arprot=3'b100;
            end

            2'b01 : begin
                if(en_read) rd_en=1;
                arprot=3'b000;
                en_instr=0;
                araddr= rs1+imm;
                case (wordsize)
                    2'b10  : begin
                        if(enable) align=(araddr[1:0]==0)? 1:0;
                        rdataq=rdata_mem;
                    end
                    
                    2'b01  : begin
                        if(enable) align=(araddr[0]==0)? 1:0;
                        case (araddr[1])
                            1'b0: begin 
                                case (signo) 
                                    1'b1: relleno16={16{rdata_mem[15]}};
                                    1'b0: relleno16=16'd0;
                                endcase
                                rdataq= {relleno16,rdata_mem[15:0]};
                            end
                            1'b1: begin 
                                case (signo) 
                                    1'b1: relleno16={16{rdata_mem[31]}};
                                    1'b0: relleno16=16'd0;
                                endcase
                                rdataq = {relleno16,rdata_mem[31:16]};
                            end
                        endcase
                    end
            
                    2'b00  : begin
                        align=1;
                        case (araddr[1:0])
                            2'b00:  begin 
                                case (signo) 
                                    1'b0: relleno24=24'd0;
                                    1'b1: relleno24={24{rdata_mem[7]}};
                                endcase
                                rdataq = {relleno24,rdata_mem[ 7: 0]}; 
                            end
                            2'b01:  begin 
                                case (signo) 
                                    1'b0: relleno24=24'd0;
                                    1'b1: relleno24={24{rdata_mem[15]}};
                                endcase 
                                rdataq = {relleno24,rdata_mem[15: 8]}; 
                            end
                            2'b10:  begin 
                                case (signo) 
                                    1'b0: relleno24=24'd0;
                                    1'b1: relleno24={24{rdata_mem[23]}};
                                endcase
                                rdataq = {relleno24,rdata_mem[23:16]}; 
                            end
                            2'b11:  begin 
                                case (signo) 
                                    1'b0: relleno24=24'd0;
                                    1'b1: relleno24={24{rdata_mem[31]}};
                                endcase 
                                rdataq = {relleno24,rdata_mem[31:24]}; 
                            end
                        endcase
                    end
                endcase    
            end
        endcase
    end
    

    always @ (posedge clock) begin
        if (!resetn) begin
            Wdata <= 32'd0;
            rdu <= 32'd0;
            Wstrb <= 4'b0000;
            inst <= 32'd0;
                 
        end else begin 
            Wdata<=Wdataq;
            Wstrb<=Wstrbq;
            if(en_read) rdu<=rdataq;
            if(en_instr && en_read) inst <= rdata_mem;
        end
    end
    
    assign rd= rd_en?rdataq:32'bz;
         

endmodule


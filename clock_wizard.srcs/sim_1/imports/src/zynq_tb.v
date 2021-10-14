//---------------------------------------------------------------------------
// Testbench  
//---------------------------------------------------------------------------
//
//***************************************************************************
// DISCLAIMER OF LIABILITY
//
// This file contains proprietary and confidential information of
// Xilinx, Inc. ("Xilinx"), that is distributed under a license
// from Xilinx, and may be used, copied and/or disclosed only
// pursuant to the terms of a valid license agreement with Xilinx.
//
// XILINX IS PROVIDING THIS DESIGN, CODE, OR INFORMATION
// ("MATERIALS") "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
// EXPRESSED, IMPLIED, OR STATUTORY, INCLUDING WITHOUT
// LIMITATION, ANY WARRANTY WITH RESPECT TO NONINFRINGEMENT,
// MERCHANTABILITY OR FITNESS FOR ANY PARTICULAR PURPOSE. Xilinx
// does not warrant that functions included in the Materials will
// meet the requirements of Licensee, or that the operation of the
// Materials will be uninterrupted or error-free, or that defects
// in the Materials will be corrected. Furthermore, Xilinx does
// not warrant or make any representations regarding use, or the
// results of the use, of the Materials in terms of correctness,
// accuracy, reliability or otherwise.
//
// Xilinx products are not designed or intended to be fail-safe,
// or for use in any application requiring fail-safe performance,
// such as life-support or safety devices or systems, Class III
// medical devices, nuclear facilities, applications related to
// the deployment of airbags, or any other applications that could
// lead to death, personal injury or severe property or
// environmental damage (individually and collectively, "critical
// applications"). Customer assumes the sole risk and liability
// of any use of Xilinx products in critical applications,
// subject only to applicable laws and regulations governing
// limitations on product liability.
//
// Copyright 2009 Xilinx, Inc.
// All rights reserved.
//
// This disclaimer and copyright notice must be retained as part
// of this file at all times.
//***************************************************************************
//

`timescale 1ns / 1ps

module tb;
    
    wire locked;
    wire new_clk;

    reg tb_ACLK;
    reg tb_ARESETn;
   
    wire temp_clk;
    wire temp_rstn; 
   
    reg [31:0] read_data;
    reg [31:0] lock_status;
    
    wire [3:0] leds;
    reg resp;
    
    parameter address_base = 32'h43C00000;
    parameter address_offset = 32'h200;
    parameter address_offset2 = 32'h208;// + 32'h0C;
    parameter address_offset_commit = 32'h25C;
    parameter address_offset_dutycycle = 32'h210;
    
    parameter DIVCLK_DIVIDE  = 8'h4;
    parameter DIV_DEFAULT = 32'h00000000;
    parameter DIV_VALUE = DIVCLK_DIVIDE | DIV_DEFAULT;
    
    parameter TOTAL_DIVIDE = 1;
    parameter TOTAL_MULT = 1;
    parameter CURRENT_DIVIDE = 4;
    parameter DUTY_CYCLE_PERCENT = 0.1;
    
    reg [31:0] first_config= 0;
    reg [31:0] second_config= 0;
    reg [31:0] duty_cycle = DUTY_CYCLE_PERCENT*1000;
    
    
    initial 
    begin       
        tb_ACLK <= 1'b0;
        
        first_config[7:0] <= TOTAL_DIVIDE;
        first_config[15:8] <= TOTAL_MULT;
        
        second_config[7:0] <= CURRENT_DIVIDE;
    end
    
    //------------------------------------------------------------------------
    // Simple Clock Generator
    //------------------------------------------------------------------------
    
    always #10 tb_ACLK = !tb_ACLK;
       
    initial
    begin
    
        $display ("running the tb");
        
        tb_ARESETn = 1'b0;
        repeat(20)@(posedge tb_ACLK);        
        tb_ARESETn = 1'b1;
        @(posedge tb_ACLK);
        
        repeat(5) @(posedge tb_ACLK);
          
        //Reset the PL
        tb.zynq_sys.design_clock_wizard_i.processing_system7_0.inst.fpga_soft_reset(32'h1);
        tb.zynq_sys.design_clock_wizard_i.processing_system7_0.inst.fpga_soft_reset(32'h0);
        
        // check lock status
        tb.zynq_sys.design_clock_wizard_i.processing_system7_0.inst.read_data(address_base | 32'h04,4,lock_status, resp);
        while(lock_status != 1) begin
            tb.zynq_sys.design_clock_wizard_i.processing_system7_0.inst.read_data(address_base | 32'h04,4,lock_status, resp);
        end
        
        // Reset ClockWizardBlock;
        tb.zynq_sys.design_clock_wizard_i.processing_system7_0.inst.write_data(address_base,4,32'h00A, resp);
        // check lock status
        tb.zynq_sys.design_clock_wizard_i.processing_system7_0.inst.read_data(address_base | 32'h04,4,lock_status, resp);
        while(lock_status != 1) begin
            tb.zynq_sys.design_clock_wizard_i.processing_system7_0.inst.read_data(address_base | 32'h04,4,lock_status, resp);
        end
        
        
        
        
        //Set the registers 
        tb.zynq_sys.design_clock_wizard_i.processing_system7_0.inst.write_data(address_base | address_offset_dutycycle,4,duty_cycle, resp);
        tb.zynq_sys.design_clock_wizard_i.processing_system7_0.inst.write_data(address_base | address_offset,4,first_config, resp);
        tb.zynq_sys.design_clock_wizard_i.processing_system7_0.inst.write_data(address_base | address_offset2,4,second_config, resp);
        
        
        tb.zynq_sys.design_clock_wizard_i.processing_system7_0.inst.write_data(address_base | address_offset_commit,4,7, resp);
        
        tb.zynq_sys.design_clock_wizard_i.processing_system7_0.inst.read_data(address_base | 32'h04,4,lock_status, resp);
        while(lock_status == 1) begin
            tb.zynq_sys.design_clock_wizard_i.processing_system7_0.inst.read_data(address_base | 32'h04,4,lock_status, resp);
        end
        

        tb.zynq_sys.design_clock_wizard_i.processing_system7_0.inst.write_data(address_base | address_offset_commit,4,2, resp);
        while(lock_status != 1) begin
            tb.zynq_sys.design_clock_wizard_i.processing_system7_0.inst.read_data(address_base | 32'h04,4,lock_status, resp);
        end
        
        tb.zynq_sys.design_clock_wizard_i.processing_system7_0.inst.read_data(address_base | address_offset_dutycycle,4,read_data, resp);
        $display ("%t, THE DEFAULT CONF: was 32'h%x",$time, read_data);


        #1500;
        $display ("Simulation completed");
        $stop;
    end

    assign temp_clk = tb_ACLK;
    assign temp_rstn = tb_ARESETn;
   
    
design_clock_wizard_wrapper zynq_sys
   (.DDR_addr(),
    .DDR_ba(),
    .DDR_cas_n(),
    .DDR_ck_n(),
    .DDR_ck_p(),
    .DDR_cke(),
    .DDR_cs_n(),
    .DDR_dm(),
    .DDR_dq(),
    .DDR_dqs_n(),
    .DDR_dqs_p(),
    .DDR_odt(),
    .DDR_ras_n(),
    .DDR_reset_n(),
    .DDR_we_n(),
    .FIXED_IO_ddr_vrn(),
    .FIXED_IO_ddr_vrp(),
    .FIXED_IO_mio(),
    .FIXED_IO_ps_clk(temp_clk),
    .FIXED_IO_ps_porb(temp_rstn ),
    .FIXED_IO_ps_srstb(temp_rstn),
    .clk_out1_0(new_clk),
    .locked_0(locked));

endmodule



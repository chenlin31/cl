#!/bin/bash

for file in input/*.v; do

    base=`basename $file .v` # get the filename without extention

    yosys  -p "read_liberty and_or.lib;
               read_verilog $file; 
               hierarchy -auto-top -check;
               proc; 
               flatten; 
               opt; 
               techmap; 
               opt; 
               write_blif yosys_blif/$base.blif; 
               write_verilog yosys_blif/${base}_yosys.v" #yosys optimization, from verilog to blif and optimized verilog
    
    abc    -c "read yosys_blif/$base.blif; 
               strash; 
               ps; 
               compress2rs; 
               ps; 
               cec; 
               write abc_aiger/$base.aig;
               write abc_aiger/${base}_abc.v" #abc optimization, from blif to optimized aiger and optimized verilog
    
    cirkit -c "<cirkit.rs; 
               read_aiger -a abc_aiger/$base.aig; 
               lut_mapping -k 4 -a; 
               collapse_mapping; 
               lut_resynthesis; 
               ps -m; 
               compress2rs; 
               ps -m; 
               write_verilog -m cirkit_verilog/$base.v" #cirkit optimization, from aig to optimized MIG-based verilog
done

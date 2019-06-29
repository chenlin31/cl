#!/bin/bash

enable_yosys=true
enable_abc=true
enable_cirkit=true

a="only_yosys"
b="only_abc"
c="only_cirkit"
d="to_abc"

if [ -n "$1" ]; then 
  if [ "$1" == "$a" ]; then 
    enable_abc=false
    enable_cirkit=false
  elif [ "$1" == "$b" ]; then 
    enable_yosys=false
    enable_cirkit=false
  elif [ "$1" == "$c" ]; then
    enable_yosys=false
    enable_abc=false
  elif [ "$1" == "$d" ]; then
    enable_cirkit=false
  else
    echo "./run_flow [only_yosys | only_abc | only_cirkit | to_abc]"
    exit
  fi
fi

for file in input/*.v; do

    base=`basename $file .v` # get the filename without extention

    if test "$enable_yosys" = "true"; then 
      yosys   -p "read_liberty and_or.lib;
                  read_verilog $file; 
                  hierarchy -auto-top -check;
                  proc; 
                  flatten; 
                  opt; 
                  techmap; 
                  opt; 
                  write_blif yosys_blif/$base.blif; 
                  write_verilog yosys_blif/${base}_yosys.v" #yosys optimization, from verilog to blif and optimized verilog
    fi
    
    if test "$enable_abc" = "true"; then 
      abc    -c  "read yosys_blif/$base.blif; 
                  strash; 
                  ps; 
                  compress2rs; 
                  ps; 
                  cec; 
                  write abc_aiger/$base.aig;
                  write abc_aiger/${base}_abc.v" #abc optimization, from blif to optimized aiger and optimized verilog
    fi
    
    if test "$enable_cirkit" = "true"; then 
      cirkit -c  "<cirkit.rs; 
                  read_aiger -a abc_aiger/$base.aig; 
                  lut_mapping -k 4 -a; 
                  collapse_mapping; 
                  lut_resynthesis; 
                  ps -m; 
                  compress2rs; 
                  ps -m; 
                  write_verilog -m cirkit_verilog/$base.v" #cirkit optimization, from aig to optimized MIG-based verilog
    fi

done

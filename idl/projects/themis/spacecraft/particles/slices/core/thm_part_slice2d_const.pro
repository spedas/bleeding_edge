
pro thm_part_slice2d_const, q=q, mconv=mconv, c=c

    compile_opt idl2, hidden
    
  q = 1.602176d-19 ;J/eV
  
  c = 299792458d ;m/s
  
  mconv = 6.2508206d24 ; convert distrubution mass from eV/(km/s)^2 to kg

  return
end
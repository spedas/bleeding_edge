function barrel_make_standard_energies,slow=slow
  if keyword_set(slow) then $
    n=datin(barrel_find_file('barrel_calib_sspcbin.txt','barrel_sp_v3.7'),4,d)$
  else $
    n=datin(barrel_find_file('barrel_calib_mspcbin.txt','barrel_sp_v3.7'),5,d)
  ebins = reform(d[1,*])
  return,ebins
end


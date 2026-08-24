function mvn_sta_tempflag_struct, npts

if (size(npts,/type) eq 0) then npts = 1


flag_str = { cnts: 0, $ ; 1 if low countrate
  mode: 0, $ ; 1 if w/in 8sec of mode change -- that means this value is interpolated
  tail: !values.F_NAN, $ ; 1 if possible superthermal tail
  bigcorr: 0, $  ; 1 if the correction on the provided value is large
  coverage: 0, $ ; 1 if the distribution is not in the FOV
  scpot: 0 } ; 1 if sc potential is high or missing
  
  if (npts gt 1) then return, replicate(flag_str, npts) $
  else return, flag_str
  
  end
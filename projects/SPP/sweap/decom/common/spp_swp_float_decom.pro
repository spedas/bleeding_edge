

function spp_swp_float_decom,buffer,n
  if n gt n_elements(buffer)-4 then begin
    dprint,'Outside buffer size ',n
    return, !values.f_nan
  endif
  return,   swap_endian(/swap_if_little_endian,  float(buffer,n) )
end


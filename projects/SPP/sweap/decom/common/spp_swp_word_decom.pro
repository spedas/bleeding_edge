


function spp_swp_word_decom,buffer,n,num, mask=mask ,shft=shft
  if n_params() eq 3 then val =  swap_endian(/swap_if_little_endian,  uint(buffer,n,num) ) $
  else                    val =  swap_endian(/swap_if_little_endian,  uint(buffer,n) )
  if n_elements(shft) ne 0 then val = ishft(val,shft)
  if n_elements(mask) ne 0 then val = val and mask
  return, val
end

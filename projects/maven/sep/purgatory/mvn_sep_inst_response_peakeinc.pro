

function mvn_sep_inst_response_peakEinc,resp,width=width,threshold=threshold
  if ~keyword_set(width) then width = 12
  if ~keyword_set(threshold) then threshold = .05
  pk = {g:!values.f_nan, e0:!values.f_nan, s:!values.f_nan}
  pks = replicate(pk,2,256)
  for omega=0,1 do begin
    for b=0,255 do begin
      rr = resp.bin3[*,omega,b]*(resp.sim_area /100 / resp.nd * 3.14)
      w = where(total(rr,/cumulative) ge threshold,nw)
      if nw eq 0 then continue
      i1 = (w[0]-width/2) > 0
      i2 = (i1 +width) < n_elements(rr)-1
      e = resp.e_inc[i1:i2]
      r = rr[i1:i2]
      pk.g  = total(r)
      pk.e0 = total(r * e) /pk.g
      pk.s  = sqrt(total(r*(e-pk.e0)^2)/pk.g)
      pks[omega,b] = pk
    endfor
  endfor
  return,pks
end


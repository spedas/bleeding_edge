

function swfo_stis_inst_response_peakEinc,resp,width=width,threshold=threshold,test=test
  if ~keyword_set(width) then width = 6
  if ~keyword_set(threshold) then threshold = .0005
  pk = {g:!values.f_nan, e0:!values.f_nan, s:!values.f_nan}
  nbins =resp.nbins
  e_inc = resp.e_inc
  pks = replicate(pk,nbins)
  ;for omega=0,1 do begin
    for b=0,nbins-1 do begin
      if 0 then begin
        rr = resp.bin3[*,omega,b]*(resp.sim_area /100 / resp.nd * 3.14)
        w = where(total(rr,/cumulative) ge threshold,nw)
        if nw eq 0 then continue
        i1 = (w[0]-width/2) > 0
        i2 = (i1 +width) < n_elements(rr)-1
      endif else begin
        rr = total(resp.gb3[*,*,b] ,2)
        mx = max(smooth(rr* e_inc^(-2)  ,5),maxbin)
        irange = 0 > ( maxbin + width*[-1,1] ) < (n_elements(e_inc)-1)
        i1= irange[0]
        i2= irange[1]
      endelse
      e = resp.e_inc[i1:i2]
      r = rr[i1:i2]
      pk.g  = total(r)
      pk.e0 = total(r * e) /pk.g
      pk.s  = sqrt(total(r*(e-pk.e0)^2)/pk.g)
      pks[b] = pk
      if keyword_set(test) then begin
        plot,e_inc,rr > .0001,/xlog,/ylog,yrange=minmax(rr,/pos),psym=-1
        oplot,e,r,color=4,psym=-1
        print,b
      endif
    endfor
  ;endfor
  return,pks
end


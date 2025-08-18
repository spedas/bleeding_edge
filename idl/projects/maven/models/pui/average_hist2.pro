;20160404 Ali
;this is a modification of Davin's average_hist function
;FUNCTION average_hist2(a,x)
;returns the average of "a", binned according to binsized "x"
;can handle up to 8 dimentional "a", where the first dimention of "a" is time
;(e.g. MAVEN STATIC time-energy-anode-deflection-mass spectra)
;centertime is output
;nan: if set, will skip bins that have no data in them. if not set, will put NaN in them.
;to be called by mvn_pui_model > mvn_pui_data_res

function average_hist2,a,x,binsize=binsize,trange=trange,centertime=centertime,nan=nan
  if ~keyword_set(trange) then trange=minmax(x) else begin
    tdrange=time_double(trange)
    min=tdrange[0]
    max=tdrange[1]-binsize/2. ;not sure why mvn_pui_data_res needs the -binsize/2 part! Ali 2020-03-03
  endelse
  h=histogram(x,binsize=binsize,min=min,max=max,locations=centertime,reverse=ri,/nan)
  whn0=where(h,count)
  centertime+=binsize/2.
  sizeh=size(h,/dim)
  sizea=size(a,/dim)
  if keyword_set(nan) then begin
    sizeh=count
    centertime=centertime[whn0]
  endif
  fnan=!values.f_nan
  if size(sizea,/dim) eq 1 then avg=replicate(fnan,sizeh) else avg=replicate(fnan,[sizeh,sizea[1:*]])
  for j=0l,count-1 do begin
    i=whn0[j]
    ind=ri[ri[i]:ri[i+1]-1]
    if keyword_set(nan) then i=j
    avg[i,*,*,*,*,*,*,*]=average(a[ind,*,*,*,*,*,*,*],1,/nan)
  endfor
  return,avg
end

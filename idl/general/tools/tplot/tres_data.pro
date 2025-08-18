; $LastChangedBy: ali $
; $LastChangedDate: 2020-03-23 13:06:00 -0700 (Mon, 23 Mar 2020) $
; $LastChangedRevision: 28453 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/tools/tplot/tres_data.pro $

pro tres_data,varnames,nan=nan,freq=freq

  vars = tnames(varnames)
  if ~keyword_set(vars) then begin
    dprint,'Tplot variable not valid! Returning...'
    return
  endif
  
  for i=0,n_elements(vars)-1 do begin

    get_data,vars[i],data=d

    if ~keyword_set(d) then begin
      dprint,'No data in tplot variable: '+vars[i]
      continue
    endif

    if keyword_set(nan) then begin
      wf=where(finite(d.x),/null)
      str_element,/add,d,'x',d.x[wf]
    endif

    tdiff = d.x - shift(d.x,1)
    if n_elements(tdiff) gt 1 then tdiff[0] = tdiff[1]
    units='(s)'

    if keyword_set(freq) then begin
      tdiff=1./tdiff
      units='(Hz)'
    endif

    str_element,/add,d,'y', tdiff
    store_data,vars[i]+'_tres'+units,data=d,dlimit={ylog:1,ystyle:2}

  endfor

end

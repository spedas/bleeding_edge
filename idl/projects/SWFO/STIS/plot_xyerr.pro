Pro plot_xyerr, x,y,delta_x=dx,delta_y=dy,overplot=overplot, _extra = ex,verbose=verbose
  ;+
  ; PROCEDURE:
  ;	plot_xyerr, x,y, delta_x=delta_x,delta_y=delta_y
  ; PURPOSE:
  ;	Plot error bars
  ;
  ;-
  ;on_error,2                      ;Return to caller if an error occurs

  if ~isa(x) then x = findgen(n_elements(y))
  
  w = where( finite(x) and finite(y) ,nw, /null)
  if ~isa(w) then begin
    dprint,'Not enough points to plot',verbose=verbose,dlevel=2
    return
  endif

  if ~keyword_set(overplot) then plot,x,y,/nodata,_extra=ex
  ;printdat,ex

  oplot,[x],[y],_extra=ex

  n = n_elements(x)
  str_element,/add,ex,'psym',0
  str_element,/add,ex,'linestyle',0
  if keyword_set(dx) then begin
    xlow = x-dx
    if !x.type ne 0 then xlow = xlow > 1e-37
    xhigh = x+dx
    for i=0,n-1 do $
      oplot,_extra=ex,psym=0,linestyle=0,[xlow[i],xhigh[i] ],y[[i,i]]
  endif
  if keyword_set(dy) then begin
    ylow = y-dy
    yhigh = y+dy
    for i=0,n-1 do $
      oplot,_extra=ex, x[[i,i]] , [ylow[i],yhigh[i] ]
  endif

  return
end

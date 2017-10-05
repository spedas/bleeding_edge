
;+
; Procedure:   CLEAN_SPIKES, 'name'
; 
; Purpose:  Simple routine to remove spikes from tplot data.
; 
; Author: unknown, Probably Frank Marcoline
; 
; Keywords:
;  display_object = Object reference to be passed to dprint for output.
; 
; jmm, 4-jul-2007, made to work for negative data, by adding absolute values
; jmm, 30-jul-2007, Added more error checking
; jmm, 15-sep-2009, documentation test
;$LastChangedBy: $
;$LastChangedDate: $
;$LastChangedRevision: $
;$URL: $
;-
pro clean_spikes,name,new_name=new_name,nsmooth=ns,thresh=ft, display_object=display_object


get_data, name, data = d, dlim = dlim, lim = lim

If(size(d, /type) Eq 8) Then Begin
  ds = d
  if not keyword_set(ns) then  ns = 3
  ns = (fix(ns)/2)*2 + 1
  nd1 = dimen1(d.y)
  If(nd1 Le 2*ns) Then Begin
    msg = name+': Not enough data for smoothing, to despike, returning undespiked data'
    dprint, msg , display_object=display_object
    if not keyword_set(new_name) then new_name = name+'_cln'
    store_data, new_name, data = d, dlim = dlim, lim = lim
  Endif Else Begin
    if not keyword_set(ft) then  ft = 10.
    ft = float(ft)
    nd2 = dimen2(d.y)
    for i = 0, nd2-1 do ds.y[*, i] = smooth(d.y[*, i], ns, /nan)
    bad = abs(d.y) gt (ft*ns*abs(ds.y)/(ns-1+ft) )
    if nd2 gt 1 then bad = total(bad, 2)
    wbad = where(bad gt .5)
    If(wbad[0] Ne -1) Then d.y[wbad, *] = !values.f_nan
    if not keyword_set(new_name) then new_name = name+'_cln'
    store_data, new_name, data = d, dlim = dlim, lim = lim
  Endelse
Endif
end

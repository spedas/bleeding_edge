;+
;       Name: TDESPIKE_AE
;
;       Purpose:  This routine removes artificial spikes. Note that it is
;                 ONLY meant to be used for the calculation of the
;                 'THEMIS AE index' in the overview plots.
;
;       Variable:  lower = lower cutoff of spikes to be removed
;                  upper = upper cutoff of spikes to be removed
;
;       Keywords:  none
;
;       Example:   tdespike_AE, -2000.0, 1500.0
;
;       Notes:     Written by Andreas Keiling, 29 August 2007
;
; $LastChangedBy: aaflores $
; $LastChangedDate: 2009-08-03 10:43:14 -0700 (Mon, 03 Aug 2009) $
; $LastChangedRevision: 6516 $
; $URL $
;-


pro tdespike_AE, lower, upper

get_data, 'thg_pseudoAE', data=ae, dlimits = dl

last=n_elements(ae.y)-1
NaN=!values.f_nan

indices = where(ae.y gt upper OR ae.y lt lower , count)
if count ne 0 then begin
   for k=0,count-1 do begin
       i=indices[k]
       if (i eq 0 OR i eq 1 ) then begin
          ae.y[0]=NaN
          ae.y[1]=NaN
       endif else begin
          if (i eq last-1 OR i eq last) then begin
               ae.y[last-1]=NaN
               ae.y[last] = NaN
          endif else begin
               ae.y[i-2]=NaN
               ae.y[i-1]=NaN
               ae.y[i] = NaN
               ae.y[i+1]=NaN
               ae.y[i+2]=NaN
          endelse
       endelse
   endfor
endif

store_data, 'thg_pseudoAE_despike', data=ae, dlimits = dl

end

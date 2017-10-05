;+
; PROCEDURE:
;         specplot_grayNaNs, tvar
;
; PURPOSE:
;         plot spectral data, any data set to NaN is plotted gray
;
; INPUT:
;         tvar:  tplot variable name, string      
;
; EXAMPLE:
;         mms_load_eis, probes='1', trange=['2015-07-31', '2015-08-1'], datatype='electronenergy'
;         mms_eis_pad, probe='1', species='electron', datatype='electronenergy', data_units='flux'
;         specplot_grayNaNs, 'mms1_epd_eis_electronenergy_0-1000keV_electron_flux_omni_pad_spin'
;
; NOTES:
;     This is an initial release demonstrating the capability of plotting tplot spectral data that contains Nans.
;     Originally developed for MMS data, however, subsequent fixes to the data may no longer have need for this 
;     type of plot.
;     Currently the routine locates any existing Nan values and sets them to a sentinel value for display. An index
;     in the color table corresponding to the new Nan value is changed to gray  
;
;-

pro specplot_grayNaNs, tvar

  if undefined(tvar) then begin
     dprint, 'A tplot variable name is required.' 
     return
  endif

; get rgb values and set one of the indexes to gray 
TVLCT, red, green, blue, /GET
red[7]=186  ; choose index after 6th to preserve black axes, ticks, and text          
green[7]=186
blue[7]=186
TVLCT, red, green, blue

get_data, tvar, data=d, dlimits=dl, limits=l 

if is_struct(d) then begin
   dim = size(d.y, /dimen)
   ; find nans and set to a numeric value - if minzlog is available
   ; use that (TO DO: need better method for determining what value to set NaN to)
   idx_nan = where(~finite(d.y))
   nan_arr=reform(d.y, dim[0]*dim[1])
   if is_struct(l) && is_array(l.yrange) then begin
      if ~undefined (l.minzlog) then nan_arr[idx_nan]=l.minzlog $
         else nan_arr[idx_nan]=(l.yrange[0])/100.
   endif else begin
      if is_struct(dl) && is_array(dl.yrange) then nan_arr[idx_nan]=(dl.yrange[0])/100. $
         else nan_arr[idx_nan] = 0.01
   endelse

   ;create temporary tplot var to preserve original tplot var values
   tempd=d
   tempd.y=reform(nan_arr, dim[0], dim[1])
   store_data, tvar+'_temp', data=tempd, dlimits=dl, limits=l

   options, tvar+'_temp', subtitle='(Gray = NaN)' 
   tplot, tvar+'_temp'    
   
endif else begin

    dprint, 'There is no data in tplot var ' + tvar  

endelse

end
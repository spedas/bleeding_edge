;
;pro  mvn_lpw_prd_w_n_find,variable,data_out=data_out
;
;This routine takes Pas or Act spectra and calculates the density from identified plasma frequency
;The tplot variables should already be loaded before running this
;(e.g. tplot_restore, filename='hsbm_spec_anc_11-04-14.tplot')
;
;INPUTS:
; - variable='mvn_lpw_spec_hf_pas' or 'mvn_lpw_spec_hf_act'
;
;EXAMPLE:
;  mvn_lpw_prd_w_n_find, 'mvn_lpw_spec_hf_pas',data_out=density
;  mvn_lpw_prd_w_n_find, variable,data_out=density
;
;CREATED BY:   Tess McEnulty  November 2014
;FILE:         mvn_lpw_prd_w_n_find_tm.pro
;VERSION:      1.0
;LAST MODIFICATION:
; 2014-12-09 T. McEnulty - added dv for lower density error bar and added a flag
; 2014-12-10 T. McEnulty - modified to take in either ACT or PAS backround
; 2014-12-12 T. McEnulty - modified to read in text file to get background and frequency bin edges
; 2014-12-17 T. McEnulty - modified to use a default cal file if it isn't saved in dlimit
; 2015-01-08 T. McEnulty and L. Andersson - modified to use the frequency bin info from data.dv rather than bringing in the cal file

pro mvn_lpw_prd_w_n_find,variable,data_out=data_out

  ;---------------------------------------------------------------------------------------------------
  ; get bin edges and background values (later when use spec2 will already have background removed)
  ;---------------------------------------------------------------------------------------------------

  ;get data for hf_spec
  get_data,variable,data=data,limit=limit,dlimit=dlimit ;variables are passed from 'mvn_lpw_prd_w_n.pro', **after fixing the calibration in the spectra file use spec2 'mvn_lpw_spec2_hf_act','mvn_lpw_spec2_hf_pas'


  dv_test = data.dv(1,*)   ;  (f_high-f_low)/2 ;get the low and high frequency bins
  power   = data.y    ;to save background subtracted power into

  ;---------------------------------------------------------------------------------------------------
  ; cut off at a certain low power value
  ;---------------------------------------------------------------------------------------------------
  ;      power_log=alog10(power)
  ;      power_log[where(power_log lt -13)]='NaN'

  ;---------------------------------------------------------------------------------------------------
  ;create variables to save data in
  ;---------------------------------------------------------------------------------------------------
  array_length=n_elements(data.x)
  n       = fltarr(array_length) ;creating an array to save the density output
  i       = indgen(array_length) ; array with the values as the indices of data2
  k       = fltarr(array_length)
  freq    = fltarr(array_length)
  dfreq   = fltarr(array_length)
  data_y  = fltarr(array_length)
  data_dy = fltarr(array_length)
  data_dv = fltarr(array_length)
  flag    = fltarr(array_length)

  ;---------------------------------------------------------------------------------------------------
  ;find peak power at each time step and resulting frequency and density
  ;---------------------------------------------------------------------------------------------------
  for p=0,array_length-1 do begin
    pmax = max(power[p,2:126], /NaN, x) ;value of maximum power
    if pmax GT 1e-9 and total(power[p,126:127],/nan) LT 1e-12  then k[p]=x+2      else k[p]=0 ;saving the index of the maximum power point (to later figure out what the frequency was there)
    ;for now flagging all identified points as 0.8, but will have to think about how to update this as a measure of how well we could identify the peak frequency
    if total(dlimit.cal_y_const2  EQ x) GT 0                    then flag[p]=50.  ELSE  flag[p]=80.   ; this is the 'instrument' lines/frequencies

    if pmax GT 1e-14 then print, p,k[p],pmax, total(power[p,126:127],/nan)

  endfor

  ;---------------------------------------------------------------------------------------------------
  ;save the frequencies at each power peak and calculating density and error bars
  ;---------------------------------------------------------------------------------------------------

  freq[i]    = data.v[i,k[i]] ;saving the frequency of the max power at each time in data2
  dfreq[i]   = dv_test[0,k[i]] ;saving the frequency bin size at each peak frequency identified
  larger_err = where(flag EQ 50,n_larger_err)
  If n_larger_err GT 0 then dfreq[larger_err]=2.*dfreq[larger_err]   ; double the error on the 'instrument' lines/frequencies
  data_y     = (freq/8980)^2 ;calculating the density at each time using the frequency of max power
  data_dy    = ((freq+dfreq)/8980)^2-data_y  ;the upper density error bar (density from high frequency bin edge-the density at the center)
  data_dv    = data_y-((freq-dfreq)/8980)^2 ;the lower density error bar (density at center -density at low frequency bin edge)
  flag[i]    = 70.

  ;---------------------------------------------------------------------------------------------------
  ;remove data where density is below a certain value (so left with only where there was a good identification)
  ;---------------------------------------------------------------------------------------------------

  n_not_found          = where(data_y LT 5)
  data_y[n_not_found]  = 'NaN'
  data_dy[n_not_found] = 'NaN'
  data_dv[n_not_found] = 'NaN'
  flag[n_not_found]    = 0


  print, 'created structure data_out with time, density, and the upper bound of density dy, and lower bound dv'
  data_out =  create_struct( 'x', data.x, 'y', data_y,'dy', data_dy,'dv', data_dv, 'flag',flag)

  store_data,'mvn_lpw_spec2_hf_pas_n',data={x:data.x,y:data_y,dy:data_y*0.25}
  options,'mvn_lpw_spec2_hf_pas_n',yrange=[10,2e5]
  options,'mvn_lpw_spec2_hf_pas_n',ytitle='Ne_w_pas'
  options,'mvn_lpw_spec2_hf_pas_n',ylog=1


end
;+
;
; CREATED BY MOKA: 2017-01-28
; 
;#1 removes un-needed fields from struct to increase efficiency
;#2 Reforms into 1D array (angle*energy) for making easier to calculate pitch angle distrib.
;#3 copy data and zero inactive bins to ensure areas with no data are represented as NaN
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2018-04-03 15:14:57 -0700 (Tue, 03 Apr 2018) $
;$LastChangedRevision: 24992 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/particles/moka/moka_mms_clean_data.pro $
;-

PRO moka_mms_clean_data, data_in, output=output,units=units,disterr=disterr_in
  compile_opt idl2
  
  ;------------
  ; UNITS
  ;------------
  mms_convert_flux_units,data_in,units=units,output=data
  mms_convert_flux_units,data_in,units='df_km', output=data_psd
  
  ;-----------
  ; DIMENSION
  ;-----------
  dims = dimen(data.data)
  imax = dims[0]*dims[1]*dims[2]

  ;-----------
  ; DENERGY
  ;-----------
  energy_tmp = reform(data.energy,dims[0],dims[1]*dims[2])
  de = energy_tmp-shift(energy_tmp,1,0)
  denergy_tmp=shift((de+shift(de,1,0))/2.,-1)
  denergy_tmp[0,*] = de[1,*] ;just have to make a guess at the edges(bottom edge)
  denergy_tmp[dims[0]-1,*] = de[dims[0]-1,*] ;just have to make a guess at the edges(top edge)
  

  
  ;-----------
  ; ERROR
  ;-----------
  psd  = reform(data_psd.data,imax)
  if undefined(disterr_in) then begin
    err = fltarr(imax)
    cnt = fltarr(imax)
  endif else begin
    mms_convert_flux_units,disterr_in,units='df_km',output=data_err
    err = reform(data_err.data,imax)
    cnt = (psd/err)^2; actual counts recovered
  endelse
  
  ;-----------
  ; NaN
  ;-----------
  dat = reform(data.data,imax)
  bin = reform(data.bins,imax)
  idx = where(~bin,nd) 
  if nd gt 0 then begin
    dat[idx] = 0.
    psd[idx] = 0.
    err[idx] = 0.
    cnt[idx] = 0.
  endif
  
  idx = where(~finite(cnt), ct)
  if ct gt 0 then begin
    dat[idx] = 0.
    psd[idx] = 0.
    err[idx] = 0.
    cnt[idx] = 0.
  endif
  ;-----------
  ; ENERGY FILTER
  ;-----------
  energy = reform(energy_tmp,imax)
;  idx = where(energy lt 200., ct)
;  if ct gt 0 then begin
;    dat[idx] = !VALUES.F_NAN
;    psd[idx] = !VALUES.F_NAN
;    err[idx] = !VALUES.F_NAN
;    cnt[idx] = !VALUES.F_NAN
;  endif

  ;-----------
  ; REFORM
  ;-----------
  output= {  $
    time: data.time, $
    end_time:data.end_time, $
    charge:data.charge, $
    mass:data.mass,$
    magf:[0.,0.,0.],$
    sc_pot:0.,$
    scaling:fltarr(imax)+1,$
    units:units,$
    data_dat:dat, $
    data_psd:psd, $
    data_err:err, $
    data_cnt:cnt, $
    bins    :bin, $
    energy: energy, $
    denergy: reform(denergy_tmp,imax), $ ;placeholder
    phi:reform(data.phi,imax), $
    dphi:reform(data.dphi,imax), $
    theta:reform(data.theta,imax), $
    dtheta:reform(data.dtheta,imax), $
    pa:fltarr(imax) $
  }
  
END

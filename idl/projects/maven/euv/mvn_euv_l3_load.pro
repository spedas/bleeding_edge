;+
; NAME: mvn_euv_l3_load
; SYNTAX: 
;       mvn_euv_l3_load,/daily
;       or
;       mvn_euv_l3_load,/minute
; PURPOSE:
;       Load procedure for the EUV L3 (FISM) daily or minute data
; KEYWORDS: daily, minute, ionization_frequency
;
;   Daily:
;         loads flare-subtracted data for each day
;   Minute:
;         loads data with one minute cadence
;   ionization_frequency:
;         If set to any nonzero value, calculates ionization
;         frequencies for CO2, O2, O, CO, N2, Ar according to the
;         photoionization cross-sections from the SwRI database:
;         http://phidrates.space.swri.edu/ This variable also returns
;         a data structure containing all the ionization frequencies
;   
; HISTORY:
; VERSION: 
;  $LastChangedBy: ali $
;  $LastChangedDate: 2017-11-06 12:04:57 -0800 (Mon, 06 Nov 2017) $
;  $LastChangedRevision: 24264 $
;  $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/euv/mvn_euv_l3_load.pro $
;CREATED BY:  ali 20160401
;FILE: mvn_euv_l3_load.pro
;-

pro mvn_euv_l3_load,trange=trange,daily=daily,minute=minute,vr=vr,tplot=tplot,$
  ionization_frequency=ionization_frequency,get_support_data=get_support_data,verbose=verbose
  
;  L3_fileformat='maven/data/sci/euv/l3/YYYY/MM/mvn_euv_l3_daily_YYYYMMDD_v??_r??.cdf'
;  L3_fileformat='maven/data/sci/euv/l3/YYYY/MM/mvn_euv_l3_minute_YYYYMMDD_v??_r??.cdf'
  if keyword_set(daily) then cadence='daily' else cadence='minute'
  if ~keyword_set(vr) then vr='v??_r??'
  if ~keyword_set(verbose) then verbose=0

  L3_fileformat='maven/data/sci/euv/l3/YYYY/MM/mvn_euv_l3_'+cadence+'_YYYYMMDD_'+vr+'.cdf'
  files=mvn_pfp_file_retrieve(L3_fileformat,trange=trange,/daily_names,/valid_only)
  
  if files[0] eq '' then begin
    dprint,dlevel=2,'No EUVM L3 (FISM) files were found for the selected time range.'
    return
  endif
  
  cdf2tplot,files,prefix='mvn_euv_l3_'+cadence+'_',verbose=verbose,get_support_data=get_support_data
  get_data,'mvn_euv_l3_'+cadence+'_y',data=fismdata; FISM Irradiances
  store_data,'mvn_euv_l3_'+cadence+'_y',/delete,verbose=verbose
  store_data,'mvn_euv_l3_'+cadence,data={x:fismdata.x,y:fismdata.y,v:reform(fismdata.v[0,*])}, $
    dlimits={ylog:0,zlog:1,spec:1,ytitle:'Wavelength!C(nm)',ztitle:'FISM Irradiance!C(W/m2/nm)'}
  
  if keyword_set(tplot) then tplot,'mvn_euv_l3_'+cadence
  if keyword_set (ionization_frequency) then ionization_frequency=mvn_euv_ionization(fismdata)

end

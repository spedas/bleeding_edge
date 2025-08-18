;+
;FUNCTION:   get_pl(t)
;INPUT:
;    t: double,  seconds since 1970. If this time is a vector then the
;	routine will get all samples in between the two times in the 
;	vector
;KEYWORDS:
;	advance:	advance to the next data point
;	index:		select data by sample index instead of by time.
;	times:		if non-zero, return and array of data times 
;			corresponding to data samples.
;PURPOSE:   returns a 3d structure containing all data pertinent to a single
;  pesa low 3d sample.  See "3D_STRUCTURE" for a more complete 
;  description of the structure.
;
;CREATED BY:	Davin Larson
;LAST MODIFICATION:  @(#)get_pl.pro	1.24 99/04/27
;
;NOTES: The procedure "load_3dp_data" must be 
;	called first.
;-

function get_pl,t,add, times=tms, index=idx  ;, advance = adv
@wind_com.pro

dat = { pl_struct, $
   PROJECT_NAME:   'Wind 3D Plasma', $
   DATA_NAME:      'Pesa Low', $
   UNITS_NAME:     'Counts', $
   UNITS_PROCEDURE:'convert_esa_units', $
   TIME      :     0.d, $
   END_TIME  :     0.d, $
   TRANGE    :     [0.d,0.d], $
   INTEG_T   :     0.d, $
   DELTA_T   :     0.d, $
   MASS      :     0.d, $
;   CHARGE    :     1.d, $
   GEOMFACTOR:     0.d, $
   INDEX     :     0l, $
   VALID     :     0, $
   SPIN      :     0l, $
   NBINS     :     25, $
   NENERGY   :     14, $
   DACCODES  :     intarr(4,14),  $
   VOLTS     :     fltarr(4,14),  $
   DATA      :     fltarr(14, 25), $
   energy    :     fltarr(14, 25), $
   denergy   :     fltarr(14, 25), $
   phi: fltarr(14, 25), $
   dphi: fltarr(14, 25), $
   theta: fltarr(14, 25), $
   dtheta: fltarr(14, 25), $
   bins      :     replicate(1b,14,25), $
   dt        :     fltarr(14,25), $
   gf        :     fltarr(14,25), $
   bkgrate   :     fltarr(14,25), $
   deadtime  :     fltarr(14,25), $
   dvolume   :     fltarr(14,25), $
   ddata     :     replicate(!values.f_nan,14,25),$
   magf      :     replicate(!values.f_nan,3), $
   sc_pot    :	   0.,$
   p_shift   :     0b,$
   t_shift   :     0b,$
   e_shift   :     0b,$
   domega: fltarr(25) $

;   ENERGY    :     fltarr(14, 25), $
;   THETA     :     fltarr(14, 25), $
;   PHI       :     fltarr(14, 25), $
;   MAP       :     intarr(5, 5), $
;   GEOM      :     fltarr(25), $
;   DENERGY   :     fltarr(14, 25), $
;   DTHETA    :     fltarr(25), $
;   DPHI      :     fltarr(25), $
;   DOMEGA    :     fltarr(25), $
;   EFF       :     fltarr(14), $
}

size = n_tags(dat,/length)
if (n_elements(idx) eq 0) and (n_elements(t) eq 0) and (not keyword_set(adv)) $
	and (not keyword_set(tms)) then ctime,t
if keyword_set(adv) then a=adv else a=0
if n_elements(idx) eq 0 then i=-1 else i=idx
if n_elements(t)   eq 0 then t=0.d

options = long([size,a,i])

if n_elements(wind_lib) eq 0 then begin
  print, 'You must first load the data'
  return,0
endif

; get times if requested
if keyword_set(tms) then begin
   num = call_external(wind_lib,'pl5x5_to_idl')
   options[0] = num
print, num,' Pesa low time samples'
   times = dblarr(num)
   ok = call_external(wind_lib,'pl5x5_to_idl',options,times)
   return,times
endif

time = gettime(t)
if (n_elements(time) eq 1) then time=[time,time]
retdat = dat
q = 0
oldtime = dat.time
integ = n_elements(t) ge 2
repeat begin
   ok = call_external(wind_lib,'pl5x5_to_idl',options,time,dat)
   dat.end_time = dat.time + dat.integ_t
   if retdat.valid eq 0 then retdat = dat   $
   else if dat.time ge oldtime and dat.valid eq 1 then begin
           retdat.data = dat.data +  retdat.data
           retdat.dt   = dat.dt   +  retdat.dt
           retdat.delta_t = dat.delta_t + retdat.delta_t
           retdat.integ_t = dat.integ_t + retdat.integ_t
           retdat.end_time = dat.end_time
           oldtime = dat.time
           q = dat.end_time gt time(1)
   endif else if dat.valid eq 1 then q = 1
   options[2] = dat.index+1
   if (time(1) eq time(0)) then q=1
endrep until q

retdat.trange = [retdat.time,retdat.end_time]

str_element,retdat,'CHARGE',1d,/add

retdat.mass = 1836*5.6856591e-6             ; mass eV/(km/sec)^2
retdat.geomfactor = 1.62e-4/180.*5.625        
if n_params() gt 1 then add_all,retdat,add
@get_pl_extra.pro
return,retdat
end



;+
;NAME:
; thm_part_dist
;PURPOSE:
; wrapper function around the different routines called 'get_p???'
; used for ESA particle data and 'thm_sst_p???' routines that extract
; SST data.
; 
; This is a working version for development of SST calibrations.
;INPUT:
; format = a string denoting the data that is desired: options are:
;          'tha_peif': Full Esa mode data, ions, probe A
;          'tha_peef': Full Esa mode data, electrons, probe A
;          'tha_peir': Reduced Esa mode data, ions, probe A
;          'tha_peer': Reduced Esa mode data, electrons, probe A
;          'tha_peir': Burst Esa mode data, ions, probe A
;          'tha_peer': Reduced Esa mode data, electrons, probe A
;          'tha_psif': Full Sst mode data, ions, probe A
;          'tha_psef': Full Sst mode data, electrons, probe A
;          'tha_psir': Reduced Sst mode data, ions, probe A
;          'tha_pser': Reduced Sst mode data, electrons, probe A
;         For other probes, just replace 'tha' with the appropriate
;         string, 'thb', 'thc', 'thd', 'the'
;          If this is not set, then the string is constructed from the
;          type and probe keywords
; time = an input time, if not passed in, then this routine will
;        attempt to get the time from plotted data, via ctime, unless
;        the index keyword is passed in (for SST) or
;        when start, en, advance, retreat, or index are passed in.
;KEYWORDS:
; type = 4 character string denoting the type of data that you need,
;        e.g., 'peif' for full mode esa data
; probe = the THEMIS probe, 'a','b','c','d','e'
; cursor = if set, then choose a time from the plot, using
;          ctime.pro. This overrides any input -- that is, the
;          variable that was used becomes the input variable and the
;          time obtained becomes the time of the data.
; index = an index for the data point that is to be returned
; start (ESA only) = if set, then get the first saved data point
; en (ESA only) = if set, get the last saved data point
; advance (ESA only) = if set, get the data point after the one that
;                      was gotten last
; retreat (ESA only) = if set, get the data point before the one that
;                      was gotten last
; times = if set, returns the time array for all the saved data points
;OUTPUT:
; dat = the '3d data structure' for the given data type: In general
;       this will be different for different data types, but there are
;       elements that are common to all, Here is a sample for tha_psif
;       data:
;   PROJECT_NAME    STRING    'THEMIS'
;   DATA_NAME       STRING    'SST Ion Full distribution'
;   UNITS_NAME      STRING    'Counts'
;   UNITS_PROCEDURE STRING    'thm_sst_convert_units'
;   TPLOTNAME       STRING    ''
;   TIME            DOUBLE       1.1837675e+09
;   END_TIME        DOUBLE       1.1837676e+09
;   TRANGE          DOUBLE    Array[2] ;;not always present
;   INDEX           LONG                 4
;   NBINS           LONG                64
;   NENERGY         LONG                16
;   MAGF            FLOAT     Array[3]
;   SC_POT          FLOAT           0.00000
;   MASS            FLOAT         0.0104390
;   CHARGE          FLOAT           0.00000
;   VALID           INT              1
;   MODE            INT              0
;   CNFG            INT            577
;   NSPINS          INT             64
;   DATA            FLOAT     Array[16, 64]
;   ENERGY          FLOAT     Array[16, 64]
;   THETA           FLOAT     Array[16, 64]
;   PHI             FLOAT     Array[16, 64]
;   DENERGY         FLOAT     Array[16, 64]
;   DTHETA          FLOAT     Array[16, 64]
;   DPHI            FLOAT     Array[16, 64]
;   BINS            INT       Array[16, 64]
;   GF              FLOAT     Array[16, 64]
;   INTEG_T         FLOAT     Array[16, 64]
;   DEADTIME        FLOAT     Array[16, 64]
;   GEOM_FACTOR     FLOAT          0.100000
;   ATTEN           INT             10
;   ;Following fields added for ESA compatibility purposes
;   DEAD            FLOAT          0.0
;   ;Following fields added for calibration purposes, values are read from a file
;   EFF             FLOAT     Array[16, 64] ;Detector Efficiency only 16x4 unique values
;   ENERGY_SCALE    FLOAT     Array[16, 64] ;Energy Scale Factors only 4 unique values
;   ENERGY_OFFSET   FLOAT     Array[16, 64] ;Energy Offsets only 4 unique values
;   GF              FLOAT     Array[16, 64] ;Gfactor corrections, only 4 unique values
;   
;   Note: True Geometric factor = GEOM_FACTOR*GF,  GF are corrections for aperture variations
;   
;
; NOTE: 1.  that the .time tag refers to the interval start time. The
; .trange tag gives the time range, and is not always present.
;       2.  For documentation on sun contamination correction keywords that
;       may be passed in through the _extra keyword please see:
;       thm_remove_sunpulse.pro or thm_crib_sst_contamination.pro
;
;
;$LastChangedBy: pcruce $
;$LastChangedDate: 2013-09-10 16:17:02 -0700 (Tue, 10 Sep 2013) $
;$LastChangedRevision: 13014 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/particles/SST/SST_cal_workdir/thm_part_dist2.pro $
;-

function thm_part_dist2,dformat,time,index=index,times=times,$
                      badbins2mask=badbins2mask,cursor=cursor,$
                      ft_ot=ft_ot,fto=fto,f_o=f_o,_extra=ex

; From this point on only a single SST 3d structure is returned

get_data,dformat+'_data',ptr=dptr
;data_cache,'th'+probe+'_sst_raw_data',data,/get

if ~is_struct(dptr) then begin
   dprint,dlevel=0,'No data loaded for ',dformat
   return,0
endif
mdistdat = *dptr.mdistdat

if strmid(dformat,5,1) ne 's' then begin
  dprint,dlevel=0,'Error incorrect data format'
  return,0
endif

if keyword_set(times) then begin
   if size(/type,mdistdat) eq 8  then  return, mdistdat.times else return,0
endif

if n_elements(index) eq 0 then begin
    if keyword_set(time) eq 0 then begin
        ctime,time
    endif
    index=round( interp(dindgen(n_elements(mdistdat.times)),mdistdat.times,time),/l64 ) 
endif

probe =  strlowcase(strmid(dformat,2,1))
species = strlowcase(strmid(dformat,6,1))
dtype = strlowcase(strmid(dformat,7,1))

if n_elements(index) ne 1 then begin
   dprint,'Getting multiple distributions'   ;   message,'time/index ranges not allowed yet',/info
   for i=index[0],index[1] do begin
        dat = thm_part_dist2(dformat,index=i,_extra=ex)
        sdat = sum3d(sdat,dat)
   endfor
   return,sdat
endif

if ~keyword_set( mdistdat.distptrs) then return,0

varn = mdistdat.varn[index]
distdat = *(mdistdat.distptrs[varn])

if ~ptr_valid(distdat.cal_params) || ~is_struct(*distdat.cal_params) then begin
  dprint,'ERROR: Calibration parameters not found',dlevel=0
  return,0
endif else begin
  param_struct = *distdat.cal_params
endelse

vind = mdistdat.index[index]
dist = *distdat.dat3d

if species eq 'i' then begin
  
  if dtype eq 'f' then begin
    dist.apid = '45a'x
  endif else if dtype eq 'r' then begin
    dist.apid = '45b'x
  endif else if dtype eq 'b' then begin
    dist.apid = '45c'x
  endif
  
endif else if species eq 'e' then begin
  
  if dtype eq 'f' then begin
    dist.apid = '45d'x
  endif else if dtype eq 'r' then begin
    dist.apid = '45e'x
  endif else if dtype eq 'b' then begin
    dist.apid = '45f'x
  endif
  
endif

;dprint,dlevel=3,'index=',index,'ind=',vind
dist.index = index

;Note spin model updates may be required here
spin_period = 3.

;shift input times from midpoint to start & end
dist.time = (*distdat.times)[vind]-spin_period/2.0
dist.end_time = (*distdat.times)[vind]+spin_period/2.0

dist.data= thm_part_decomp16((*distdat.data)[vind,*,*])
dist.magf = keyword_set(distdat.magf) ? (*distdat.magf)[vind,*] : !values.f_nan
dist.eclipse_dphi = (*distdat.edphi)[vind]
dist.cnfg= (*distdat.cnfg)[vind]
dist.atten = (*distdat.atten)[vind]
dist.nspins= (*distdat.nspins)[vind]
dist.units_name = 'Counts'
dist.valid=1

if species eq 'i' then begin
  dist.mass = 1836.*0.511e6/(2.9979e5)^2
endif else begin
  dist.mass = 0.511e6/(2.9979e5)^2
endelse

if dtype eq 'f' || dtype eq 'b' then begin

  ;read calibration parameters from file
  ;dist.time should be set at this point
  thm_sst_calib_params2,dist,param_struct,error=err,_extra=ex
  
  if err ne 0 || ~is_struct(dist) then begin
    dprint,'Error loading calibration parameters'
    return,0
  end
  
  ;Convert DAP bin units into eV
  thm_sst_energy_cal2,dist,ft_ot=ft_ot,fto=fto,f_o=f_o

endif

if keyword_set(badbins2mask) then begin
   bad_ang = badbins2mask
   if array_equal(badbins2mask, -1) then begin
      print,''
      dprint,'WARNING: BADBINS2MASK array is empty. No bins masked for ', $
                      'th'+probe,'_psef data.'
      print,''
   endif else begin
     if ndimen(dist.bins) ge 2 then begin
       dist.bins[*,bad_ang] = 0
     endif
   endelse
endif

;NOTE: this code is coupled with code in thm_pgs_clean_sst, if you change this, you'll probably have to change that
if dtype eq 'f' || dtype eq 'b' then begin

  ;these bins are fill
  if keyword_set(fto) then begin
    dist.channel = 'fto'
    dist.bins[0:14,*] =   0
  endif else if keyword_set(ft_ot) then begin
    if species eq 'i' then begin
      dist.channel = 'ot'
      dist.bins[0:11,*] = 0
      dist.bins[14:15,*] = 0
    endif else begin
      dist.bins[0:11,*] = 0
      dist.bins[15,*] = 0
      dist.channel = 'ft'
    endelse
  endif else if species eq 'i' then begin
    dist.channel = 'o'
    dist.bins[12:15,*] = 0
  endif else if keyword_set(f_o) then begin
    dist.bins[12:15,*] = 0
    dist.channel = 'f'
  endif else begin
    dist.bins[11:15,*] = 0
    
    ;merge f & ft distributions
    dist.data[8:10,*] = dist.data[12:14,*]
    dist.data[11:15,*] = 0
    dist.energy[8:10,*] = dist.energy[12:14,*]
    dist.energy[11:15,*] = max(dist.energy[0:10,*],/nan)
    dist.theta[8:10,*] = dist.theta[12:14,*]
    dist.phi[8:10,*] = dist.phi[12:14,*]
    dist.denergy[8:10,*] = dist.denergy[12:14,*]
    dist.denergy[11:15,*] = 0
    dist.dtheta[8:10,*] = dist.dtheta[12:14,*]
    dist.dphi[8:10,*] = dist.dphi[12:14,*]
    dist.gf[8:10,*] = dist.gf[12:14,*]
    dist.integ_t[8:10,*] = dist.integ_t[12:14,*]
    dist.deadtime[8:10,*] = dist.deadtime[12:14,*]
    dist.att[8:10,*] = dist.att[12:14,*]
    dist.eff[8:10,*] = dist.eff[12:14,*]
    dist.channel = 'f_ft'
  end
  ;removes sunpulse contamination if keywords set by end user
  dist = thm_sst_remove_sunpulse(badbins2mask=badbins2mask,dist,_extra=ex)
endif else begin
  if species eq 'i' then begin
    dist.channel = 'o'
  endif else begin
    dist.channel = 'f'
  endelse
endelse

return,dist

end

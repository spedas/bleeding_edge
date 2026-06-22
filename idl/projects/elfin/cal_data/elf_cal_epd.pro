;+
;PROCEDURE:
;   elf_cal_epd
;   
;PURPOSE:
;   Calibrate EPD raw data (counts/sector) into calibrated products.
;   Supported product types are:
;   - 'raw': raw data from epd packets
;   - 'cps': counts per second [counts/s] in 16 ADC pulse-height channels
;   - 'nflux': differential-directional number flux [#/cm^2-s-str-MeV] in 16 energy channels
;   - 'eflux': differential-directional energy flux [MeV/cm^2-s-str-MeV] in 16 energy channels
;
;KEYWORDS:
;   tplotname: name of tplot variable containing epd data. tvars include ela_pef, ela_pif, 
;              ela_pes, ela_pis (and same for elb)
;   trange:    time range of interest [starttime, endtime] with the format
;              ['YYYY-MM-DD','YYYY-MM-DD'] or to specify more or less than a day
;              ['YYYY-MM-DD/hh:mm:ss','YYYY-MM-DD/hh:mm:ss']
;   type: type of calibrated data cps, nflux, eflux
;   probe:  name of probe 'a' or 'b'
;   nodownload: set this flag to force routine to use local files 
;   deadtime_corr: Deprecated, but left in place to prevent older codes from crashing
;   apply_deadtime_corr: Flag to apply the paralyzable detector correction for count rate saturation
;   
;AUTHOR:
; 2026-02-23 (CW) added in the paralyzable detector correction for count rate saturation. deadtime_corr keyword is now deprecated; apply_deadtime_corr flag added to make use of it
; 2021-03-21 (VA) added capability for summed spins [normalizes cps etc. accordingly]
;                        also vectorized dt (accumulation time) division, avoiding do-loops (faster)
; 2021-02-19 (VA) fixed: dt to median over spin (does not falter if it includes gaps)
;                        overaccumulation now applied along with dt, prior to deadtime
;                        dead time correction now applied on total cps in sector
;                        revised maxcps to 1.25e5 +2% after review of all 2019 data
;                        eliminated <0 val's from deadtime cor. (set=0 & then nearest-neighbor interpol.)
; Version: xprmnt4_wIBO_collection
; Initially written by Colin Wilkins (colinwilkins@ucla.edu)
;-

PRO elf_cal_epd, tplotname=tplotname, trange=trange, type=type, probe=probe, $
    no_download=no_download, deadtime_corr=my_deadtime, nspinsinsum=my_nspinsinsum, apply_deadtime_corr=apply_deadtime_corr

  if undefined(probe) then probe = strmid(tplotname, 2, 1) else probe = probe
  sc='el'+probe

  if ~keyword_set(my_nspinsinsum) then my_nspinsinsum=1

  ; determine which epd instrument - ion or electron
  if strpos(tplotname, 'pef') GE 0 then begin
    instrument='epde'
    stype='pef'
  endif
  if strpos(tplotname, 'pif') GE 0 then begin
    instrument='epdi'
    stype='pif'
  endif
  if undefined(type) then type = 'eflux'

  ; get epd data and double check that it exists
  get_data, tplotname, data=d, dlimits=dl, limits=l
  if size(d,/type) NE 8 then begin
     dprint, dlevel = 1, 'There is no data in ' + tplotname
     return
  endif
  get_data, sc+'_'+stype+'_spinper', data=dspinper ; handled, clr THIS NEEDS TO BE MODIFIED TO INLCUDE MATCHING VARIABLE (A OR B, E OR I)
  get_data, sc+'_'+stype+'_sectnum', data=dsectnum ; handled, clr THIS NEEDS TO BE MODIFIED TO INLCUDE MATCHING VARIABLE (A OR B, E OR I)
  get_data, sc+'_'+stype+'_nsectors', data=dnsectors ; handled, clr THIS NEEDS TO BE MODIFIED TO INLCUDE MATCHING VARIABLE (A OR B, E OR I)

  ; check that time range variable is correctly set
  if (~undefined(trange) && n_elements(trange) eq 2) && (time_double(trange[1]) lt time_double(trange[0])) then begin
    dprint, dlevel = 0, 'Error, endtime is before starttime; trange should be: [starttime, endtime]'
    return
  endif
  if ~undefined(trange) && n_elements(trange) eq 2 $
    then tr = timerange(trange) $
  else tr = timerange()

  ; based on a probe, instrument (epde or epdi), and time range retrieve the data needed to 
  ; calibrate the epd instrument
  epd_cal = elf_get_epd_calibration(probe=probe, instrument=instrument, trange=trange, no_download=no_download)
  if size(epd_cal, /type) NE 8 then begin
     dprint, dlevel = 1, 'EPD calibration data was not retrieved. Unable to calibrate the data.'
     return
  endif
  
  if undefined(apply_deadtime_corr) then apply_deadtime_corr = !false
  ;
  ; setup variables
  num_samples = (size(d.x))[1]
  ebins = epd_cal.epd_ebins
  cal_ch_factors = epd_cal.epd_cal_ch_factors
  overint_factors = epd_cal.epd_overaccumulation_factors
  ebins_logmean = epd_cal.epd_ebins_logmean
  ;n_sectors=16. ; <--- this needs to be part of the CDF in the future, hardcoded for now!
  n_sectors=dnsectors.y
  ; useful quantities
  dE = 1.e-3*(ebins[1:15]-ebins[0:14]) ; in MeV
  dE = [dE,6.2] ; energy in units of MeV
  mytimesra=make_array(num_samples,/float,value=1.)
  n_energies=n_elements(ebins)
  mynrgyra=make_array(n_energies,/float,value=1.)
  ;

  ; New paralyzable detector dead time correction
  ; -- old deadtime_corr is now deprecated; warn if used
  
  if (keyword_set(my_deadtime) && (my_deadtime ne 0.)) then begin
    print,'Warning: deadtime_corr keyword is now deprecated! Please use /apply_deadtime_corr flag instead (see elf_cal_epd_old.pro for reference)'
  endif
  max_cps_para = 1.02/(2.4e-6) ; this is the paralyzable detector time constant from the 2.4us rise time of the preamp pulse-shaper, scaled by 1/e (from the maximum of w*e^{-w}) -- it a fixed property of the instrument, resulting in a max rate 1/e times lower
  dt= (my_nspinsinsum*(dspinper.y/n_sectors)*overint_factors[dsectnum.y]) # mynrgyra ; accumulation time
  ;
  ; Perform calibration
  if apply_deadtime_corr then begin
    print, 'Applying paralyzable detector model count rate correction'
  endif else begin
    print, 'No detector deadtime correction applied (use /apply_deadtime_corr to enable)'
  endelse
  Case type of
    'raw': store_data, tplotname, data={x:d.x, y:d.y, v:findgen(n_energies) }, dlimits=dl, limits=l
    'cps': begin
      d.y=d.y/dt ; this is cps now
      if (apply_deadtime_corr) then begin
        ; each energy channel's counts are summed downward from the top to compute the effective argument to lambert W function for that particular channel
        ; form the channel count summing matrix (16x16) for efficient vectorized adding
        ch_summing_mat = fltarr(16,16)
        for i = 0, 15, 1 do begin
          for j = 0, 15, 1 do begin
            if (j ge i) then ch_summing_mat[i,j]=1.
          endfor
        endfor
        d_y_cpy = d.y ; copy this to preserve 0-count channels
        ch_summing_mat = transpose(ch_summing_mat) ; transpose to follow tplot row/column ordering
        d.y = -1.*max_cps_para*lambertw(-1.*d.y#ch_summing_mat/max_cps_para) ; corrected cps via lambert W inversion on the real branch closest to 0
        d.y[where(d_y_cpy eq 0.)] = 0. ; if a channel had no counts, assume 0 counts is the true total (replacing lambert sum value)
      endif
      
      ineg=where(total(d.y,2,/NaN) lt 0,jneg) ; only reason for negatives is deadtime corr.
      if jneg gt 0 then begin
        d.y[ineg,*]=0
        d3interpol=d.y
        d3interpol[1:num_samples-2,*]=(d.y[0:num_samples-3,*]+d.y[2:num_samples-1,*])/2.
        d.y[ineg,*]=d3interpol[ineg,*]
      endif
      store_data, tplotname, data={x:d.x, y:d.y, v:ebins_logmean }, dlimits=dl, limits=l
    end
    'nflux': begin
      d.y=d.y/dt ; this is cps now
      if (apply_deadtime_corr) then begin
        ; each energy channel's counts are summed downward from the top to compute the effective argument to lambert W function for that particular channel
        ; form the channel count summing matrix (16x16) for efficient vectorized adding
        ch_summing_mat = fltarr(16,16)
        for i = 0, 15, 1 do begin
          for j = 0, 15, 1 do begin
            if (j ge i) then ch_summing_mat[i,j]=1.
          endfor
        endfor
        d_y_cpy = d.y ; copy this to preserve 0-count channels
        ch_summing_mat = transpose(ch_summing_mat) ; transpose to follow tplot row/column ordering
        d.y = -1.*max_cps_para*lambertw(-1.*d.y#ch_summing_mat/max_cps_para) ; corrected cps via lambert W inversion on the real branch closest to 0
        d.y[where(d_y_cpy eq 0.)] = 0. ; if a channel had no counts, assume 0 counts is the true total (replacing lambert sum value)
      endif
      d.y=d.y*(mytimesra#(cal_ch_factors/dE)) ; relative energy calibration and division by dE
      ineg=where(total(d.y,2,/NaN) lt 0,jneg) ; only reason for negatives is deadtime cor.
      if jneg gt 0 then begin
        d.y[ineg,*]=0
        d3interpol=d.y
        d3interpol[1:num_samples-2,*]=(d.y[0:num_samples-3,*]+d.y[2:num_samples-1,*])/2.
        d.y[ineg,*]=d3interpol[ineg,*]
      endif
      store_data, tplotname, data={x:d.x, y:d.y, v:ebins_logmean }, dlimits=dl, limits=l
    end
    'eflux': begin
      d.y=d.y/dt ; this is cps now
      if (apply_deadtime_corr) then begin
        ; each energy channel's counts are summed downward from the top to compute the effective argument to lambert W function for that particular channel
        ; form the channel count summing matrix (16x16) for efficient vectorized adding
        ch_summing_mat = fltarr(16,16)
        for i = 0, 15, 1 do begin
          for j = 0, 15, 1 do begin
            if (j ge i) then ch_summing_mat[i,j]=1.
          endfor
        endfor
        d_y_cpy = d.y ; copy this to preserve 0-count channels
        ch_summing_mat = transpose(ch_summing_mat) ; transpose to follow tplot row/column ordering
        d.y = -1.*max_cps_para*lambertw(-1.*d.y#ch_summing_mat/max_cps_para) ; corrected cps via lambert W inversion on the real branch closest to 0
        d.y[where(d_y_cpy eq 0.)] = 0. ; if a channel had no counts, assume 0 counts is the true total (replacing lambert sum value)
      endif
      d.y=d.y*(mytimesra#(ebins_logmean*cal_ch_factors/dE)) ; relative energy calibration and division by dE
      ineg=where(total(d.y,2,/NaN) lt 0,jneg) ; only reason for negatives is deadtime cor.
      if jneg gt 0 then begin
        d.y[ineg,*]=0
        d3interpol=d.y
        d3interpol[1:num_samples-2,*]=(d.y[0:num_samples-3,*]+d.y[2:num_samples-1,*])/2.
        d.y[ineg,*]=d3interpol[ineg,*]
      endif
      store_data, tplotname, data={x:d.x, y:d.y, v:ebins_logmean }, dlimits=dl, limits=l
      end
  Endcase
  
  
END

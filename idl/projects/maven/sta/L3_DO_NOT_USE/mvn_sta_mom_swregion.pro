;+
;Using just STATIC data, determine whether MAVEN is sampling the solar wind or not. Routine finds the peak eflux bin, and sums eflux in that and
;the two neighboring bins. If 85% of the eflux lies in these 3 bins, and the energy of the peak is > 200 eV, timestamp is flagged as 
;being in the solar wind. Good first order identification method, but not perfect. J. Halekas also has a region identifying routine that uses 
;SWIA and MAG data, which is probably more accurate.
;
;
;INPUTS:
;sta_apid: string: STATIC data product to use, eg 'c6', 'd0', etc. Used to grab correct STATIC common block
;
;
;
;EXAMPLE:
;timespan, '2018-11-27', 1.
;
;timespan, '2019-08-01', 1.
;mvn_sta_l2_load, sta_apid='c6'
;mvn_sta_l2_tplot
;mvn_sta_mom_swregion, sta_apid='c6'
;
;HISTORY:
;Original version written by CM Fowler (cmfowler@berkeley.edu) on 2019-12-04.
;
;.r /Users/cmfowler/IDL/STATIC_routines/mvn_sta_mom/mvn_sta_mom_swregion.pro  ;for testing, ignore
;-
;

pro mvn_sta_mom_swregion, sta_apid=sta_apid, success=success, trange=trange

proname = 'mvn_sta_mom_region'

case sta_apid of
  'c6' : begin
          common mvn_c6, get_ind_c6, all_dat_c6
          all_dat = all_dat_c6        
         end
  'd0' : begin
          common mvn_d0, get_ind_d0, all_dat_d0
          all_dat = all_dat_d0
         end
  'd1' : begin
          common mvn_d1, get_ind_d1, all_dat_d1
          all_dat = all_dat_d1        
         end
  'ce' : begin
          common mvn_ce, get_ind_ce, all_dat_ce
          all_dat = all_dat_ce         
         end
  'cf' : begin
          common mvn_cf, get_ind_cf, all_dat_cf
          all_dat = all_dat_cf        
         end
  'ca' : begin
          common mvn_ca, get_ind_ca, all_dat_ca
          all_dat = all_dat_ca        
         end
  'c8' : begin
          common mvn_c8, get_ind_c8, all_dat_c8
          all_dat = all_dat_c8         
         end
         
  else : begin
              print, proname, ": sta_apid must be one of c6, d0, d1, ce, cf, ca or c8."
              success=0
              return
         end
endcase

if keyword_set(trange) then begin
    iTIME = where(all_dat.time ge trange[0] and all_dat.end_time le trange[1], neleT)
endif else begin
    neleT = n_elements(all_dat.time)
    iTIME = findgen(neleT)
endelse

neleEN = all_dat.Nenergy  ;number of energy steps for this data product

;ARRAYS:
fracARR = fltarr(neleT)   ;fraction of energy flux in the peak
peakENARR = fltarr(neleT)  ;save energy of peak

for tt = 0l, neleT-1l do begin
  
    execSTR = 'datTMP = mvn_sta_get_'+sta_apid+'(index='+strtrim(long(iTIME[tt]),2)+')'  ;this is the executable below.

    res1 = execute(execSTR)  ;get STATIC data structure for this index tt
      
    ;Use eflux units: (correct units?)
    datTMP = conv_units(datTMP, 'eflux')
    
    ;Subtract background:
    ;TBW - needed?
    
    ;Extract just protons by removing unwanted masses:
    iRM = where(datTMP.mass_arr lt 0.5 or datTMP.mass_arr gt 1.5, niRM)  ;remove these indices
    if niRM gt 0 then begin
      datTMP.data[iRM] = 0.
      datTMP.cnts[iRM] = 0.
    endif
    
    ;Sum over mass range:
    datTMP2 = sum4m(datTMP)  ;don't need mass keywords as have already applied those to array above
    
    ;Sum eflux in peak+-1 energy bin. Calculate % this is of total df over all energies. Use 3 bins instead of just
    ;peak bin to reduce noise.
    m1 = max(datTMP2.data, imax, /nan)  ;find peak
    inds = [(imax-1l)>0, imax, (imax+1)<(neleEN-1l)]   ;make sure inds lie within STATIC energy table.
    
    fracARR[tt] = 100.*total(datTMP2.data[inds])/total(datTMP2.data,/nan)  ;% of total df.
    peakENARR[tt] = datTMP2.energy[imax]  ;energy of peak
endfor  ;tt

timesave = all_dat.time[iTIME] + ((all_dat.end_time[iTIME] - all_dat.time[iTIME])/2.)

store_data, 'fracp', data={x: timesave, y: fracARR}
  ylim, 'fracp', -5, 105

;Flags to pick out valid times:
;fraction > X%
;Peak energy bin > Z eV
SW_region = fltarr(neleT)  ;1 = sw, 0 = not sw
iSW = where(fracARR gt 85. and peakENARR gt 300., niSW)
if niSW gt 0 then SW_region[iSW] = 1

store_data, 'mvn_sta_sw_region', data={x: timesave, y: SW_region}
  ylim, 'mvn_sta_sw_region', -1, 2
  options, 'mvn_sta_sw_region', ytitle='STA SW!Cregion'

success=1

end




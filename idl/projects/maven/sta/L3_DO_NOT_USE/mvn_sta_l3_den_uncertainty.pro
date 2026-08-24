;+
;Calculate uncertainties in derived ion densities from STATIC data. Routine is hardcoded to deal with the 5 primary ion species:
;H+, He++, O+, O2+, CO2+.
;
;The routine uses information stored in tplot variables to determine which apids were used to generate each density point in time. This
;information is then used to obtain the full STATIC measurement data structure for that apid from the common block structures. The dat
;structure is then used to calculate the statistical uncertainty in the derived density, using Gwens routine for nbc or dn_4d().
;
;KEYWORDS:
;trange: double array [a,b] of start-stop UNIX times. If set, routine calculates uncertainty between these times. If not set, routine
;        calculates uncertainty for all available times.
;
;
;min_cnts: minimum counts required when calculating density. If not set, 10 is used as the default.
;
;colorindices: a data structure containg the color table indices for IDL for the color/element names:
; black, purple, brown, magenta, blue, cyan, green, yellow, orange, red, white. Use best guesses if the set color table doesn't
; have some of these specifically. Should work for ct 39, 43. For processing routine, this structure is created in mvn_sta_l3_den.pro.
;
;.r /Users/cmfowler/IDL/STATIC_routines/Processing_software/L3/mvn_sta_l3_den_uncertainty.pro  ;for CMF testing only
;-
;

pro mvn_sta_l3_den_uncertainty, trange=trange, min_cnts=min_cnts, colorindices=colorindices, print=print

@'qualcolors'

if size(min_cnts,/type) eq 0 then min_cnts=0.  ;set to zero, and flag low counts in the flagging routine

;Get common blocks:
common mvn_c6, get_ind_c6, all_dat_c6
common mvn_d0, get_ind_d0, all_dat_d0 
common mvn_d1, get_ind_d1, all_dat_d1

;Get tplot variables:
get_data, 'mvn_sta_light_den_method', data=ddm1  ;method for H+ and He++. 0=c6, 1=d0, 2=d1
get_data, 'mvn_sta_den_method', data=ddm2   ;method for O+, O2+, CO2+. 0=c6, 1 = O+ d0/d1., 2 = O2+ d0/d1, 3 = CO2+ d0/d1. 
get_data, 'mvn_sta_density_prelim_2', data=ddsta  ;density values
get_data, 'mvn_sta_apid_method', data=ddapidmethod  ;is c6, d0, d1 used?

;neleT is the number of timestamps to look at, iKPT is the corresponding indice array within the tplot variable to look at
if keyword_set(trange) then begin
  iKPT = where(ddm1.x ge trange[0] and ddm1.x le trange[1], neleT)
endif else begin
  neleT = n_elements(ddm1.x)
  iKPT = findgen(neleT)
endelse

;#######
;ARRAYS:
neleM = 5.  ;number of masses, hardcoded ***
den_uncert = fltarr(neleT,neleM)+!values.f_nan  ;default is no value (NaN)

mrange = mvn_sta_get_mrange()

for tt = 0l, neleT-1l do begin
    iTMP1 = iKPT[tt]  ;indice for this timestamp
    
    timeTMP = ddm1.x[iTMP1]  ;timestamp for this step
    
    ;########
    ;H+/He++:
    ;########
 
    ;c6:
    ;if ddm1.y[iTMP1] eq 0 then begin
    if ddapidmethod.y[iTMP1,0] eq 1 then begin
        iTMP2 = where(all_dat_c6.time le timeTMP and all_dat_c6.end_time ge timeTMP, niTMP2)
        
        if niTMP2 eq 1. then begin
            errdat1 = mvn_sta_get_c6(index=iTMP2[0]) ;get the dat structure for this timestep        
            result1 = dn_4d_f(errdat1, MASS=mrange.h, m_int=1., mincnt=min_cnts)  ;When attenuators = 0 (ie ddm1.y=0), can use dn_4d() on c6.
            result2 = dn_4d_f(errdat1, MASS=mrange.he, m_int=2., mincnt=min_cnts)          
            if finite(ddsta.y[iTMP1,0]) eq 1 then den_uncert[iTMP1,0] = result1  ;sqrt(N), where N is the density in cm^-3
            if finite(ddsta.y[iTMP1,1]) eq 1 then den_uncert[iTMP1,1] = result2  ;only add uncertainty if a finite density is reported
        endif     
    endif
    
    ;d0:
    ;if ddm1.y[iTMP1] eq 1 then begin
    if ddapidmethod.y[iTMP1,0] eq 2 then begin
        iTMP2 = where(all_dat_d0.time le timeTMP and all_dat_d0.end_time ge timeTMP, niTMP2)
        
        if niTMP2 eq 1 then begin
            errdat1 = mvn_sta_get_d0(index=iTMP2[0])
            result1 = dn_4d_f(errdat1, MASS=mrange.h, m_int=1., mincnt=min_cnts)  ;ENERGY=en,ERANGE=er,EBINS=ebins,ANGLE=an,ARANGE=ar,BINS=bins,
            result2 = dn_4d_f(errdat1, MASS=mrange.he, m_int=2., mincnt=min_cnts)
            if finite(ddsta.y[iTMP1,0]) eq 1 then den_uncert[iTMP1,0] = result1  ;stat uncertainty in density, cm^-3
            if finite(ddsta.y[iTMP1,1]) eq 1 then den_uncert[iTMP1,1] = result2
        endif   
    endif
    
    ;d1:
    ;if ddm1.y[iTMP1] eq 2 then begin
    if ddapidmethod.y[iTMP1,0] eq 3 then begin
        iTMP2 = where(all_dat_d1.time le timeTMP and all_dat_d1.end_time ge timeTMP, niTMP2)
  
        if niTMP2 eq 1 then begin
            errdat1 = mvn_sta_get_d1(index=iTMP2[0])
            result1 = dn_4d_f(errdat1, MASS=mrange.h, m_int=1., mincnt=min_cnts)  ;ENERGY=en,ERANGE=er,EBINS=ebins,ANGLE=an,ARANGE=ar,BINS=bins,
            result2 = dn_4d_f(errdat1, MASS=mrange.he, m_int=2., mincnt=min_cnts)
            if finite(ddsta.y[iTMP1,0]) eq 1 then den_uncert[iTMP1,0] = result1  ;stat uncertainty in density, cm^-3
            if finite(ddsta.y[iTMP1,1]) eq 1 then den_uncert[iTMP1,1] = result2
        endif 
    endif

    ;##############
    ;O+, O2+, CO2+:
    ;##############
    ;These must be done separately, as they tend to transition to beam-like (nbc) at different times, depending on mass.    
    nbcenergy = [0., 11.]   ;energy range in eV for nbc method - this is hard coded in mac_den_v2. 
    
    ;O+:
    ;dm2.y = 1 (beam)
    ;dm2.y = 0 (n_4d) and c6, d0, or d1
    ;Beam, using  c6:
    if ddm2.y[iTMP1,0] eq 1 then begin
      iTMP3 = where(all_dat_c6.time le timeTMP and all_dat_c6.end_time ge timeTMP, niTMP3)
      if niTMP3 eq 1 then begin
          errdat3 = mvn_sta_get_c6(index=iTMP3[0])
          result3 = mvn_sta_l3_nbc_staterr(errdat3, MASS=mrange.o, m_int=16., mincnt=min_cnts, energy=nbcenergy)
          if finite(ddsta.y[iTMP1,2]) eq 1 then den_uncert[iTMP1,2] = result3
      endif     
    endif
    
    ;Not beam, using n_4d:
    if (ddm2.y[iTMP1,0] eq 0) or (ddm2.y[iTMP1,0] eq 0.5) then begin
        ;c6:
        if ddapidmethod.y[iTMP1[0],2] eq 1 then begin
              iTMP3 = where(all_dat_c6.time le timeTMP and all_dat_c6.end_time ge timeTMP, niTMP3)          
              if niTMP3 eq 1 then begin
                  errdat3 = mvn_sta_get_c6(index=iTMP3[0])  ;get errdat3
                  result3 = dn_4d_f(errdat3, MASS=mrange.o, m_int=16., mincnt=min_cnts)
                  if finite(ddsta.y[iTMP1,2]) eq 1 then den_uncert[iTMP1,2] = result3
              endif
        endif
        
        ;d0:
        if ddapidmethod.y[iTMP1[0],2] eq 2 then begin
            iTMP3 = where(all_dat_d0.time le timeTMP and all_dat_d0.end_time ge timeTMP, niTMP3)
            if niTMP3 eq 1 then begin
                errdat3 = mvn_sta_get_d0(index=iTMP3[0])  ;get errdat3
                result3 = dn_4d_f(errdat3, MASS=mrange.o, m_int=16., mincnt=min_cnts)
                if finite(ddsta.y[iTMP1,2]) eq 1 then den_uncert[iTMP1,2] = result3
            endif
        endif
        
        ;d0:
        if ddapidmethod.y[iTMP1[0],2] eq 3 then begin
            iTMP3 = where(all_dat_d1.time le timeTMP and all_dat_d1.end_time ge timeTMP, niTMP3)
            if niTMP3 eq 1 then begin
                errdat3 = mvn_sta_get_d1(index=iTMP3[0])  ;get errdat3
                result3 = dn_4d_f(errdat3, MASS=mrange.o, m_int=16., mincnt=min_cnts)
                if finite(ddsta.y[iTMP1,2]) eq 1 then den_uncert[iTMP1,2] = result3
            endif
        endif
    endif
    
    ;O2+:
    ;Beam, using  c6:
    if ddm2.y[iTMP1,1] eq 2 then begin
        iTMP3 = where(all_dat_c6.time le timeTMP and all_dat_c6.end_time ge timeTMP, niTMP3)
        if niTMP3 eq 1 then begin
            errdat3 = mvn_sta_get_c6(index=iTMP3[0])
            result3 = mvn_sta_l3_nbc_staterr(errdat3, MASS=mrange.o2, m_int=32., mincnt=min_cnts, energy=nbcenergy)
            if finite(ddsta.y[iTMP1,3]) eq 1 then den_uncert[iTMP1,3] = result3
        endif
    endif

    ;Not beam, using n_4d:
    if (ddm2.y[iTMP1,1] eq 0) or (ddm2.y[iTMP1,1] eq 0.5) then begin
        ;c6:
        if ddapidmethod.y[iTMP1[0],3] eq 1 then begin
          iTMP3 = where(all_dat_c6.time le timeTMP and all_dat_c6.end_time ge timeTMP, niTMP3)
          if niTMP3 eq 1 then begin
            errdat3 = mvn_sta_get_c6(index=iTMP3[0])  ;get errdat3
            result3 = dn_4d_f(errdat3, MASS=mrange.o2, m_int=32., mincnt=min_cnts)
            if finite(ddsta.y[iTMP1,3]) eq 1 then den_uncert[iTMP1,3] = result3
          endif
        endif
  
        ;d0:
        if ddapidmethod.y[iTMP1[0],3] eq 2 then begin
          iTMP3 = where(all_dat_d0.time le timeTMP and all_dat_d0.end_time ge timeTMP, niTMP3)
          if niTMP3 eq 1 then begin
            errdat3 = mvn_sta_get_d0(index=iTMP3[0])  ;get errdat3
            result3 = dn_4d_f(errdat3, MASS=mrange.o2, m_int=32., mincnt=min_cnts)
            if finite(ddsta.y[iTMP1,3]) eq 1 then den_uncert[iTMP1,3] = result3
          endif
        endif
  
        ;d0:
        if ddapidmethod.y[iTMP1[0],3] eq 3 then begin
          iTMP3 = where(all_dat_d1.time le timeTMP and all_dat_d1.end_time ge timeTMP, niTMP3)
          if niTMP3 eq 1 then begin
            errdat3 = mvn_sta_get_d1(index=iTMP3[0])  ;get errdat3
            result3 = dn_4d_f(errdat3, MASS=mrange.o2, m_int=32., mincnt=min_cnts)
            if finite(ddsta.y[iTMP1,3]) eq 1 then den_uncert[iTMP1,3] = result3
          endif
        endif
    endif

    ;CO2+:
    ;Beam, using  c6:
    if ddm2.y[iTMP1,2] eq 3 then begin
        iTMP3 = where(all_dat_c6.time le timeTMP and all_dat_c6.end_time ge timeTMP, niTMP3)
        if niTMP3 eq 1 then begin
          errdat3 = mvn_sta_get_c6_co2(index=iTMP3[0])
          result3 = mvn_sta_l3_nbc_staterr(errdat3, MASS=mrange.co2, m_int=44., mincnt=min_cnts, energy=nbcenergy)
          if finite(ddsta.y[iTMP1,4]) eq 1 then den_uncert[iTMP1,4] = result3
        endif
    endif

    ;Not beam, using n_4d:
    if (ddm2.y[iTMP1,2] eq 0) or (ddm2.y[iTMP1,2] eq 0.5) then begin
        ;c6:
        if ddapidmethod.y[iTMP1[0],4] eq 1 then begin
          iTMP3 = where(all_dat_c6.time le timeTMP and all_dat_c6.end_time ge timeTMP, niTMP3)
          if niTMP3 eq 1 then begin
            errdat3 = mvn_sta_get_c6_co2(index=iTMP3[0])  ;get errdat3
            result3 = dn_4d_f(errdat3, MASS=mrange.co2, m_int=4., mincnt=min_cnts)
            if finite(ddsta.y[iTMP1,4]) eq 1 then den_uncert[iTMP1,4] = result3
          endif
        endif
  
        ;d0:
        if ddapidmethod.y[iTMP1[0],4] eq 2 then begin
          iTMP3 = where(all_dat_d0.time le timeTMP and all_dat_d0.end_time ge timeTMP, niTMP3)
          if niTMP3 eq 1 then begin
            ;### NOTE 01/28/22: CMF: mvn_sta_get_d0/d1 will not remove O2+ straggling correctly from CO2+ below. However, CO2+ densities derived
            ;from d0 and d1 are currently not used (because this straggling has not been characterized for all anodes - only anode 7 at periapsis), 
            ;this code is left in place here for now, in case this is fixed and needed in the future. 
            errdat3 = mvn_sta_get_d0(index=iTMP3[0])  ;get errdat3 
            result3 = dn_4d_f(errdat3, MASS=mrange.co2, m_int=44., mincnt=min_cnts)
            if finite(ddsta.y[iTMP1,4]) eq 1 then den_uncert[iTMP1,4] = result3
          endif
        endif
  
        ;d0:
        if ddapidmethod.y[iTMP1[0],4] eq 3 then begin
          iTMP3 = where(all_dat_d1.time le timeTMP and all_dat_d1.end_time ge timeTMP, niTMP3)
          if niTMP3 eq 1 then begin
            errdat3 = mvn_sta_get_d1(index=iTMP3[0])  ;get errdat3
            result3 = dn_4d_f(errdat3, MASS=mrange.co2, m_int=44., mincnt=min_cnts)
            if finite(ddsta.y[iTMP1,4]) eq 1 then den_uncert[iTMP1,4] = result3
          endif
        endif
    endif
  
endfor

;#################
;Checks: if there is a finite() density reported, but uncertainty=0, then pick uncertainty=100%. This can happen at very low count rates
;(<10 counts), where dn_4d() can only derive an uncertainty of zero. I'm not sure why this is - something to do with how the random
;counts are generated in dn_4d().
staden = ddsta.y[iKPT,*]  ;the densities within the requested time range

iFIX = where(finite(staden) eq 1 and den_uncert eq 0., niFIX)
if niFIX gt 0 then den_uncert[iFIX] = staden[iFIX]

;#################
;STORE INTO TPLOT:
tname = 'mvn_sta_den_uncert'
store_data, tname, data={x: ddm1.x[iKPT], y: den_uncert}
  options, tname, ylog=1
  options, tname, colors=[colorindices.black, colorindices.purple, colorindices.blue, colorindices.red, colorindices.green]
  options, tname, labflag=1
  options, tname, labels=['H+', 'He++', 'O+', 'O2+', 'CO2+']
  options, tname, ytitle='STA!Cuncert.!Cabs [cm!U-3!N]'

tname = 'mvn_sta_den_uncert_perc'
store_data, tname, data={x: ddm1.x[iKPT], y: 100.*den_uncert/staden}
  options, tname, ylog=1
  options, tname, colors=[colorindices.black, colorindices.purple, colorindices.blue, colorindices.red, colorindices.green]
  options, tname, labflag=1
  options, tname, labels=['H+', 'He++', 'O+', 'O2+', 'CO2+']
  options, tname, ytitle='STA!Cuncert.!C%'

end


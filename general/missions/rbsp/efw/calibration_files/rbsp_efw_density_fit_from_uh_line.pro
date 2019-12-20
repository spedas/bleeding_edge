;+
; NAME: rbsp_efw_density_fit_from_uh_line
; SYNTAX:
; PURPOSE: Return a tplot variable of density based on sc
; potential. Calibrations from the UH line are updated every few weeks
; The double-exponential fit is based on Escoubet 1997
; INPUT: sc_potential - name of tplot variable (string) that contains the quantity (V1+V2)/2
; OUTPUT: tplot variable of density
; KEYWORDS: sc -> 'a' or 'b'
;           newname -> name of output density tplot variable. Defaults
;                 to 'density'
;         dmin, dmax -> min and max allowable density values. Values
;            outside of these limits are set to NaN or setval if set
;         setval -> value to set density to if it is outside dmin,
;         dmax range
;
; HISTORY: Written by Aaron W Breneman (UMN), based on Scott
; Thaller's density calibrations to EMFISIS upper hybrid line
; VERSION:
;   $LastChangedBy: aaronbreneman $
;   $LastChangedDate: 2019-12-19 12:12:54 -0800 (Thu, 19 Dec 2019) $
;   $LastChangedRevision: 28128 $
;   $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/rbsp/efw/calibration_files/rbsp_efw_density_fit_from_uh_line.pro $
;-

pro rbsp_efw_density_fit_from_uh_line,sc_potential,sc,newname=newname,dmin=dmin,dmax=dmax,setval=setval


  cal = rbsp_get_density_calibration(sc)


  get_data,sc_potential,data=pot

  if is_struct(pot) then begin

     times = time_double(pot.x)
     v = pot.y
     den = fltarr(n_elements(pot.x))
     timesf = dblarr(n_elements(pot.x))

     for i=0,n_elements(cal.t0)-1 do begin

                                ;check for roaming date
                                ;(i.e. calibration that's
                                ;currently being used)
        if cal.t1[i] eq 'xxxx-xx-xx/xx:xx:xx' then cal.t1[i] = time_string(systime(/seconds))

        tst = where(times ge time_double(cal.t0[i]) and times lt time_double(cal.t1[i]))
        if tst[0] ne -1 then begin
           dentmp = cal.A[i]*exp(v*cal.B[i]) + cal.C[i]*exp(v*cal.D[i])
           den[tst] = dentmp[tst]
           timesf[tst] = times[tst]
        endif
     endfor



;--------------------------------------------------
;If set, remove density values below and above dmin and dmax
;--------------------------------------------------

     if keyword_set(dmin) then begin
        goo = where(den lt dmin)
        if goo[0] ne -1 then begin
           if ~keyword_set(setval) then den[goo] = !values.f_nan else den[goo] = setval
        endif
     endif
     if keyword_set(dmax) then begin
        goo = where(den gt dmax)
        if goo[0] ne -1 then begin
           if ~keyword_set(setval) then den[goo] = !values.f_nan else den[goo] = setval
        endif
     endif


     if keyword_set(newname) then store_data,newname,data={x:timesf,y:den} else store_data,'density',data={x:timesf,y:den}


  endif else print,'NO VALID TPLOT VARIABLE INPUTTED.....SKIPPING'

end

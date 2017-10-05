;+
;PROCEDURE:   mvn_swe_ql
;PURPOSE:
;  Creates SWEA TPLOT variables for QuickLook plots.
;
;USAGE:
;  mvn_swe_ql
;
;INPUTS:
;
;KEYWORDS:
;
;       NAMES:        TPLOT variables names created.
;                     Returns 0 if no variables are created.
;
;       PAD_E:        Energy for plotting PAD's.  Default = 280 eV.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2014-10-31 14:15:03 -0700 (Fri, 31 Oct 2014) $
; $LastChangedRevision: 16106 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_ql.pro $
;
;CREATED BY:    David L. Mitchell  04-30-13
;FILE: mvn_swe_ql.pro
;VERSION:   1.0
;-
pro mvn_swe_ql, names=names, pad_e=pad_e

  @mvn_swe_com

  if not keyword_set(pad_e) then pad_e = 280.
  
  names = ['']

; Energy Spectra (APID A4)

  if (size(a4,/type) eq 8) then begin
    if (size(mvn_swe_engy,/type) ne 8) then mvn_swe_makespec, units='eflux'

    x = mvn_swe_engy.time
    y = transpose(mvn_swe_engy.data)
    
    v = swe_swp[*,0]
    Emin = min(v, max=Emax)

    ename = 'swe_espec'
    store_data,ename,data={x:x, y:y, v:v}
    options,ename,'spec',1
    ylim,ename,Emin,Emax,1
    options,ename,'ytitle','Energy (eV)'
    options,ename,'yticks',0
    options,ename,'yminor',0
    zlim,ename,0,0,1
    options,ename,'y_no_interp',1
    options,ename,'x_no_interp',1
    
    names = [names, ename]
  endif

; Pitch angle distributions (APID A2)
;   This is a simplified, quick conversion.  See mvn_swe_getpad for the full
;   conversion.
  
  if (size(a2,/type) eq 8) then begin
    n_e = swe_ne[a2.group]               ; number of energy channels
    dt = 2D*swe_duty/(6D*double(n_e))    ; integration time for each energy/deflector bin
                                         ; each PAD bin accumulates for one deflector bin

    npkt = n_elements(a2)                ; number of packets
    x = dblarr(npkt)
    y = fltarr(npkt,16)
    for i=0L,(npkt-1L) do begin
      de = min(abs(swe_swp[0:(n_e[i]-1),a2[i].group] - pad_e),j)
      x[i] = a2[i].time + 1.95D*(double(j) + 0.5D)/double(n_e[i])  ; center time
      y[i,*] = transpose(a2[i].data[*,j])/dt[i]                    ; count rate
    endfor

; Correct for deadtime.

    yc = y/(1. - swe_dead*y)

; Create TPLOT variable

    v = findgen(16)                      ; no PA mapping yet, just bin numbers

    pad_s = strtrim(string(round(pad_e)),2)
    pname = 'swe_pad'
    store_data,pname,data={x:x, y:yc, v:v}
    options,pname,'ytitle',('E PAD (' + pad_s + ')')
    options,pname,'spec',1
    ylim,pname,0,0,0
    zlim,pname,0,0,1
    options,pname,'x_no_interp',1
    options,pname,'y_no_interp',1
    
    names = [names, pname]
  endif
  
  if (n_elements(names) gt 1) then names = names[1:*] else names = 0
  
  return

end

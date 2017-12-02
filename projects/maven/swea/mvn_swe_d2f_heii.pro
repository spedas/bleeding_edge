;+
;PROCEDURE:
;   mvn_swe_d2f_heii
;
;PURPOSE:
;   To calculate second derivatives of energy flux, used in routine 
;   'mvn_swe_sc_negpot_twodir_burst'
;
;INPUTS:
;   faway,ftwd,energy,ee
;
;KEYWORDS:
;
;   ERANGE
;
;
;OUTPUTS:
;   d2f_away,d2f_twd
;
; $LastChangedBy: xussui_lap $
; $LastChangedDate: 2017-12-01 11:52:37 -0800 (Fri, 01 Dec 2017) $
; $LastChangedRevision: 24384 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_d2f_heii.pro $
;
;CREATED BY:    Shaosui Xu  01-03-17
;-

Pro mvn_swe_d2f_heii,faway,ftwd,energy,d2f_away,d2f_twd,ee,erange=erange

    @mvn_swe_com
    
    if (n_elements(erange) lt 2) then begin
        emi = 3.5;10.
        ema = 30.
    endif else emi = min(float(erange), max=ema)

    e = energy

    ; Select energy channels

    endx = where((e[*] ge 0) and (e[*] le 60), ecnt)
    if (ecnt eq 0L) then begin
        print,"No data within energy range: ",emi,ema
        return
    endif
    e=e[endx]
    
    ; Oversample and smooth
    n_es = 4*ecnt
    emax = max(e, min=emin)
    dloge = (alog10(emax) - alog10(emin))/float(n_es - 1)
    ;ee = 10.^((replicate(1.,n_es) # alog10(emax)) - (findgen(n_es) # dloge))
    ee = 10^(alog10(emax)-findgen(n_es)*dloge)
    
    ;Away
    f = alog10(faway[endx])
    df = f
    d2f = f
    df[*] = !values.f_nan
    d2f[*] = !values.f_nan
    df[*] = deriv(double(f[*]))
    d2f[*] = deriv(double(df[*]))

    ; Oversample and smooth
    
    dfs = dblarr(n_es)
    dfs[*] = interpol(df[*],n_es)
;    dfs[*] = interpol(df[*],alog10(e),alog10(ee))
    d2fs = dblarr(n_es)
    d2fs[*] = interpol(d2f[*],n_es)
;    d2fs[*] = interpol(d2f[*],alog10(e),alog10(ee))

    ; Trim to the desired search range

    indx = where((ee[*] gt emi) and (ee[*] lt ema), n_e)
    ee = ee[indx]
    dfs = dfs[indx]
    d2fs = d2fs[indx]
    
    d2f_away = d2fs
    
    
    ;Towards
    f = alog10(ftwd[endx])
    df = f
    d2f = f
    df[*] = !values.f_nan
    d2f[*] = !values.f_nan
    df[*] = deriv(f[*])
    d2f[*] = deriv(df[*])

    ; Oversample and smooth

    dfs = dblarr(n_es)
    dfs[*] = interpol(df[*],n_es)
    d2fs = dblarr(n_es)
    d2fs[*] = interpol(d2f[*],n_es)

    ; Trim to the desired search range
    dfs = dfs[indx]
    d2fs = d2fs[indx]

    d2f_twd = d2fs
;stop
return
end    

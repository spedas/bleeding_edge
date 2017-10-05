;+
;PROCEDURE:
;   mvn_swe_calc_shape_arr
;
;PURPOSE:
;   Take an input spectrum and calculate the shape parameter
;
;AUTHOR:
;   Shaosui Xu
;
;CALLING SEQUENCE:
;   This procedure is called by mvn_swe_shape_pad
;
;
;INPUTS:
;
;   NPTS: Number of electron energy spectrum
;   
;   FIN: Input electron energy spectrum
;   
;   Energy: The energy array corresponding to the electron energy spectrum
;   
;   ERANGE: The energy range given to calculate the shape parameter
;   
;   HRESFLG: If set to 1, then using high energy resolution (burst) pad data
;            to calculate shape parameter. Usually, hresflg=0, survey pad data is used
;
;KEYWORDS: 
;   none
;
;OUTPUTS:
;   PAR: Calculated shape parameter
;
; $LastChangedBy: xussui_lap $
; $LastChangedDate: 2016-06-22 17:22:28 -0700 (Wed, 22 Jun 2016) $
; $LastChangedRevision: 21352 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_calc_shape_arr.pro $
;
;CREATED BY:    Shaosui Xu  06-22-16
;-

Pro mvn_swe_calc_shape_arr, npts, fin, energy, par, erange, hresflg
    ;spec, energy, par, erange

    compile_opt idl2

    @mvn_swe_com

    df_lres=[  0.0371289,    0.0179520,    0.0179520,    0.0356604,    0.0356604,     0.259604,$
        0.259604,     0.188697,     0.188697,   -0.0261332,   -0.0261332,    0.0849961, $
        0.0849961,     0.102494,     0.102494,    0.0595406,    0.0595406,    0.0591643, $
        0.0591643,    0.0459675 ,   0.0459675,    0.0296691,    0.0296691,     0.204077, $
        0.204077,     0.308229,     0.308229,    0.0962973,    0.0962973,     0.118876, $
        0.118876,     0.160658,     0.160658,    0.0387319,    0.0387319,   0.00507925, $
        0.00507925,    0.0866565,    0.0866565,     0.114288,     0.114288,    0.0612787, $
        0.0612787,    0.0209041,    0.0209041,   -0.0567795,   -0.0567795,    -0.124904, $
        -0.124904,    -0.123564,    -0.123564,     0.123564]
    df_hres=[  -0.00621939,     0.144627,  -0.00556159 ,   0.0933514,     0.101257,     0.186915,$
        0.479829,     0.401596,    0.0638178,   -0.0410685,   -0.0147899,    0.0405415, $
        0.120542,     0.129752,    0.0718670,    0.0592695,    0.0666794,    0.0681327, $
        0.0577553,    0.0493796,    0.0360952,    0.0234586,    0.0409702,     0.108591, $
        0.251231,     0.360782,     0.279757,     0.129745,    0.0748887,    0.0924677, $
        0.131181,     0.166274,     0.156800,    0.0917069,   -0.0123766,   -0.0285236, $
        0.0425429,    0.0720319,    0.0926143,     0.114485,     0.105823,    0.0707967,$
        0.0469701,    0.0305556,   0.00320172,   -0.0334262,   -0.0743820,    -0.107133, $
        -0.127032,    -0.128968,    -0.118429,    -0.120177]

    ;  df_iono = [-0.2280,  0.3775,  0.4587,  0.0689, -0.0861, -0.0140,  0.0622,  0.0958, $
    ;    0.1089,  0.1106,  0.0483,  0.0071,  0.0467,  0.0470,  0.0293,  0.0571, $
    ;    0.0638,  0.0452,  0.0865,  0.1886,  0.3264,  0.2966,  0.1527,  0.0861, $
    ;    0.0845,  0.1114,  0.1573,  0.1719,  0.1376,  0.0232, -0.0524,  0.0109, $
    ;    0.0525,  0.0743,  0.1065,  0.1232,  0.0928,  0.0521,  0.0392,  0.0192, $
    ;    -0.0191, -0.0712, -0.1264, -0.1769, -0.2073, -0.2146, -0.2251] ; Dave's template

    if hresflg eq 1 then df_iono = df_hres $
    else df_iono = df_lres

    if (n_elements(erange) lt 2) then begin
        emin = 0.
        emax = 100.
    endif else emin = min(float(erange), max=emax)

    e = energy

    ; Select energy channels

    n_e = n_elements(df_iono)
    indx = indgen(n_e) + (64 - n_e)
    e = e[indx]
    endx = where((e[*] ge emin) and (e[*] le emax), ecnt)
    if (ecnt eq 0L) then begin
        print,"No data within energy range: ",emin,emax
        return
    endif

    ; Take first derivative of log(eflux) w.r.t. log(E)
    f = alog10(fin[indx,*])
    ; Filter out bad spectra (such as hot electron voids)
    gndx = round(total(finite(f[endx,*]),1))
    gndx = where(gndx eq ecnt, ngud)
    if (ngud eq 0L) then begin
        print,"No good spectra!"
        return
    endif
    df = f
    df[*,*] = !values.f_nan
    for i=0L,(ngud-1L) do df[*,gndx[i]] = deriv(f[*,gndx[i]])

    ; Calculate electron energy shape parameter over [emin, emax]

    par = df - (df_iono # replicate(1., npts))
    par = total(abs(par[endx,*]),1)

    return
end
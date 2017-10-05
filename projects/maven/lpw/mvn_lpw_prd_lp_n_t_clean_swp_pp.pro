;+
;FUNCTION:   mvn_lpw_prd_lp_n_t_fit
; Clean up the sweep fit result. Take away uncertain data points.
;
;INPUTS:
;   PP  :  Analysed LP sweep data set structure.
;
;EXAMPLE:
; PP = mvn_lpw_prd_lp_n_t_clean_swp_pp(PP)
;
;CREATED BY:   Michiko Morooka  03-23-15
;FILE:         mvn_lpw_prd_lp_n_t_clean_swp_pp.pro
;VERSION:      1.2
;LAST MODIFICATION:
; 2015-03-23   M. Morooka
; 2015-03-26   M. Morooka (1.0)
; 2015-06-19   M. Morooka (1.1) Add ion side calcuration
; 2015-07-02   M. Morooka (1.2) derive_io2

;------- this_version_mvn_lpw_prd_lp_n_t_clean_swp_pp -------------------------
function this_version_mvn_lpw_prd_lp_n_t_clean_swp_pp
  ver = 1.2
  pdr_ver= 'version mvn_lpw_prd_lp_n_t_clean_swp_pp: ' + string(ver,format='(F4.1)')
  return, pdr_ver
end
;--------------------------- this_version_mvn_lpw_prd_lp_n_t_clean_swp_pp -----

;------- clearn_ver_0 ---------------------------------------------------------
function clearn_ver_0, swp_pp_org, addUsc=addUsc
  
  swp_pp=swp_pp_org
  print, 'Clean swp_pp flg: clearn_ver_0'

  ;----- Add dUsc info ----------------------------------------------
  if keyword_set(addUsc) then begin
    swp_pp.dUsc = swp_pp.dU0
    ind = where(finite(swp_pp.dU1))
    if ind(0) ne -1 then  swp_pp(ind).dUsc = swp_pp(ind).dU1
    print, 'dUsc info added'
    return, swp_pp
  endif
  if n_elements(where(finite(swp_pp.dUsc) eq 1)) eq 1 then begin
    swp_pp.dUsc = swp_pp.dU0
    ind = where(finite(swp_pp.dU1))
    if ind(0) ne -1 then  swp_pp(ind).dUsc = swp_pp(ind).dU1
    print, 'dUsc info added'
  endif

  ;----- extract time and probe -------------------------------------
  tinfo = strsplit(time_string(swp_pp(0).time),'-/:',/extract)
  date_in = long(tinfo(0))*10000 + long(tinfo(1))*100 + long(tinfo(2))
  prb = swp_pp(0).PROBE
  ;print, date_in

  ;----- Avoid these days -------------------------------------------
  if date_in le 20141020              then swp_pp(*).flg = -6
  ;if date_in ge 20150219 and prb eq 2 then swp_pp(*).flg = -6
  if date_in le 20141030 and prb eq 2 then swp_pp(*).flg = -6
  if date_in eq 20141115 and prb eq 1 then swp_pp(*).flg = -6
  if date_in eq 20141112 and prb eq 1 then swp_pp(*).flg = -6
  if date_in ge 20141217 and date_in le 20141223 and prb eq 2 then swp_pp(*).flg = -6
  if swp_pp(0).flg eq -6 then return, swp_pp

  ;----- Suspiciously two dIdV bump data --------------------------------------
  NotwoBMP = 1
  if NotwoBMP then begin
    ind = where(-swp_pp.Usc-swp_pp.U_zero gt 1.0)
    swp_pp(ind).flg = -8
  endif

  ;----- Avoid S/C charging event ---------------------------------------------
  sc_charge = 0
  if sc_charge then begin
    ind = where(swp_pp.Usc ge -4)
    swp_pp(ind).flg = -111
  endif

  return, swp_pp  

end
;----------------------------------------------------------- clearn_ver_0 -----

;------- clearn_ver_1 ---------------------------------------------------------
function clearn_ver_1, swp_pp_org

  swp_pp=swp_pp_org
  print, 'Clean swp_pp flg: clearn_ver_1'
  
  ;----- Define Usc for 'fitswp_SW_01' mode -----------------------------------
  ind = where(swp_pp.FIT_FUNCTION_NAME eq 'fitswp_SW_01')
  swp_pp(ind).Usc = swp_pp(ind).U0
  swp_pp(ind).dUsc = swp_pp(ind).dU0

  ;ind = where(swp_pp.FIT_FUNCTION_NAME eq 'fitswp_new_gaussian')

  ;----- Put flag if Te data points are too few -------------------------------    
  ind = where(swp_pp(ind).flg eq 13)
  swp_pp(ind).flg = -1 * swp_pp(ind).flg
  ind = where(swp_pp.Te le 0.01) & swp_pp(ind).flg = -1 & delvar, ind
  ind = where(swp_pp.Te eq 0.1)  & swp_pp(ind).flg = -1 & delvar, ind
  
  return, swp_pp
end
;----------------------------------------------------------- clearn_ver_1 -----

;------- derive_ion2 ----------------------------------------------------------
function derive_ion2, pp_org

  ;pp = define_Ufloat(pp_org)
  pp = pp_org

  ;----- Extract information ----------------------------
  M = pp.m2  & b = pp.b2
  RXA = pp.RXA     & if finite(RXA) ne 1 then RXA = 1
  Vsc = pp.Vsc*1e3 & if finite(Vsc) ne 1 then Vsc = 4e3
  ;----- get Ufloat assume that Ufloat sit around the dIdV max
  Ufloat = max([pp.U0,pp.U1,pp.U2],/nan)
  ;Ufloat = !values.F_NAN
  ;if finite(pp.Usc) then Ufloat   =  -pp.Usc else Ufloat = -pp.U_Imin
  if finite(Ufloat) ne 1 then begin
    Usortind = sort(pp.voltage) & U = pp.voltage(Usortind) & I = pp.I_ion(Usortind)
    ind = where(I eq 0.0) & ind=ind(0)
    Ufloat = -U(ind-1)
  endif
  pp.Usc = Ufloat

  ;if finite(pp.Usc) ne 1 then Ufloat   =  -pp.U2 $
  ;else                        Ufloat   =   pp.Usc
  ;if finite(Ufloat) ne 1 then Ufloat   =  -pp.U_didvmax
  ;-----            or                     around the Imin
  ;if finite(Ufloat) ne 1 then Ufloat   =  -pp.U_Imin
  Ufloat2   = -pp.U_Imin

  ;----- Constants --------------------------------------
  mH = 1.67262158e-27     ; Mass of Proton in [Kg]
  Z = 1.              ;charge [+/-] of current carrying species.
  kb = 1.3807e-23
  qe = 1.602176462e-19 ;Electron charge/[C]

  rp =  6.35e-3*0.5       ; Diameter of Langmuir Probe [m]
  lp =  0.4               ; Length of cylindrical Langmuir Probe [m]
  Ap =  !pi*6.35e-3*0.4   ; Area of probe surface [m^2]
  XA =  6.35e-3*0.4       ; Effective probe surface in [m^2], (lp*rp)

  ;----- Correct by angle -----
  b = b/RXA^2.0 & M = M/RXA^2.0

  M2 = M/b  ;----- (1/2)mVsc^2 -Ufloat

  mi = (2.0*qe*(M2-Ufloat)/(Vsc^2.0))              ;----- [kg]
  Ni = (sqrt(mi*b/(2*qe))/(Ap*qe) )                ;----- [m^-3]
  pp.mi = mi/mH                                    ;----- store in mass number
  pp.Ni = Ni *1e-6                                 ;----- store in [cm^-3]

  mi = (2.0*qe*(M2-Ufloat2)/(Vsc^2.0))             ;----- [kg]
  Ni = (sqrt(mi*b/(2*qe))/(Ap*qe) )                ;----- [m^-3]
  pp.mi2 = mi/mH                                   ;----- store in mass number
  pp.Ni2 = Ni *1e-6                                ;----- store in [cm^-3]

  return, pp

end
;------------------------------------------------------------ derive_ion2 -----

;------- mvn_lpw_prd_lp_n_t_clean_swp_pp --------------------------------------
function mvn_lpw_prd_lp_n_t_clean_swp_pp, swp_pp_org,$
                                       addUsc=addUsc, clean_ver_no=clean_ver_no

  ;----- Check keywords -------------------------------------------------------
  if not keyword_set(addUsc) then addUsc = 0
  
  ;----- Set cleaning version information -------------------------------------
  prd_ver_clnpp = this_version_mvn_lpw_prd_lp_n_t_clean_swp_pp()
  if not keyword_set(clean_ver_no) then $
          clean_ver_no = float(strmid(prd_ver_clnpp, strlen(prd_ver_clnpp)-3,3))
  prd_ver = strmid(prd_ver_clnpp,0,strlen(prd_ver_clnpp)-3) $
                                        + string(clean_ver_no,format='(F4.1)')

  ;----- Copy data ------------------------------------------------------------
  swp_pp=swp_pp_org
  
  if clean_ver_no lt 1.0 then swp_pp=clearn_ver_0(swp_pp,addUsc=addUsc) $
  else                        swp_pp=clearn_ver_1(swp_pp)
    
  ;----- These are common cleaning process ------------------------------------
  ;----- Put negative flg for SW analysis -------------------------------------
  noSW = 1
  if noSW then begin
    ind = where(swp_pp.FIT_FUNCTION_NAME eq 'fitswp_SW_01')
    swp_pp(ind).flg = -7
    delvar, ind
    ind = where(swp_pp.fit_function_name eq 'fitswp_SW_03')
    swp_pp(ind).flg = -7
    delvar, ind
    ;swp_pp(ind).Ne_tot = !values.F_NAN
    ;swp_pp(ind).Te     = !values.F_NAN
    ;swp_pp(ind).Usc    = swp_pp(ind).U0 
  endif
    
  ;----- Add ion/version info --------------------------------------------------
  for ii=0,n_elements(swp_pp)-1 do begin
    swp_pp(ii) = derive_ion2(swp_pp(ii))    ;----- Add ion information ----------
    swp_pp(ii).prd_ver = swp_pp(ii).prd_ver + ' # ' + prd_ver    
  endfor
       
  return, swp_pp
  
end
;---------------------------------------- mvn_lpw_prd_lp_n_t_clean_swp_pp -----


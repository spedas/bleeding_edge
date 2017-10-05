;+
;FUNCTION:   mvn_lpw_prd_lp_n_t_fit
; Sweep fitting function set for MAVEN/LPW
;
;INPUTS:
;   PP  :  LP sweep data set structure. (See  )
;   type:
;
;KEYWORDS:
;   win: use this keyword to see the every sweeep plot during the run
;
;EXAMPLE:
; mvn_lpw_prd_lp_n_t_fit, PP, 'l0'
;
;CREATED BY:   Michiko Morooka  10-21-14
;FILE:         mvn_lpw_prd_lp_n_t_fit.pro
;VERSION:      2.6
;LAST MODIFICATION:
; 2014-10-20   M. Morooka
; 2014-11-13   M. Morooka Update first version of fitting set.
; 2014-11-17   M. Morooka Bug fixed for the electron fitting limit define. (fitswp_10V_00)
;                         Outer region fitting fixed to two components. (fitswp_SW_02)
; 2014-11-24   M. Morooka add givenU define algorithm (fitswp_10V_00)
; 2014-12-19   Add two electron component fitting to the dense plasma resion. 
;               fitswp_SW_03, fitswp_10V_01
; 2015-01-31   Change fitting routine for the dense plasma resion. 
;               fitswp_10V_02_e
; 2015-02-02   Change fitting routine for the dense plasma resion. Two electron component fitting.
;               fitswp_10V_03_2e
; 2015-03-23   Minor changes for fitting routine. 
; 2015-04-16   dTe is added dTe (2.7)
; 2015-05-26   new gaussian fit (3.0)
; 2015-07-02   revise gaussian fit (3.1)
;-

;------- this_version_mvn_lpw_prd_lp_n_t_fit --------------
function this_version_mvn_lpw_prd_lp_n_t_fit
  ver = 3.1
  prd_ver= 'version mvn_lpw_prd_lp_n_t_fit: ' + string(ver,format='(F4.1)')
  return, prd_ver
end
;---------------- this_version_mvn_lpw_prd_lp_n_t_fit -----

;------- fit_ion_linear ---------------------------------------------------------------------------
function fit_ion_linear, voltage, current, U_lim=U_lim
  ; Process linear fitting to the negative voltage part [Umin, Umax]
  ; Returns a set of fitting coeeficients m (ofset) and b(gradient). [m,b]
  ; calcurate I = m + b*U to reconstrut the fitting
  
  if keyword_set(U_lim) eq 0 then U_lim = -5.0
  
  U = voltage & I = current
  if n_elements(U_lim) eq 1 then U_lim = [-80, U_lim]
  ind = where(U ge U_lim(0) AND U le U_lim(1))
  UL = U(ind) & IL = I(ind)
  
  ; ----- Apply Linear fitting -----
  coeff = linfit(UL,IL,yfit=u2)
  return, coeff ; coeff = [m,b]  
end
;----------------------------------------------------------------------------- fit_ion_linear -----

;------- myzero -----------------------------------------------------------------------------------
function myzero, voltage_org, current_org
  
  ; ignore NaN values
  val =  WHERE(~FINITE(current_org, /NAN))
  U = voltage_org(val) & I = current_org(val) & delvar, val
  if n_elements(I) le 3 then return, !values.F_nan
  I = smooth(I,3) 
  ; I = I(0:n_elements(I)-3)
  
  li = n_elements(I)
  lu = n_elements(U);
  U0=!values.F_nan;
  
  if li ne lu then begin & print, 'U and I need to be same length'                 & return, U0 & endif
  if li lt 8  then begin & print, 'Too short sweep..we assume longer than 8 values' & return, U0 & endif
  
  plt = where(I lt 0.0) & pgt = where(I gt 0.0)
  
  Dlt=transpose([[U(plt)],[I(plt)]]) ; Data curr lower than zero
  Dgt=transpose([[U(pgt)],[I(pgt)]]) ; Data curr higher than zero
  
  if n_elements(plt) lt 2 || n_elements(pgt) lt 2 then begin
    print, 'Warning, all data above or below zero!' & return, U0
  endif
  
  nrow = sort(Dlt(1,*))  & Dlt = Dlt(*,nrow) ; Sort by current
  Dlt = reverse(Dlt,2)
  
  ; Select atmost the 4 lowest curr. values and sort by bias
  ui = n_elements(Dlt(0,*))
  if ui gt 4 then ui=4  & Dlt = Dlt(*,0:ui-1)
  nrow = sort(Dlt(0,*)) & Dlt = Dlt(*,nrow)
  Dlt = reverse(Dlt,2)
  ; At this point the first row in Dlt is a data point with
  ; high probability to be close and to the left of the rightmost
  ; zero crossing..second value has lower probability and so on
  
  delvar, nrow, ui
  
  nrow = sort(Dgt(1,*))  & Dgt = Dgt(*,nrow) ; Sort by current
  
  ; Select atmost the 4 lowest curr. values and sort by bias
  ui = n_elements(Dgt(0,*))
  if ui gt 4 then ui=4 & Dgt = Dgt(*,0:ui-1)
  nrow = sort(Dgt(0,*)) & Dgt = Dgt(*,nrow)
  Dlt = reverse(Dgt,2)
  ; At this point the first row in Dlt is a data point with
  ; high probability to be close and to the right of the rightmost
  ; zero crossing..second value has lower probability and so on
  
  ; Use most probable points draw a line between them
  ; and return bias at zero current
  
  vp=Dgt(0,0)
  ip=Dgt(1,0)
  vn=Dlt(0,0)
  in=Dlt(1,0)
  
  U0=vp-ip*(vp-vn)/(ip-in);
  
  return, U0
end
;------------------------------------------------------------------------------------- myzero -----

;------- mvn_lpw_J_e_thermal_brace ----------------------------------------------------------------
;        input: U, P(Ufloat[V],Ne[cm^-3],Te[eV](,Bt))
function mvn_lpw_J_e_thermal_brace, U, P

  eV2K = 11604
  
  Ufloat = P[0]
  N      = P[1] * 1e6
  T      = P[2] * eV2K
  if n_elements(P) ge 4 then Bt = P[3] else Bt = 3.0/4.0 ;----- PVO number (for theoretical cylindrical, 0.5)
  ;if N eq 0.0 then return, 0.0
  
  m = 9.10938188e-31  ;Electron mass in [kg]
  ;V = 0               ;velocity of the body with respect to the plasma [km/s].
  Z = -1              ;charge [+/-] of current carrying species.
  rp = 6.35e-3/2.     ;Radius of Langmuir Probe [m]
  lp = 0.4            ;Length of cylindrical Langmuir Probe [m]
  A  = 2*!pi*rp*lp    ;Probe surface area for thermal electron
  
  j_thermal = make_array(size=size(U),value=!values.F_nan)
  U_pts = n_elements(U)
  kb = 1.3807e-23
  qe = 1.602176462e-19 ;Electron charge/[C]
  
  Vp = U+Ufloat
  
  ; Is the body moving with a velocity, V, with respect to the plasma ?
  ; Criteria set such that it is considered.
  ; important if V > 0.1 * V_th. But we assume V << V_th for electron here.
  ; -----------------------------------------------------------------
  X = ( qe / (kb*T) ) * Vp              ; --- Ratio of potential to thermal energy.
  Ip = A*N*qe*sqrt( T*kb/(2.0*!pi*m) )  ;----- Randum current -----  
  
  pos_ind = where( Vp ge 0 )
  neg_ind = where( Vp lt 0 )
  
  sq    = make_array(size=size(Vp), value=0, /double)
  erfv  = make_array(size=size(Vp), value=0, /double)
  
  sq(neg_ind) = sqrt( abs(-X(neg_ind)) );
  sq(pos_ind) = sqrt( abs(+X(pos_ind)) );
  erfv = erf( sq );
  
  
  ;----- RETARDING REGION -----
  j_thermal(neg_ind) = Ip *  exp(X(neg_ind))
  
  ;----- ACCELERATING REGION -----
  j_thermal(pos_ind) = Ip * (2./sqrt(!pi)) * (1.0 + X(pos_ind))^Bt
  
  return, j_thermal
  
end
;------------------------------------------------------------------- mvn_lpw_J_e_thermal_brace ----

;------- mvn_lpw_j_i_thermal_cyl_brace ------------------------------------------------------------
;        input: U, P(Ufloat,Ni,Ti,Vi,(mi,RXA))
function mvn_lpw_j_i_thermal_cyl_brace, U, P
  
 ; return, mvn_lpw_J_i_thermal(U, P)

  mH = 1.67262158e-27     ; Mass of Proton in [Kg]
  qe = 1.602176462e-19    ; Electron charge in [C]
  kb = 1.3807e-23
  eV2K = qe/kb ;11604
  
  Ufloat = P[0] ; floating potential
  Ni     = P[1] * 1e6  ; Ion density in m^-3 (effective)
  Ti     = P[2] * eV2K ;temperature[K]
  Vi     = P[3] * 1e3  ; Ion drift velocity [m/s]
  if n_elements(P) ge 5 then mi   = P[4] * mH   else   mi  = 32 * mH
  if n_elements(P) ge 6 then RXA  = P[5] else RXA = 1.0

  rp = 6.35e-3/2.     ;Radius of Langmuir Probe [m]
  lp = 0.4            ;Length of cylindrical Langmuir Probe [m]
  ;----- Cylindrical probe
  Ap     = 2*!pi*rp*lp;
  ;----- ellipsoid shape
  ;p = 1.6075
  ;lp=lp*1.2
  ;Ap = 2*!pi*(( rp^p*rp^p + rp^p*(0.5*lp)^p + rp^p*(0.5*lp)^p )/3.)^(1/p)
  
  Ap = Ap * RXA
  
  Vp = U+Ufloat ;----- normarized voltage -----
  pos_ind = where( Vp ge 0 ) ;----- for retarding region
  neg_ind = where( Vp lt 0 ) ;----- for accelerating region (RAM)

  Vp = abs(Vp/(Ti/eV2K))             ;----- bias voltage normarized by Ti -----
  s = sqrt(mi*Vi^2/(2.0*kb*Ti))      
  
  
  Ii0  = Ap*Ni*qe*sqrt( Ti*kb/(2.0*!pi*mi) )  ;----- Randum current -----
 ;X = ( qe / (mi*Vi^2/2 + kb*Ti) ) * Vp ; --- Ratio of potential to thermal energy.
  X = ( qe / (kb*Ti) ) * Vp              
  
  J_thi = dblarr(n_elements(Vp))
    
  ;----- Ion saturation current: Ram + thermal + potential effected ---
   J_thi(neg_ind) = -Ii0 * (2./sqrt(!dpi)) * sqrt( s^2.0 + 0.5 + Vp(neg_ind) )
  ;J_thi(neg_ind) = -Ii0 * (2./sqrt(!dpi)) * sqrt( s^2.0 + Vp(neg_ind) + 0.5*(s^2)/(Vp(neg_ind)+s^2) +Vp(neg_ind)/(Vp(neg_ind)+s^2)  )
 
  ;----- Ion retardent current -----
  j_thi(pos_ind) = -Ii0 * (2./sqrt(!pi)) * sqrt(s^2 - X(pos_ind))
  ;j_thi(pos_ind) = -Ii0 * exp(-X(pos_ind))  
  
  ind = where(finite(j_thi) ne 1) & j_thi(ind) = 0.0

  return, float(J_thi)
  
  ;j_thi(pos_ind) = -Ii0 * (2./sqrt(!pi)) * exp(-(sqrt(Vp(pos_ind))-s)^2)
  ;j_thi(pos_ind) = -2.0 * Ii0 * (2./sqrt(!pi)) * exp(-X(pos_ind))
  ;J_thi(pos_ind) = -Ii0 * (2./sqrt(!pi)) * ( s^2 + Vp(pos_ind) )^0.8 ; s>>V case
  
end
;-------------------------------------------------------------- mvn_lpw_j_i_thermal_cyl_brace -----

;------- mvn_lpw_j_i_thermal_sph_hoegy ------------------------------------------------------------
;        input: U, P(Ufloat,Ni,Ti,Vi,(mi,RXA))
function mvn_lpw_j_i_thermal_sph_hoegy, U, P

  eV2K = 11604
  mH = 1.67262158e-27     ; Mass of Proton in [Kg]
  qe = 1.602176462e-19    ; Electron charge in [C]
  kb = 1.3807e-23
  E0 = 8.854e-12
  
  Ufloat = P[0] ; floating potential
  Ni     = P[1] * 1e6  ; Ion density in m^-3 (effective)
  Ti     = P[2] * eV2K ;temperature[K]
  Vi     = P[3] * 1e3  ; Ion drift velocity [m/s]
  if n_elements(P) ge 5 then mi   = P[4] * mH   else   mi  = 32 * mH
  if n_elements(P) ge 6 then RXA  = P[5] else RXA = 1.0
  
  rp = 6.35e-3/2.     ;Radius of Langmuir Probe [m]
  lp = 0.4            ;Length of cylindrical Langmuir Probe [m]
  ;----- Cylindrical probe
  Ap     = !pi*rp*lp;
  ;----- ellipsoid shape
  ;p = 1.6075
  ;lp=lp*1.2
  ;Ap = 2*!pi*(( rp^p*rp^p + rp^p*(0.5*lp)^p + rp^p*(0.5*lp)^p )/3.)^(1/p)
  Ap = Ap * RXA
  
  Vp = U+Ufloat              ;----- probe to plasma potential
  pos_ind = where( Vp ge 0 ) ;----- for retarding region
  neg_ind = where( Vp lt 0 ) ;----- for accelerating region (RAM)
  Vp = abs(Vp/(Ti/eV2K))     ;----- normarized voltage -----
  
  M = sqrt(mi*Vi^2/(2.0*qe*(Ti/eV2K)))
  Ii0  = Ap*Ni*qe*sqrt( Ti*kb/(2.0*!pi*mi) )  ;----- Randum current -----
  Ld = sqrt(E0*kb*Ti/(Ni*qe^2))               ;----- Debye length as sheath radius
  a_r = Ld/rp ;----- sheath area limited      ;----- sheath/probe radius ratio
  a_r = 100
  
  G = 1./sqrt(a_r-1.0)
  
  ;print, 'M : '+ string(M,format='(F10.4)')
  ;print, 'Ld: '+ string(Ld*1e3,format='(F10.4)') + 'cm'
  ;print, 'a_r : '+ string(a_r,format='(F10.4)')
  ;print, 'G : '+ string(G,format='(F10.4)')
  
  J_thi = fltarr(n_elements(Vp))
  erfv  = fltarr(n_elements(Vp))
  expv  = fltarr(n_elements(Vp))
  
  erfv = erf(M - G * sqrt(Vp)) + erf(M + G * sqrt(Vp))
  
  ;----- Ion ACC CURRENT -----
  expv(neg_ind) = ((M+G*sqrt(Vp(neg_ind)))*exp(-(M-G*sqrt(Vp(neg_ind)))^2.) + $
    (M-G*sqrt(Vp(neg_ind)))*exp(-(M+G*sqrt(Vp(neg_ind)))^2.) ) /(4*M)
    
  J_thi(neg_ind) = a_r^2.0 * ( $
    0.5*sqrt(!pi) * (M^2+0.5) * 2 * erf(M) / (2*M) $
    +   0.5*exp(-M^2) $
    +   0.5*sqrt(!pi) * (Vp(neg_ind)/(2*M)) * erfv(neg_ind)) $
    - (a_r^2 -1) * ( $
    0.5*sqrt(!pi)*(M^2+0.5+Vp(neg_ind))*(0.5/M)*erfv(neg_ind) $
    +  expv(neg_ind))
    
  ;----- Ion RET CURRENT -----
  J_thi(pos_ind) = 0.5*sqrt(!pi) * (M^2 + 0.5 - Vp(pos_ind)) * erfv(pos_ind) /(2*M) + expv(pos_ind)
  
  return, -Ii0 * J_thi
end
;-------------------------------------------------------------- mvn_lpw_j_i_thermal_sph_hoegy -----

;------- mvn_lpw_J_e_thermal ----------------------------------------------------------------------
;        input: U, P(Ufloat[V],Ne[cm^-3],Te[eV])
function mvn_lpw_J_e_thermal, U, P
  
  eV2K = 11604
  
  Ufloat = P[0]
  N      = P[1] * 1e6
  T      = P[2] * eV2K
  ;if N eq 0.0 then return, 0.0
  
  m = 9.10938188e-31  ;Electron mass in [kg]
  ;V = 0               ;velocity of the body with respect to the plasma [km/s].
  Z = -1              ;charge [+/-] of current carrying species.
  rp = 6.35e-3/2.     ;Radius of Langmuir Probe [m]
  lp = 0.4            ;Length of cylindrical Langmuir Probe [m]
  A  = 2*!pi*rp*lp;
  
  j_thermal = make_array(size=size(U))
  U_pts = n_elements(U)
  kb = 1.3807e-23
  qe = 1.602176462e-19 ;Electron charge/[C]
  
  ;Vp = U
  Vp = U+Ufloat
  
  ; Is the body moving with a velocity, V, with respect to the plasma ?
  ; Criteria set such that it is considered.
  ; important if V > 0.1 * V_th. But we assume V << V_th for electron here.
  ; -----------------------------------------------------------------
  X = ( qe / (kb*T) ) * Vp              ; --- Ratio of potential to thermal energy.
  Ip = A*N*qe*sqrt( T*kb/(2.0*!pi*m) )  ; --- Total current to/from body.
  
  
  pos_ind = where( Vp ge 0 )
  neg_ind = where( Vp lt 0 )
  
  sq    = make_array(size=size(Vp), value=0)
  erfv  = make_array(size=size(Vp), value=0)
  
  sq(neg_ind) = sqrt( abs(-X(neg_ind)) );
  sq(pos_ind) = sqrt( abs(+X(pos_ind)) );
  erfv = erf( sq );
  
  j_thermal(neg_ind) = Ip * exp(X(neg_ind))
  j_thermal(pos_ind) = Ip * ( (2.0/sqrt(!pi)) * sq(pos_ind) + exp(+X(pos_ind)) * (1.0 - erfv(pos_ind)) );
   
  pos_ind_sheath = where(finite(exp(+X),/INFINITY))
  j_thermal(pos_ind_sheath) = Ip * ( (2.0/sqrt(!pi)) * sq(pos_ind_sheath))
    
  return, j_thermal
end
;------------------------------------------------------------------------- mvn_lpw_J_e_thermal ----

;------- mvn_lpw_J_2e_thermal ----------------------------------------------------------------------
;        input: U, P(Ufloat,U1[V],Ne1,Ne2[cm^-3],Te1,Te2[eV])
function mvn_lpw_J_2e_thermal, U, P

  U0 = P[0] & U1 = P[1]  & Ufloat = U0
  N1 = P[2] & N2 = P[3]
  T1 = P[4] & T2 = P[5]
  
  J_tot =  mvn_lpw_J_e_thermal(U, [U0, N1, T1])  $  ; T in [eV], N in[cm^3], U in [V]
        +  mvn_lpw_J_e_thermal(U, [U1, N2, T2])     ; T in [eV], N in[cm^3], U in [V]

  return, J_tot
end
;------------------------------------------------------------------------- mvn_lpw_J_2e_thermal ----

;------- mvn_lpw_J_i_thermal ----------------------------------------------------------------------
;        input: U, P(Ufloat[V],Ni[cm^-3],Ti[eV],Vi[km],(mi))
function mvn_lpw_J_i_thermal, U, P

  eV2K = 11604
  mH = 1.67262158e-27     ; Mass of Proton in [Kg]
  
  Ufloat = P[0]
  N      = P[1] * 1e6  ;density[m^-3]
  T      = P[2] * eV2K ;temperature[K]
  V      = P[3] * 1e3  ;velocity of the body with respect to the plasma [m/s].
  if n_elements(P) ge 5 then m  = P[4] * mH $
  else                       m  =   32 * mH            ; O2
    
  Z = +1              ;charge [+/-] of current carrying species.
  rp=6.35e-3/2.  ;Radius of Langmuir Probe [m]
  lp=0.4      ;Length of cylindrical Langmuir Probe [m]
  A     = !pi*rp*lp;
  
  j_thermal = make_array(size=size(U))
  U_pts = n_elements(U)
  kb = 1.3807e-23
  qe = 1.602176462e-19 ;Electron charge/[C]
  
  ;Vp = U
  Vp = U+Ufloat
  
  ; Is the body moving with a velocity, V, with respect to the plasma ?
  ; Criteria set such that it is considered. important if V > 0.1 * V_th.
  ; Ions thermal is usually smaller than S/C velocity.
  ; -----------------------------------------------------------------
  X = ( qe / (m*V^2/2 + kb*T) ) * Vp;
  Ip = A*N*qe*sqrt( V^2/16 + T*kb/(2.0*!pi*m) );
  
  pos_ind = where( Vp ge 0 )
  neg_ind = where( Vp lt 0 )
  
  sq    = make_array(size=size(Vp), value=0)
  erfv  = make_array(size=size(Vp), value=0)
  
  sq(neg_ind) = sqrt( abs(-X(neg_ind)) );
  sq(pos_ind) = sqrt( abs(+X(pos_ind)) );
  erfv = erf( sq );
  
  j_thermal(pos_ind) = Ip * exp(-X(pos_ind));
  j_thermal(neg_ind) = Ip * ( (2/sqrt(!pi)) * sq(neg_ind)  + exp(-X(neg_ind)) * (1.0 - erfv(neg_ind)) );
  neg_ind_sheath = where(finite(exp(-X),/INFINITY))
  j_thermal(neg_ind_sheath) = Ip * ( (2/sqrt(!pi)) * sq(neg_ind_sheath))

  return, -j_thermal
end
;------------------------------------------------------------------------- mvn_lpw_J_i_thermal ----

;------- mvn_lpw_J_e_photo ------------------------------------------------------------------------
;        input: U, P(Ufloat,UV) 
function mvn_lpw_J_e_photo, U,P
  
  Ufloat = P[0]
  UV     = P[1]
  
  ;R_sun = 1.5
  rp=6.35e-3/2.  ;Radius of Langmuir Probe [m]
  lp=0.4      ;Length of cylindrical Langmuir Probe [m]
  XA = 2*lp*rp
  
  Vp = U+Ufloat
  ind1 = where( Vp lt 0 )
  ind2 = where( Vp ge 0 );
  
  J_photo = make_array(size=size(U))
  
  ;J_photo(ind1) = -UV * (5.6e-5*XA/R_sun^2)
  ;J_photo(ind2) = -UV * (XA/R_sun^2) * ( 5.0e-5 * exp( - Vp(ind2) / 2.74 ) + $
  ; 1.2e-5 * exp( - (Vp(ind2) + 10.0) / 14.427 ) )
  
  J_photo(ind1) = -UV *  5.6e-5 * XA
  J_photo(ind2) = -UV *  XA * ( 5.0e-5 * exp( - Vp(ind2) / 2.74 ) + $
    1.2e-5 * exp( - (Vp(ind2) + 10.0) / 14.427 ) )
    
  return, J_photo
  
end
;-------------------------------------------------------------------------- mvn_lpw_J_e_photo -----

;------- mvn_lpw_J_3e_thermal_photo ---------------------------------------------------------------
;        input: U, P(Ufloat,U1,U2,Ne1,Ne2,Ne3,Te1,Te2,Te3,UV)
function mvn_lpw_J_3e_thermal_photo, U, P

  U0 = P[0] & U1 = P[1] & U2 = P[2]  & Ufloat = U0
  N1 = P[3] & N2 = P[4] & N3 = P[5]
  T1 = P[6] & T2 = P[7] & T3 = P[8]
  UV = P[9]
  
  J_tot =  mvn_lpw_J_e_thermal(U, [U0, N1, T1])  $  ; T in [eV], N in[cm^3], U in [V]
    +  mvn_lpw_J_e_thermal(U, [U1, N2, T2])  $  ; T in [eV], N in[cm^3], U in [V]
    +  mvn_lpw_J_e_thermal(U, [U2, N3, T3])  $  ; T in [eV], N in[cm^3], U in [V]
    +  mvn_lpw_J_e_photo(U,[Ufloat,UV])
    
  return, J_tot
end
;----------------------------------------------------------------- mvn_lpw_J_3e_thermal_photo -----

;------- mvn_lpw_J_2e_thermal_photo ---------------------------------------------------------------
;        input: U, P(Ufloat,U1,Ne1,Ne2,Te1,Te2,UV) 
function mvn_lpw_J_2e_thermal_photo, U, P

  U0 = P[0] & U1 = P[1]  & Ufloat = U0
  N1 = P[2] & N2 = P[3]
  T1 = P[4] & T2 = P[5]
  UV = P[6]
  
  J_tot =  mvn_lpw_J_e_thermal(U, [U0, N1, T1])  $  ; T in [eV], N in[cm^3], U in [V]
        +  mvn_lpw_J_e_thermal(U, [U1, N2, T2])  $  ; T in [eV], N in[cm^3], U in [V]
        +  mvn_lpw_J_e_photo(U,[Ufloat,UV])
    
  return, J_tot
end
;----------------------------------------------------------------- mvn_lpw_J_2e_thermal_photo -----

;------- mvn_lpw_J_1e_thermal_photo ---------------------------------------------------------------
;        input: U, P(Ufloat,Ne,Te,UV) 
function mvn_lpw_J_1e_thermal_photo, U, P

  U0 = P[0] & Ufloat = U0
  N1 = P[1]
  T1 = P[2]
  UV = P[3]
  
  J_tot = mvn_lpw_J_e_thermal(U, [U0, N1, T1]) $ ; T in [eV], N in[cm^3], U in [V]
        + mvn_lpw_J_e_photo(U,[Ufloat,UV])
    
  return, J_tot
end
;----------------------------------------------------------------- mvn_lpw_J_1e_thermal_photo -----

;------- MVN_LPW_J_ICO2 ---------------------------------------------------------------------------
;        input: U, P(Ufloat,Ni,Ti,Vi) 
function mvn_lpw_J_iCO2, U, P

  Ufloat = P[0] ; floating potential
  Ni     = P[1] ; Ion density (effective)
  Ti     = P[2] ; Ion thermal velocity [eV]
  Vi     = P[3] ; Ion drift velocity [km/s]
  
  rp=6.35e-3/2.  ;Radius of Langmuir Probe [m]
  lp=0.4      ;Length of cylindrical Langmuir Probe [m]
  Ap =  2.0*!pi*rp*lp  ; Area of probe surface [m^2]
  
  mH = 1.67262158e-27     ; Mass of Proton in [Kg]
  qe = 1.602176462e-19    ; Electron charge in [C]
  
  Ni = Ni * 1e6 ; calcuration in m^-3
  mi = 22 * mH
  
  Vp = U+Ufloat
  
  ind1 = where(Vp lt 0)
  ind2 = where(Vp ge 0)
  
  Xi = ( 1 / (mi*(Vi*1e3)^2/(2*qe) + Ti) ) * Vp
  I  = Ap*Ni*qe*sqrt( (Vi*1e3)^2/16 + qe*Ti/(2.0*!pi*mi)  )
  
  J_thi = fltarr(n_elements(Vp))
  J_thi(ind1) = -I * (1 - Xi(ind1))
  J_thi(ind2) = -I * exp(-Xi(ind2))
  
  return, float(J_thi)
  
end
;------------------------------------------------------------------------- --- mvn_lpw_J_iCO2 -----

;------- MVN_LPW_J_1E_ICO2 ------------------------------------------------------------------------
;        input: U, P(Ufloat,Ne,Te,Ni,Ti,Vi)
function mvn_lpw_J_1e_iCo2, U, P

  U0 = P[0] & Ufloat = U0
  N1 = P[1]
  T1 = P[2]
  Ni = P[3]
  Ti = P[4]
  Vi = P[5]
  
  J_tot = mvn_lpw_J_e_thermal(U, [U0, N1, T1]) $ ; T in [eV], N in[cm^3], U in [V]
    + mvn_lpw_J_iCO2(U,[Ufloat,Ni, Ti, Vi])
    
  return, J_tot
end
;-------------------------------------------------------------------------- mvn_lpw_J_1e_iCo2 -----

;------- fitswp_l0_01 -----------------------------------------------------------------------------
function fitswp_l0_01, PP, Vsc

  PP.fit_function_name = 'fitswp_l0_01'
  
  U = PP.voltage &  I = PP.current
  
  if finite(Vsc) eq 0 then Vsc = 25
  
  ;----- Search current zero crossing ---------------------------------------------------
  U00 = where(abs(I) eq min(abs(I))) & U_zero = min(U(U00)) & PP.U_zero = U_zero
  
  ;------ Try fitting only ion component fitting first ----------------------------------
  ;U0_pre = -1.0 & U_lim = [-15, 1]
  U0_pre = -U_zero
  U_lim = [-15, U_zero]
  ;ifit_int = 17 & U_lim = [U_zero-ifit_int, U_zero]
  ind = where(U gt U_lim(0) and U lt U_lim(1)) ;& print, U_lim
  
  ;U_lim  = [U0_pre-2.0, U0_pre, U0_pre+2.0]
  U_lim  = [U0_pre-2.0, U0_pre, U0_pre+2.0]
  Ni_lim = [1e0, 1e4, 1e6]
  Ti_lim = [1e-2, 1e-1, 1e1]
  Vi_lim = [0, 25, 50]
  
  start   = [U_lim(1), Ni_lim(1), Ti_lim(1), Vi_lim(1)]
  
  parinfo = replicate({fixed:0, limited:[1,1], limits:[0.D,0.D]},n_elements(start))
  parinfo[0].limits = [U_lim(0),  U_lim(2)]  ; limits for U0
  parinfo[1].limits = [Ni_lim(0), Ni_lim(2)] ; limits for Ni
  parinfo[2].limits = [Ti_lim(0), Ti_lim(2)] ; limits for Ti
  parinfo[3].limits = [Vi_lim(0), Vi_lim(2)] ; limits for Vi
  
  ;parinfo[2].fixed = 1  ; Velocity to be fixed
  ;parinfo[3].fixed = 1  ; Velocity to be fixed
  
  err = make_array(n_elements(ind),value=1e-9)
  P = mpfitfun('mvn_lpw_J_iCO2',U(ind),I(ind),err,start,PARINFO=parinfo)
  
  PP.I_ion        = mvn_lpw_J_iCO2(U,P([0,1,2,3]))
  PP.U0  = P[0]
  PP.Ni  = P[1]
  PP.Ti  = P[2]
  PP.Vi  = P[3]
  
  I_tmp = I - PP.I_ion
  PP.U_zero = -P(0)
  
  ;goto, FIT_END
  ; ----- Try fitting one electron ----------------------------------------------------------
  ; ----- Do not care abut stray current (I-photo from probe) -------------------------------
  ;U0_pre = P(0) & U_lim = [-5,  10]
  U0_pre = P(0) & U_lim = [-U0_pre-6,  -U0_pre+9]
  ind = where(U gt U_lim(0) and U lt U_lim(1))
  
  U_lim  = [U0_pre-2.0, U0_pre, U0_pre+2]
  Ne_lim = [1e0, 1e3, 1e6]
  Te_lim = [1e-2, 0.5, 1e1]
  
  start   = [U_lim(1), Ne_lim(1), Te_lim(1)]
  
  parinfo = replicate({fixed:0, limited:[1,1], limits:[0.D,0.D]},n_elements(start))
  parinfo[0].limits = [U_lim(0),  U_lim(2)]  ; limits for U0
  parinfo[1].limits = [Ne_lim(0), Ne_lim(2)] ; limits for Ne
  parinfo[2].limits = [Te_lim(0), Te_lim(2)] ; limits for Te
  
  err = make_array(n_elements(ind),value=1e-9)
  P = mpfitfun('mvn_lpw_J_e_thermal',U(ind),I_tmp(ind),err,start,PARINFO=parinfo)
  
  ;pp.fit_err = transpose([[U(ind)],[err]])
  PP.I_electron1  = mvn_lpw_J_e_thermal(U, P([0,1,2]))  ;P[U,N,T]
  
  PP.I_tot        = PP.I_electron1 + PP.I_ion
  
  PP.No_e  = 1
  PP.U0  = P[0]
  PP.Ne1 = P[1]
  PP.Te1 = P[2]
  
  PP.Ne_tot = PP.Ne1
  PP.Te     = PP.Te1
  
  goto, FIT_END
  ;----- Finaly try one electron and one CO2 ion components fitting based on the result above
  U0_pre = P(0) & U_lim = [-U0_pre-17,  -U0_pre+9]
  ind = where(U gt U_lim(0) and U lt U_lim(1))
  
  U0_pre = PP.U0
  U_lim  = [U0_pre-2.0, U0_pre, U0_pre+2.0]
  Ne_lim = [1e0, PP.Ne1, 1e6]
  Te_lim = [1e-2, PP.Te1, 1e1]
  Ni_lim = [1e0, PP.Ni, 1e6]
  Ti_lim = [1e-2, PP.Ti, 1e1]
  Vi_lim = [0, PP.Vi, 50]
  
  start   = [U_lim(1), Ne_lim(1), Te_lim(1), Ni_lim(1), Ti_lim(1), Vi_lim(1)]
  
  parinfo = replicate({fixed:0, limited:[1,1], limits:[0.D,0.D]},n_elements(start))
  parinfo[0].limits = [U_lim(0),  U_lim(2)]  ; limits for U0
  parinfo[1].limits = [Ne_lim(0), Ne_lim(2)] ; limits for Ne
  parinfo[2].limits = [Te_lim(0), Te_lim(2)] ; limits for Te
  parinfo[3].limits = [Ni_lim(0), Ni_lim(2)] ; limits for Ne
  parinfo[4].limits = [Ti_lim(0), Ti_lim(2)] ; limits for Te
  parinfo[5].limits = [Vi_lim(0), Vi_lim(2)] ; limits for Te
  
  err = make_array(n_elements(ind),value=1e-9)
  P = mpfitfun('mvn_lpw_J_1e_iCo2',U(ind),I(ind),err,start,PARINFO=parinfo)
  
  ;pp.fit_err = transpose([[U(ind)],[err]])
  PP.I_electron1  = mvn_lpw_J_e_thermal(U, P([0,1,2]))  ;P[U,N,T]
  PP.I_ion        = mvn_lpw_J_iCO2(U,P([0,3,4,5]))
  PP.I_tot        = PP.I_electron1 + PP.I_ion
  
  PP.No_e  = 1
  PP.U0  = P[0]
  PP.Ne1 = P[1]
  PP.Te1 = P[2]
  PP.Ni  = P[3]
  PP.Ti  = P[4]
  PP.Vi  = P[5]
    
FIT_END:
  return, PP
  
end
;------------------------------------------------------------------------------- fitswp_l0_01 -----

;------- fitswp_l0_00 -----------------------------------------------------------------------------
function fitswp_l0_00, swp_pp
  swp_pp.fit_function_name = 'fitswp_l0_00'

  U = swp_pp.voltage & I = swp_pp.current
  
  ;----- define ion curent ----------------------------------------------------
  coeff = fit_ion(U, I)
  I_ion = coeff(0) + coeff(1) * U ;--- define ion current
  swp_pp.I_ion = I_ion
  swp_pp.m = coeff(0) & swp_pp.b = coeff(1)
  
  ;----- define initial value of U0 -------------------------------------------
  ind = where(I lt I_ion)
  ind2 = where(U(ind) eq max(U(ind)))
  U0_pre = U(ind(ind2))
  if isa(U0_pre,/array) then U0_pre = U0_pre(n_elements(U0_pre)-1)
  ;----- define 'linear part' upper voltage limit
  ind = where(U lt U0_pre)
  Ii_upper = I_ion + 0.5*stddev(I(ind)-I_ion(ind))
  ind = where(I lt Ii_upper) & U0_pre = U(ind) & U0_pre = max(U0_pre)
  delvar, ind
  
  ; ----- replace a part of negative voltage data with I_ion for U0 analysis
  I_tmp = I & ind = where(U lt U0_pre) & I_tmp(ind) = I_ion(ind)
  
  ; ----- Try fitting two components fitting at once --------------------------
  ; ----- Should use probe photoelectron current to get correct potential. ----
  U0_pre = -U0_pre
  U_lim1 = [U0_pre-5.0, U0_pre, U0_pre+5.0]
  
  N_lim1 = [1e0, 1e2, 1e3]
  T_lim1 = [1e-2, 1e0, 1e1]
  UV_lim = [0.0D, 0.5, 1.0D]
  
  ind = where(U gt -10.0 and U lt 30.0)
  
  start   = [U_lim1(1), N_lim1(1), T_lim1(1), UV_lim(1)]  ;U0 = P[0] N1 = P[1], T1 = P[2], UV = P[3]
  
  parinfo = replicate({fixed:0, limited:[1,1], limits:[0.D,0.D]},n_elements(start))
  parinfo[0].limits = [U_lim1(0), U_lim1(2)] ; limits for U0
  parinfo[1].limits = [N_lim1(0), N_lim1(2)] ; limits for N1
  parinfo[2].limits = [T_lim1(0), T_lim1(2)] ; limits for T1
  parinfo[3].limits = [UV_lim(0), UV_lim(2)] ; limits for UV
  
  err = make_array(n_elements(ind),value=1e-9)
  P = mpfitfun('mvn_lpw_J_electron1',U(ind),I_tmp(ind),err,start,PARINFO=parinfo)
  
  ;swp_pp.fit_err = err
  swp_pp.I_electron1  = mvn_lpw_J_e_thermal(U, P([0,1,2]))  ;P[U,N,T]
  swp_pp.I_photo      = mvn_lpw_J_e_photo(U,P([0,3])) ;P[Ufloat,UV]
  swp_pp.I_electron2  = make_array(n_elements(U),1,value = !values.F_nan)
  swp_pp.I_electron3  = make_array(n_elements(U),1,value = !values.F_nan)
  swp_pp.I_tot        = swp_pp.I_ion + swp_pp.I_electron1  + swp_pp.I_photo 
  swp_pp.No_e  = 1
  swp_pp.U0  = P[0]
  swp_pp.Ne1 = P[1]
  swp_pp.Te1 = P[2]
  swp_pp.UV  = P[3]
  
  ; ***** This part should be processed when Ne/U0 statistics is ready ********
  swp_pp.Neprox  = !values.F_nan
  
  return, swp_pp
end
;------------------------------------------------------------------------------- fitswp_l0_00 -----

;------- fitswp_SW_00 -----------------------------------------------------------------------------
function fitswp_SW_00, swp_pp
  swp_pp.fit_function_name = 'fitswp_SW_00'

  U = swp_pp.voltage & I = swp_pp.current
  
  ;----- define ion curent ----------------------
  coeff = fit_ion_linear(U, I)
  I_ion = coeff(0) + coeff(1) * U ;--- define ion current
  swp_pp.I_ion = I_ion
  swp_pp.m = coeff(0) & swp_pp.b = coeff(1)
  
  ;----- define initial value of U0 -------------
  ind = where(I lt I_ion)
  ind2 = where(U(ind) eq max(U(ind)))
  U0_pre = U(ind(ind2))
  if isa(U0_pre,/array) then U0_pre = U0_pre(n_elements(U0_pre)-1)
  ;----- define 'linear part' upper voltage limit
  ind = where(U lt U0_pre)
  Ii_upper = I_ion + 0.5*stddev(I(ind)-I_ion(ind))
  ind = where(I lt Ii_upper) & U0_pre = U(ind) & U0_pre = max(U0_pre)
  delvar, ind
  
  ; ----- replace a part of negative voltage data with I_ion for U0 analysis
  I_tmp = I & ind = where(U lt U0_pre) & I_tmp(ind) = I_ion(ind)
  
  ; ----- Try fitting two components fitting at once ------------------------
  ; ----- Should use probe photoelectron current to get correct potential. --
  U0_pre = -U0_pre
  U_lim1 = [U0_pre-5.0, U0_pre, U0_pre+5.0]
  U_lim2 = [-9.0, -4.0, U0_pre]
  
  N_lim1 = [1e0, 1e2, 1e3]
  T_lim1 = [1e-2, 1e0, 1e1]
  UV_lim = [0.0D, 0.5, 1.0D]
  
  ind = where(U gt -10.0 and U lt 15.0)
  
  ;U0 = P[0] & U1 = P[1]  & Ufloat = U0
  ;N1 = P[2] & N2 = P[3]
  ;T1 = P[4] & T2 = P[5]
  ;UV = P[6]
  
  start   = [U_lim1(1), U_lim2(1), $ ;[0,1]
    N_lim1(1), N_lim1(1), $ ;[2,3]
    T_lim1(1), T_lim1(1), $ ;[4,5]
    UV_lim(1)]              ;[6]
    
  parinfo = replicate({fixed:0, limited:[1,1], limits:[0.D,0.D]},n_elements(start))
  parinfo[0].limits = [U_lim1(0), U_lim1(2)] ; limits for U0
  parinfo[1].limits = [U_lim2(0), U_lim2(2)] ; limits for U1
  parinfo[2].limits = [N_lim1(0), N_lim1(2)] ; limits for N1
  parinfo[3].limits = [N_lim1(0), N_lim1(2)] ; limits for N2
  parinfo[4].limits = [T_lim1(0), T_lim1(2)] ; limits for T1
  parinfo[5].limits = [T_lim1(0), T_lim1(2)] ; limits for T2
  parinfo[6].limits = [UV_lim(0), UV_lim(2)] ; limits for UV
  
  err = make_array(n_elements(ind),value=1e-9)
  P = mpfitfun('mvn_lpw_J_2e_thermal_photo',U(ind),I_tmp(ind),err,start,PARINFO=parinfo)
  
  ;swp_pp.fit_err = err
  swp_pp.I_electron1  = mvn_lpw_J_e_thermal(U, P([0,2,4]))  ;P[U,N,T]
  swp_pp.I_electron2  = mvn_lpw_J_e_thermal(U, P([1,3,5]))  ;P[U,N,T]
  swp_pp.I_photo      = mvn_lpw_J_e_photo(U,P([0,6])) ;P[Ufloat,UV]
  swp_pp.I_electron3  = make_array(n_elements(U),1,value = !values.F_nan)
  swp_pp.I_tot        = swp_pp.I_electron1 + swp_pp.I_electron2 + swp_pp.I_photo + swp_pp.I_ion
  swp_pp.No_e  = 2
  swp_pp.U0  = P[0]
  swp_pp.U1  = P[1]
  swp_pp.Ne1 = P[2]
  swp_pp.Ne2 = P[3]
  swp_pp.Te1 = P[4]
  swp_pp.Te2 = P[5]
  swp_pp.UV  = P[6]
  
  swp_pp.Ne_tot = total([swp_pp.Ne1,swp_pp.Ne2],/nan)
  swp_pp.Te     =  mean([swp_pp.Te1,swp_pp.Te2],/nan)
  
  
  ; ***** This part should be processed when Ne/U0 statistics is ready ********
  swp_pp.Neprox  = !values.F_nan
  
  return, swp_pp
end
;------------------------------------------------------------------------------- fitswp_SW_00 -----

;------- fitswp_SW_01 -----------------------------------------------------------------------------
;------- MAVEN LP Sweep fitting in Solar Wind case. Photoelectron + three component electron ------
function fitswp_SW_01, PP_org, givenU=givenU
  swp_pp = PP_org
  swp_pp.fit_function_name = 'fitswp_SW_01'
  ;print, swp_pp.fit_function_name
    
  U = swp_pp.voltage & I = swp_pp.current
  
  ;----- set suggested floating potential -------------------------------------
  if keyword_set(givenU) eq 0 then givenU = [!values.F_nan,-10,-20]
  if n_elements(givenU) eq 1  then givenU = [givenU,-10,-20]
  if n_elements(givenU) eq 2  then givenU = [givenU(0),givenU(1),-20]
  if finite(givenU(1)) eq 0 then givenU(1) = -10
  if finite(givenU(2)) eq 0 then givenU(2) = -20
  
  swp_pp.U_input = givenU
  ;print, givenU
  
  ;----- define ion curent ----------------------
  ;----- First order linear fitting -------------
  ;coeff = fit_ion_linear(U, I)
  ;I_ion = coeff(0) + coeff(1) * U ;--- define ion current
  ;swp_pp.I_ion = I_ion
  ;swp_pp.m = coeff(0) & swp_pp.b = coeff(1)
  ;----- Use avarage value instead. Assume constant in negative voltage side ---
  ind = where(U lt -5.0)
  swp_pp.m = mean(I(ind)) & swp_pp.b = 0.0
  I_ion = swp_pp.m + swp_pp.b * U ;--- define ion current
  
  ;----- define initial value of U0 -------------
  ind = where(I lt I_ion)
  ind2 = where(U(ind) eq max(U(ind)))
  U0_pre = U(ind(ind2))
  if isa(U0_pre,/array) then U0_pre = U0_pre(n_elements(U0_pre)-1)
  ;----- define 'linear part' upper voltage limit
  ind = where(U lt U0_pre)
  Ii_upper = I_ion + 0.5*stddev(I(ind)-I_ion(ind))
  ind = where(I lt Ii_upper) & U0_pre = U(ind) & U0_pre = max(U0_pre)
  delvar, ind
  
  ; ----- replace a part of negative voltage data with I_ion for U0 analysis
  I_tmp = I & ind = where(U lt U0_pre) & I_tmp(ind) = I_ion(ind)
  
  ;---- Estimate UV intensity -------------------------------------------------
  I_photo_dummy = mvn_lpw_J_e_photo(U,[-U0_pre,1.0]) ;P[Ufloat,UV]
  ind = where(U eq min(U)) & ind=ind(0)
  UV0 = swp_pp.m/I_photo_dummy(ind) & delvar, ind
  
  ; ----- Try fitting tree electron components fitting ------------------------
  ; ----- Should use probe photoelectron current to get correct potential. ----
  ; ----- input: U, P(Ufloat,U1,U2,Ne1,Ne2,Ne3,Te1,Te2,Te3,UV)
  if finite(givenU(0)) then U0_pre = givenU(0) else U0_pre = -U0_pre
  U_lim0 = [U0_pre-5.0, U0_pre, U0_pre+5.0]
  
  ;U_lim1 = [givenU(2), givenU(1), U0_pre]
  ;U_lim2 = [givenU(2)-5, givenU(2), givenU(1)]
  du = 10
  if    U0_pre le givenU(2)+du then U_lim1 = [givenU(1)-du, givenU(1), U0_pre] $
  else                             U_lim1 = [givenU(1)-du, givenU(1), givenU(1)+du]
  if givenU(1) le givenU(2)+du then U_lim2 = [givenU(2)-du, givenU(2), givenU(1)] $
  else                             U_lim2 = [givenU(2)-du, givenU(2), givenU(2)+du]
  
  N_lim = [1e0, 1e2, 1e3]  ;& N_lim2 = [1e0, 1e2, 1e3]  & N_lim3 = [1e0, 1e2, 1e3]
  T_lim = [1e-2, 1e0, 1e1] ;& T_lim2 = [1e-2, 1e0, 1e1] & T_lim3 = [1e-2, 1e0, 1e1]
  
  UV_lim = [0.0D, UV0, 1.0D]
  
  ;ind = where(U gt -40.0 and U lt 35.0)
  ind = where(U gt -20.0 and U lt 10.0)
  
  ;U0 = P[0] & U1 = P[1]  & Ufloat = U0
  ;N1 = P[2] & N2 = P[3]
  ;T1 = P[4] & T2 = P[5]
  ;UV = P[6]
  
  start   = [U_lim0(1), U_lim1(1), U_lim2(1), $ ;[0,1,2]
    N_lim(1),  N_lim(1),  N_lim(1), $  ;[3,4,5]
    T_lim(1),  T_lim(1),  T_lim(1), $  ;[6,7,8]
    UV_lim(1)]                         ;[9]
    
  parinfo = replicate({fixed:0, limited:[1,1], limits:[0.D,0.D]},n_elements(start))
  parinfo[0].limits = [U_lim0(0), U_lim0(2)] ; limits for U0
  parinfo[1].limits = [U_lim1(0), U_lim1(2)] ; limits for U1
  parinfo[2].limits = [U_lim2(0), U_lim2(2)] ; limits for U2
  parinfo[3].limits = [N_lim(0),  N_lim(2)]  ; limits for N1
  parinfo[4].limits = [N_lim(0),  N_lim(2)]  ; limits for N2
  parinfo[5].limits = [N_lim(0),  N_lim(2)]  ; limits for N3
  parinfo[6].limits = [T_lim(0),  T_lim(2)]  ; limits for T1
  parinfo[7].limits = [T_lim(0),  T_lim(2)]  ; limits for T2
  parinfo[8].limits = [T_lim(0),  T_lim(2)]  ; limits for T3
  parinfo[9].limits = [UV_lim(0), UV_lim(2)] ; limits for UV
  
  err = make_array(n_elements(ind),value=1e-9)
  P = mpfitfun('mvn_lpw_J_3e_thermal_photo',U(ind),I_tmp(ind),err,start,PARINFO=parinfo,/quiet)

  if n_elements(p) eq 1 then begin
    flg = -3 & return, swp_pp
  endif
  swp_pp.fit_err = err
  swp_pp.I_electron1  = mvn_lpw_J_e_thermal(U, P([0,3,6]))  ;P[U,N,T]
  swp_pp.I_electron2  = mvn_lpw_J_e_thermal(U, P([1,4,7]))  ;P[U,N,T]
  swp_pp.I_electron3  = mvn_lpw_J_e_thermal(U, P([2,5,8]))  ;P[U,N,T]
  swp_pp.I_photo      = mvn_lpw_J_e_photo(U,P([0,9])) ;P[Ufloat,UV]
  swp_pp.I_tot        = swp_pp.I_electron1 + swp_pp.I_electron2 + swp_pp.I_electron3 + swp_pp.I_photo
  swp_pp.No_e  = 3
  swp_pp.U0  = P[0] & swp_pp.U1  = P[1] & swp_pp.U2  = P[2]
  swp_pp.Ne1 = P[3] & swp_pp.Ne2 = P[4] & swp_pp.Ne3 = P[5]
  swp_pp.Te1 = P[6] & swp_pp.Te2 = P[7] & swp_pp.Te3 = P[8]
  swp_pp.UV  = P[9]
  
  swp_pp.Ne_tot = total([swp_pp.Ne1,swp_pp.Ne2,swp_pp.Ne3],/nan)
  swp_pp.Te     =  mean([swp_pp.Te1,swp_pp.Te2,swp_pp.Te3],/nan)
  
  ; ***** This part should be processed when Ne/U0 statistics is ready ********
  swp_pp.Neprox  = !values.F_nan
 
  swp_pp.fit_err2 = stddev(abs((swp_pp.I_TOT - swp_pp.CURRENT)/swp_pp.CURRENT),/nan)
 
  ;print, U_lim0, U_lim1, U_lim2
  return, swp_pp
end
;------------------------------------------------------------------------------- fitswp_SW_01 -----

;------- fitswp_SW_02 -----------------------------------------------------------------------------
;------- MAVEN LP Sweep fitting in Solar Wind case. Photoelectron + two component electron --------
function fitswp_SW_02, PP_org, givenU=givenU
  swp_pp = PP_org

  swp_pp.fit_function_name = 'fitswp_SW_02'
  ;print, swp_pp.fit_function_name

  U = swp_pp.voltage &  I = swp_pp.current
  U_org = U
  under_sat = where(U le 25) & U = U(under_sat) & I = I(under_sat)
  
  if finite(givenU(1)) eq 0 then givenU(1) = -20
  swp_pp.U_input = givenU
  ;print, givenU
  
  ;----- define ion curent ----------------------
  ;----- First order linear fitting -------------
  ind = where(U lt -5.0 and U gt -40) ;& ind = ind(1:n_elements(ind)-1)
   coeff = fit_ion_linear(U(ind), I(ind))
   I_ion = coeff(0) + coeff(1) * U ;--- define ion current
   swp_pp.I_ion = I_ion
   swp_pp.m = coeff(0) & swp_pp.b = coeff(1)
  
  ;----- Use avarage value instead. Assume constant in negative voltage side ---
  ;ind = where(U lt -5.0 and U gt -40) ;& ind = ind(1:n_elements(ind)-1)
  ;swp_pp.m = mean(I(ind)) & swp_pp.b = 0.0

  I_ion = swp_pp.m + swp_pp.b * U ;--- define ion current
  
  ;----- define initial value of U0 -------------
  ind = where(I lt I_ion)
  ind2 = where(U(ind) eq max(U(ind)))
  U0_pre = U(ind(ind2))
  if isa(U0_pre,/array) then U0_pre = U0_pre(n_elements(U0_pre)-1)
  ;----- define 'linear part' upper voltage limit
  ind = where(U lt U0_pre)
  Ii_upper = I_ion + 0.5*stddev(I(ind)-I_ion(ind))
  ind = where(I lt Ii_upper) & U0_pre = U(ind) & U0_pre = max(U0_pre)
  delvar, ind
  
  ; ----- replace a part of negative voltage data with I_ion for U0 analysis
  I_tmp = I & ind = where(U lt U0_pre) & I_tmp(ind) = I_ion(ind)
  
  ; ----- Try fitting two electron components fitting ------------------------
  ; ----- Should use probe photoelectron current to get correct potential. ----
  ; ----- input: U, P(Ufloat,U1,U2,Ne1,Ne2,Ne3,Te1,Te2,Te3,UV)
  if finite(givenU(0)) then U0_pre = givenU(0) else U0_pre = -U0_pre
  U_lim0 = [U0_pre-5.0, U0_pre, U0_pre+5.0]
  U_lim1 = [givenU(1)-5, givenU(1), U0_pre]
  
  N_lim = [1e0, 1e2, 1e3]
  T_lim = [1e-2, 1e0, 1e1]
  UV_lim = [0.0D, 0.5, 1.0D]
  
  ind = where(U gt -40.0 and U lt -givenU(1)+5)
  
  start   = [U_lim0(1), U_lim1(1), $ ;[0,1]
    N_lim(1),  N_lim(1),  $ ;[2,3]
    T_lim(1),  T_lim(1),  $ ;[4,5]
    UV_lim(1)]              ;[6]
    
  parinfo = replicate({fixed:0, limited:[1,1], limits:[0.D,0.D]},n_elements(start))
  parinfo[0].limits = [U_lim0(0), U_lim0(2)] ; limits for U0
  parinfo[1].limits = [U_lim1(0), U_lim1(2)] ; limits for U1
  parinfo[2].limits = [N_lim(0),  N_lim(2)] ; limits for N1
  parinfo[3].limits = [N_lim(0),  N_lim(2)] ; limits for N2
  parinfo[4].limits = [T_lim(0),  T_lim(2)] ; limits for T1
  parinfo[5].limits = [T_lim(0),  T_lim(2)] ; limits for T2
  parinfo[6].limits = [UV_lim(0), UV_lim(2)] ; limits for UV
  
  err = make_array(n_elements(ind),value=1e-9)
  P = mpfitfun('mvn_lpw_J_2e_thermal_photo',U(ind),I_tmp(ind),err,start,PARINFO=parinfo,/quiet)
  
  swp_pp.fit_err = err
  swp_pp.I_electron1  = mvn_lpw_J_e_thermal(U_org, P([0,2,4]))  ;P[U,N,T]
  swp_pp.I_electron2  = mvn_lpw_J_e_thermal(U_org, P([1,3,5]))  ;P[U,N,T]
  swp_pp.I_photo      = mvn_lpw_J_e_photo(U_org,P([0,6])) ;P[Ufloat,UV]
  
  if finite(P(0)) eq 0 then goto, END_fit_swp_SW_02
  
  swp_pp.I_electron3  = make_array(n_elements(U_org),1,value = !values.F_nan)
  swp_pp.I_tot        = swp_pp.I_electron1 + swp_pp.I_electron2 + swp_pp.I_photo
  swp_pp.No_e  = 2
  swp_pp.U0  = P[0]
  swp_pp.U1  = P[1]
  swp_pp.Ne1 = P[2]
  swp_pp.Ne2 = P[3]
  swp_pp.Te1 = P[4]
  swp_pp.Te2 = P[5]
  swp_pp.UV  = P[6]
  
  swp_pp.Ne_tot = total([swp_pp.Ne1,swp_pp.Ne2],/nan)
  swp_pp.Te     =  mean([swp_pp.Te1,swp_pp.Te2],/nan)
  
END_fit_swp_SW_02:  
  ; ***** This part should be processed when Ne/U0 statistics is ready ********
  swp_pp.Neprox  = !values.F_nan

  swp_pp.fit_err2 = stddev(abs((swp_pp.I_TOT - swp_pp.CURRENT)/swp_pp.CURRENT),/nan)
  
  return, swp_pp
end
;------------------------------------------------------------------------------- fitswp_SW_02 -----

;------- fitswp_SW_03 -----------------------------------------------------------------------------
;------- MAVEN LP Sweep fitting in Solar Wind case. Ion current + two component electron --------
function fitswp_SW_03, PP_org, givenU=givenU

  PP = PP_org
  PP.fit_function_name = 'fitswp_SW_03'

  U = PP.voltage &  I = PP.current
  U_org = U

  if keyword_set(givenU) eq 0 then givenU = [!values.F_nan, !values.F_nan, !values.F_nan]

  ;----- Try fitting ion side to subtract the electron current ----------------
  ;----- Ion current is  straight rather than the theoretical erf curve -------
  fit_Ulim = [-50, -5]
  fit_ind = where(U lt fit_Ulim(1) and U gt fit_Ulim(0)) ;& ind = ind(1:n_elements(ind)-1)
  coeff = fit_ion_linear(U(fit_ind), I(fit_ind))
  I_ion = coeff(0) + coeff(1) * U
  PP.I_ion = I_ion
  PP.m = coeff(0) & PP.b = coeff(1)
  PP.Ii_ind(fit_ind) = I(fit_ind)
  dI = stddev(abs(I_ion(fit_ind)-I(fit_ind)))
  pp.I_ion2 = I_ion + 2.*dI

  ;----- Look for U0 roughly --------------------------------------------------
  ind = where( U le 0. and I le PP.I_ion+2.*dI )
  U_Ie = U(ind) & U0_pre = max(U_Ie)
  pp.U_zero = U0_pre

  ;----- Replace linear part with model ---------------------------------------
  ind = where(U lt U0_pre)
  I(ind) = I_ion(ind)
  I_tmp = I - I_ion

  ; ----- Try fitting two electron components fitting -------------------------
  ; ----- Should use probe photoelectron current to get correct potential. ----
  ; ----- input: U, P(Ufloat,U1,U2,Ne1,Ne2,Ne3,Te1,Te2,Te3,UV)
  if finite(givenU(0)) then U0_pre = givenU(0) else U0_pre = -U0_pre
  givenU(0) = U0_pre
  if finite(givenU(1)) eq 0 then givenU(1) = -20
  ;print, givenU
  U0_lim = [U0_pre-5.0, U0_pre, U0_pre+5.0]
  U1_lim = [givenU(1)-8, givenU(1), U0_pre]

  N_lim = [1e0, 1e2, 1e3]
  T_lim = [1e-2, 1e0, 1e1]

  fit_ind = where(U gt -40.0 and U lt -givenU(1)+5)
  PP.Ie_ind(fit_ind) = I_tmp(fit_ind)

  start   = [U0_lim(1), U1_lim(1), N_lim(1), N_lim(1), T_lim(1), T_lim(1)]

  parinfo = replicate({fixed:0, limited:[1,1], limits:[0.D,0.D]},n_elements(start))
  parinfo[0].limits = [U0_lim(0),  U0_lim(2)]  ; limits for U0
  parinfo[1].limits = [U1_lim(0),  U1_lim(2)]  ; limits for U0
  parinfo[2].limits = [N_lim(0), N_lim(2)] ; limits for Ne
  parinfo[3].limits = [N_lim(0), N_lim(2)] ; limits for Ne
  parinfo[4].limits = [T_lim(0), T_lim(2)] ; limits for Te
  parinfo[5].limits = [T_lim(0), T_lim(2)] ; limits for Te

  err = make_array(n_elements(fit_ind),value=1e-9)
  P = mpfitfun('mvn_lpw_J_2e_thermal',U(fit_ind),I_tmp(fit_ind),err,start,PARINFO=parinfo,PERROR=PERROR,BESTNORM=BESTNORM,/quiet)

  if n_elements(p) le 1 then pp.flg=-4
  if n_elements(p) le 1 then return, pp
  
  PP.U0  = P[0]
  PP.U1  = P[1]
  PP.Ne1 = P[2]
  PP.Ne2 = P[3]
  PP.Te1 = P[4]
  PP.Te2 = P[5]

  PP.fit_err = transpose([[U(fit_ind)],[err]])
  PP.I_electron1  = mvn_lpw_J_e_thermal(U_org, [PP.U0,PP.Ne1,PP.Te1])  ;P[U,N,T]
  PP.I_electron2  = mvn_lpw_J_e_thermal(U_org, [PP.U1,PP.Ne2,PP.Te2])  ;P[U,N,T]

  if n_elements(fit_ind) ge 3 then begin
    if keyword_set(perror) ne 0 then begin      
      PP.dU0 = perror(0) & PP.dNe1 = perror(2) & PP.dTe1 = perror(4)
      PP.dU1 = perror(1) & PP.dNe2 = perror(3) & PP.dTe2 = perror(5)      
      DOF     = N_ELEMENTS(fit_ind) - N_ELEMENTS(P) ; deg of freedom
      PCERROR = PERROR * SQRT(BESTNORM / DOF)   ; scaled uncertainties
      ;if dof ge 10 then stop
    endif
  endif

  PP.I_tot = PP.I_ion + PP.I_electron1 + PP.I_electron2

  PP.Ne_tot = PP.Ne1 + PP.Ne2
  PP.Te     = mean([PP.Te1 , PP.Te2])

  fit_ind = where(finite(PP.Ie_ind))
  PP.fit_err2 = stddev(abs((PP.current(fit_ind) - PP.I_tot(fit_ind))/PP.I_tot(fit_ind)),/nan)
  PP.efit_points = n_elements(fit_ind)

  if pp.Te1 le 1.5e-2 then pp.flg = -11

  return, PP
end
;------- fitswp_SW_03 -----------------------------------------------------------------------------

;------- fitswp_IONP_00 ---------------------------------------------------------------------------
function fitswp_IONP_00, PP, Vsc=Vsc, givenU=givenU
  PP.fit_function_name = 'fitswp_IONP_00'
  
  U = PP.voltage &  I = PP.current & U_org = U
  ind = where(finite(I)) &  U=U(ind) & I=I(ind)
  ind = sort(U) & U=U(ind) & I=I(ind)
  
  U_Imin = where(abs(I(where(U ge -10.))) eq min(abs(I(where(U ge -10.)))))
  if keyword_set(givenU) eq 0 then givenU = -U(U_Imin)
  if n_elements(givenU) gt 1 then givenU = givenU(0)
  if finite(givenU)      eq 0 then givenU = -U(U_Imin)
  if keyword_set(Vsc) eq 0 then Vsc = 4.0
  if finite(Vsc)      eq 0 then Vsc = 4.
  
  print, PP.fit_function_name
  ;print, givenU

  ;----- define ion curent ----------------------
  ;----- First order linear fitting -------------
  ;coeff = fit_ion_linear(U, I)
  ;I_ion = coeff(0) + coeff(1) * U ;--- define ion current
  ;swp_pp.I_ion = I_ion
  ;swp_pp.m = coeff(0) & swp_pp.b = coeff(1)
  ;----- Use avarage value instead. Assume constant in negative voltage side ---
  ind = where(U lt -5.0)
  PP.m = mean(I(ind)) & PP.b = 0.0
  I_ion = PP.m + PP.b * U ;--- define ion current
  
  ;----- define initial value of U0 -------------
  ind = where(I lt I_ion)
  ind2 = where(U(ind) eq max(U(ind)))
  U0_pre = U(ind(ind2))
  if isa(U0_pre,/array) then U0_pre = U0_pre(n_elements(U0_pre)-1)
  ;----- define 'linear part' upper voltage limit
  ind = where(U lt U0_pre)
  Ii_upper = I_ion + 0.5*stddev(I(ind)-I_ion(ind))
  ind = where(I lt Ii_upper) & U0_pre = U(ind) & U0_pre = max(U0_pre)
  delvar, ind
  
  ; ----- replace a part of negative voltage data with I_ion for U0 analysis
  I_tmp = I & ind = where(U lt U0_pre) & I_tmp(ind) = I_ion(ind)

  ; ----- Try fitting one electron components fitting ------------------------
  ; ----- Should use probe photoelectron current to get correct potential. ----
  ; ----- mvn_lpw_J_1e_thermal_photo, input: U, P(Ufloat,Ne,Te,UV)  
  if finite(givenU(0)) then U0_pre = givenU(0) else U0_pre = -U0_pre
  U_lim0 = [U0_pre-5.0, U0_pre, U0_pre+5.0]  
  N_lim = [1e0, 1e2, 1e5]
  T_lim = [1e-2, 1e0, 1e1]
  UV_lim = [0.0D, 0.5, 1.0D]
  
  U_lim = [-20, U(U_Imin)+1]  
  ind = where(U gt U_lim(0) and U lt U_lim(1)) ;& print, U_lim
  ;ind = where(U gt -40.0 and U lt -givenU(1)+5)
  
  start   = [U_lim0(1), N_lim(1), T_lim(1), UV_lim(1)]
    
  parinfo = replicate({fixed:0, limited:[1,1], limits:[0.D,0.D]},n_elements(start))
  parinfo[0].limits = [U_lim0(0), U_lim0(2)] ; limits for U0
  parinfo[1].limits = [N_lim(0),  N_lim(2)] ; limits for Ne
  parinfo[2].limits = [T_lim(0),  T_lim(2)] ; limits for Te
  parinfo[3].limits = [UV_lim(0), UV_lim(2)] ; limits for UV
  
  err = make_array(n_elements(ind),value=1e-9)
  P = mpfitfun('mvn_lpw_J_1e_thermal_photo',U(ind),I_tmp(ind),err,start,PARINFO=parinfo,/quiet)
  
 ;PP.fit_err = err
  PP.I_electron1  = mvn_lpw_J_e_thermal(U_org, P([0,1,2]))  ;P[U,N,T]
  PP.I_photo      = mvn_lpw_J_e_photo(U_org,P([0,3])) ;P[Ufloat,UV]
  PP.I_electron3  = make_array(n_elements(U),1,value = !values.F_nan)
  PP.I_tot        = PP.I_electron1 + PP.I_electron2 + PP.I_photo
  PP.No_e  = 1
  PP.U0  = P[0]
  PP.Ne1 = P[1]
  PP.Te1 = P[2]
  PP.UV  = P[3]
  
  PP.Ne_tot = PP.Ne1
  PP.Te     = PP.Te1
  
  ; ***** This part should be processed when Ne/U0 statistics is ready ********
  PP.Neprox  = !values.F_nan

  givenU = [givenU,!values.F_nan,!values.F_nan]
  PP.U_input = givenU
  
  return, PP

end
;----------------------------------------------------------------------------- fitswp_IONP_00 -----

;------- fitswp_10V_00 ----------------------------------------------------------------------------
function fitswp_10V_00, PP_org, Vsc=Vsc, givenU=givenU
  PP = PP_org
  PP.fit_function_name = 'fitswp_10V_00'
  
  U = PP.voltage &  I = PP.current
  U_org = U

  ;----- avoid saturation current -------------------------------------------------------
  while 1 do begin
    dIdU = deriv(U,I)
    if dIdU(n_elements(dIdU)-1) lt 0.0 then begin
      U = U(0:n_elements(U)-2) & I = I(0:n_elements(I)-2)
    endif else break    
  endwhile
  under_sat = where(U le 25) & U = U(under_sat) & I = I(under_sat)
    
  U_Imin = where(abs(I(where(U ge -10.))) eq min(abs(I(where(U ge -10.)))))
  U_Imin=U_Imin(0)
  
 ; if finite(givenU(0)) eq 0 then delvar, givenU

  ;----- Define givenU if not assigned --------------------------------------------------
  if keyword_set(givenU) eq 0 then begin    
     dIdU = deriv(U,I)
    U_dIdUmax = where( dIdU eq max(dIdU,/NAN)) & U_dIdUmax=U_dIdUmax(0)
    if U(U_dIdUmax) gt U(U_Imin) then givenU = -U(U_dIdUmax) else givenU = -U(U_Imin)
  endif
  if n_elements(givenU) gt 1 then givenU = givenU(0)
  if finite(givenU)      eq 0 then begin
    dIdU = deriv(U,I)    
    U_dIdUmax = where( dIdU eq max(dIdU,/NAN)) & U_dIdUmax=U_dIdUmax(0)
    if U(U_dIdUmax) gt U(U_Imin) then givenU = -U(U_dIdUmax)-0.5 else givenU = -U(U_Imin)
    ;givenU = -U(U_Imin)
  endif

  ;----- Define Vsc if not assigned -----------------------------------------------------
  if keyword_set(Vsc) eq 0 then Vsc = 4.0
  if finite(Vsc)      eq 0 then Vsc = 4.
  
  ;print, PP.fit_function_name
  ;print, givenU
  
  ;----- Search current zero crossing ---------------------------------------------------
  U00 = where(abs(I) eq min(abs(I))) & U_zero = min(U(U00)) & PP.U_zero = U_zero
  
  ;------ Try fitting only ion component fitting first ----------------------------------
  ;U0_pre = -1.0 & U_lim = [-15, 1]
  ;U0_pre = -U_zero
  ;U_lim = [-15, U_zero]
  ;ifit_int = 17 & U_lim = [U_zero-ifit_int, U_zero]
  
  U0_pre = givenU
  ;U_lim = [-4.0, 0.0]
 ;U_lim = [U(U_Imin)-20, U(U_Imin)]
 ;U_lim = [U(U_Imin)-10, U(U_Imin)+1]
  U_lim = [-20, U(U_Imin)-1]
  ind = where(U gt U_lim(0) and U le U_lim(1)) ;& print, U_lim
  if n_elements(ind) lt 3 then return, PP

  ;----- Try with linear fitting -------------------------------
  coeff = fit_ion_linear(U(ind),I(ind))
  PP.m = coeff(0) & PP.b = coeff(1)
  ;I_ion = coeff(0) + coeff(1) * U ;--- define ion current
  ;PP.I_ion = I_ion
  ;I_tmp = I - PP.I_ion
  ;PP.I_electron2 = I_tmp
  ;goto, skip_tmp
    
  U_lim  = [U0_pre-2.0, U0_pre, U0_pre+2.0]
  Ni_lim = [1e2, 1e4, 1e6]
  Ti_lim = [1e-2, 1e-1, 1e1]
  Vi_lim = [0, Vsc, 50]
  
  start   = [U_lim(1), Ni_lim(1), Ti_lim(1), Vi_lim(1)]
  
  parinfo = replicate({fixed:0, limited:[1,1], limits:[0.D,0.D]},n_elements(start))
  parinfo[0].limits = [U_lim(0),  U_lim(2)]  ; limits for U0
  parinfo[1].limits = [Ni_lim(0), Ni_lim(2)] ; limits for Ni
  parinfo[2].limits = [Ti_lim(0), Ti_lim(2)] ; limits for Ti
  parinfo[3].limits = [Vi_lim(0), Vi_lim(2)] ; limits for Vi
  
  ;parinfo[2].fixed = 1  ; Velocity to be fixed
  ;parinfo[3].fixed = 1  ; Velocity to be fixed
  
  err = make_array(n_elements(ind),value=1e-9)
  P = mpfitfun('mvn_lpw_J_i_thermal',U(ind),I(ind),err,start,PARINFO=parinfo,/quiet)
  
  PP.I_ion        = mvn_lpw_J_i_thermal(U_org,P([0,1,2,3]))
  PP.U0  = P[0]
  PP.Ni  = P[1]
  PP.Ti  = P[2]
  PP.Vi  = P[3]
 
  I_tmp = I - PP.I_ion
  ;PP.U_zero = -P(0)
  
skip_tmp:  
  ;goto, FIT_END_fitswp_10V_00
  ; ----- Try fitting one electron ----------------------------------------------------------
  ; ----- Do not care abut stray current (I-photo from probe) -------------------------------
  ;U0_pre = P(0) & U_lim = [-5,  10]
  ;U0_pre = P(0) & U_lim = [-U0_pre-6,  -U0_pre+3]
  
  ;print, 'U0_pre: '+ string(U0_pre,format='(F5.2)')
  ;mvn_lpw_prd_lp_sweep_plot, PP=PP, xlim=[-2,6], win=5
  ; stop

  ;----- Start electron fitting ---------------------------  
  U0_pre = givenU
  
  U_givenU = where(U le -givenU) & U_givenU=U_givenU(n_elements(U_givenU)-1)
  
  ind_all = make_array(n_elements(U),/integer,value=0)
  if U_givenU eq n_elements(U)-1 then ind_all(U_Imin:U_givenU) = 1 $
  else                                ind_all(U_Imin:U_givenU+1) = 1
  
  ind   = where(ind_all eq 1)
  ind_n = where(ind_all eq 0)
  
  ;U_lim = [U(U_Imin)-1, -U0_pre+0.1]  
  ;ind   = where(U ge U_lim(0) and U le U_lim(1))
  ;ind_n = where(U lt U_lim(0) or  U gt U_lim(1))
  if n_elements(ind) lt 3 then return, PP
  
  dU = 1
  U_lim  = [U0_pre-dU, U0_pre, U0_pre+dU]
  Ne_lim = [1e0, 1e3, 1e6]
  Te_lim = [1e-2, 0.5, 1e1]
  
  start   = [U_lim(1), Ne_lim(1), Te_lim(1)]
  
  parinfo = replicate({fixed:0, limited:[1,1], limits:[0.D,0.D]},n_elements(start))
  parinfo[0].limits = [U_lim(0),  U_lim(2)]  ; limits for U0
  parinfo[1].limits = [Ne_lim(0), Ne_lim(2)] ; limits for Ne
  parinfo[2].limits = [Te_lim(0), Te_lim(2)] ; limits for Te
  
  err = make_array(n_elements(ind),value=1e-9)
  P = mpfitfun('mvn_lpw_J_e_thermal',U(ind),I_tmp(ind),err,start,PARINFO=parinfo,/quiet)
  I_tmp(ind_n) = !values.F_nan
  PP.I_electron2  = I_tmp
  
  fit_ind = ind
  
  PP.No_e  = 1
  PP.U0  = P[0]
  PP.Ne1 = P[1]
  PP.Te1 = P[2]
  
  PP.fit_err = transpose([[U(ind)],[err]])
  PP.I_electron1  = mvn_lpw_J_e_thermal(U_org, P([0,1,2]))  ;P[U,N,T]  
  ;PP.I_ion        = mvn_lpw_J_i_thermal(U_org,[PP.U0, PP.Ni, PP.Ti, PP.Vi])
  PP.I_ion        = mvn_lpw_J_i_thermal(U_org,[PP.U0, PP.Ni, PP.Ti, PP.Vi])
  PP.I_photo      = make_array(n_elements(U_org),1,value = !values.F_nan)

  PP.I_tot        = PP.I_electron1 + PP.I_ion
  

  Ie1   = mvn_lpw_J_e_thermal(U(fit_ind), P([0,1,2]))  ;P[U,N,T]
  Ii    = mvn_lpw_J_i_thermal(U(fit_ind),[PP.U0, PP.Ni, PP.Ti, PP.Vi])
  I_tot = Ie1 + Ii  
  PP.fit_err2 = stddev(abs((I_tot - I(fit_ind))/I(fit_ind)),/nan)
  PP.efit_points = n_elements(fit_ind)
  
  PP.Ne_tot = PP.Ne1
  PP.Te     = PP.Te1
  
  ;goto, FIT_END_fitswp_10V_00
  ;----- Try correct the ion current using fixed U0 ------------
  U0_pre = PP.U0
  U_lim = [-20, U(U_Imin)-1]
  ind = where(U gt U_lim(0) and U le U_lim(1)) ;& print, U_lim  
  
  U_lim  = [U0_pre-2.0, U0_pre, U0_pre+2.0]
  Ni_lim = [1e2, 1e4, 1e6]
  Ti_lim = [1e-2, 1e-1, 1e1]
  Vi_lim = [0, Vsc, 50]
  
  start   = [U_lim(1), Ni_lim(1), Ti_lim(1), Vi_lim(1)]
  
  parinfo = replicate({fixed:0, limited:[1,1], limits:[0.D,0.D]},n_elements(start))
  parinfo[0].limits = [U_lim(0),  U_lim(2)]  ; limits for U0
  parinfo[1].limits = [Ni_lim(0), Ni_lim(2)] ; limits for Ni
  parinfo[2].limits = [Ti_lim(0), Ti_lim(2)] ; limits for Ti
  parinfo[3].limits = [Vi_lim(0), Vi_lim(2)] ; limits for Vi
  
  parinfo[0].fixed = 1  ; Ufloat to be fixed
  ;parinfo[3].fixed = 1  ; Velocity to be fixed
  
  err = make_array(n_elements(ind),value=1e-9)
  P = mpfitfun('mvn_lpw_J_i_thermal',U(ind),I(ind),err,start,PARINFO=parinfo,/quiet)
 
;print, PP.Ni  
  PP.I_ion        = mvn_lpw_J_i_thermal(U_org,P([0,1,2,3]))
  PP.I_tot        = PP.I_electron1 + PP.I_ion
  PP.U0  = P[0]
  PP.Ni  = P[1]
  PP.Ti  = P[2]
  PP.Vi  = P[3]
;print, PP.Ni
  
  goto, FIT_END_fitswp_10V_00
  ;----- Finaly try one electron and one CO2 ion components fitting based on the result above
  U0_pre = P(0) & U_lim = [-U0_pre-17,  -U0_pre+9]
  ind = where(U gt U_lim(0) and U lt U_lim(1))
  
  U0_pre = PP.U0
  U_lim  = [U0_pre-2.0, U0_pre, U0_pre+2.0]
  Ne_lim = [1e0, PP.Ne1, 1e6]
  Te_lim = [1e-2, PP.Te1, 1e1]
  Ni_lim = [1e0, PP.Ni, 1e6]
  Ti_lim = [1e-2, PP.Ti, 1e1]
  Vi_lim = [0, PP.Vi, 50]
  
  start   = [U_lim(1), Ne_lim(1), Te_lim(1), Ni_lim(1), Ti_lim(1), Vi_lim(1)]
  
  parinfo = replicate({fixed:0, limited:[1,1], limits:[0.D,0.D]},n_elements(start))
  parinfo[0].limits = [U_lim(0),  U_lim(2)]  ; limits for U0
  parinfo[1].limits = [Ne_lim(0), Ne_lim(2)] ; limits for Ne
  parinfo[2].limits = [Te_lim(0), Te_lim(2)] ; limits for Te
  parinfo[3].limits = [Ni_lim(0), Ni_lim(2)] ; limits for Ne
  parinfo[4].limits = [Ti_lim(0), Ti_lim(2)] ; limits for Te
  parinfo[5].limits = [Vi_lim(0), Vi_lim(2)] ; limits for Te
  
  err = make_array(n_elements(ind),value=1e-9)
  P = mpfitfun('mvn_lpw_J_1e_1i_thermal',U(ind),I(ind),err,start,PARINFO=parinfo,/quiet)
  
  PP.fit_err = transpose([[U(ind)],[err]])
  PP.I_electron1  = mvn_lpw_J_e_thermal(U, P([0,1,2]))  ;P[U,N,T]
  PP.I_ion        = mvn_lpw_J_i_thermal(U,P([0,3,4,5]))
  PP.I_tot        = PP.I_electron1 + PP.I_ion
  
  PP.No_e  = 1
  PP.U0  = P[0]
  PP.Ne1 = P[1]
  PP.Te1 = P[2]
  PP.Ni  = P[3]
  PP.Ti  = P[4]
  PP.Vi  = P[5]
  
  FIT_END_fitswp_10V_00:
  givenU = [givenU,!values.F_nan,!values.F_nan]
  PP.U_input = givenU
  
  ;PP.fit_err2 = stddev(abs((PP.I_TOT - PP.CURRENT)/PP.CURRENT),/nan)
  
  return, PP
end
;------------------------------------------------------------------------------ fitswp_10V_00 -----

;------- fitswp_10V_01 ----------------------------------------------------------------------------
function fitswp_10V_01, PP_org, Vsc=Vsc, givenU=givenU

  PP = PP_org
  if(n_elements(where(pp.voltage ne pp.voltage(0)))) le 3 then return, PP
  
  PP.fit_function_name = 'fitswp_10V_01'

  U = PP.voltage &  I = PP.current
  U_org = U

  if keyword_set(Vsc) eq 0 then Vsc = 4.0

  ;givenU=!values.F_nan
  if keyword_set(givenU) eq 0 then givenU=!values.F_nan
  ;if n_elements(givenU) gt 1 then givenU = givenU(0)

  ;----- Is ion ofset ok? Ignore all(I) > 0.------------
  ind = where(I lt 0.0)
  if n_elements(ind) le 3 then return, pp
 
  ;----- look for zero crossing by 1) finding min(|I|) and 2) use myzero around it -------
  ind_Ival = where(abs(pp.current) ge 2.0e-9) ; take away under noise level data point
  I_val = interpol(I(ind_Ival),U(ind_Ival),U) ; and interpolate with linear
  
  ind_Imin = where(abs(I_val) eq min(abs(I_val))) ; find min(|I|) 
  ind_Imin=ind_Imin(0) & U_Imin=U(ind_Imin)
  
  U_lim_tmp = [U_Imin-2., U_Imin+2.0]   ; fine tune U_Izero using myzero
  ind_tmp = where(U ge U_lim_tmp(0) and U le U_lim_tmp(1))
  U_Imin = myzero(U(ind_tmp),I_val(ind_tmp))
  if finite(U_Imin) ne 1 then return, PP
  if U_Imin ge max(U,/nan) then return, PP
  PP.U_zero = U_Imin

  ;----- look for dIdU peak -------------------------------
  ind = sort(U) & U_sorted = U(ind) & I_sorted = I(ind)
  dIdU = deriv(U_sorted,I_sorted)
  ind_search = where(U_sorted ge U_Imin and U_sorted le U_Imin+5.0)
  U_tmp    = U_sorted(ind_search) & dIdU_tmp = dIdU(ind_search)
  ind_dIdUmax = where( dIdU_tmp eq max(dIdU_tmp,/NAN)) & ind_dIdUmax=ind_dIdUmax(0)
  U_dIdUmax = U_tmp(ind_dIdUmax)
  if finite(U_dIdUmax) ne 1 then return, PP  

  ;----- Define givenU if not assigned --------------------
  if keyword_set(givenU) then if finite(givenU(0)) eq 0 then begin
    ;if U_dIdUmax gt U_Imin then givenU = -U_dIdUmax else givenU = -U_Imin
   ;givenU = [-(U_Imin + (U_dIdUmax-U_Imin)*1.0/2.0), -U_dIdUmax]
    givenU = [-(U_Imin + (U_dIdUmax-U_Imin)*1.0/2.0), -U_dIdUmax]
  endif
  pp.U_input=givenU; , !values.F_nan, !values.F_nan]
 ;print, 'givenU'  
 ;print, givenU
 ;print, [-(U_Imin + (U_dIdUmax-U_Imin)*2.0/3.0), -U_dIdUmax]
  
  ;----- Try fitting ion side to subtract the electron current ----------------
  ;----- Ion current is  straight rather than the theoretical erf curve -------
  fit_Ulim = [-20, U_Imin]
  fit_ind = where(U lt fit_Ulim(1) and U gt fit_Ulim(0)) ;& ind = ind(1:n_elements(ind)-1)  
  coeff = fit_ion_linear(U(ind), I(ind),U_lim=fit_Ulim)
  I_ion = coeff(0) + coeff(1) * U
  PP.I_ion = I_ion
  PP.m = coeff(0) & PP.b = coeff(1)
  PP.Ii_ind(fit_ind) = I(fit_ind)
  
  ;----- Replace linear part with model ---------------------------------------
  ;dI = stddev(abs(I_ion(fit_ind)-I(fit_ind)))
  ;pp.I_ion2 = I_ion + 2.*dI
  ;ind = where( U le 0. and I le PP.I_ion+2.*dI )
  ;U_Ie = U(ind) & U_Iiupper = max(U_Ie)
  ;ind = where(U lt U_Iiupper)
  ;I(ind) = I_ion(ind)

  ;----- Replace noise small current data (< +-2e-9 [A]) with model ion -------
  noise_ind = where(abs(I) le 1.e-9)
  I(noise_ind) = I_ion(noise_ind)
  I_tmp = I - I_ion
  
goto, fitswp_10V_01_FIT_E
  
  U0_pre = -U_Imin
  U_lim  = [U0_pre-2.0, U0_pre, U0_pre+2.0]
  Ni_lim = [1e2, 1e4, 1e6]
  Ti_lim = [1e-2, 1e-1, 1e1]
  Vi_lim = [0, Vsc, 10]
  mi_lim = [1, 32, 40]

  fit_Ulim = [-20, U_Imin]
  fit_ind = where(U gt fit_Ulim(0) and U le fit_Ulim(1)) ;& print, U_lim
  ;PP.Ii_ind(fit_ind) = I(fit_ind)
  if n_elements(fit_ind) lt 3 then return, PP

  start   = [U_lim(1), Ni_lim(1), Ti_lim(1), Vi_lim(1), mi_lim(1)]

  parinfo = replicate({fixed:0, limited:[1,1], limits:[0.D,0.D]},n_elements(start))
  parinfo[0].limits = [U_lim(0),  U_lim(2)]  ; limits for U0
  parinfo[1].limits = [Ni_lim(0), Ni_lim(2)] ; limits for Ni
  parinfo[2].limits = [Ti_lim(0), Ti_lim(2)] ; limits for Ti
  parinfo[3].limits = [Vi_lim(0), Vi_lim(2)] ; limits for Vi
  parinfo[4].limits = [mi_lim(0), mi_lim(2)] ; limits for Vi

  parinfo[2].fixed = 1  ; Ti to be fixed
  ;parinfo[3].fixed = 1  ; Velocity to be fixed
  ;parinfo[4].fixed = 1  ; Velocity to be fixed

  err = make_array(n_elements(fit_ind),value=1e-9)
  P = mpfitfun('mvn_lpw_J_i_thermal',U(fit_ind),I(fit_ind),err,start,PARINFO=parinfo,/quiet)

  PP.I_ion        = mvn_lpw_J_i_thermal(U_org,P([0,1,2,3,4]))
  PP.U0  = P[0]
  PP.Ni  = P[1]
  PP.Ti  = P[2]
  PP.Vi  = P[3]

fitswp_10V_01_FIT_E:

  delvar, fit_Uind, fit_ind, fit_Ulim
  ;----- Try fitting electron with two components fitting -----
  U_sorted = U(sort(U))
  ind = where(U_sorted gt U_dIdUmax) & next2peak = U_sorted(ind(1)) & delvar, ind
  ind = where(U_sorted lt U_dIdUmax) & next2peak2= U_sorted(ind(n_elements(ind)-1)) & delvar, ind
  ind = where(U_sorted lt U_Imin)    & next2min  = U_sorted(ind(n_elements(ind)-1)) & delvar, ind
 ;fit_Ulim = [next2min, U_dIdUmax] & print, fit_Ulim
  fit_Ulim = [U_Imin, next2peak]  & ;print, fit_Ulim
  ;fit_Ulim = [U_Imin-1, next2peak]
  fit_ind = where(U ge fit_Ulim(0) and U le fit_Ulim(1)) ;& print, U_lim
  PP.Ie_ind = make_array(n_elements(PP.current),value=!values.F_NAN)
  PP.Ie_ind(fit_ind) = I_tmp(fit_ind)

  if n_elements(where(finite(PP.Ie_ind))) lt 5 then goto, fitswp_10V_01_FIT_one_E

  dU = 0.5
  U0_lim  = [givenU(0)-dU, givenU(0), givenU(0)+dU]
  U1_lim  = [givenU(1)-dU, givenU(1), givenU(1)+dU]
  Ne_lim = [1e1, 1e3, 1e6]
  Te_lim = [1e-2, 0.5, 1e1]

  start   = [U0_lim(1), U1_lim(1), Ne_lim(1), Ne_lim(1), Te_lim(1), Te_lim(1)]

  parinfo = replicate({fixed:0, limited:[1,1], limits:[0.D,0.D]},n_elements(start))
  parinfo[0].limits = [U0_lim(0),  U0_lim(2)]  ; limits for U0
  parinfo[1].limits = [U1_lim(0),  U1_lim(2)]  ; limits for U0
  parinfo[2].limits = [Ne_lim(0), Ne_lim(2)] ; limits for Ne
  parinfo[3].limits = [Ne_lim(0), Ne_lim(2)] ; limits for Ne
  parinfo[4].limits = [Te_lim(0), Te_lim(2)] ; limits for Te
  parinfo[5].limits = [Te_lim(0), Te_lim(2)] ; limits for Te

  err = make_array(n_elements(fit_ind),value=1e-9)
  P = mpfitfun('mvn_lpw_J_2e_thermal',U(fit_ind),I_tmp(fit_ind),err,start,PARINFO=parinfo,/quiet)

  if finite(P(0)) eq 0 then return, PP 

  PP.No_e  = 2
  if P[0] ge P[1] then begin
    PP.U0  = P[0] &  PP.U1  = P[1]
    PP.Ne1 = P[2] &  PP.Ne2 = P[3]
    PP.Te1 = P[4] &  PP.Te2 = P[5]
  endif else begin
    PP.U0  = P[1] &  PP.U1  = P[0]
    PP.Ne1 = P[3] &  PP.Ne2 = P[2]
    PP.Te1 = P[5] &  PP.Te2 = P[4]
  endelse

  PP.fit_err = transpose([[U(fit_ind)],[err]])
  PP.I_electron1  = mvn_lpw_J_e_thermal(U_org, [PP.U0,PP.Ne1,PP.Te1])  ;P[U,N,T]
  PP.I_electron2  = mvn_lpw_J_e_thermal(U_org, [PP.U1,PP.Ne2,PP.Te2])  ;P[U,N,T]

  PP.Ne_tot = PP.Ne1 + PP.Ne2
  PP.Te     = mean([PP.Te1 , PP.Te2])

  goto, END_fitswp_10V_01
    
fitswp_10V_01_FIT_one_E:

  givenU = [givenU(1), !values.F_nan, !values.F_nan]
  pp.U_input=givenU 
  dU = 1.0
  U_lim  = [givenU(0)-dU, givenU(0), givenU(0)+dU]
  Ne_lim = [1e1, 1e3, 1e6]
  Te_lim = [1e-2, 0.5, 1e1]
  
  start   = [U_lim(1), Ne_lim(1), Te_lim(1)]
  
  parinfo = replicate({fixed:0, limited:[1,1], limits:[0.D,0.D]},n_elements(start))
  parinfo[0].limits = [U_lim(0),  U_lim(2)]  ; limits for U0
  parinfo[1].limits = [Ne_lim(0), Ne_lim(2)] ; limits for Ne
  parinfo[2].limits = [Te_lim(0), Te_lim(2)] ; limits for Te
  
  err = make_array(n_elements(fit_ind),value=1e-9)
  P = mpfitfun('mvn_lpw_J_e_thermal',U(fit_ind),I_tmp(fit_ind),err,start,PARINFO=parinfo,/quiet)
  
  if finite(P(0)) eq 0 then return, PP
  
  PP.No_e  = 1
  PP.U0  = P[0] & PP.Ne1 = P[1] & PP.Te1 = P[2]
  
  PP.fit_err = transpose([[U(fit_ind)],[err]])
  PP.I_electron1  = mvn_lpw_J_e_thermal(U_org, [PP.U0,PP.Ne1,PP.Te1])  ;P[U,N,T]
  
  PP.Ne_tot = PP.Ne1
  PP.Te     = PP.Te1

  goto, END_fitswp_10V_01

  ;----- re-calcurate Ion with fixed Ufloat -----
  Ii_cyl = smooth(PP.current - PP.I_ion, 4)  
  fit_ind = where(Ii_cyl gt 1e-9 and U le U_Imin+0.0)  
  PP.Ii_ind = make_array(128,1,value=!values.F_nan)
  PP.Ii_ind(fit_ind) = I(fit_ind)

  
  U0_pre = PP.U0 & ;print, U0_pre
  U_lim  = [U0_pre-2.0, U0_pre, U0_pre+2.0]
  Ni_lim = [1e2, 1e4, 1e6]
  Ti_lim = [1e-2, PP.Te, 1e1]
  Vi_lim = [0, Vsc, 10]
  mi_lim = [1, 32, 100]

  start   = [U_lim(1), Ni_lim(1), Ti_lim(1), Vi_lim(1), mi_lim(1)]

  parinfo = replicate({fixed:0, limited:[1,1], limits:[0.D,0.D]},n_elements(start))
  parinfo[0].limits = [U_lim(0),  U_lim(2)]  ; limits for U0
  parinfo[1].limits = [Ni_lim(0), Ni_lim(2)] ; limits for Ni
  parinfo[2].limits = [Ti_lim(0), Ti_lim(2)] ; limits for Ti
  parinfo[3].limits = [Vi_lim(0), Vi_lim(2)] ; limits for Vi
  parinfo[4].limits = [mi_lim(0), mi_lim(2)] ; limits for Vi

  parinfo[0].fixed = 1
  parinfo[1].fixed = 0
  parinfo[2].fixed = 0
  parinfo[3].fixed = 0
  parinfo[4].fixed = 0

  err = make_array(n_elements(fit_ind),value=1e-9)
  P = mpfitfun('mvn_lpw_J_i_thermal',U(fit_ind),I(fit_ind),err,start,PARINFO=parinfo,/quiet)

  PP.I_ion        = mvn_lpw_J_i_thermal(U_org,P([0,1,2,3,4]))
  PP.U0  = P[0]
  PP.Ni  = P[1]
  PP.Ti  = P[2]
  PP.Vi  = P[3]
  PP.mi  = P[4]

  ;print, 'Ion' &   print, P

END_fitswp_10V_01:
  PP.I_tot = PP.I_electron1 + PP.I_electron2 + PP.I_ion

  fit_ind = where(finite(PP.Ie_ind))
  PP.fit_err2 = stddev(abs((PP.current(fit_ind) - PP.I_tot(fit_ind))/PP.I_tot(fit_ind)),/nan)
  PP.efit_points = n_elements(fit_ind)
  
  ;if pp.Te1 le 1e-2 then pp.flg = 1
  ;if pp.Te2 le 1e-2 then pp.flg = 1

  return, PP
end
;------------------------------------------------------------------------------ fitswp_10V_01 -----

;------- fitswp_10V_01_1e -------------------------------------------------------------------------
function fitswp_10V_01_1e, PP_org, Vsc=Vsc, givenU=givenU

  PP = PP_org
  if(n_elements(where(pp.voltage ne pp.voltage(0)))) le 3 then return, PP
  
  PP.fit_function_name = 'fitswp_10V_01_1e'
  
  U = PP.voltage &  I = PP.current
  U_org = U
  
  if keyword_set(Vsc) eq 0 then Vsc = 4.0
  
  ;givenU=!values.F_nan
  if keyword_set(givenU) eq 0 then givenU=!values.F_nan
  ;if n_elements(givenU) gt 1 then givenU = givenU(0)
  
  ;----- Is ion ofset ok? Ignore all(I) > 0.------------
  ind = where(I lt 0.0)
  if n_elements(ind) le 3 then return, pp
  
  ;----- look for zero crossing by 1) finding min(|I|) and 2) use myzero around it -------
  ind_Ival = where(abs(pp.current) ge 2.0e-9) ; take away under noise level data point
  I_val = interpol(I(ind_Ival),U(ind_Ival),U) ; and interpolate with linear
  
  ind_Imin = where(abs(I_val) eq min(abs(I_val))) ; find min(|I|)
  ind_Imin=ind_Imin(0) & U_Imin=U(ind_Imin)
  
  U_lim_tmp = [U_Imin-2., U_Imin+2.0]   ; fine tune U_Izero using myzero
  ind_tmp = where(U ge U_lim_tmp(0) and U le U_lim_tmp(1))
  U_Imin = myzero(U(ind_tmp),I_val(ind_tmp))
  if finite(U_Imin) ne 1 then return, PP
  if U_Imin ge max(U,/nan) then return, PP
  PP.U_zero = U_Imin
  
  ;----- look for dIdU peak -------------------------------
  ind = sort(U) & U_sorted = U(ind) & I_sorted = I(ind)
  dIdU = deriv(U_sorted,I_sorted)
  ind_search = where(U_sorted ge U_Imin and U_sorted le U_Imin+5.0)
  U_tmp    = U_sorted(ind_search) & dIdU_tmp = dIdU(ind_search)
  ind_dIdUmax = where( dIdU_tmp eq max(dIdU_tmp,/NAN)) & ind_dIdUmax=ind_dIdUmax(0)
  U_dIdUmax = U_tmp(ind_dIdUmax)
  if finite(U_dIdUmax) ne 1 then return, PP
  
  ;----- Define givenU if not assigned --------------------
  if keyword_set(givenU) then if finite(givenU(0)) eq 0 then givenU = -U_dIdUmax
  
  pp.U_input = [givenU , !values.F_nan, !values.F_nan]
;  print, 'givenU'
;  print, givenU
  
  
  ;----- Try fitting ion side to subtract the electron current ----------------
  ;----- Ion current is  straight rather than the theoretical erf curve -------
  fit_Ulim = [-20, U_Imin-5]
  fit_ind = where(U lt fit_Ulim(1) and U gt fit_Ulim(0)) ;& ind = ind(1:n_elements(ind)-1)
  coeff = fit_ion_linear(U(ind), I(ind),U_lim=fit_Ulim)
  I_ion = coeff(0) + coeff(1) * U
  PP.I_ion = I_ion
  PP.m = coeff(0) & PP.b = coeff(1)
  PP.Ii_ind(fit_ind) = I(fit_ind)
  
  ;----- Replace linear part with model ---------------------------------------
  ;dI = stddev(abs(I_ion(fit_ind)-I(fit_ind)))
  ;pp.I_ion2 = I_ion + 2.*dI
  ;ind = where( U le 0. and I le PP.I_ion+2.*dI )
  ;U_Ie = U(ind) & U_Iiupper = max(U_Ie)
  ;ind = where(U lt U_Iiupper)
  ;I(ind) = I_ion(ind)
  
  ;----- Replace noise small current data (< +-2e-9 [A]) with model ion -------
  noise_ind = where(abs(I) le 1.e-9)
  I(noise_ind) = I_ion(noise_ind)
  I_tmp = I - I_ion
  
  goto, fitswp_10V_01_FIT_E
  
  U0_pre = -U_Imin
  U_lim  = [U0_pre-2.0, U0_pre, U0_pre+2.0]
  Ni_lim = [1e2, 1e4, 1e6]
  Ti_lim = [1e-2, 1e-1, 1e1]
  Vi_lim = [0, Vsc, 10]
  mi_lim = [1, 32, 40]
  
  fit_Ulim = [-20, U_Imin]
  fit_ind = where(U gt fit_Ulim(0) and U le fit_Ulim(1)) ;& print, U_lim
  ;PP.Ii_ind(fit_ind) = I(fit_ind)
  if n_elements(fit_ind) lt 3 then return, PP
  
  start   = [U_lim(1), Ni_lim(1), Ti_lim(1), Vi_lim(1), mi_lim(1)]
  
  parinfo = replicate({fixed:0, limited:[1,1], limits:[0.D,0.D]},n_elements(start))
  parinfo[0].limits = [U_lim(0),  U_lim(2)]  ; limits for U0
  parinfo[1].limits = [Ni_lim(0), Ni_lim(2)] ; limits for Ni
  parinfo[2].limits = [Ti_lim(0), Ti_lim(2)] ; limits for Ti
  parinfo[3].limits = [Vi_lim(0), Vi_lim(2)] ; limits for Vi
  parinfo[4].limits = [mi_lim(0), mi_lim(2)] ; limits for Vi
  
  parinfo[2].fixed = 1  ; Ti to be fixed
  ;parinfo[3].fixed = 1  ; Velocity to be fixed
  ;parinfo[4].fixed = 1  ; Velocity to be fixed
  
  err = make_array(n_elements(fit_ind),value=1e-9)
  P = mpfitfun('mvn_lpw_J_i_thermal_erf',U(fit_ind),I(fit_ind),err,start,PARINFO=parinfo,/quiet)
  
  PP.I_ion        = mvn_lpw_J_i_thermal_erf(U_org,P([0,1,2,3,4]))
  PP.U0  = P[0]
  PP.Ni  = P[1]
  PP.Ti  = P[2]
  PP.Vi  = P[3]
  
  fitswp_10V_01_FIT_E:
  
  delvar, fit_Uind, fit_ind, fit_Ulim
  ;----- Try fitting electron with two components fitting -----
  U_sorted = U(sort(U))
  ind = where(U_sorted gt U_dIdUmax) & next2peak = U_sorted(ind(1)) & delvar, ind
  ind = where(U_sorted lt U_dIdUmax) & next2peak2= U_sorted(ind(n_elements(ind)-1)) & delvar, ind
  ind = where(U_sorted lt U_Imin)    & next2min  = U_sorted(ind(n_elements(ind)-1)) & delvar, ind
  fit_Ulim = [next2min, next2peak2]; & print, fit_Ulim
 ;fit_Ulim = [next2min, U_dIdUmax] & print, fit_Ulim
  ; fit_Ulim = [next2min, U_dIdUmax] & print, fit_Ulim
  ; fit_Ulim = [next2min, next2peak2] & print, fit_Ulim
  
  ;fit_Ulim = [U_Imin, next2peak]  & print, fit_Ulim
  ;fit_Ulim = [U_Imin-1, next2peak]
  fit_ind = where(U ge fit_Ulim(0) and U le fit_Ulim(1)) ;& print, U_lim
  PP.Ie_ind = make_array(n_elements(PP.current),value=!values.F_NAN)
  PP.Ie_ind(fit_ind) = I_tmp(fit_ind)
  
  if n_elements(where(finite(PP.Ie_ind))) lt 5 then goto, fitswp_10V_01_FIT_one_E
  
  dU = 0.8
  U0_lim  = [givenU(0)-dU, givenU(0), givenU(0)+dU]
  Ne_lim = [1e1, 1e3, 1e6]
  Te_lim = [1e-2, 0.5, 1e1]
  
  start   = [U0_lim(1), Ne_lim(1), Te_lim(1)]
  
  parinfo = replicate({fixed:0, limited:[1,1], limits:[0.D,0.D]},n_elements(start))
  parinfo[0].limits = [U0_lim(0),  U0_lim(2)]  ; limits for U0
  parinfo[1].limits = [Ne_lim(0), Ne_lim(2)] ; limits for Ne
  parinfo[2].limits = [Te_lim(0), Te_lim(2)] ; limits for Te
  
  err = make_array(n_elements(fit_ind),value=1e-9)
  P = mpfitfun('mvn_lpw_J_e_thermal',U(fit_ind),I_tmp(fit_ind),err,start,PARINFO=parinfo,/quiet,PERROR=PERROR,BESTNORM=BESTNORM)
  
  if finite(P(0)) eq 0 then return, PP
  
  PP.No_e  = 1
  PP.U0  = P[0] & PP.Ne1 = P[1] &  PP.Te1 = P[2]
  if n_elements(fit_ind) ge 3 then begin
    if keyword_set(perror) ne 0 then begin
      PP.dU0 = perror(0) & PP.dNe1 = perror(1) & PP.dTe1 = perror(2)
    endif
  endif
  
  PP.fit_err = transpose([[U(fit_ind)],[err]])
  PP.I_electron1  = mvn_lpw_j_e_thermal(U_org, [PP.U0,PP.Ne1,PP.Te1])  ;P[U,N,T]
  
  PP.Ne_tot = PP.Ne1
  PP.Te     = PP.Te1
  
  goto, END_fitswp_10V_01
  
fitswp_10V_01_FIT_one_E:
  
  givenU = [givenU(0), !values.F_nan, !values.F_nan]
  pp.U_input=givenU
  dU = 1.0
  U_lim  = [givenU(0)-dU, givenU(0), givenU(0)+dU]
  Ne_lim = [1e1, 1e3, 1e6]
  Te_lim = [1e-2, 0.5, 1e1]
  
  start   = [U_lim(1), Ne_lim(1), Te_lim(1)]
  
  parinfo = replicate({fixed:0, limited:[1,1], limits:[0.D,0.D]},n_elements(start))
  parinfo[0].limits = [U_lim(0),  U_lim(2)]  ; limits for U0
  parinfo[1].limits = [Ne_lim(0), Ne_lim(2)] ; limits for Ne
  parinfo[2].limits = [Te_lim(0), Te_lim(2)] ; limits for Te
  
  err = make_array(n_elements(fit_ind),value=1e-9)
  P = mpfitfun('mvn_lpw_J_e_thermal',U(fit_ind),I_tmp(fit_ind),err,start,PARINFO=parinfo,/quiet,PERROR=PERROR,BESTNORM=BESTNORM)
    
  if finite(P(0)) eq 0 then return, PP
  
  PP.No_e  = 1
  PP.U0  = P[0] & PP.Ne1 = P[1] & PP.Te1 = P[2]
  if n_elements(fit_ind) ge 3 then begin
    if keyword_set(perror) ne 0 then begin
     PP.dU0 = perror(0) & PP.dNe1 = perror(1) & PP.dTe1 = perror(2)    
     DOF     = N_ELEMENTS(fit_ind) - N_ELEMENTS(P) ; deg of freedom
     PCERROR = PERROR * SQRT(BESTNORM / DOF)   ; scaled uncertainties    
     ;if dof ge 10 then stop
    endif
  endif
  
  PP.fit_err = transpose([[U(fit_ind)],[err]])
  PP.I_electron1  = mvn_lpw_J_e_thermal(U_org, [PP.U0,PP.Ne1,PP.Te1])  ;P[U,N,T]
  
  PP.Ne_tot = PP.Ne1
  PP.Te     = PP.Te1
  goto, END_fitswp_10V_01
  
  ;----- re-calcurate Ion with fixed Ufloat -----
  Ii_cyl = smooth(PP.current - PP.I_ion, 4)
  fit_ind = where(Ii_cyl gt 1e-9 and U le U_Imin+0.0)
  PP.Ii_ind = make_array(128,1,value=!values.F_nan)
  PP.Ii_ind(fit_ind) = I(fit_ind)
  
  
  U0_pre = PP.U0 & ;print, U0_pre
  U_lim  = [U0_pre-2.0, U0_pre, U0_pre+2.0]
  Ni_lim = [1e2, 1e4, 1e6]
  Ti_lim = [1e-2, PP.Te, 1e1]
  Vi_lim = [0, Vsc, 10]
  mi_lim = [1, 32, 100]
  
  start   = [U_lim(1), Ni_lim(1), Ti_lim(1), Vi_lim(1), mi_lim(1)]
  
  parinfo = replicate({fixed:0, limited:[1,1], limits:[0.D,0.D]},n_elements(start))
  parinfo[0].limits = [U_lim(0),  U_lim(2)]  ; limits for U0
  parinfo[1].limits = [Ni_lim(0), Ni_lim(2)] ; limits for Ni
  parinfo[2].limits = [Ti_lim(0), Ti_lim(2)] ; limits for Ti
  parinfo[3].limits = [Vi_lim(0), Vi_lim(2)] ; limits for Vi
  parinfo[4].limits = [mi_lim(0), mi_lim(2)] ; limits for Vi
  
  parinfo[0].fixed = 1
  parinfo[1].fixed = 0
  parinfo[2].fixed = 0
  parinfo[3].fixed = 0
  parinfo[4].fixed = 0
  
  err = make_array(n_elements(fit_ind),value=1e-9)
  P = mpfitfun('mvn_lpw_J_i_thermal',U(fit_ind),I(fit_ind),err,start,PARINFO=parinfo,/quiet)
  
  PP.I_ion        = mvn_lpw_J_i_thermal(U_org,P([0,1,2,3,4]))
  PP.U0  = P[0]
  PP.Ni  = P[1]
  PP.Ti  = P[2]
  PP.Vi  = P[3]
  PP.mi  = P[4]
  
  ;print, 'Ion' &   print, P
  
END_fitswp_10V_01:
PP.I_tot = PP.I_electron1 +  PP.I_ion

fit_ind = where(finite(PP.Ie_ind))
fit_err = stddev(abs((PP.current(fit_ind) - PP.I_tot(fit_ind))/PP.I_tot(fit_ind)),/nan)
PP.fit_err2 = fit_err

PP.dU0 = alog(fit_err*abs(PP.U0)) & PP.dNe1 = PP.Ne1*fit_err & PP.dTe1 = (PP.Te1*fit_err)^2.0

;PP.fit_err2 = stddev(abs((alog(PP.current(fit_ind)) - alog(PP.I_tot(fit_ind)))/alog(PP.I_tot(fit_ind))),/nan)
PP.efit_points = n_elements(fit_ind)

;if pp.Te1 le 1e-2 then pp.flg = 1
;if pp.Te2 le 1e-2 then pp.flg = 1

return, PP
end
;--------------------------------------------------------------------------- fitswp_10V_01_1e -----

;------- fitswp_10V_02_1e -------------------------------------------------------------------------
function fitswp_10V_02_1e, PP_org, Vsc=Vsc, fix_U0=fix_U0 ;, givenU=givenU

  PP = PP_org
  if(n_elements(where(pp.voltage ne pp.voltage(0)))) le 3 then return, PP
  
  PP.fit_function_name = 'fitswp_10V_02_1e'
  pp.flg = 0
  
  U = PP.voltage &  I = PP.current
  U_org = U
  
  if keyword_set(Vsc) eq 0 then if finite(pp.Vsc) then Vsc = pp.Vsc else Vsc = 4.0
  
  ;givenU=!values.F_nan
  ;if keyword_set(givenU) eq 0 then givenU=!values.F_nan
  ;if n_elements(givenU) gt 1 then givenU = givenU(0)
  
  ;----- Is ion ofset ok? Ignore all(I) > 0.------------
  ind = where(I lt 0.0)
  if n_elements(ind) le 3 then begin
    pp.flg = -1
    return, pp
  endif
  
  ;----- look for zero crossing by 1) finding min(|I|) and 2) use myzero around it -------
  ind_Ival = where(abs(pp.current) ge 2.0e-9) ; take away under noise level data point
  I_val = interpol(I(ind_Ival),U(ind_Ival),U) ; and interpolate with linear
  
  ind_Imin = where(abs(I_val) eq min(abs(I_val))) ; find min(|I|)
  ind_Imin=ind_Imin(0) & U_Imin=U(ind_Imin)
  
  U_lim_tmp = [U_Imin-2., U_Imin+2.0]   ; fine tune U_Izero using myzero
  ind_tmp = where(U ge U_lim_tmp(0) and U le U_lim_tmp(1))
  U_Imin = myzero(U(ind_tmp),I_val(ind_tmp))
  if finite(U_Imin) ne 1 then begin
    pp.flg = -1
    return, PP
  endif
  if U_Imin ge max(U,/nan) then begin
    pp.flg = -1
    return, PP
  endif
  PP.U_zero = U_Imin
  
  ;----- look for dIdU peak -------------------------------
  ind = sort(U) & U_sorted = U(ind) & I_sorted = I(ind)
  dIdU = deriv(U_sorted,I_sorted)
  ind_search = where(U_sorted ge U_Imin and U_sorted le U_Imin+5.0)
  U_tmp    = U_sorted(ind_search) & dIdU_tmp = dIdU(ind_search)
  ind_dIdUmax = where( dIdU_tmp eq max(dIdU_tmp,/NAN)) & ind_dIdUmax=ind_dIdUmax(0)
  U_dIdUmax = U_tmp(ind_dIdUmax)
  if finite(U_dIdUmax) ne 1 then begin
    pp.flg = -2
    return, PP
  endif
  
  ;----- Define givenU if not assigned --------------------
  ;if keyword_set(givenU) then if finite(givenU(0)) eq 0 then givenU = -U_dIdUmax
  
  pp.U_input = [!values.F_nan, !values.F_nan, !values.F_nan]
  ;print, 'givenU'
  ;print, givenU
  
  ;----- Get the ion current level with liner function ------------------------
  fit_Ulim = [-20, U_Imin-1.]
  fit_ind = where(U lt fit_Ulim(1) and U gt fit_Ulim(0)) ;& ind = ind(1:n_elements(ind)-1)
  coeff = fit_ion_linear(U(ind), I(ind),U_lim=fit_Ulim)
  I_ion = coeff(0) + coeff(1) * U
  PP.I_ion = I_ion
  PP.m = coeff(0) & PP.b = coeff(1)
  PP.Ii_ind(fit_ind) = I(fit_ind)
  
  ;----- Replace noise small current data (< +-2e-9 [A]) with model ion -------
  noise_ind = where(abs(I) le 1.e-9)
  I(noise_ind) = I_ion(noise_ind)
  ;I_tmp = I - I_ion
  
  delvar, fit_Uind, fit_ind, fit_Ulim
  
  ;----- Try fit the ion current ------------
  ;fit_Ulim = [-20, U_dIdUmax-2.] ; Near U_Izero the current can be desturbed 
                                 ;by the electron current.
                                 ; Avoid those points.
  fit_Ulim = [-20, U_Imin]
 ;fit_Ulim = [U_Imin-2, U_Imin]
  fit_ind = where(U ge fit_Ulim(0) and U le fit_Ulim(1)) ;& print, U_lim
  PP.Ii_ind = make_array(n_elements(PP.current),value=!values.F_NAN)
  PP.Ii_ind(fit_ind) = pp.current(fit_ind)
  
  type = 0 ; 1 for U0=Umin, 0 for U0=U0_from_electron
  U_lim  = [-U_dIdUmax-1.0, -U_dIdUmax, -U_dIdUmax+1.0]
 ;U_lim  = [-U_Imin-1.0,  -U_Imin, -U_Imin+1.0]
  Ni_lim = [1e2, 1e3, 1e6]
  Ti_lim = [1e-2, 1e-1, 10]
  Vi_lim = [0, 4.0, 10] ;Vi_lim = [0, Vsc, 10]
  mi_lim = [1, 32,  58]
  RXA = 1 ;RXA    = PP.RXA
  
  start   = [U_lim(1), Ni_lim(1), Ti_lim(1), Vi_lim(1), mi_lim(1) , RXA]
  
  parinfo = replicate({fixed:0, limited:[1,1], limits:[0.D,0.D]},n_elements(start))
  parinfo[0].limits = [U_lim(0),  U_lim(2)]  ; limits for U0
  parinfo[1].limits = [Ni_lim(0), Ni_lim(2)] ; limits for Ni
  parinfo[2].limits = [Ti_lim(0), Ti_lim(2)] ; limits for Ti
  parinfo[3].limits = [Vi_lim(0), Vi_lim(2)] ; limits for Vi
  parinfo[4].limits = [mi_lim(0), mi_lim(2)] ; limits for Mi
  parinfo[5].limits = [RXA, RXA] ; limits for Mi
  
  parinfo[0].fixed = 1 ;fixed U0
  parinfo[1].fixed = 0 ;unfix Ni
  parinfo[2].fixed = 0 ;unfix Ti
  parinfo[3].fixed = 1 ;fix   Vi
  parinfo[4].fixed = 0 ;unfix Mi
  parinfo[5].fixed = 1 ;fix   RXA
  
  err = make_array(n_elements(fit_ind),value=1e-9)
  sph = 0
  if sph then $
    P = mpfitfun('mvn_lpw_j_i_thermal_sph_hoegy',pp.voltage(fit_ind),pp.current(fit_ind),err,start,PARINFO=parinfo,/quiet) $
  else $
    P = mpfitfun('mvn_lpw_j_i_thermal_cyl_brace',pp.voltage(fit_ind),pp.current(fit_ind),err,start,PARINFO=parinfo,/quiet)
    
  if sph then PP.I_ion  = mvn_lpw_j_i_thermal_sph_hoegy(U_org,P) $
  else        PP.I_ion  = mvn_lpw_j_i_thermal_cyl_brace(U_org,P)
    
  PP.U0  = P[0]
  PP.Ni  = P[1]
  PP.Ti  = P[2]
  PP.Vi  = P[3]
  PP.mi  = P[4]
   
;goto, END_fitswp_10V_02_1e

  ;----- Electron fitting -----------------------------------------------------
  
  ;----- Extract retarding region ---------------------------------------------
  Ie_fit = pp.current - pp.I_ion

  ;----- Define parameter limitation ------------------------------------------  
  fit_Ulim = [U_Imin, U_dIdUmax]
  fit_ind = where(U ge fit_Ulim(0) and U le fit_Ulim(1)) ;& print, U_lim
  PP.Ie_ind = make_array(n_elements(PP.current),value=!values.F_NAN)
  PP.Ie_ind(fit_ind) = Ie_fit(fit_ind)
  
  if n_elements(where(finite(PP.Ie_ind))) lt 5 then begin
    pp.flg = -3
    goto, END_fitswp_10V_02_1e
  endif
  
  dU = 0.5
  ;U0_lim  = [givenU(0)-dU, givenU(0), givenU(0)+dU]
  U0_lim  = [-U_dIdUmax-dU, -U_dIdUmax, -U_dIdUmax+dU]  
  
  Ne_lim = [1e1, 1e3, 1e6]
  Te_lim = [1e-2, 0.5, 1e1]
  
  start   = [U0_lim(1), Ne_lim(1), Te_lim(1)]
  
  parinfo = replicate({fixed:0, limited:[1,1], limits:[0.D,0.D]},n_elements(start))
  parinfo[0].limits = [U0_lim(0), U0_lim(2)]  ; limits for U0
  parinfo[1].limits = [Ne_lim(0), Ne_lim(2)] ; limits for Ne
  parinfo[2].limits = [Te_lim(0), Te_lim(2)] ; limits for Te
  
  ;----- First fitting to determine Te ----------------------------------------
  parinfo[0].fixed = 1 ;----- Potential fixed to U_dIdVmax
  
  err = make_array(n_elements(fit_ind),value=1e-9)
  P = mpfitfun('mvn_lpw_j_e_thermal_brace',U(fit_ind),Ie_fit(fit_ind),err,start,PARINFO=parinfo,/quiet,perror=perror)
  
  if finite(P(0)) eq 0 then begin
    pp.flg = -4
    return, PP
  endif
  
  PP.No_e   = 1
  PP.U0     = P[0]
  PP.Ne1    = P[1]
  PP.Te1    = P[2]
  PP.I_electron1  = mvn_lpw_j_e_thermal_brace(U_org, [PP.U0,PP.Ne1,PP.Te1])  ;P[U,N,T]

  ;PP.dU0 = perror(0) & PP.dNe1 = perror(1) & PP.dTe1 = perror(2)

 ;if keyword_set(fix_U0) then print, pp.U0
  if keyword_set(fix_U0) then goto, err_estimate_fitswp_10V_02_1e 
  
  ;----- Second fitting to define the U0 -------------------------------------
  U_sorted = U(sort(U))
  extra = 5
  ind = where(U_sorted gt U_dIdUmax) & next2peak = U_sorted(ind(min([extra,n_elements(ind)-1]))) & delvar, ind
 ;ind = where(U_sorted lt U_dIdUmax) & next2peak = U_sorted(ind(n_elements(ind)-1)) & delvar, ind
  ;fit_Ulim = [U_Imin, -P[0]+1]
  fit_Ulim = [U_Imin, next2peak]
  fit_ind = where(U ge fit_Ulim(0) and U le fit_Ulim(1)) ;& print, U_lim
  PP.Ie_ind = make_array(n_elements(PP.current),value=!values.F_NAN)
  PP.Ie_ind(fit_ind) = Ie_fit(fit_ind)
  
  dU = 0.3
  U0_lim  = [P[0]-dU, P[0], P[0]+dU]
  Ne_lim = [1e1, P[1], 1e6]
  Te_lim = [1e-2,P[2], 1e1]
  Bt_lim = [0.0, 0.5, 1.0]
  
  start   = [U0_lim(1), Ne_lim(1), Te_lim(1), Bt_lim(1)]
  
  parinfo = replicate({fixed:0, limited:[1,1], limits:[0.D,0.D]},n_elements(start))
  parinfo[0].limits = [U0_lim(0), U0_lim(2)]  ; limits for U0
  parinfo[1].limits = [Ne_lim(0), Ne_lim(2)] ; limits for Ne
  parinfo[2].limits = [Te_lim(0), Te_lim(2)] ; limits for Te
  parinfo[3].limits = [Bt_lim(0), Bt_lim(2)] ; limits for Beta
  
  parinfo[2].fixed = 1 ;----- Te fixed
  parinfo[3].fixed = 0 ;----- fixed cylindrical if 1
  
  err = make_array(n_elements(fit_ind),value=1e-9)
  P = mpfitfun('mvn_lpw_j_e_thermal_brace',U(fit_ind),Ie_fit(fit_ind),err,start,PARINFO=parinfo,/quiet,perror=perror,BESTNORM=BESTNORM)
  
  PP.No_e   = 1
  PP.U0     = P[0]
  PP.Ne1    = P[1]
  PP.Te1    = P[2]
  PP.Dummy1 = P[3]
  
  PP.fit_err = transpose([[U(fit_ind)],[err]])
  PP.I_electron1  = mvn_lpw_j_e_thermal_brace(U_org, [PP.U0,PP.Ne1,PP.Te1,pp.dummy1])  ;P[U,N,T]
  
  PP.Ne_tot = PP.Ne1
  PP.Te     = PP.Te1
  PP.Usc    = PP.U0
  
  
err_estimate_fitswp_10V_02_1e:  
  ;----- Error estimation using the mpfitfun option ---------------------------
  ;if n_elements(fit_ind) ge 3 then begin
  ;  if keyword_set(perror) ne 0 then begin
  ;    PP.dU0 = perror(0) & PP.dNe1 = perror(1) & PP.dTe1 = perror(2)
  ;    DOF     = N_ELEMENTS(fit_ind) - N_ELEMENTS(P) ; deg of freedom
  ;    PCERROR = PERROR * SQRT(BESTNORM / DOF)   ; scaled uncertainties
  ;    ;if dof ge 10 then stop
  ;  endif
  ;endif

  ;----- Define Error for U0 --------------------------------------------------
  ind = where(abs(U(fit_ind) +pp.U0) eq min(abs(U(fit_ind) +pp.U0))) & ind=ind(0)
  pp.dU0 = abs(U(fit_ind(ind)) +pp.U0)
  if pp.dU0 ge 1.0 then pp.flg = -3

  ;----- Define Error for Te1 --------------------------------------------------
  UU = U(fit_ind) & II = Ie_fit(fit_ind)
  ind = where(UU lt -pp.U0) & UU = UU(ind) & II = II(ind)
  if n_elements(ind) le 3 then begin
    pp.flg = -3
    goto, END_fitswp_10V_02_1e
  endif
  
  ind = sort(UU)
  ind = ind(n_elements(ind)-3:n_elements(ind)-1)
  UU = UU(ind) & II=II(ind)
  
  Te_series = II/deriv(UU,II) 
  ind = where(Te_series gt 0.0) & Te_series = Te_series(ind)  
  pp.dTe1 = max( abs(Te_series-pp.Te1) )
  pp.dTe = pp.dTe1

  ;----- Define Error for Ne1 --------------------------------------------------
  pp.dNe1 = 0.5*pp.Ne1
  pp.dNe_tot = pp.dNe1
    
  goto, skip_beta_fitswp_10V_02_1e
  ;----- Third fitting is just to investigate Beta number ---------------------
  U_sorted = U(sort(U)) ;----- avoid satulation
  ind = where(U_sorted lt max(U,/nan)) & U_max = U_sorted(ind(n_elements(ind)-2)) & delvar, ind
  fit_Ulim = [U_Imin, U_max]
   fit_ind = where(U ge fit_Ulim(0) and U le fit_Ulim(1)) ;& print, U_lim
  
  start   = [pp.U0, pp.Ne1, pp.Te1, Bt_lim(1)]
  
  parinfo[0].fixed = 1
  parinfo[1].fixed = 1
  parinfo[2].fixed = 1
  parinfo[3].fixed = 0
  parinfo[3].limits = [0., 1.] ; limits for Beta
  
  err = make_array(n_elements(fit_ind),value=1e-9)
  P = mpfitfun('mvn_lpw_j_e_thermal_brace',U(fit_ind),Ie_fit(fit_ind),err,start,PARINFO=parinfo,/quiet)
  
  PP.No_e   = 1
  ;PP.U0     = P[0] & PP.Ne1    = P[1] & PP.Te1    = P[2]
  PP.Dummy1 = P[3]

  PP.fit_err = transpose([[U(fit_ind)],[err]])
  PP.I_electron1  = mvn_lpw_j_e_thermal_brace(U_org, [PP.U0,PP.Ne1,PP.Te1,pp.dummy1])  ;P[U,N,T]

skip_beta_fitswp_10V_02_1e:
;goto, END_fitswp_10V_02_1e
  
  ;----- Try fit the ion current again using the derived potential ------------
 ;fit_ind = where(finite(pp.Ii_ind))
 ;fit_Ulim = [-20, -pp.U0-3.] ; Near U_Izero the current can be desturbed by the electron current.
                              ; Avoid those points.
  fit_Ulim = [-20, U_Imin] 
  fit_ind = where(U ge fit_Ulim(0) and U le fit_Ulim(1)) ;& print, U_lim
  PP.Ii_ind = make_array(n_elements(PP.current),value=!values.F_NAN)
  
  PP.Ii_ind(fit_ind) = pp.current(fit_ind) ;   - pp.I_electron1(fit_ind)  

  type = 0 ; 1 for U0=Umin, 0 for U0=U0_from_electron
  dU = 1
  if type then U_lim  = [-U_Imin-dU, -U_Imin, -U_Imin+dU] $
  else         U_lim  = [pp.U0-1.0, pp.U0, pp.U0+1.0]
 ;U_lim  = [0-dU, 0, 0+dU]
  Ni_lim = [pp.Ne1*0.1, pp.Ne1, pp.Ne1*10.0]
  Ti_lim = [PP.Te1*0.1, PP.Te1, PP.Te1*10.0]
  Vi_lim = [0, Vsc, 10]
  mi_lim = [1, 32,  58]
  RXA    = PP.RXA
  
  start   = [U_lim(1), Ni_lim(1), Ti_lim(1), Vi_lim(1), mi_lim(1) , RXA]
  
  parinfo = replicate({fixed:0, limited:[1,1], limits:[0.D,0.D]},n_elements(start))
  parinfo[0].limits = [U_lim(0),  U_lim(2)]  ; limits for U0
  parinfo[1].limits = [Ni_lim(0), Ni_lim(2)] ; limits for Ni
  parinfo[2].limits = [Ti_lim(0), Ti_lim(2)] ; limits for Ti
  parinfo[3].limits = [Vi_lim(0), Vi_lim(2)] ; limits for Vi
  parinfo[4].limits = [mi_lim(0), mi_lim(2)] ; limits for Mi
  parinfo[5].limits = [RXA, RXA] ; limits for Mi
  
  parinfo[0].fixed = 1 ;fixed U0
  parinfo[1].fixed = 1 ;fixed Ni
  parinfo[2].fixed = 0;fixed Ti
  parinfo[3].fixed = 1 ;fixed Vi
  parinfo[4].fixed = 0 ;fixed Mi
  parinfo[5].fixed = 1 ;fixed RXA
  
  err = make_array(n_elements(fit_ind),value=1e-9)
  sph = 0
  if sph then $
    P = mpfitfun('mvn_lpw_j_i_thermal_sph_hoegy',pp.voltage(fit_ind),pp.Ii_ind(fit_ind),err,start,PARINFO=parinfo,/quiet) $
  else $
    P = mpfitfun('mvn_lpw_j_i_thermal_cyl_brace',pp.voltage(fit_ind),pp.Ii_ind(fit_ind),err,start,PARINFO=parinfo,/quiet)

  if sph then PP.I_ion  = mvn_lpw_j_i_thermal_sph_hoegy(U_org,P) $
  else        PP.I_ion  = mvn_lpw_j_i_thermal_cyl_brace(U_org,P)
    
  PP.Dummy2  = P[0]
  PP.Ni  = P[1]
  PP.Ti  = P[2]
  PP.Vi  = P[3]
  PP.mi  = P[4]

goto, END_fitswp_10V_02_1e
  ;----- Last ion fitting is just for test ------------------------------------
  fit_Ulim = [-20, U_Imin]
  fit_ind = where(U ge fit_Ulim(0) and U le fit_Ulim(1)) ;& print, U_lim

  dU = 1  
  type = 1 ; 1 for U0=Umin, 0 for U0=U0_from_electron
  if type then U_lim  = [-U_Imin-dU, -U_Imin, -U_Imin+dU] $
  else         U_lim  = [pp.U0-1.0, pp.U0, pp.U0+1.0]
  Ni_lim = [pp.Ne1*0.1, pp.Ne1, pp.Ne1*10.0]
  Ti_lim = [PP.Te1*0.1, PP.Te1, PP.Te1*10.0]
  Vi_lim = [0, Vsc, 10]
  mi_lim = [1, 32,  58]
  RXA    = PP.RXA
  
  start   = [U_lim(1), Ni_lim(1), Ti_lim(1), Vi_lim(1), mi_lim(1) , RXA]
  
  parinfo = replicate({fixed:0, limited:[1,1], limits:[0.D,0.D]},n_elements(start))
  parinfo[0].limits = [U_lim(0),  U_lim(2)]  ; limits for U0
  parinfo[1].limits = [Ni_lim(0), Ni_lim(2)] ; limits for Ni
  parinfo[2].limits = [Ti_lim(0), Ti_lim(2)] ; limits for Ti
  parinfo[3].limits = [Vi_lim(0), Vi_lim(2)] ; limits for Vi
  parinfo[4].limits = [mi_lim(0), mi_lim(2)] ; limits for Mi
  parinfo[5].limits = [RXA, RXA] ; limits for Mi
  
  parinfo[0].fixed = 0 ;fixed U0
  parinfo[1].fixed = 1 ;fixed Ni
  parinfo[2].fixed = 0;fixed Ti
  parinfo[3].fixed = 1 ;fixed Vi
  parinfo[4].fixed = 0 ;fixed Mi
  parinfo[5].fixed = 1 ;fixed RXA
  
  err = make_array(n_elements(fit_ind),value=1e-9)
  sph = 0
  if sph then $
    P = mpfitfun('mvn_lpw_j_i_thermal_sph_hoegy',pp.voltage(fit_ind),pp.Ii_ind(fit_ind),err,start,PARINFO=parinfo,/quiet) $
  else $
    P = mpfitfun('mvn_lpw_j_i_thermal_cyl_brace',pp.voltage(fit_ind),pp.Ii_ind(fit_ind),err,start,PARINFO=parinfo,/quiet)
    
  if sph then PP.I_ion2  = mvn_lpw_j_i_thermal_sph_hoegy(U_org,P) $
  else        PP.I_ion2  = mvn_lpw_j_i_thermal_cyl_brace(U_org,P)
  
  PP.Dummy2  = P[0]

END_fitswp_10V_02_1e:

PP.I_tot = PP.I_electron1 +  PP.I_ion

;pp.I_electron3 = pp.current - pp.I_ion - pp.I_electron1
;pp.Ne3 = 1

fit_ind = where(finite(PP.Ie_ind))
PP.fit_err2 = stddev(abs((PP.current(fit_ind) - PP.I_tot(fit_ind))/PP.I_tot(fit_ind)),/nan)
PP.efit_points = n_elements(fit_ind)

 if n_elements(where(finite(pp.Ie_ind))) le 3 then pp.flg = -3 ;pp.flg + 10

return, PP
end
;--------------------------------------------------------------------------- fitswp_10V_02_1e -----

;------- fitswp_10V_03_2e -------------------------------------------------------------------------
function fitswp_10V_03_2e, PP_org, Vsc=Vsc;, givenU=givenU

  PP = PP_org
  if(n_elements(where(pp.voltage ne pp.voltage(0)))) le 3 then return, PP
  
  PP.fit_function_name = 'fitswp_10V_03_2e'
  pp.flg = 0
  
  U = PP.voltage &  I = PP.current
  U_org = U
  
  if keyword_set(Vsc) eq 0 then if finite(pp.Vsc) then Vsc = pp.Vsc else Vsc = 4.0
  
  ;givenU=!values.F_nan
  ;if keyword_set(givenU) eq 0 then givenU=!values.F_nan
  ;if n_elements(givenU) gt 1 then givenU = givenU(0)
  
  ;----- Is ion ofset ok? Ignore all(I) > 0.------------
  ind = where(I lt 0.0)
  if n_elements(ind) le 3 then begin
    pp.flg = -1
    return, pp
  endif

retreat_fitswp_10V_03_2e:
  
  ;----- look for zero crossing by 1) finding min(|I|) and 2) use myzero around it -------
  ind_Ival = where(abs(pp.current) ge 2.0e-9) ; take away under noise level data point
  I_val = interpol(I(ind_Ival),U(ind_Ival),U) ; and interpolate with linear
  
  ind_Imin = where(abs(I_val) eq min(abs(I_val))) ; find min(|I|)
  ind_Imin=ind_Imin(0) & U_Imin=U(ind_Imin)
  
  U_lim_tmp = [U_Imin-2., U_Imin+2.0]   ; fine tune U_Izero using myzero
  ind_tmp = where(U ge U_lim_tmp(0) and U le U_lim_tmp(1))
  U_Imin = myzero(U(ind_tmp),I_val(ind_tmp))
  if finite(U_Imin) ne 1 then begin
    pp.flg = -1 & return, PP
  endif
  if U_Imin ge max(U,/nan) then begin
    pp.flg = -1 & return, PP
  endif
  PP.U_zero = U_Imin
  
  ;----- look for dIdU peak -------------------------------
  ind = sort(U) & U_sorted = U(ind) & I_sorted = I(ind)
  dIdU = deriv(U_sorted,I_sorted)
  ind_search = where(U_sorted ge U_Imin and U_sorted le U_Imin+5.0)
  U_tmp    = U_sorted(ind_search) & dIdU_tmp = dIdU(ind_search)
  ind_dIdUmax = where( dIdU_tmp eq max(dIdU_tmp,/NAN)) & ind_dIdUmax=ind_dIdUmax(0)
  U_dIdUmax = U_tmp(ind_dIdUmax)
  if finite(U_dIdUmax) ne 1 then begin
    pp.flg = -2 & return, PP
  endif
  
  ;----- Define givenU if not assigned --------------------
  ;if keyword_set(givenU) then if finite(givenU(0)) eq 0 then givenU = -U_dIdUmax  
  ;pp.U_input = [givenU , !values.F_nan, !values.F_nan]
  ;pp.U_input = [!values.F_nan , !values.F_nan, !values.F_nan]
  ;print, 'givenU' ;& print, givenU
  
  ;----- Try fitting ion side with linear function ----------------------------
  ;----- Ion current is  straight rather than the theoretical erf curve -------
  fit_Ulim = [-20, U_Imin-1.]
  fit_ind = where(U lt fit_Ulim(1) and U gt fit_Ulim(0)) ;& ind = ind(1:n_elements(ind)-1)
  coeff = fit_ion_linear(U(fit_ind), I(fit_ind),U_lim=fit_Ulim)
  I_ion = coeff(0) + coeff(1) * U
 ;PP.I_ion = I_ion
  PP.m = coeff(0) & PP.b = coeff(1)
  PP.Ii_ind(fit_ind) = I(fit_ind)
  
  ;----- Replace noise small current data (< +-2e-9 [A]) with model ion -------
   noise_ind = where(abs(I) le 1.e-9)
   I(noise_ind) = I_ion(noise_ind)
  
  I_tmp = I - I_ion
  
  delvar, fit_Uind, fit_ind, fit_Ulim
  
  ;----- Fit Ion current first ------------------------------------------------
  ;----- Roughly estimate correct U0 ---------------------------
  ;fit_ind = where(finite(pp.Ii_ind))
  U_sorted = U(sort(U))
  ind = where(U_sorted lt U_Imin) & next2Imin = U_sorted(ind(n_elements(ind)-1)) & delvar, ind
  ;ind = where(U_sorted gt U_Imin) & next2Imin = U_sorted(ind(0)) & delvar, ind
  ;fit_Ulim = [-20, next2Imin]
  fit_Ulim = [-20, U_Imin]
  fit_ind = where(U ge fit_Ulim(0) and U le fit_Ulim(1)) ;& print, U_lim
  PP.Ii_ind(fit_ind) = pp.current(fit_ind)
  
  U0 = -U_Imin
  dU = 0.2
  U_lim  = [U0-dU, U0, U0+dU]
  ;U_lim  = [-U_dIdUmax-1.0, -U_dIdUmax, -U_dIdUmax+1.0]
  Ni_lim = [1e1, 1e3, 1e6]
  Ti_lim = [1e-2, 0.1, 10]
  Vi_lim = [0, Vsc, 10]
  mi_lim = [1, 32, 58]
  RXA    = PP.RXA
  
  start   = [U_lim(1), Ni_lim(1), Ti_lim(1), Vi_lim(1), mi_lim(1), RXA]
  
  parinfo = replicate({fixed:0, limited:[1,1], limits:[0.D,0.D]},n_elements(start))
  parinfo[0].limits = [U_lim(0),  U_lim(2)]  ; limits for U0
  parinfo[1].limits = [Ni_lim(0), Ni_lim(2)] ; limits for Ni
  parinfo[2].limits = [Ti_lim(0), Ti_lim(2)] ; limits for Ti
  parinfo[3].limits = [Vi_lim(0), Vi_lim(2)] ; limits for Vi
  parinfo[4].limits = [mi_lim(0), mi_lim(2)] ; limits for Mi
  parinfo[5].limits = [RXA, RXA] ; limits for Vi
  
  parinfo[0].fixed = 0
  parinfo[1].fixed = 0 ; Ni
  parinfo[2].fixed = 0 ; Ti
  parinfo[3].fixed = 1 ; Vi 
  parinfo[4].fixed = 0 ; Mi no fix
  parinfo[5].fixed = 1
  
  I_fit = pp.current
  sph = 0
  err = make_array(n_elements(fit_ind),value=1e-9)
  if sph then $
    P = mpfitfun('mvn_lpw_j_i_thermal_sph_hoegy',pp.voltage(fit_ind),I_fit(fit_ind),err,start,PARINFO=parinfo,/quiet) $
  else        $
    P = mpfitfun('mvn_lpw_j_i_thermal_cyl_brace',pp.voltage(fit_ind),I_fit(fit_ind),err,start,PARINFO=parinfo,/quiet)
  
  if sph then PP.I_ion        = mvn_lpw_j_i_thermal_sph_hoegy(U_org,P([0,1,2,3,4,5])) $
  else        PP.I_ion        = mvn_lpw_j_i_thermal_cyl_brace(U_org,P([0,1,2,3,4,5]))
  PP.U0  = P[0] & pp.Usc = pp.U0
  PP.Ni  = P[1]
  PP.Ti  = P[2]
  PP.Vi  = P[3]
  PP.mi  = P[4]

  ;goto, END_fitswp_10V_03_2E
  
  ;----- Extract Electron retardent current ----------------------------------
  Ie_ret = pp.current-pp.I_ion  

  ;----- Use derived potential to estimate cold electron ----------------------
  U0 = PP.U0 ;& print, U0
  U_sorted = U(sort(U))
  ind = where(U_sorted gt -U0) & next2peak = U_sorted(ind(1)) & delvar, ind
  ind = where(U_sorted gt U_Imin) & next2Imin = U_sorted(ind(0)) & delvar, ind
  fit_Ulim = [U_Imin, max([U_Imin+0.3, next2peak])]
  ;fit_Ulim = [U_Imin, next2peak]
  ;fit_Ulim = [next2Imin, -U0]
  ;fit_Ulim = [U_Imin, -U0]
  
  fit_ind = where(U ge fit_Ulim(0) and U le fit_Ulim(1)) ;& print, U_lim
  if n_elements(fit_ind) le 3 then goto, FIT_WARM_COMP_fitswp_10V_03_2E
  PP.dummy_arr4 = make_array(n_elements(PP.current),value=!values.F_NAN)
  PP.dummy_arr4(fit_ind) = I_tmp(fit_ind)
  
  dU = 0.2
  U0_lim  = [U0-dU, U0, U0+dU]
  Ne_lim = [1e1, 1e2, 1e6]
  Te_lim = [1e-2,0.1, 1e0]
  Bt_lim = [0.0, 0.5, 1.0]
  
  start   = [U0_lim(1), Ne_lim(1), Te_lim(1), Bt_lim(1)]
  
  parinfo = replicate({fixed:0, limited:[1,1], limits:[0.D,0.D]},n_elements(start))
  parinfo[0].limits = [U0_lim(0), U0_lim(2)]  ; limits for U0
  parinfo[1].limits = [Ne_lim(0), Ne_lim(2)] ; limits for Ne
  parinfo[2].limits = [Te_lim(0), Te_lim(2)] ; limits for Te
  parinfo[3].limits = [Bt_lim(0), Bt_lim(2)] ; limits for Beta
  
  parinfo[3].fixed = 1 ; fixed bata
  
  err = make_array(n_elements(fit_ind),value=1e-9)
  I_tmp = Ie_ret
  P = mpfitfun('mvn_lpw_j_e_thermal_brace',U(fit_ind),I_tmp(fit_ind),err,start,PARINFO=parinfo,/quiet,perror=perror,BESTNORM=BESTNORM)
  
  if n_elements(P) eq 1 then goto, FIT_WARM_COMP_fitswp_10V_03_2E
  
  PP.No_e   = 1
  PP.U0     = P[0]
  PP.Ne1    = P[1]
  PP.Te1    = P[2]
  PP.Dummy1 = P[3]
  
  ; PP.I_electron1  = mvn_lpw_j_e_thermal(U_org, [PP.U0,PP.Ne1,PP.Te1])  ;P[U,N,T]
  PP.I_electron1  = mvn_lpw_j_e_thermal_brace(U_org, [PP.U0,PP.Ne1,PP.Te1,pp.dummy1])  ;P[U,N,T]
    
  ;----- Error estimation using the mpfitfun option ---------------------------
  PP.fit_err = transpose([[U(fit_ind)],[err]])
  ;if n_elements(fit_ind) ge 3 then begin
  ;  if keyword_set(perror) ne 0 then begin
  ;    PP.dU0 = perror(0) & PP.dNe1 = perror(1) & PP.dTe1 = perror(2)
  ;    DOF     = N_ELEMENTS(fit_ind) - N_ELEMENTS(P) ; deg of freedom
  ;    PCERROR = PERROR * SQRT(BESTNORM / DOF)   ; scaled uncertainties
  ;    ;if dof ge 10 then stop
  ;  endif
  ;endif
    
  ;----- Define Error for U0 --------------------------------------------------
  ;ind = where(abs(U(fit_ind) +pp.U0) eq min(abs(U(fit_ind) +pp.U0))) & ind=ind(0)
  ;pp.dU0 = abs(U(fit_ind(ind)) +pp.U0)
  ;if pp.dU0 ge 1.0 then pp.flg = -3
   pp.dU0 = abs(pp.U0 - U0)

  ;----- Define Error for Te1 --------------------------------------------------
  UU = U(fit_ind) & II = I_tmp(fit_ind)
  ind = where(UU lt -pp.U0) & UU = UU(ind) & II = II(ind)
   if n_elements(ind) le 3 then begin
     PP.U0     = !values.F_nan
     PP.Ne1    = !values.F_nan
     PP.Te1    = !values.F_nan
     PP.Dummy1 = !values.F_nan
     goto, FIT_WARM_COMP_fitswp_10V_03_2E
   endif
  ind = sort(UU)
  ind = ind(n_elements(ind)-3:n_elements(ind)-1)
  UU = UU(ind) & II=II(ind)
  
  Te_series = II/deriv(UU,II)
  ind = where(Te_series gt 0.0) & Te_series = Te_series(ind)
  pp.dTe1 = max( abs(Te_series-pp.Te1) )
  pp.dTe = pp.dTe1

  ;----- Define Error for Ne1 --------------------------------------------------
  pp.dNe1 = 0.5*pp.Ne1
  pp.dNe_tot = pp.dNe1
    
  pp.I_tot = pp.I_electron1+pp.I_ion
;goto, END_fitswp_10V_03_2E
  
  ;----- Extract the Electron retarding current for second component ----------
  ;I_tmp = pp.current - pp.I_ion - pp.I_electron1
  Ie_ret = Ie_ret - pp.I_electron1
  
;print, U_dIdUmax+pp.U0  
  if U_dIdUmax+pp.U0 ge 1.0 and keyword_set(retreated) ne 1 then begin
    pp.current = pp.current - pp.I_electron1
    PP.U2     = !values.F_nan
    PP.Ne3    = !values.F_nan
    PP.Te3    = !values.F_nan
    pp.I_electron3 = pp.I_electron1
    pp.flg = -6
    
    ;PP = fitswp_10V_02_1e(PP,Vsc=pp.Vsc,/fix_U0)
    ;goto, END_fitswp_10V_03_2E
    ;retreated = 1
    ;goto, retreat_fitswp_10V_03_2e
  endif

FIT_WARM_COMP_fitswp_10V_03_2E:  
  ;----- Derive warm electron once more ---------------------------------------
  ;----- First fitting to determin Te -----------------------------------------
  U_sorted = U(sort(U))
  extra = 5
  ind = where(U_sorted gt U_dIdUmax) & next2peak = U_sorted(ind(min([extra,n_elements(ind)-1]))) & delvar, ind
  fit_Ulim = [U_Imin, next2peak]
  ;fit_Ulim = [U_Imin, U_dIdUmax]
  fit_ind = where(U ge fit_Ulim(0) and U le fit_Ulim(1)) ;& print, U_lim
  PP.Ie_ind = make_array(n_elements(PP.current),value=!values.F_NAN)
  PP.Ie_ind(fit_ind) = Ie_ret(fit_ind)
  
  if n_elements(where(finite(PP.Ie_ind))) lt 5 then PP.flg = -1
  
  dU = 0.3
  U0_lim  = [-U_dIdUmax-dU, -U_dIdUmax, -U_dIdUmax+dU]
  Ne_lim = [1e1, 1e3, 1e6]
  Te_lim = [1e-2, 0.5, 1e1]
  Bt_lim = [0.0, 0.5, 1.0]
  
  start   = [U0_lim(1), Ne_lim(1), Te_lim(1), Bt_lim(1)]
  
  parinfo = replicate({fixed:0, limited:[1,1], limits:[0.D,0.D]},n_elements(start))
  parinfo[0].limits = [U0_lim(0),  U0_lim(2)]  ; limits for U0
  parinfo[1].limits = [Ne_lim(0), Ne_lim(2)] ; limits for Ne
  parinfo[2].limits = [Te_lim(0), Te_lim(2)] ; limits for Te
  parinfo[3].limits = [Bt_lim(0), Bt_lim(2)] ; limits for Beta
  
  if pp.flg eq -6 then parinfo[0].fixed = 1
  parinfo[3].fixed = 0 ; Set to cylindrical if 1
    
  err = make_array(n_elements(fit_ind),value=1e-9)
  I_tmp = Ie_ret
  P = mpfitfun('mvn_lpw_j_e_thermal_brace',U(fit_ind),I_tmp(fit_ind),err,start,PARINFO=parinfo,/quiet,perror=perror)
  
  if finite(P(0)) eq 0 then begin
    if pp.flg ne -6 then pp.flg = -4 
    return, PP
  endif
  
  if finite(pp.Ne1) ne 1 then begin
    PP.No_e   = 1
    PP.U0     = P[0]
    PP.Usc    = P[0]
    PP.Ne1    = P[1]
    PP.Te1    = P[2]
    PP.Dummy1 = P[3]    
    PP.I_electron1  = mvn_lpw_j_e_thermal_brace(U_org, [PP.U0,PP.Ne1,PP.Te1,pp.dummy1])  ;P[U,N,T]
    pp.I_tot = pp.I_electron1+pp.I_ion    
    PP.Ne_tot = PP.Ne1    
    PP.Te     = PP.Te
    ;----- Error estimation using the mpfitfun option ---------------------------
    ;if n_elements(fit_ind) ge 3 then begin
    ;  if keyword_set(perror) ne 0 then begin
    ;    PP.dU0 = perror(0) & PP.dNe1 = perror(1) & PP.dTe1 = perror(2)
    ;    DOF     = N_ELEMENTS(fit_ind) - N_ELEMENTS(P) ; deg of freedom
    ;    PCERROR = PERROR * SQRT(BESTNORM / DOF)   ; scaled uncertainties
    ;    ;if dof ge 10 then stop
    ;  endif
    ;endif

    ;----- Define Error for U0 --------------------------------------------------
    ind = where(abs(U(fit_ind) +pp.U0) eq min(abs(U(fit_ind) +pp.U0))) & ind=ind(0)
    pp.dU0 = abs(U(fit_ind(ind)) +pp.U0)
    if pp.dU0 ge 1.0 then pp.flg = -3
    ;----- Define Error for Te1 --------------------------------------------------
    UU = U(fit_ind) & II = I_tmp(fit_ind)
    ind = where(UU lt -pp.U0) & UU = UU(ind) & II = II(ind)
    if n_elements(ind) le 3 then begin
      pp.flg = -3
      goto, END_fitswp_10V_03_2e
    endif        
    ind = sort(UU)
    ind = ind(n_elements(ind)-3:n_elements(ind)-1)
    UU = UU(ind) & II=II(ind)
    
    Te_series = II/deriv(UU,II)
    ind = where(Te_series gt 0.0) & Te_series = Te_series(ind)
    pp.dTe1 = max( abs(Te_series-pp.Te1) )
    pp.dTe = pp.dTe1
    ;----- Define Error for Ne1 --------------------------------------------------
    pp.dNe1 = 0.5*pp.Ne1
    pp.dNe_tot = pp.dNe1
    ;-----------------------------------------------------------------------------    
  endif else begin
    PP.No_e   = 2
    PP.U1     = P[0]
    PP.Usc    = P[0]
    PP.Ne2    = P[1]
    PP.Te2    = P[2]
    PP.Dummy1 = P[3]
    PP.I_electron2  = mvn_lpw_j_e_thermal_brace(U_org, [PP.U1,PP.Ne2,PP.Te2,pp.dummy1])  ;P[U,N,T]    
    pp.I_tot = pp.I_electron1+pp.I_electron2+pp.I_ion    
    PP.Ne_tot = PP.Ne2 ;+ PP.Ne1
    PP.Te     = PP.Te2    
    ;----- Error estimation using the mpfitfun option ---------------------------
    ;if n_elements(fit_ind) ge 3 then begin
    ;  if keyword_set(perror) ne 0 then begin
    ;    PP.dU1 = perror(0) & PP.dNe2 = perror(1) ;& PP.dTe2 = perror(2)
    ;    DOF     = N_ELEMENTS(fit_ind) - N_ELEMENTS(P) ; deg of freedom
    ;    PCERROR = PERROR * SQRT(BESTNORM / DOF)   ; scaled uncertainties
    ;    ;if dof ge 10 then stop
    ;  endif
    ;endif
    ;----- Define Error for U1 --------------------------------------------------
    ind = where(abs(U(fit_ind) +pp.U1) eq min(abs(U(fit_ind) +pp.U1))) & ind=ind(0)
    pp.dU1 = abs(U(fit_ind(ind)) +pp.U1)
    if pp.dU1 ge 1.0 then pp.flg = -3
    ;----- Define Error for Te2 --------------------------------------------------
    UU = U(fit_ind) & II = I_tmp(fit_ind)
    ind = where(UU lt -pp.U1) & UU = UU(ind) & II = II(ind)
    if n_elements(ind) le 3 then begin
      pp.flg = -3
      goto, END_fitswp_10V_03_2e
    endif
    ind = sort(UU)
    ind = ind(n_elements(ind)-3:n_elements(ind)-1)
    UU = UU(ind) & II=II(ind)
    
    Te_series = II/deriv(UU,II)
    ind = where(Te_series gt 0.0) & Te_series = Te_series(ind)
    pp.dTe2 = max( abs(Te_series-pp.Te2) )
    pp.dTe = pp.dTe2
    ;----- Define Error for Ne1 --------------------------------------------------
    pp.dNe2 = 0.5*pp.Ne2
    pp.dNe_tot = pp.dNe2;+pp.dNe1
    ;-----------------------------------------------------------------------------    
  endelse
    
  ;----- Last ion side fitting ------------------------------------------------
  ;fit_ind = where(finite(pp.Ii_ind))
  U_sorted = U(sort(U))
  ind = where(U_sorted lt U_Imin) & next2Imin = U_sorted(ind(n_elements(ind)-1)) & delvar, ind
  fit_Ulim = [-20, next2Imin-0.5]
  ;fit_Ulim = [-20, U_Imin]
  fit_ind = where(U ge fit_Ulim(0) and U le fit_Ulim(1)) ;& print, U_lim
  pp.Ii_ind(*) = !values.F_NAN
  PP.Ii_ind(fit_ind) = I(fit_ind)
  
  ;U_lim  = [pp.U0-1.0, pp.U0, pp.U0+1.0]
  U_lim  = [pp.U1-1.0, pp.U1, pp.U1+1.0]
  ;U_lim  = [-U_Imin-1.0, -U_Imin, -U_Imin+1.0]
  Ni_lim = [pp.Ne_tot*0.1, pp.Ne_tot, pp.Ne_tot*10.0]
  Ti_lim = [PP.Te1*0.1, PP.Te1, PP.Te1*10.0]
  Vi_lim = [0, Vsc, 10]
  mi_lim = [1, 32, 50]
  RXA    = PP.RXA
  
  start   = [U_lim(1), Ni_lim(1), Ti_lim(1), Vi_lim(1), mi_lim(1), RXA]
  
  parinfo = replicate({fixed:0, limited:[1,1], limits:[0.D,0.D]},n_elements(start))
  parinfo[0].limits = [U_lim(0),  U_lim(2)]  ; limits for U0
  parinfo[1].limits = [Ni_lim(0), Ni_lim(2)] ; limits for Ni
  parinfo[2].limits = [Ti_lim(0), Ti_lim(2)] ; limits for Ti
  parinfo[3].limits = [Vi_lim(0), Vi_lim(2)] ; limits for Vi
  parinfo[4].limits = [mi_lim(0), mi_lim(2)] ; limits for Mi
  parinfo[5].limits = [RXA, RXA] ; limits for Vi
  
  parinfo[0].fixed = 1
  parinfo[1].fixed = 1 ; Ni no fix
  parinfo[2].fixed = 0 ; Ti
  parinfo[3].fixed = 1 ; Vi no fix
  parinfo[4].fixed = 0 ; Mi no fix
  parinfo[5].fixed = 1
  
  if pp.No_e eq 1 then I_tmp = pp.current - pp.I_electron1 $
  else                 I_tmp = pp.current - pp.I_electron1 - pp.I_electron2
  ;I_tmp = pp.current
  
  err = make_array(n_elements(fit_ind),value=1e-9)
  sph = 0
  if sph then $
    P = mpfitfun('mvn_lpw_j_i_thermal_sph_hoegy',pp.voltage(fit_ind),pp.Ii_ind(fit_ind),err,start,PARINFO=parinfo,/quiet) $
  else $
    P = mpfitfun('mvn_lpw_j_i_thermal_cyl_brace',pp.voltage(fit_ind),pp.Ii_ind(fit_ind),err,start,PARINFO=parinfo,/quiet)
    
  if sph then PP.I_ion  = mvn_lpw_j_i_thermal_sph_hoegy(U_org,P) $
  else        PP.I_ion  = mvn_lpw_j_i_thermal_cyl_brace(U_org,P)
  
 ;PP.U0  = P[0]
  PP.Ni  = P[1]
  PP.Ti  = P[2]
  PP.Vi  = P[3]
  PP.mi  = P[4]
  
  if pp.No_e eq 1 then PP.I_tot = PP.I_electron1 + PP.I_ion $ 
  else                 PP.I_tot = PP.I_electron1 + PP.I_electron2 +PP.I_ion
  
END_fitswp_10V_03_2E:

  if pp.No_e eq 1 and pp.flg ne -6 then begin      
    PP = fitswp_10V_02_1e(PP,Vsc=pp.Vsc)
    pp.flg = -5
  end


fit_ind = where(finite(PP.Ie_ind))
PP.fit_err2 = stddev(abs((PP.current(fit_ind) - PP.I_tot(fit_ind))/PP.I_tot(fit_ind)),/nan)
PP.efit_points = n_elements(fit_ind)

;if pp.Te1 le 1e-2 then pp.flg = 1
;if pp.Te2 le 1e-2 then pp.flg = 1

return, PP

end
;------------------------------------------------------------------------ fitswp_10V_03_2e --------

;------- fitswp_10V_02 ----------------------------------------------------------------------------
function fitswp_10V_02, PP_org, Vsc=Vsc, givenU=givenU

  PP = PP_org
  PP.fit_function_name = 'fitswp_10V_02'
  
  U = PP.voltage &  I = PP.current
  U_org = U
  
  if keyword_set(Vsc) eq 0 then Vsc = 4.0
  
  ;givenU=!values.F_nan
  if keyword_set(givenU) eq 0 then givenU=!values.F_nan
  ;if n_elements(givenU) gt 1 then givenU = givenU(0)
  
  ;----- Is ion ofset ok? Ignore of all(I) > 0.------------
  ind = where(I lt 0.0)
  if n_elements(ind) le 3 then return, pp
  
  ;----- look for zero crossing by finding min(|I|) -------
  ind_Imin = where(abs(I) eq min(abs(I)))
  ind_Imin=ind_Imin(0) & U_Imin=U(ind_Imin)
  PP.U_ZERO = U_Imin
  
  ;----- look for dIdU peak -------------------------------
  dIdU = deriv(U,I)
  ind = where(finite(U)) & mid = (n_elements(ind)/2.)-1
  n = 6 & sstep = indgen(n*2,start=mid-n+1)
  dIdU(sstep) = !values.F_nan
  ind_dIdUmax = where( dIdU eq max(dIdU,/NAN)) & ind_dIdUmax=ind_dIdUmax(0)
  U_dIdUmax = U(ind_dIdUmax)
  
  ;----- Define givenU if not assigned --------------------
  if keyword_set(givenU) then if finite(givenU(0)) eq 0 then begin
    ;if U_dIdUmax gt U_Imin then givenU = -U_dIdUmax else givenU = -U_Imin
    givenU = -U_dIdUmax
  endif
  pp.U_input=givenU; , !values.F_nan, !values.F_nan]
  
  ;----- Try fitting ion side to subtract the electron current
  ;----- Ion current is  straight rather than the theoretical erf curve -------
  fit_Ulim = [-20, U_Imin-5]
  fit_ind = where(U lt fit_Ulim(1) and U gt fit_Ulim(0)) ;& ind = ind(1:n_elements(ind)-1)
  coeff = fit_ion_linear(U(ind), I(ind))
  I_ion = coeff(0) + coeff(1) * U
  PP.I_ion = I_ion
  PP.m = coeff(0) & PP.b = coeff(1)
goto,   fitswp_10V_02_FIT_E
  U0_pre = -U_Imin
  U_lim  = [U0_pre-2.0, U0_pre, U0_pre+2.0]
  Ni_lim = [1e2, 1e4, 1e6]
  Ti_lim = [1e-2, 1e-1, 1e1]
  Vi_lim = [0, Vsc, 10]
  mi_lim = [1, 32, 40]
  
  fit_Ulim = [-20, U_Imin]
  fit_ind = where(U gt fit_Ulim(0) and U le fit_Ulim(1)) ;& print, U_lim
  ;PP.Ii_ind(fit_ind) = I(fit_ind)
  if n_elements(fit_ind) lt 3 then return, PP
  
  start   = [U_lim(1), Ni_lim(1), Ti_lim(1), Vi_lim(1), mi_lim(1)]
  
  parinfo = replicate({fixed:0, limited:[1,1], limits:[0.D,0.D]},n_elements(start))
  parinfo[0].limits = [U_lim(0),  U_lim(2)]  ; limits for U0
  parinfo[1].limits = [Ni_lim(0), Ni_lim(2)] ; limits for Ni
  parinfo[2].limits = [Ti_lim(0), Ti_lim(2)] ; limits for Ti
  parinfo[3].limits = [Vi_lim(0), Vi_lim(2)] ; limits for Vi
  parinfo[4].limits = [mi_lim(0), mi_lim(2)] ; limits for Vi
  
  parinfo[2].fixed = 1  ; Ti to be fixed
  ;parinfo[3].fixed = 1  ; Velocity to be fixed
  ;parinfo[4].fixed = 1  ; Velocity to be fixed
  
  err = make_array(n_elements(fit_ind),value=1e-9)
  P = mpfitfun('mvn_lpw_J_i_thermal',U(fit_ind),I(fit_ind),err,start,PARINFO=parinfo,/quiet)
  
  PP.I_ion        = mvn_lpw_J_i_thermal(U_org,P([0,1,2,3,4]))
  PP.U0  = P[0]
  PP.Ni  = P[1]
  PP.Ti  = P[2]
  PP.Vi  = P[3]
  
fitswp_10V_02_FIT_E:
  ;print, 'Ion' & print, P
  I_tmp = I - PP.I_ion
  ;goto, END_fitswp_10V_01
  
  delvar, fit_Uind, fit_ind, fit_Ulim
  ;----- Try fitting electron two component fitting -----
  U_sorted = U(sort(U))
  ind = where(U_sorted gt U_dIdUmax) & next2peak = U_sorted(ind(1)) & delvar, ind
  ind = where(U_sorted lt U_Imin)    & next2min  = U_sorted(ind(n_elements(ind)-1)) & delvar, ind
  ;fit_Ulim = [next2min, next2peak]
  fit_Ulim = [U_Imin, next2peak]
  fit_ind = where(U ge fit_Ulim(0) and U le fit_Ulim(1)) ;& print, U_lim
  PP.Ie_ind(fit_ind) = I_tmp(fit_ind)
  
  dU = 0.5
  ;print, givenU
  U0_lim  = [givenU(0)-dU, givenU(0), givenU(0)+dU]
  Ne_lim = [1e1, 1e3, 1e6]
  Te_lim = [1e-2, 0.5, 1e1]
  
  start   = [U0_lim(1), Ne_lim(1), Te_lim(1)]
  
  parinfo = replicate({fixed:0, limited:[1,1], limits:[0.D,0.D]},n_elements(start))
  parinfo[0].limits = [U0_lim(0), U0_lim(2)]  ; limits for U0
  parinfo[1].limits = [Ne_lim(0), Ne_lim(2)] ; limits for Ne
  parinfo[2].limits = [Te_lim(0), Te_lim(2)] ; limits for Te
  
  err = make_array(n_elements(fit_ind),value=1e-9)
  P = mpfitfun('mvn_lpw_J_e_thermal',U(fit_ind),I_tmp(fit_ind),err,start,PARINFO=parinfo,/quiet)
  
  PP.No_e  = 1
  PP.U0  = P[0]
  PP.Ne1 = P[1]
  PP.Te1 = P[2]  
  
  PP.fit_err = transpose([[U(fit_ind)],[err]])
  PP.I_electron1  = mvn_lpw_J_e_thermal(U_org, [PP.U0,PP.Ne1,PP.Te1])  ;P[U,N,T]
goto, END_fitswp_10V_02
  
  ;----- re-calcurate Ion with fixed Ufloat -----
  I_tmp = I - PP.I_electron1
  U0_pre = PP.U0 ;& print, U0_pre
  U_lim  = [U0_pre-2.0, U0_pre, U0_pre+2.0]
  Ni_lim = [1e2, 1e4, 1e6]
  Ti_lim = [1e-2, 1e-1, 1e1]
  Vi_lim = [0, Vsc, 10]
  mi_lim = [1, 32, 40]
  
  fit_Ulim = [-20.0, -U0_pre]
  fit_ind = where(U ge fit_Ulim(0) and U le fit_Ulim(1))
  PP.Ii_ind(fit_ind) = I(fit_ind)
  
  start   = [U_lim(1), Ni_lim(1), Ti_lim(1), Vi_lim(1), mi_lim(1)]
  
  parinfo = replicate({fixed:0, limited:[1,1], limits:[0.D,0.D]},n_elements(start))
  parinfo[0].limits = [U_lim(0),  U_lim(2)]  ; limits for U0
  parinfo[1].limits = [Ni_lim(0), Ni_lim(2)] ; limits for Ni
  parinfo[2].limits = [Ti_lim(0), Ti_lim(2)] ; limits for Ti
  parinfo[3].limits = [Vi_lim(0), Vi_lim(2)] ; limits for Vi
  parinfo[4].limits = [mi_lim(0), mi_lim(2)] ; limits for Vi
  
  parinfo[0].fixed = 1
  ;parinfo[3].fixed = 1
  ;parinfo[4].fixed = 1
  
  err = make_array(n_elements(fit_ind),value=1e-9)
  P = mpfitfun('mvn_lpw_J_i_thermal',U(fit_ind),I(fit_ind),err,start,PARINFO=parinfo,/quiet)
  
  PP.I_ion        = mvn_lpw_J_i_thermal(U_org,P([0,1,2,3,4]))
  PP.U0  = P[0]
  PP.Ni  = P[1]
  PP.Ti  = P[2]
  PP.Vi  = P[3]
  
  ;print, 'Ion' &   print, P
END_fitswp_10V_02:

  PP.I_tot = PP.I_electron1  + PP.I_ion
  PP.Ne_tot = PP.Ne1
  PP.Te     = PP.Te1

  return, PP
end
;------------------------------------------------------------------------------ fitswp_10V_02 -----

;======= function set for fitswp_new_gaussian =====================================================

;------- gaussian_fit -----------------------------------------------------------------------------
function gaussian_fit, x, A
  ; A0: gausian height
  ; A1: gausian Center
  ; A2: gausian Width
  ; F(x) = A0 exp(-Z^2/2)
  ; Z = (x-A1)/A2

  Z = (x-A(1))/A(2)
  y = A(0) * exp(-Z^2./2.)
  return, y
end
;------------------------------------------------------------------------------- gaussian_fit -----

;------- mvn_find_peaks ---------------------------------------------------------------------------
function mvn_find_peaks, swp_pp_org

  swp_pp = swp_pp_org

  ;----- Prepare curves ---------------------------------------------
  V = swp_pp.voltage
  I = swp_pp.current
  didv = deriv(V,I) ;didv = ts_diff(I,1)/ts_diff(V,1)
  Y    = ts_diff(didv,1)/ts_diff(V,1)  ;Y = deriv(V,deriv(V,I))

  ;----- Define retarding region ------------------------------------
  ind_Imin = where(abs(I) eq min(abs(I)))
  U_Imin = V(ind_Imin(0))
  swp_pp.U_Imin = U_Imin

  ind = where(V ge U_Imin and V le U_Imin+5.0)
  vv = V(ind) & yy = didv(ind)
  ind_dIdVmax = where(yy eq max(yy,/nan))
  U_didvmax = vv(ind_dIdVmax(0))
  swp_pp.U_didvmax = U_didvmax

  ;----- Define roughly the basic gausian width ---------------------
  Gw = (U_didvmax - U_Imin)/12.0

  ;----- Define first area to find the first peak -------------------
  Y_fit = []
  U_lim = [U_Imin-0.0,U_Imin+((U_didvmax - U_Imin)/3.0)]
  fit_ind = where(V ge U_lim(0) and V le U_lim(1))
  ;Y_fit = make_array(n_elements(V),value=!values.F_NAN) & Y_fit(fit_ind)=Y(fit_ind)
  Gh_lim = [0.,  max(Y,/nan)/2.0, max(Y,/nan)]
  Gc_lim = [U_lim(0), (U_lim(0)+U_lim(1))/2.0, U_lim(1)]
  Gw_lim = [0, Gw/2.0, Gw]

  start   = [Gh_lim(1), Gc_lim(1), Gw_lim(1)]

  parinfo = replicate({fixed:0, limited:[1,1], limits:[0.D,0.D]},n_elements(start))
  parinfo[0].limits = [Gh_lim(0), Gh_lim(2)]
  parinfo[1].limits = [Gc_lim(0), Gc_lim(2)]
  parinfo[2].limits = [Gw_lim(0), Gw_lim(2)]

  err = make_array(n_elements(fit_ind),value=1e-9)
  P = mpfitfun('gaussian_fit',V(fit_ind),Y(fit_ind),err,start,PARINFO=parinfo,/quiet)

  if not finite(P(0)) then return, swp_pp
  y_fit = [[Y_fit],[gaussian_fit(V,[P(0), P(1), P(2)])]]
  peaks = P(1)+P(2)
  WGaussian    = P(2)
  HGaussian    = P(0)

  Y2 = Y-Y_fit
  ;Y_fit = [[Y_fit],[Y-Y_fit]]

  ;----- Define second area to find the decond peak -------------------
  U_lim = [peaks(0),U_Imin+2.0*((U_didvmax - U_Imin)/3.0)]
  fit_ind = where(V ge U_lim(0) and V le U_lim(1))
  ;Y_fit = make_array(n_elements(V),value=!values.F_NAN) & Y_fit(fit_ind)=Y(fit_ind)
  Gh_lim = [0,  max(Y)/2.0, max(Y)]
  Gc_lim = [U_lim(0), (U_lim(0)+U_lim(1))/2.0, U_lim(1)]
  Gw_lim = [0.0, (U_didvmax - U_Imin)/24.0, (U_didvmax - U_Imin)/12.0]

  start   = [Gh_lim(1), Gc_lim(1), Gw_lim(1)]

  parinfo = replicate({fixed:0, limited:[1,1], limits:[0.D,0.D]},n_elements(start))
  parinfo[0].limits = [Gh_lim(0), Gh_lim(2)]
  parinfo[1].limits = [Gc_lim(0), Gc_lim(2)]
  parinfo[2].limits = [Gw_lim(0), Gw_lim(2)]

  err = make_array(n_elements(fit_ind),value=1e-9)
  P = mpfitfun('gaussian_fit',V(fit_ind),Y(fit_ind),err,start,PARINFO=parinfo,/quiet)

  y_fit = [[Y_fit],[gaussian_fit(V,[P(0), P(1), P(2)])]]
  peaks = [peaks, P(1)+P(2)]
  WGaussian    = [WGaussian, P(2)]
  HGaussian    = [HGaussian, P(0)]

  if abs(peaks(1)-peaks(0)) le 2*Gw then peaks = [!values.F_NAN, (peaks(0)+peaks(1))/2.0]
  if peaks(0) le U_Imin then peaks(0) = !values.F_NAN
  if peaks(1) le U_Imin then peaks(1) = !values.F_NAN

  peaks = [peaks, U_didvmax]
  swp_pp.peaks     = peaks
  swp_pp.WGaussian = [WGaussian, !values.F_NAN]
  swp_pp.HGaussian = [HGaussian, !values.F_NAN]

  return, swp_pp

end
;----------------------------------------------------------------------------- mvn_find_peaks -----

;------- define_ion_lenear ------------------------------------------------------------------------
function define_ion_lenear, swp_pp_org
  swp_pp = swp_pp_org

  U_Imin = swp_pp.U_Imin
  U      = swp_pp.voltage
  I      = swp_pp.current

  fit_Ulim = [-20, U_Imin-1.]
  fit_ind = where(U lt fit_Ulim(1) and U gt fit_Ulim(0)) ;& ind = ind(1:n_elements(ind)-1)
  coeff = fit_ion_linear(U(fit_ind), I(fit_ind),U_lim=fit_Ulim)
  I_ion = coeff(0) + coeff(1) * U
  swp_pp.I_ion = I_ion
  swp_pp.m = coeff(0) & swp_pp.b = coeff(1)

  swp_pp.ifit_points = n_elements(fit_ind)
  
  return, swp_pp
end
;-------------------------------------------------------------------------- define_ion_lenear -----


;------- define_ion_sqlinear ----------------------------------------------------------------------
function define_ion_sqlinear, swp_pp_org
  swp_pp = swp_pp_org

  U     = swp_pp.voltage
  I     = swp_pp.current
  II     = swp_pp.current^2.0
  ind_Imin = where(abs(I) eq min(abs(I)))
  U_Imin = U(ind_Imin(0))

  fit_Ulim = [-20, U_Imin-0.]
  fit_ind = where(U lt fit_Ulim(1) and U gt fit_Ulim(0)) ;& ind = ind(1:n_elements(ind)-1)
  UL = U(fit_ind) & IIL = II(fit_ind) & IL = I(fit_ind)

  Ii_ind = make_array(128,value=!values.F_NAN)
  Ii_ind(fit_ind) = I(fit_ind)
  swp_pp.Ii_ind = Ii_ind

  ; ----- Apply Linear fitting -----
  coeff_II = linfit(UL,IIL,yfit=u2)

  m =  coeff_II(0)
  b = -coeff_II(1)

  I_ion = -sqrt(m - b * U)
  ind = where(finite(I_ion) eq 0) & I_ion(ind) = 0
  swp_pp.I_ion = I_ion
  swp_pp.m2 = m & swp_pp.b2 = b
  swp_pp.ifit_points = n_elements(fit_ind)

  return, swp_pp
end
;------------------------------------------------------------------------ define_ion_sqlinear -----

;------- define_dT --------------------------------------------------------------------------------
function define_dT, U, I, U0, Te

  dTe = !values.F_NAN
  ind = where(U lt U0) & U = U(ind) & I = I(ind)
  ;if n_elements(ind) le 3 then  flg = -1 ; flag that fitting data points are too few.
  n_ind = n_elements(ind)
  if n_ind le 2 then goto, dt_cal_out
  ind = sort(U)
  ind = ind(n_elements(ind)-3:n_elements(ind)-1)
  U = U(ind) & I=I(ind)
  Te_series = I/deriv(U,I)
  ind = where(Te_series gt 0.0) & Te_series = Te_series(ind)
  dTe = max( abs(Te_series-Te) )
dt_cal_out:
  return, [dTe, n_ind]
end
;---------------------------------------------------------------------------------- define_dT -----

;------- define_secondary_electron ----------------------------------------------------------------
function define_secondary_electron, swp_pp_org, Umin_set=Umin_set

  swp_pp = swp_pp_org
  U = swp_pp.voltage
  I = swp_pp.current - swp_pp.I_ion
  U_Imin = swp_pp.U_Imin

  if keyword_set(Umin_set) then begin
    U_order = sort(U)
    U_sorted=U(U_order) & I_sorted=I(U_order)
    ind = where(I_sorted ge 5e-9 and U_sorted ge U_Imin-0.5)
    U_Imin = U_sorted(ind(0))
    ;print, swp_pp.U_Imin, U_Imin
  endif

  U0 = swp_pp.peaks(0)
  U_sorted = U(sort(U))
  ind = where(U_sorted gt U0) & U_next2peak = U_sorted(ind(min([1,n_elements(ind)-1]))) & delvar, ind
  fit_Ulim = [U_Imin, U_next2peak]

  fit_ind = where(U ge fit_Ulim(0) and U le fit_Ulim(1)) ;& print, U_lim

  Ie_ind = make_array(128,value=!values.F_NAN)
  Ie_ind(fit_ind) = I(fit_ind)
  swp_pp.Ie_ind = Ie_ind
  swp_pp.efit_points(0) = n_elements(fit_ind)

  dU = swp_pp.WGaussian(0)
  U0_lim  = [-U0-dU, -U0, -U0+dU]
  Ne_lim = [1e1, 1e2, 1e6]
  Te_lim = [1e-2,0.1, 1e0]
  Bt_lim = [0.0, 1.0, 1.0]

  start   = [U0_lim(1), Ne_lim(1), Te_lim(1), Bt_lim(1)]

  parinfo = replicate({fixed:0, limited:[1,1], limits:[0.D,0.D]},n_elements(start))
  parinfo[0].limits = [U0_lim(0), U0_lim(2)]  ; limits for U0
  parinfo[1].limits = [Ne_lim(0), Ne_lim(2)] ; limits for Ne
  parinfo[2].limits = [Te_lim(0), Te_lim(2)] ; limits for Te
  parinfo[3].limits = [Bt_lim(0), Bt_lim(2)] ; limits for Beta

  parinfo[3].fixed = 1 ; fix bata to be 1 (spherical case)

  err = make_array(n_elements(fit_ind),value=1e-9)
  P = mpfitfun('mvn_lpw_J_e_thermal_brace',U(fit_ind),I(fit_ind),err,start,PARINFO=parinfo,/quiet,perror=perror,BESTNORM=BESTNORM)

  if finite(P(0)) eq 0 then return, swp_pp
  swp_pp.U0     = P[0]
  swp_pp.Ne1    = P[1]
  swp_pp.Te1    = P[2]
  swp_pp.I_electron1  = mvn_lpw_J_e_thermal_brace(U, [swp_pp.U0,swp_pp.Ne1,swp_pp.Te1,1.0])  ;P[U,N,T]

  ;----- Define Error for U0 --------------------------------------------------
  swp_pp.dU0 = abs(swp_pp.U0 - U0)

  ;----- Define Error for Te1 --------------------------------------------------
  UU = U(fit_ind) & II = I(fit_ind)
  Uind = sort(UU) & UU=UU(Uind) & II = II(Uind)
  ind = where(UU le -swp_pp.U0) & UU = UU(ind) & II = II(ind)
  ;  if n_elements(ind) ge 4 then begin
  ;    ind = ind(n_elements(ind)-4:n_elements(ind)-1)
  ;    UU = UU(ind) & II=II(ind)
  ;  endif

  if n_elements(UU) lt 3 then swp_pp.dTe1 = swp_pp.Te1 $
  else begin
    Te_series = II/deriv(UU,II)
    ind = where(Te_series gt 0.0) & Te_series = Te_series(ind)
    swp_pp.dTe1 = max( abs(Te_series-swp_pp.Te1) )
  end

  ;----- Define Error for Ne1 --------------------------------------------------
  swp_pp.dNe1 = 0.5*swp_pp.Ne1

  return, swp_pp

end
;------------------------------------------------------------------ define_secondary_electron -----

;------- define_electron1 -------------------------------------------------------------------------
function define_electron1, swp_pp_org,Umin_set=Umin_set
  swp_pp = swp_pp_org

  U = swp_pp.voltage
  I = swp_pp.current - swp_pp.I_ion
  if n_elements(where(finite(swp_pp.I_electron1))) gt 1 then I = I - swp_pp.I_electron1
  U_Imin = swp_pp.U_Imin

  if keyword_set(Umin_set) then begin
    U_order = sort(U)
    U_sorted=U(U_order) & I_sorted=I(U_order)
    ind = where(I_sorted ge 5e-9 and U_sorted ge U_Imin-0.5)
    U_Imin = U_sorted(ind(0))
    ;print, swp_pp.U_Imin, U_Imin
  endif

  if not finite(swp_pp.peaks(1))     then return, swp_pp
  if not finite(swp_pp.HGAUSSIAN(1)) then return, swp_pp

  U0 = swp_pp.peaks(1)
  U_sorted = U(sort(U))
  ind = where(U_sorted gt U0) & U_next2peak = U_sorted(ind(min([2,n_elements(ind)-1]))) & delvar, ind
  fit_Ulim = [U_Imin, U_next2peak]

  fit_ind = where(U ge fit_Ulim(0) and U le fit_Ulim(1)) ;& print, U_lim
  if not finite(swp_pp.Te1) then begin
    Ie_ind = make_array(128,value=!values.F_NAN)
    Ie_ind(fit_ind)=I(fit_ind)
    swp_pp.Ie_ind = Ie_ind
  endif

  dU = swp_pp.WGaussian(1)
  U0_lim  = [-U0-dU, -U0, -U0+dU]
  Ne_lim = [1e1, 1e2, 1e6]
  Te_lim = [1e-2,0.1, 1e0]
  Bt_lim = [0.0, 0.5, 1.0]

  start   = [U0_lim(1), Ne_lim(1), Te_lim(1), Bt_lim(1)]

  parinfo = replicate({fixed:0, limited:[1,1], limits:[0.D,0.D]},n_elements(start))
  parinfo[0].limits = [U0_lim(0), U0_lim(2)]  ; limits for U0
  parinfo[1].limits = [Ne_lim(0), Ne_lim(2)] ; limits for Ne
  parinfo[2].limits = [Te_lim(0), Te_lim(2)] ; limits for Te
  parinfo[3].limits = [Bt_lim(0), Bt_lim(2)] ; limits for Beta

  parinfo[3].fixed = 0

  err = make_array(n_elements(fit_ind),value=1e-9)
  P = mpfitfun('mvn_lpw_J_e_thermal_brace',U(fit_ind),I(fit_ind),err,start,PARINFO=parinfo,/quiet,perror=perror,BESTNORM=BESTNORM)

  swp_pp.U1     = P[0]
  swp_pp.Ne2    = P[1]
  swp_pp.Te2    = P[2]
  Beta1         = P[3]
  swp_pp.I_electron2  = mvn_lpw_J_e_thermal_brace(U, [swp_pp.U1,swp_pp.Ne2,swp_pp.Te2,Beta1])  ;P[U,N,T]

  ;----- Add Fitting Info -----------------------------------------------------
  swp_pp.efit_points(1) = n_elements(fit_ind)
  ;----- Defind dT ------------------------------------------------------------
  UU = U(fit_ind) & II = I(fit_ind)
  dt_info = define_dT(UU,II,-swp_pp.U1,swp_pp.Te2)
  flg = dt_info(1) & dTe = dt_info(0)
  if flg le 3 then swp_pp.flg = 23 ; data point to fit too few
  swp_pp.dTe2 = dTe
  ;----- Define dU ------------------------------------------------------------
  UU = U(fit_ind)
  dU = min(abs(UU+swp_pp.U1),/nan)
  swp_pp.dU1 = dU
  ;----- Define Error for Ne1 -------------------------------------------------
  swp_pp.dNe2 = 0.5*swp_pp.Ne2

  return, swp_pp
end
;--------------------------------------------------------------------------- define_electron1 -----

;------- define_electron2 -------------------------------------------------------------------------
function define_electron2, swp_pp_org
  swp_pp = swp_pp_org

  U = swp_pp.voltage
  I = swp_pp.current - swp_pp.I_ion
  if n_elements(where(finite(swp_pp.I_electron1))) gt 1 then I = I - swp_pp.I_electron1
  if n_elements(where(finite(swp_pp.I_electron2))) gt 1 then I = I - swp_pp.I_electron2
  U_Imin = swp_pp.U_Imin

 ;if not finite(swp_pp.peaks(1)) then return, swp_pp

  U0 = swp_pp.peaks(2)
  U_sorted = U(sort(U))
  ind = where(U_sorted gt U0)
  if ind(0) eq -1 then return, swp_pp
  if n_elements(ind) le 3 then U_next2peak = U_sorted(ind(n_elements(ind)-1)) $
  else                         U_next2peak = U_sorted(ind(3))
  delvar, ind
  fit_Ulim = [U_Imin, U_next2peak]

  fit_ind = where(U ge fit_Ulim(0) and U le fit_Ulim(1)) ;& print, U_lim

  dU = swp_pp.WGaussian(1)
  U0_lim  = [-U0-dU, -U0, -U0+dU]
  Ne_lim = [1e1, 1e2, 1e6]
  Te_lim = [1e-2,0.1, 1e0]
  Bt_lim = [0.0, 0.5, 1.0]

  start   = [U0_lim(1), Ne_lim(1), Te_lim(1), Bt_lim(1)]

  parinfo = replicate({fixed:0, limited:[1,1], limits:[0.D,0.D]},n_elements(start))
  parinfo[0].limits = [U0_lim(0), U0_lim(2)]  ; limits for U0
  parinfo[1].limits = [Ne_lim(0), Ne_lim(2)] ; limits for Ne
  parinfo[2].limits = [Te_lim(0), Te_lim(2)] ; limits for Te
  parinfo[3].limits = [Bt_lim(0), Bt_lim(2)] ; limits for Beta

  parinfo[3].fixed = 0

  err = make_array(n_elements(fit_ind),value=1e-9)
  P = mpfitfun('mvn_lpw_J_e_thermal_brace',U(fit_ind),I(fit_ind),err,start,PARINFO=parinfo,/quiet,perror=perror,BESTNORM=BESTNORM)

  swp_pp.U2     = P[0]
  swp_pp.Ne3    = P[1]
  swp_pp.Te3    = P[2]
  Beta2         = P[3]
  swp_pp.I_electron3  = mvn_lpw_J_e_thermal_brace(U, [swp_pp.U2,swp_pp.Ne3,swp_pp.Te3,Beta2])  ;P[U,N,T]

  ;----- Add Fitting Info -----------------------------------------------------
  swp_pp.efit_points(2) = n_elements(fit_ind)
  ;----- Defind dT ------------------------------------------------------------
  UU = U(fit_ind) & II = I(fit_ind)
  dt_info = define_dT(UU,II,-swp_pp.U2,swp_pp.Te3)
  flg = dt_info(1) & dTe = dt_info(0)
  if flg le 3 then swp_pp.flg = 33 ; data point to fit too few
  swp_pp.dTe3 = dTe
  ;----- Define dU ------------------------------------------------------------
  UU = U(fit_ind)
  dU = min(abs(UU+swp_pp.U2),/nan)
  swp_pp.dU2 = dU
  ;----- Define Error for Ne1 -------------------------------------------------
  swp_pp.dNe3 = 0.5*swp_pp.Ne3

  return, swp_pp
end
;--------------------------------------------------------------------------- define_electron2 -----

;------- fitswp_new_gaussian ----------------------------------------------------------------------
function fitswp_new_gaussian, swp_pp_org

  swp_pp = swp_pp_org
  swp_pp.fit_function_name = 'fitswp_new_gaussian'
  
  ;----- Is ion ofset ok? Ignore all(I) > 0.-------------------------
  ind = where(swp_pp.current lt 0.0)
  if n_elements(ind) le 3 then begin
    swp_pp.flg = -1 & return, swp_pp
  endif
  
  ;----- Find peak and define U_Imin and U_didvmax etc. -------------
  swp_pp = mvn_find_peaks(swp_pp)

  ;----- Try fitting ion side with linear function ------------------
  ;swp_pp = define_ion_lenear(swp_pp)
  ;swp_pp = define_ion(swp_pp)
   swp_pp = define_ion_sqlinear(swp_pp)

  ;----- Three peaks case: the lowest is secondary ------------------
  if finite(swp_pp.peaks(0)) then begin
    swp_pp = define_secondary_electron(swp_pp,/Umin_set)
  endif

  swp_pp = define_electron1(swp_pp)

  swp_pp = define_electron2(swp_pp)

  swp_pp.I_tot = swp_pp.I_ion
  
  if n_elements(where(finite(swp_pp.I_electron1))) gt 1 then swp_pp.I_tot = swp_pp.I_tot + swp_pp.I_electron1
  if n_elements(where(finite(swp_pp.I_electron2))) gt 1 then swp_pp.I_tot = swp_pp.I_tot + swp_pp.I_electron2
  if n_elements(where(finite(swp_pp.I_electron3))) gt 1 then swp_pp.I_tot = swp_pp.I_tot + swp_pp.I_electron3

  No_e = 0
  if not finite(swp_pp.Ne1) then No_e = No_e + 1
  if not finite(swp_pp.Ne2) then No_e = No_e + 1
  if not finite(swp_pp.Ne3) then No_e = No_e + 1

  swp_pp.Ne_tot = total( [[swp_pp.Ne1] , [swp_pp.Ne2] , [swp_pp.Ne3]],2,/nan )

  if finite(swp_pp.Te1)            then begin
    swp_pp.Te = swp_pp.Te1 & swp_pp.dTe = swp_pp.dTe1
  endif else if finite(swp_pp.Te2) then begin
    swp_pp.Te = swp_pp.Te2 & swp_pp.dTe = swp_pp.dTe2
  endif else if finite(swp_pp.Te3) then begin
    swp_pp.Te = swp_pp.Te3 & swp_pp.dTe = swp_pp.dTe3
  endif

  swp_pp.Usc = max([swp_pp.U0,swp_pp.U1,swp_pp.U2],/nan)

  return, swp_pp
end
;------------------------------------------------------------------------ fitswp_new_gaussian -----

;==================================================================================================
function mvn_lpw_prd_lp_n_t_fit, PP, type, Vs=Vs, givenU=givenU

  ;------ the version number of this routine --------------------------------------------------------
  t_routine=SYSTIME(0)
  prd_ver= this_version_mvn_lpw_prd_lp_n_t_fit()
  ;--------------------------------------------------------------------------------------------------
  
  ;if type ne 'SW2' and type ne 'IOSP' then stop  
  PP_new = PP
  case type of
    'IOSP':           PP_new = fitswp_10V_02_1e(PP,Vsc=Vsc);,givenU=givenU)
   ;'IOSP':           PP_new = fitswp_10V_03_2e(PP,Vsc=Vsc,givenU=givenU)
    
    'SW':             PP_new = fitswp_SW_01(PP,givenU=givenU) 
    'SW2':            PP_new = fitswp_SW_03(PP,givenU=givenU)
    
    'fitswp_SW_01':     PP_new = fitswp_SW_01(PP,givenU=givenU)
    'fitswp_10V_00':    PP_new = fitswp_10V_00(PP,Vsc=Vsc,givenU=givenU)
    'fitswp_10V_01':    PP_new = fitswp_10V_01(PP,Vsc=Vsc,givenU=givenU)
    'fitswp_10V_01_1e': PP_new = fitswp_10V_01_1e(PP,Vsc=Vsc,givenU=givenU)
    'fitswp_10V_02':    PP_new = fitswp_10V_02(PP,Vsc=Vsc,givenU=givenU)
    'fitswp_SW_02':     PP_new = fitswp_SW_02(PP,givenU=givenU)
    'fitswp_SW_03':     PP_new = fitswp_SW_03(PP,givenU=givenU)
    'fitswp_IONP_00':   PP_new = fitswp_IONP_00(PP,Vsc=Vsc,givenU=givenU)
    'fitswp_10V_02_1e': PP_new = fitswp_10V_02_1e(PP,Vsc=Vsc);,givenU=givenU)
    'fitswp_10V_03_2e': PP_new = fitswp_10V_03_2e(PP,Vsc=Vsc)
    
    'fitswp_new_gaussian': PP_new = fitswp_new_gaussian(PP)
   
   ; 'fitswp_10V_test' : PP_new = fitswp_10V_test(PP,Vsc=Vsc,givenU=givenU)        
   ; 'fitswp_10V_test2': PP_new = fitswp_10V_test2(PP,Vsc=Vsc,givenU=givenU)
  endcase
  
  PP_new.prd_ver = PP_new.prd_ver + ' # ' + prd_ver
  return, PP_new

end
;==================================================================================================
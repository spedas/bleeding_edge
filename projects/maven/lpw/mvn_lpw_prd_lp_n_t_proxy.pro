;+
;FUNCTION:   mvn_lpw_prd_lp_n_t_proxy
;
;
;INPUTS:
;    PP:  Analysed LP sweep data set structure.
;
;EXAMPLE:
; PP = mvn_lpw_prd_lp_n_t_clean_swp_pp(PP)
;
;CREATED BY:   Michiko Morooka  09-18-15
;FILE:         mvn_lpw_prd_lp_n_t_proxy.pro
;VERSION:      0.0

;------- this_version_mvn_lpw_prd_lp_n_t_clean_swp_pp -------------------------
function this_version_mvn_lpw_prd_lp_n_t_proxy
  ver = 0.0
  pdr_ver= 'version this_version_mvn_lpw_prd_lp_n_t_proxy: ' + string(ver,format='(F4.1)')
  return, pdr_ver
end
;--------------------------- this_version_mvn_lpw_prd_lp_n_t_clean_swp_pp -----

;------- Ufl2Ne ---------------------------------------------------------------
function Ufl2Ne, Ufl,prb

  switch prb of
    1: begin
      coeff = [3.3678, -3.1454, 15.3531, -0.3256]
    end
    2: begin
      coeff = [7.5231, -1.9632, 14.7475, -0.3403]
    end
  endswitch

  Ne_proxy = coeff(0)*exp(coeff(1)*Ufl) + coeff(2)*exp(coeff(3)*Ufl);
  return, Ne_proxy
end
;----------------------------------------------------------------- Ufl2Ne -----

;------- correct_Usc ----------------------------------------------------------
function correct_Usc, Ufl, Neproxy,Te
;Calcurate S/C potential(Usc_corr)

  ; --- Usc will be corrected as Usc = Ufl / (1-(5/6)*exp(-ds/D)
  ds = 400;  % --- distance from S/C to plobe in cm

  ; --- use Te from Sweep for Ne>=5 --- %
  D   =  6.9 * sqrt(Te*11600.0/Neproxy);  % Debye length in cm: 6.9*(Te[K]/Ne[/cc])^0.5
  Usc = Ufl/(1-(5.0/6.0)*exp(-ds/D));

  return, Usc
  
end
;------------------------------------------------------------ correct_Usc -----

;------- mvn_lpw_prd_lp_n_t_clean_swp_pp --------------------------------------
function mvn_lpw_prd_lp_n_t_proxy, swp_pp_org


; assumption that it is boom 1 only we are working with

  swp_pp = swp_pp_org
  time   = swp_pp_org.time
  fit_mm = swp_pp_org
  prd_ver = this_version_mvn_lpw_prd_lp_n_t_proxy()
  

;####################################################
;----------------------Read in the variable from different sources----------
 if keyword_set(tnames('da_shadow_1')) eq 1 then begin
       get_data,'da_shadow_1',data=asun_mvn
       sun_mvn=asun_mvn.y
      ENDIF ELSE $ 
      if keyword_set(tnames('mvn_lpw_anc_boom_shadow_orient')) eq 1 then begin
           get_data, 'mvn_lpw_anc_boom_shadow_orient',  data=asun_mvn
           ;interpolate the positions etc into the same time steps as the sc_pot
            sun_mvn = []
            for ii=0,1 do sun_mvn = [[sun_mvn], [interpol(asun_mvn.y(*,ii),asun_mvn.x,swp_pp.time)]]
      endif else begin
           print, 'tplot value missing: mvn_lpw_anc_boom_shadow_orient'
           return, swp_pp
      endelse
      
if keyword_set(tnames('da_posx_1')) eq 1 then begin
        get_data, 'da_posx_1', data=d1
        get_data, 'da_posy_1', data=d2
        get_data, 'da_posz_1', data=d3
        mso={x:d1,y:[[d1],[d2],[d3]]}
        msox=d1.y
        msoy=d2.y
        msoz=d3.y
      ENDIF ELSE $
        if keyword_set(tnames('mvn_lpw_anc_mvn_pos_mso')) eq 1 then begin
         get_data, 'mvn_lpw_anc_mvn_pos_mso',  data=mso
         if max(time) GE min(mso.x) OR min(time) LE max(mso.x)  THEN stanna ; the sc-potential and position are not from the same time period
         ;interpolate the positions etc into the same time steps as the sc_pot
         mso_xyz = []
         for ii=0,2 do mso_xyz = [[mso_xyz], [interpol(mso.y(*,ii),mso.x,time)]]
         msox = mso_xyz(*,0) & msoy = mso_xyz(*,1) & msoz = mso_xyz(*,2)
      endif else begin
        print, 'tplot value missing: mvn_lpw_anc_mvn_pos_mso'
        return, swp_pp
      endelse
     
    
 
      
if keyword_set(tnames('da_alt_iau_1')) eq 1 then begin
        get_data,'da_alt_iau_1',data=alt_iau
        alt=alt_iau.y
      ENDIF ELSE $
        if keyword_set(tnames('mvn_lpw_anc_mvn_alt_iau')) eq 1 then begin
        get_data, 'mvn_lpw_anc_mvn_alt_iau',  data=alt_iau
         ;interpolate the positions etc into the same time steps as the sc_pot
         alt = interpol(alt_iau.y,alt_iau.x,time)  
      endif else begin
        print, 'tplot value missing: mvn_lpw_anc_mvn_alt_iau'
        return, swp_pp
      endelse

; do not understand when this should be used     
;    msox = swp_pp.anc.mso_pos.x
;    msoy = swp_pp.anc.mso_pos.y
;    msoz = swp_pp.anc.mso_pos.z
;    alt  = swp_pp.anc.ALT_IAU
;    sun_mvn = []
;    for ii=0,1 do sun_mvn = [[sun_mvn], [interpol(asun_mvn.y(*,ii),asun_mvn.x,swp_pp.time)]]

 
 ;####################################################
 
   ;----- extract the data -----------------------
  function_name = FIT_MM.FIT_FUNCTION_NAME
  Ufloat        = FIT_MM.U_ZERO  ; U_ZERO FIT_MM.U0
  prb           = fix(fit_mm(0).PROBE)   ; Laila's code expect only boom 1 to be used

  ind = where(FIT_MM.FIT_FUNCTION_NAME ne 'fitswp_SW_01')
  Ufloat(ind) = !values.F_nan

  Ne_proxy = Ufl2Ne(Ufloat,prb)
  FIT_MM.NEPROX = Ne_proxy

  ;===== Define dN (factor 5) ===================
  fit_mm.DNEPROX = 5.0*FIT_MM.NEPROX

  ;===== Calcurate Usc (assuming Te = 100 eV) ===
  fit_mm.USC = correct_Usc(FIT_MM.U0,FIT_MM.NEPROX,100.0)
  
  ;===== Define dU ==============================
  fit_mm.dUSC = 0.5*fit_mm.USC
  fit_mm.dU0  = 0.5*fit_mm.U0

  ;===== make all kinds of flg ==================
  ind = where(FIT_MM.FIT_FUNCTION_NAME eq 'fitswp_SW_01')
  FIT_MM(ind).flg = 0

  ;----- not Nepoxy over 500/cc -----------------
  ind = where(FIT_MM.NEPROX gt 500.0)
  FIT_MM(ind).FLg = -1

  ;----- avoid mars shadow ----------------------
  ind = where( msox lt 0.0 and sqrt( msox^2 + msoy^2 ) lt 1.1 and finite(FIT_MM.NEPROX))
  FIT_MM(ind).FLg = -1

  ;----- Altitude < 1000 km ---------------------
  ind = where(alt lt 1000.0 and finite(FIT_MM.NEPROX))
  FIT_MM(ind).flg = -1

  ;----- Use only sun point case ----------------
 
   ind = where(sun_mvn(*,0) gt 0.05 and finite(FIT_MM.NEPROX))
  FIT_MM(ind).FLg = -1

  ;----- Boom-2 behaves strange from March ------
  ;-----               under investigation ------
  if (prb eq 2 and time(0) gt time_double('2015-03-01/00:00:00')) then begin
    ind = where(finite(FIT_MM.NEPROX))
    FIT_MM(ind).FLg = -1    
  endif

  ;----- Add ion/version info -------------------
  for ii=0,n_elements(fit_mm)-1 do begin
    FIT_MM(ii).prd_ver = FIT_MM(ii).prd_ver + ' # ' + prd_ver
  endfor

  if  where(strcmp(tag_names(swp_pp),'fit_mm',/FOLD_CASE)) eq -1 then swp_pp = fit_mm $
  else  swp_pp.fit_mm = fit_mm

  return, swp_pp
  
end
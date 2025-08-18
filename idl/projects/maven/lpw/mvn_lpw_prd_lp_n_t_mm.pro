;+
;FUNCTION:   mvn_lpw_prd_lp_n_t_mm
;
; ROUTINE that use 'LPSTRUC' data struture and proceed the sweep curve fitting for MAVEN/LPW
; 
;, prd_ver=prd_ver, lpstruc_filename=lpstruc_filename, pp_save=pp_save, pp_dir=pp_dir
;INPUTS:
;   in1:  Data structure for LP sweep analysis.
;         Specify prbe number if lp sweep data and ephemeris exsist in tplot var.
;
;KEYWORDS:
;   I_offset: give specific number for negative biased current offset. (default NaN)
;   
;EXAMPLE:
; swp_pp = mvn_lpw_prd_lp_n_t_mm(lpstruc)
; swp_pp = mvn_lpw_prd_lp_n_t_mm(probe_no)
;
;CREATED BY:   Michiko Morooka  01-14-15
;FILE:         mvn_lpw_prd_lp_n_t_mm.pro
;VERSION:      2.0
;LAST MODIFICATION:
;   15-02-20/M.W.Morooka/ Two component fitting is activated for lpw mode-0.
;                         Adding dNe dTe dU
;   15-03-23 M.Morooka Fit result clean option added.
;   15-04-15 M.Morooka bug fix for make_sweep_set (1.1)
;   15-05-26 M.Morooka new gaussian fitting for ionosphere (2.0)
;   15-07-02 M.Morooka Minor procedure change (2.1)
;-

;======= this_version_mvn_lpw_prd_lp_n_t_mm =============================================
function this_version_mvn_lpw_prd_lp_n_t_mm
  ver = 2.1
  prd_ver= 'version mvn_lpw_prd_lp_n_t_mm: ' + string(ver,format='(F4.1)')
  return, list(prd_ver,ver)
end
;=============================================== this_version_mvn_lpw_prd_lp_n_t_mm =====

;===== make_sweep_set_new ================================================================
; Average two same voltage current data and
;             clean the sweep current to ready for analysys
function make_sweep_set_new, T_org, U_org, I_org, mode

  U = U_org & I = I_org & T = T_org

  ;if mode eq 15 then begin
  ;   pp = indgen(64,start=64)
  ;endif else begin
  ;  ;--- data selection is try chose only down going sweep 
  ;  ;    + not take first/end constant V steps
  ;   pp =  where(ts_diff(U,1) gt 0.0)
  ;endelse

  case fix(mode) of
    5: begin
      if max(U)-min(U) le 50. then  pp = indgen(64)  ;+++ +-20V double
      ; something wrong at 2014-12-07 02:55:00-03:00:00
    end
    12: pp = indgen(125,start=2) ;+++ +-20V single
    14: pp = indgen(126)         ;+++ +-40V single
    15: pp = indgen(64,start=64) ;+++ French mode +-10
    else: begin
      if T(0) lt time_double('2014-11-01/00:00:00.') then pp = indgen(64) $
      else                                                pp = indgen(125,start=1)
    end
  endcase

  if keyword_set(pp) then begin
    I = I(pp) & U = U(pp)
  endif else begin
    I = make_array(n_elements(I),1,value=!values.F_nan)
  endelse
  
  ;----- clean sweep to ready for the analysis --------------------------------------
  ;vind = sort(U) & U = U(vind) & I = I(vind)
  
  new_swp = [[U],[I]]
  return, new_swp
end
;================================================================ make_sweep_set_new =====

;===== make_sweep_set ===================================================================
; Average two same voltage current data and
;             clean the sweep current to ready for analysys
function make_sweep_set, U_org, I_org, mode

  U = U_org & I = I_org

  ;**********************************************************************************
  ; For the moment we use only the first down sweep data for analysis. Need to be
  ; taken care considering time variability and hysteresis .
  ;**********************************************************************************
  
  case fix(mode) of
    ;1: pp = indgen(64)          ;+++ +-10V double
     0: pp = indgen(126)
     5: begin
      if max(U)-min(U) le 50. then  pp = indgen(64)  ;+++ +-20V double
      ; something wrong at 2014-12-07 02:55:00-03:00:00
      end
    12: pp = indgen(125,start=2) ;+++ +-20V single
    14: pp = indgen(126)         ;+++ +-40V single
    15: pp = indgen(64,start=64) ;+++ French mode +-10    
    else: begin
      if U(0)*U(127) gt 0. then pp = indgen(64) $ ;case for first sweep
      else pp = indgen(128)
    end
  endcase
  
  if keyword_set(pp) then begin
    I = I(pp) & U = U(pp)
  endif else begin
    I = make_array(n_elements(I),1,value=!values.F_nan)
  endelse
  
  ;----- clean sweep to ready for the analysis --------------------------------------
  vind = sort(U) & U = U(vind) & I = I(vind)
  
  new_swp = [[U],[I]]
  return, new_swp
  
end
;=================================================================== make_sweep_set =====

;======= get_swp_type_l1a ===============================================================
function get_swp_type_l1a, mode, I
  
  ;***** Use max sweep current value to define the analys method for the moment *****
  ;      Max(I) > 1e-6 as IOSP mode
  if max(I) gt 1e-6 then swp_type = 'IOSP' else swp_type = 'SW'
  if mode eq 0 then swp_type = 'fitswp_10V_03_2e'
  return, swp_type
end
;================================================================= get_swp_type_l1a =====

; case mode of
;     0: swp_matrix = {type:fix(-1),mode:'Deep Dip',        file:'swp00.txt'} ;
;     1: swp_matrix = {type:fix(-1),mode:'Low Altitude',    file:'swp01.txt'} ;
;     2: swp_matrix = {type:fix(-1),mode:'Ionospause',      file:'swp02.txt'} ;
;     3: swp_matrix = {type:fix( 1),mode:'High Altitude',   file:'swp03.txt'} ;fitswp_magnetosphere()
;     4: swp_matrix = {type:fix(-1),mode:'Deep Dip',        file:'swp01.txt'} ;
;     5: swp_matrix = {type:fix(-1),mode:'Low Altitude',    file:'swp02.txt'} ;
;     6: swp_matrix = {type:fix(-1),mode:'Ionopause',       file:'swp02.txt'} ;
;     7: swp_matrix = {type:fix( 1),mode:'Transition mode', file:'swp03.txt'} ;fitswp_magnetosphere()
;     8: swp_matrix = {type:fix( 1),mode:'Comet Mode',      file:''         } ;fitswp_magnetosphere()
;     9: swp_matrix = {type:fix(-1),mode:'Boom Cleaning',   file:''         } ;
;    10: swp_matrix = {type:fix( 1),mode:'Cruise Mode',     file:'swp10.txt'} ;fitswp_magnetosphere()
;   100: swp_matrix = {type:fix( 0),mode:'l0 process',      file:''         } ;fitswp_l0()
;   200: swp_matrix = {type:fix( 0),mode:'l2 process',      file:''         } ;fitswp_l0()
;  else:swp_matrix  = {type:fix(-1),mode:'mode not assigned',file:''} ;
; endcase

;======= get_swp_type ===================================================================
function get_swp_type, mode, I
  ;***** Use max sweep current value to define the analys method for the moment *****
  ;      Max(I) > 1e-6 as IOSP mode

  if max(I) gt 1e-6 then swp_type = 'fitswp_new_gaussian' else swp_type = 'SW'  
  return, swp_type
end
;================================================================= get_swp_type_l1a =====

;======= derive_ion =====================================================================
function derive_ion, m, b, Ufloat, n_mi, RAp

  if b_org le 0.0 then return, [!values.F_NaN, !values.F_NaN]
  if m_org ge 0.0 then return, [!values.F_NaN, !values.F_NaN]
  
  mH = 1.67262158e-27     ; Mass of Proton in [Kg]
  Z = 1.              ;charge [+/-] of current carrying species.
  kb = 1.3807e-23
  qe = 1.602176462e-19 ;Electron charge/[C]
  
  rp=6.35e-3  ;Radius of Langmuir Probe [m]
  lp=0.4      ;Length of cylindrical Langmuir Probe [m]
  ;----- cylindrical shape
  ;Ap     = !pi*rp*lp;
  ;----- ellipsoid shape
  p = 1.6075
  Ap = 2*!pi*(( rp^p*rp^p + rp^p*(0.5*lp)^p + rp^p*(0.5*lp)^p )/3.)^(1/p)
  
  Ap = Ap * RAp
  
  m = abs(m_org) & b = abs(b_org)
  mi = n_mi * mH
  af = abs(m-b*Ufloat)
  
  Ti_eff = af/b
  vi_ti_eff = sqrt(2*qe/mi) * Ti_eff
  
  nivi = 4.0*af/(Ap*qe)
  Ni = (nivi/(vi_ti_eff))* 1e-6
  vi_ti_eff = vi_ti_eff*1e-3
  
  return, [Ni, vi_ti_eff]
  
end
;======================================================================= derive_ion =====

;======= extract_lpstruc ================================================================
function extract_lpstruc, lpstruc_org, prd_ver, I_offset=I_offset

  lpstruc = lpstruc_org
  ;----- SET STRUCTURES -----------------------------------------------------------------
  swp_pp = mvn_lpw_prd_lp_swp_setupparam(prd_ver)
  swp_pp.probe = lpstruc.boom
  mode_swp = lpstruc.data.mode         & swp_pp.swp_mode = mode_swp
  Vsc      = lpstruc.anc.MSO_VEL.mag   & swp_pp.Vsc      = Vsc
  
  ;----- select sweep set and store the original ----------------------------------------
  swp_pp.voltage_l0 = lpstruc.data.VSWP
  swp_pp.current_l0 = lpstruc.data.ISWP
  swp_pp.time_l0    = lpstruc.data.TSWP
  swp_pp.time       = lpstruc.time
  
  ;----- Extract and clean the sweep data for analysis ----------------------------------
  if float(strmid(prd_ver, strlen(prd_ver)-3,3)) lt 2.0 then $
     new_swp = make_sweep_set(swp_pp.voltage_l0, swp_pp.current_l0, mode_swp) $
  else $
     new_swp = make_sweep_set_new(swp_pp.time_l0, swp_pp.voltage_l0, swp_pp.current_l0, mode_swp)
  
  U = new_swp[*,0] & I = new_swp[*,1] & delvar, new_swp
  
  ;----- store sweep information --------------------------------------------------------
  if float(strmid(prd_ver, strlen(prd_ver)-3,3)) lt 2.0 then begin    
    if not keyword_set(I_offset)  then I_offset = 8.78647e-09 else $
    if not finite(I_offset)       then I_offset = 8.78647e-09    
  endif
      
  swp_pp.voltage = U
  if not finite(I_offset) then swp_pp.current = I $
  else                         swp_pp.current = I - I_offset
  swp_pp.I_off = I_offset
  
  swp_pp.xlim = [min(U),max(U)]
  swp_pp.ptitle = strmid(swp_pp.proj,0,5)+'_P'+string(swp_pp.probe,format='(I01)')+' '+ $
                  time_string(lpstruc.data.TSWP(0))+'-'+ $
                  strmid(time_string(lpstruc.data.TSWP(n_elements(lpstruc.data.TSWP)-1)),11,18)
    
  swp_pp.RXA = sin(lpstruc.anc.BOOM_RAM_ANG*!pi/180.)

  return, swp_pp
end
;================================================================== extract_lpstruc =====

;======= create_mmstruc =================================================================
function create_mmstruc, prb

  fdummy = !Values.F_NAN & ddummy = !values.D_NAN & bdummy = byte(0)
  
  mmstruc_base = create_struct( $
                'NAME', 'MAVEN LPW IV SWEEP STRUCTURE MM', $
                'BOOM', bdummy, $
                'DATE', 'YYYY-MM-DD/HH:MM:SS.SSSSS', $
                'TIME', ddummy, $
                'DATA', {MODE: fdummy, VSWP:make_array(128,/float), $
                         ISWP: make_array(128,/float), TSWP:make_array(128,/double)}, $
                'ANC',  {MSO_VEL:{X:fdummy,Y:fdummy,Z:fdummy,MAG:fdummy}, $
                         BOOM_RAM_ANG:fdummy, $
                         BOOM_SUN_ANG:fdummy} $
            )

  ;----- Create data information from the tplot var. ---------------------------------
  case prb of
    1: begin
       get_data, 'mvn_lpw_swp1_I1',     data=data_I, limit=limit_I, dlimit=dlimit_I
       get_data, 'mvn_lpw_swp1_I1_pot', data=data_V, limit=limit_V, dlimit=dlimit_V
       get_data, 'mvn_lpw_swp1_mode',   data=data_mode, limit=limit_mode, dlimit=dlimit_mode       
    end
    2: begin
       get_data, 'mvn_lpw_swp2_I2',     data=data_I, limit=limit_I, dlimit=dlimit_I
       get_data, 'mvn_lpw_swp2_I2_pot', data=data_V, limit=limit_V, dlimit=dlimit_V
       get_data, 'mvn_lpw_swp2_mode',   data=data_mode, limit=limit_mode, dlimit=dlimit_mode
    end
  endcase
  
  get_data, 'mvn_lpw_anc_boom_wake_ram_angles',  data=data_ram_ang, limit=limit_ram_ang, dlimit=dlimit_ram_ang  
  get_data, 'mvn_lpw_anc_boom_shadow_angles',    data=data_sun_ang, limit=limit_sun_ang, dlimit=dlimit_sun_ang
  get_data, 'mvn_lpw_anc_mvn_vel_mso',           data=data_mso_vel, limit=limit_mso_vel, dlimit=dlimit_mso_vel

  if not keyword_set(data_I) then print, 'No I data. QUIT.'
  if not keyword_set(data_I) then return, -1
  if not keyword_set(data_V) then print, 'No I_pot data. QUIT.'
  if not keyword_set(data_V) then return, -1

  mmstruc = REPLICATE(mmstruc_base, n_elements(data_I.x)/128)

  mmstruc.data.mode = data_mode.y
  mmstruc.data.tswp = reform(data_I.x,128,n_elements(data_I.x)/128)
  mmstruc.data.Iswp = reform(data_I.y,128,n_elements(data_I.y)/128)
  mmstruc.data.Vswp = reform(data_V.y,128,n_elements(data_V.x)/128)

  mmstruc.boom = prb
  mmstruc.time = mmstruc.data.tswp(0)
  mmstruc.date = time_string(mmstruc.data.tswp(0),tformat='YYYY-MM-DD/hh:mm:ss.fffff')

  if not keyword_set(data_mso_vel) then return, mmstruc
    
  mmstruc.anc.mso_vel.x   = interpol(data_mso_vel.y(*,0),data_mso_vel.x,mmstruc.time)
  mmstruc.anc.mso_vel.y   = interpol(data_mso_vel.y(*,1),data_mso_vel.x,mmstruc.time)
  mmstruc.anc.mso_vel.z   = interpol(data_mso_vel.y(*,2),data_mso_vel.x,mmstruc.time)
  mmstruc.anc.mso_vel.mag = interpol(data_mso_vel.y(*,3),data_mso_vel.x,mmstruc.time)

  case prb of
    1: begin
        mmstruc.anc.BOOM_RAM_ANG = interpol(data_ram_ang.y(*,0),data_ram_ang.x,mmstruc.time)
        mmstruc.anc.BOOM_SUN_ANG = interpol(data_sun_ang.y(*,0),data_sun_ang.x,mmstruc.time)
       end
    2: begin
        mmstruc.anc.BOOM_RAM_ANG = interpol(data_ram_ang.y(*,1),data_ram_ang.x,mmstruc.time)
        mmstruc.anc.BOOM_SUN_ANG = interpol(data_sun_ang.y(*,1),data_sun_ang.x,mmstruc.time)
       end
  endcase

  return, mmstruc
end
;================================================================== create_mmstruc ======

;======= mm_fit_mvn_pre =================================================================
function mm_fit_mvn_pre, lpstruc, givenU=givenU, prd_ver=prd_ver, I_offset=I_offset

  ;----- input check --------------------------------------------------------------------
  if keyword_set(prd_ver) eq 0 then prd_ver = ''
  if keyword_set(givenU)  eq 0 then givenU = [!values.F_nan,-10,-20]

  ;----- VARIOUS SETTINGS ---------------------------------------------------------------
  if keyword_set(I_offset) then swp_pp = extract_lpstruc(lpstruc, prd_ver, I_offset=I_offset) $
  else                          swp_pp = extract_lpstruc(lpstruc, prd_ver)    
    
  ;***** skip analys if negative voltage sampling is less han eight *********************
  ;U_neg = where(U lt 0.0) & if n_elements(U_neg) lt 8 then continue
  ;**************************************************************************************

  ;----- Search current zero crossing roughly -------------------------------------------
   U = swp_pp.voltage & I = swp_pp.current & mode_swp = fix(swp_pp.swp_mode)
   U00 = where(abs(I) eq min(abs(I))) & U_zero = U(U00) & swp_pp.U_zero = min(U_zero)

  ;---- define analysis method depending on product level and mode ------------------
  if float(strmid(prd_ver, strlen(prd_ver)-3,3)) ge 2.0 then $
     swp_pp.fit_function_name = get_swp_type(mode_swp,I(where(U le 20))) $
  else $
     swp_pp.fit_function_name = get_swp_type_l1a(mode_swp,I(where(U le 20)))
  
  if swp_pp.flg eq -1 then return, swp_pp

  ;----- For the moment, the first and second parameters for the SW are fixed -------
  if swp_pp.fit_function_name eq 'SW'   then givenU = [givenU(0), -10, -20]
  if swp_pp.fit_function_name eq 'SW2'  then givenU = [givenU(0), givenU(0)-6, !values.F_nan]
  if swp_pp.fit_function_name eq 'IOSP' then givenU(0) = !values.F_nan
  swp_pp.U_input = givenU

  return, swp_pp
  
end
;=================================================================== mm_fit_mvn_pre =====

;= MAIN  mvn_lpw_prd_lp_n_t_mm ==========================================================
function mvn_lpw_prd_lp_n_t_mm, in1, I_offset=I_offset, fitname=fitname
  
  ;------ the version number of this routine --------------------------------------------------------
  t_routine=SYSTIME(0) & prd_ver_n_t_mm= this_version_mvn_lpw_prd_lp_n_t_mm()
  this_ver = prd_ver_n_t_mm(1) & prd_ver_n_t_mm = prd_ver_n_t_mm(0)
  print, '------------------------------' & print, prd_ver_n_t_mm & print, '------------------------------'
  prd_ver = prd_ver_n_t_mm

  ;----- Set negative bias voltage side current offset ----------------------------------
  if not keyword_set(I_offset) then  I_offset = !values.F_nan 

  ;----- create lpstruc if not exist ----------------------------------------------------
  if size(in1,/type) eq 3 or size(in1,/type) eq 2 then begin
     prb = in1
     lpstruc = create_mmstruc(prb)
  endif else if size(in1,/type) eq 8 then lpstruc = in1
  
  if size(lpstruc,/type) ne 8 then begin
    print, 'Err: invalid lpstruc. quit mvn_lpw_prd_lp_n_t_mm.' & return, -1
  endif
  
  ;----- set up sweep analysis parameter structures -------------------------------------
  paramset = mvn_lpw_prd_lp_swp_setupparam(prd_ver)
  swp_pp = REPLICATE(paramset, n_elements(lpstruc))

  count = 0
  for ii=0,n_elements(lpstruc)-1 do begin ;-------------------------------- loop ii -----
      
      if keyword_set(givenU) eq 0 then givenU = [!values.F_nan,-10,-20]
      
      pp = mm_fit_mvn_pre(lpstruc(ii),givenU=givenU,prd_ver=prd_ver,I_offset=I_offset)      
      givenU = pp.U_input
      
      if keyword_set(fitname) then if pp.fit_function_name ne fitname then begin
        swp_pp(ii) = pp
        continue
      endif
      
      swp_pp(ii) = mvn_lpw_prd_lp_n_t_fit(pp,pp.fit_function_name, givenU=givenU)

      
      if count mod 150 eq 0 then print, time_string(swp_pp(ii).time)+': '+swp_pp(ii).fit_function_name
      
      ;----- Give the result to the next analysis -----
      ;----- effect to the SW analysis ----------------
      ;givenU = [swp_pp(ii).U0,swp_pp(ii).U1,swp_pp(ii).U2]
       givenU = [swp_pp(ii).U0,-10,-20]
      count = count+1
  endfor;------------------------------------------------------------------ loop ii -----

  swp_pp = mvn_lpw_prd_lp_n_t_clean_swp_pp(swp_pp)

  return, swp_pp
end
;========================================================================= END_MAIN =====

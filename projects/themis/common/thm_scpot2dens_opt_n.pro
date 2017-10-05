;+
; NAME:
;    thm_scpot2dens_opt_n
;
; PURPOSE:
;    Convert the spacecraft potential to the electron density
;
; CATEGORY:
;    EFI, ESA
;
; CALLING SEQUENCE:
;    thm_scpot2dens_opt_n,sc=sc,datatype_esa=datatype_esa,trange=trange
;
; EXAMPLE:
;    thm_scpot2dens_opt_n,sc='d',datatype_esa='peer' ;scpot and vthermal from peer
;
; PRE-REQUIREMENTS:
;    Timespan for the calculation like
;    timespan,'2009-01-01/00:00:00',1,/day
;
; KEYWORD PARAMETERS:
;    probe         spacecraft name: 'a', 'b', 'c', 'd' or 'e'. Default is 'a'.
;    datatype_esa       ESA datatype: 'peef', 'peer', 'peem' or
;                       'peeb'. Default is 'peer'.
;    trange     The time range to input, if not set, then the timespan
;               value is used.
;    no_data_load - if set, do not load data
;    nscpot_ion_density_threshold - data for times where the ion
;                                  density is above this value are
;                                  flagged as 'bad' and set to
;                                  'NaN'. The default value is 4.0e1
; OUTPUTS:
;    'th?_*_density' Electron density in cm-3
; RESTRICTIONS:
;    The calculated electron density may include
;    uncertainties. Uncertainties are larger where the thermal
;    velocity of electrons is not accurately estimated: in the
;    plasmasphere, plasmatrough and lobe. Error data in the electron
;    thermal speed or spacecraft potential give unreliable denisities.
;
; MODIFICATION HISTORY:
;    Written by: Toshi Nishimura@UCLA/NAGOYA, 05/02/2009 (toshi at atmos.ucla.edu)
;    Modification 05/26/2009 Add keywords 'datatype_esa'. 
;    Modification 07/13/2009 Update the scpot-density relation mainly
;    for the plasmasphere.
;    Modfication 10/08/2009 Added trange keyword, jmm, jimm@ssl.berkeley.edu
;
;    Collaborators: Vassilis Angelopoulos, John Bonnell and Wen Li
;    It is recommended to contact people listed above before
;    presentations or publications using the data created by this
;    code.
;
;-
pro thm_scpot2dens_opt_n, probe = probe, datatype_esa = datatype_esa, trange = trange, no_data_load = no_data_load, $
                          nscpot_ion_density_threshold = nscpot_ion_density_threshold, _extra = _extra

  if (keyword_set(probe)) then sc = probe[0] Else sc = 'a'
  thx = 'th'+sc
  if not (keyword_set(datatype_esa)) then datatype_esa = 'peer'
  If(Not keyword_set(trange)) Then get_timespan, t Else t = trange
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;load data
  esa_iontype = 'peim'
  If(Not keyword_set(no_data_load)) Then Begin
    if(datatype_esa eq 'peef' or datatype_esa eq 'peer' or datatype_esa eq 'peeb') then begin
      thm_load_esa, probe = sc, level = 2, datatype = datatype_esa+'_'+['density', 'vthermal', 'sc_pot'], trange = t
      case datatype_esa of
         'peef':esa_iontype = 'peif'
         'peer':esa_iontype = 'peir'
         'peeb':esa_iontype = 'peib'
      endcase
      thm_load_esa, probe = sc, level = 2, datatype = esa_iontype+'_'+['density', 'vthermal', 'sc_pot'], trange = t
    endif else if(datatype_esa eq 'peem') then begin
       ;peem data comes from mom files
       thm_load_mom, probe = sc, level = 2, datatype = ['pe?m_density', 'pe?m_vthermal', 'pxxm_pot'], trange = t
       copy_data, thx+'_pxxm_pot', thx+'_peem_sc_pot'
       esa_iontype = 'peim'
    endif 
  Endif else begin   
    case datatype_esa of
      'peef':esa_iontype = 'peif'
      'peer':esa_iontype = 'peir'
      'peeb':esa_iontype = 'peib'
    endcase 
  Endelse
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;SM position
  thm_load_state, probe = sc, coord = 'sm', trange = t, suffix = '_sm_coordinates'

  get_data, thx+'_state_pos_sm_coordinates', data = tmp
  If(is_struct(tmp) Eq 0) Then Begin
    dprint, 'Missing: '+thx+'_state_pos_sm_coordinates'
    return
  Endif

  store_data, thx+'_R', data = {x:tmp.x, y:sqrt(tmp.y[*, 0]^2+tmp.y[*, 1]^2+tmp.y[*, 2]^2)/6371.2}, $
    dlim = {colors:[0], labels:['R'], ysubtitle:'[km]', labflag:1, constant:0, ytitle:thx+'_R'}
  MLT = atan(tmp.y[*, 1]/tmp.y[*, 0])*180/!pi/15.+12
  if(n_elements(where(tmp.y[*, 0] lt 0)) gt 1) then MLT[where(tmp.y[*, 0] lt 0)] = $
    (atan(tmp.y[where(tmp.y[*, 0] lt 0), 1]/tmp.y[where(tmp.y[*, 0] lt 0), 0])+!pi)*180/!pi/15.+12
  if(n_elements(where(MLT[*] gt 24)) gt 1) then MLT[where(MLT[*] ge 24)] = MLT[where(MLT[*] ge 24)]-24
  store_data, thx+'_MLT', data = {x:tmp.x, y:MLT}, $
    dlim = {colors:[0], labels:['R'], ysubtitle:'[km]', labflag:1, constant:0, ytitle:thx+'_MLT'}
  MLAT = atan(tmp.y[*, 2]/sqrt(tmp.y[*, 0]^2+tmp.y[*, 1]^2))*180/!pi
  store_data, thx+'_MLAT', data = {x:tmp.x, y:MLAT}, $
    dlim = {colors:[0], labels:['MLAT'], ysubtitle:'[deg]', labflag:1, constant:0, ytitle:thx+'_MLAT'}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;load data
  ;Vsc
  get_data, thx+'_'+datatype_esa+'_sc_pot', data = Vdata, index = index
  if(index eq 0) then begin
    dprint, 'Missing: '+thx+'_'+datatype_esa+'_sc_pot'
    return
  endif
  Vdata.y[*] = -Vdata.y[*]
  store_data, thx+'_'+datatype_esa+'_-sc_pot', data = Vdata
  ;Ne
  get_data, thx+'_'+datatype_esa+'_density', data = Nedata, index = index
  if(index eq 0) then begin
    dprint, 'Missing: '+thx+'_'+datatype_esa+'_density'
    return
  endif
  ;Vth
  get_data, thx+'_'+datatype_esa+'_vthermal', data = Vthdata, index = index
  if(index eq 0) then begin
    dprint, 'Missing: '+thx+'_'+datatype_esa+'_vthermal'
    return
  endif

  ;R,MLT
  tinterpol_mxn, thx+'_R', thx+'_'+datatype_esa+'_sc_pot', newname = thx+'_R_int'
  tinterpol_mxn, thx+'_MLT', thx+'_'+datatype_esa+'_sc_pot', newname = thx+'_MLT_int'
  get_data, thx+'_R_int', data = R, index = index1
  get_data, thx+'_MLT_int', data = MLT, index = index2
  if(index1 eq 0) then begin
    dprint, 'Missing: '+thx+'_R_int'
    return
  endif
  if(index2 eq 0) then begin
    dprint, 'Missing: '+thx+'_MLT_int'
    return
  endif

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Vth correction
  Vthdata.y = Vthdata.y*(1-(-1/(1+exp(-2*(R.y-4)))+1))+10^4*(-1/(1+exp(-2*(R.y-4)))+1)
  store_data, thx+'_vthermal2', data = Vthdata

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;scpot-density conversion
  Case sc Of
    'a': Ne_scpot = (10^(Vdata.y/22.0)*20000.+10^(Vdata.y/ 5.0)*160000.+10^(Vdata.y/2.0)*15000000.0+10^(Vdata.y/0.4)*1500000000000.0)/Vthdata.y
    'b': Ne_scpot = (10^(Vdata.y/25.5)*16500.                          +10^(Vdata.y/2.0)*3000000.0+10^(Vdata.y/0.4)*1500000000000.0)/Vthdata.y
    'c': Ne_scpot = (10^(Vdata.y/26.0)*22000.                          +10^(Vdata.y/2.0)*3000000.0+10^(Vdata.y/0.25)*1e14)/Vthdata.y
    'd': Ne_scpot = (10^(Vdata.y/25.5)*20000.+10^(Vdata.y/ 5.0)*30000.+10^(Vdata.y/2.0)*10000000.0+10^(Vdata.y/0.2)*5000000000000000.0)/Vthdata.y
    'e': Ne_scpot = (10^(Vdata.y/25.5)*20000.+10^(Vdata.y/ 5.0)*30000.+10^(Vdata.y/2.0)*10000000.0+10^(Vdata.y/0.2)*3000000000000000.0)/Vthdata.y
  Endcase
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  store_data, thx+'_'+datatype_esa+'_en_eflux_pot', data = [thx+'_'+datatype_esa+'_en_eflux', thx+'_'+datatype_esa+'_scpot']
  ylim, thx+'_'+datatype_esa+'_en_eflux_pot', 5e0, 2.3e4, style = 1

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;plasmasphere model (just for comparison) [Sheeley et al.]
  Ne_Sheeley_PSph = 1390*(3/R.y)^4.8
  Ne_Sheeley_PSsh = 124*(3/R.y)^4.0+36*(3/R.y)^3.5*cos((MLT.y-(7.7*(3/R.y)^2+12))*!pi/12)
  insert_nan = where(R.y[*] lt 2 or R.y[*] gt 7)
  If(insert_nan[0] Ne -1) Then Begin
    Ne_Sheeley_PSph[insert_nan] = 'NaN'
    Ne_Sheeley_PSsh[insert_nan] = 'NaN'
  Endif

;flag data, for high ion density areas, there are issues with sc
;potential, so this calculation is problematic, jmm, 2015-07-17
  ion_test_density = data_cut(thx+'_'+esa_iontype+'_density', Vdata.x)
  If(keyword_set(nscpot_ion_density_threshold)) Then nspcid = nscpot_ion_density_threshold $
  Else nspcid = 40.0
  bad = where(ion_test_density Gt nspcid, nbad)
  If(nbad Gt 0) Then Begin
     dprint, 'Flagging'+strcompress(string(nbad))+' points as bad for ion density >'+strcompress(string(nspcid))+'/cm^3'
     ne_scpot[bad] = !values.f_nan
     ne_sheeley_psph[bad] = !values.f_nan
  Endif

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;store data
  store_data, thx+'_'+datatype_esa+'_density_npot', data = {x:Vdata.x, y:Ne_scpot}, $
    dlim = {colors:[0], labels:['Ne_scpot'], ysubtitle:'[cm-3]', labflag:1, constant:0, ylog:1}
  store_data, thx+'_'+datatype_esa+'_density_Sheeley', data = {x:Vdata.x, y:Ne_Sheeley_PSph}, $
    dlim = {colors:[0], labels:['Ne_Sheeley_PSph'], ysubtitle:'[cm-3]', labflag:1, constant:0, ylog:1}

;error check the number of data points
  If(n_elements(nedata.x) Eq n_elements(vdata.x)) Then Begin
    store_data, thx+'_'+datatype_esa+'_density_comparison', $
      data = {x:Vdata.x, y:[[Nedata.y], [Ne_scpot], [Ne_Sheeley_PSph]]}, $
      dlim = {colors:[0, 2, 6], labels:['Ne_pxxm', 'Ne_scpot', 'Ne_Sheeley_PSph'], $
              ysubtitle:'[cm-3]', labflag:-1, constant:0, ylog:1}
    options, thx+'_'+datatype_esa+'_density_comparison'
  Endif

end

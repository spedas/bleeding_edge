;+
;FUNCTION:   mvn_lpw_prd_lp_swp_setupparam_new
; Create initial Sweep parameter set forMAVEN/LPW sweep analysis.
;
;INPUTS:
;OUTPUTS: gives LP Sweep parameter set specific for the mvn_lpw_prd_lp analys program.
;KEYWORDS:
;   win: use this keyword to see the every sweeep plot during the run
;
;EXAMPLE:
; mvn_lpw_prd_lp_swp_setupparam, PP, 'l0'
;
;CREATED BY:   Michiko Morooka  10-21-14
;FILE:         mvn_lpw_prd_lp_n_t_fit.pro
;VERSION:      3.0
;LAST MODIFICATION:
; 2014-10-20   M. Morooka
; 2014-11-17   M. Morooka   Add err information
;                           Add current_l0, voltage_l0
; 2015-01-13   M. Morooka   Add extra dummy fields
; 2015-04-16   M. Morooka   dTe added (2.3)
; 2015-05-26   M. Morooka   Change for new_fit (3.0)
; 2015-06-19   M. Morooka   Minor addition (3.1) (Ni2, mi2)
;-
;

;------- this_version_mvn_lpw_prd_lp_swp_setupparam -------
function this_version_mvn_lpw_prd_lp_swp_setupparam
  ver = 3.1
  prd_ver= 'version mvn_lpw_prd_lp_swp_setupparam: ' + string(ver,format='(F4.1)')
  return, prd_ver
end
;--------- this_version_mvn_lpw_prd_lp_swp_setupparam -----

; ------ swp_setupparam -----------------------------------
function mvn_lpw_prd_lp_swp_setupparam, prd_ver_in

  ;------ the version number of this routine --------------------------------------------------------
  t_routine=SYSTIME(0)
  prd_ver= this_version_mvn_lpw_prd_lp_swp_setupparam()
  ;print, '------------------------------' & print, prd_ver & print, '------------------------------'
  ;--------------------------------------------------------------------------------------------------

  PROJECT =                'MAVEN/LPW'
  rp =                  6.35e-3*0.5   ; Diameter of Langmuir Probe [m]
  lp =                          0.4   ; Length of cylindrical Langmuir Probe [m]
  Ap =              !pi*6.35e-3*0.4   ; Area of probe surface [m^2]
  XA =                  6.35e-3*0.4   ; Effective probe surface in [m^2], (lp*rp)
  RXA =                         1.0   ; persentage of probe surface (0-1.0)
  R_sun =                       1.5   ; distance from sun in [AU]
  v_len =                       128   ; Max number of Voltage steps

  PP = create_struct( $
    'ptitle',     'Sweep Current Plots' $ ; plotting title
    ,'xlim',[!values.F_nan, !values.F_nan] $
    ,'proj',                    PROJECT $ ; project name
    ,'probe',                         0 $ ; Probe number
    ,'rp',                           rp $ ; Radius of Langmuir Probe [m]
    ,'lp',                           lp $ ; Length of cylindrical Langmuir Probe [m]
    ,'Ap',                           Ap $ ; Area of probe surface [m^2]
    ,'XA',                           XA $ ; Effective probe surface in [m^2], (2*lp*rp)
    ,'RXA',                         RXA $ ; persentage of probe surface (0-1.0)
    ,'R_sun',                     R_sun $ ; distance from sun in [AU]
    ; +++++ Operation information +++++
    ,'swp_mode',                   -1.0 $  ; sweep mode
    ; +++++ Spacectaft Attitude information +++++
    ; +++++ Sweep Info. +++++
    ,'voltage_l0',        make_array(v_len,1,value=!values.F_nan) $
    ,'current_l0',        make_array(v_len,1,value=!values.F_nan) $      
    ,'time_l0',           make_array(v_len,1,value=double(!values.F_nan)) $
    ,'voltage',           make_array(v_len,1,value=!values.F_nan) $
    ,'time',              double(!values.F_nan) $
    ,'current',           make_array(v_len,1,value=!values.F_nan) $
    ,'I_photo',           make_array(v_len,1,value=!values.F_nan) $
    ,'I_ion',             make_array(v_len,1,value=!values.F_nan) $
    ,'I_electron1',       make_array(v_len,1,value=!values.F_nan) $
    ,'I_electron2',       make_array(v_len,1,value=!values.F_nan) $
    ,'I_electron3',       make_array(v_len,1,value=!values.F_nan) $
    ,'I_tot',             make_array(v_len,1,value=!values.F_nan) $
    ,'I_tmp',             make_array(v_len,1,value=!values.F_nan) $
    ,'I_ion2',            make_array(v_len,1,value=!values.F_nan) $
    ,'I_tot2',            make_array(v_len,1,value=!values.F_nan) $
    ,'I_off',             !values.F_nan $ ; Instrumental current error (set 8.78647e-09 for ver. before 2.0)
    ; +++++ Plasma parameters +++++
    ,'Vsc',               !values.F_nan $ ; Spacecraft velosity respect to plasma [km]
    ; +++++ positive bias side +++++
    ,'No_e',              !values.F_nan $ ; Number of electron populations (1, 2, or 3 only)
    ,'Ne_tot',            !values.F_nan $ ; Total electron density in [cm(-3)]
    ,'Ne1',               !values.F_nan $ ; Electron density of comp1 in [cm(-3)]
    ,'Ne2',               !values.F_nan $ ; Electron density of comp2 in [cm(-3)]
    ,'Ne3',               !values.F_nan $ ; Electron density of comp3 in [cm(-3)]
    ,'dNe_tot',           !values.F_nan $ ; Total electron density in [cm(-3)]
    ,'dNe1',              !values.F_nan $ ; error
    ,'dNe2',              !values.F_nan $ ; error
    ,'dNe3',              !values.F_nan $ ; error
    ,'Neprox',            !values.F_nan $ ; Enectron density in thin plasma region using floating potential proxy
    ,'dNeprox',           !values.F_nan $ ; error
    ,'U_zero',            !values.F_nan $ ; Voltage that current goes to zero in [V]
    ,'U0',                !values.F_nan $ ; Probe Floating potential [V]
    ,'U1',                !values.F_nan $ ; Characteristic potentials between probe-to-plasma1  [V]
    ,'U2',                !values.F_nan $ ; Characteristic potentials between probe-to-plasma2  [V]
    ,'dU0',               !values.F_nan $ ; error
    ,'dU1',               !values.F_nan $ ; error
    ,'dU2',               !values.F_nan $ ; error
    ,'Usc',               !values.F_nan $ ; Spacecraft potential (Debye length assumed with obtained density)
    ,'dUsc',              !values.F_nan $ ; error
    ,'Usc_corr',          !values.F_nan $ ; Spacecraft potential corrected by attitudes
    ,'Te',                !values.F_nan $ ; Average Electron temperature  in [eV]
    ,'Te1',               !values.F_nan $ ; Electron temperature of comp1 in [eV]
    ,'Te2',               !values.F_nan $ ; Electron temperature of comp2 in [eV]
    ,'Te3',               !values.F_nan $ ; Electron temperature of comp3 in [eV]
    ,'dTe',               !values.F_nan $ ; error of main electron component in [eV]
    ,'dTe1',              !values.F_nan $ ; error
    ,'dTe2',              !values.F_nan $ ; error
    ,'dTe3',              !values.F_nan $ ; error
    ,'fnorm',             !values.F_nan $ ;
    ; +++++ negative bias side +++++
    ,'Ni',                !values.F_nan $ ; Ion effective density in [cm(-3)]
    ,'Ni2',               !values.F_nan $ ; Ion effective density in [cm(-3)]
    ,'Ufloat',            !values.F_nan $ ; Ufloat to calcurate Ni   [V] (=Usc)
    ,'Ufloat2',           !values.F_nan $ ; Alternative Ufloat to calcurate Ni2 [V]
    ,'Ti',                !values.F_nan $ ; Ion thermal velocity in [eV]
    ,'Vi',                !values.F_nan $ ; Ion drift velocity in [km/s]
    ,'m',                 !values.F_nan $ ; Linearised Ion current constans
    ,'m2',                !values.F_nan $ ; Linearised Ion current constans (squared m)
    ,'m_corr',            !values.F_nan $ ; 'M' value corrected by attitude
    ,'b',                 !values.F_nan $ ; Linearised Ion current gradient
    ,'b2',                 !values.F_nan $ ;Linearised Ion current gradient (squared b)
    ,'mi',                !values.F_nan $ ; Average Ion mass number
    ,'mi2',               !values.F_nan $ ; Average Ion mass number
    ,'dNi',               !values.F_nan $ ; error
    ,'dTi',               !values.F_nan $ ; error
    ,'dVi',               !values.F_nan $ ; error
    ,'dM',                !values.F_nan $ ; error
    ,'dB',                !values.F_nan $ ; error
    ,'dmi',               !values.F_nan $ ; error
    ,'mb_norm',           !values.F_nan $ ; Norm value for linear fitting
    ,'UV',                !values.F_nan $ ; UV level
    ,'dUV',               !values.F_nan $ ; error
    ; +++++ fitting info +++++
    ,'Ii_ind',            make_array(v_len,1,value=!values.F_nan) $
    ,'Ie_ind',            make_array(v_len,1,value=!values.F_nan) $
    ; +++++ numbers for calibrations 
    ,'ifit_points',       0             $ ; number of points used for ion      fitting for IOSP
    ,'efit_points',       [0, 0, 0]     $ ; number of points used for electron fitting for IOSP
    ,'flg',                           0 $
   ;,'flag_info',                    '' $
   ;,'flag_source',                  '' $
    ,'fit_err',            make_array(v_len,2,value=!values.F_nan) $ ; fitting err value
    ,'fit_err2',            !values.F_nan $ ; fitting err value
    ,'fit_err3',            !values.F_nan $ ; fitting err value
    ,'fit_err4',           make_array(v_len,2,value=!values.F_nan) $ ; fitting err value
    ; +++++ add prd ver in the end
    ,'prd_ver',                 prd_ver_in + ' # ' + prd_ver $
    ,'fit_function_name',            '' $   ; fitting routine name; 
    ,'U_input',        [!values.F_nan,!values.F_nan,!values.F_nan] $ ; Initial suggestion of U if needed
    ; +++++ add extra field for in case
    ,'dummy_arr1',             make_array(v_len,1,value=!values.F_nan) $ ;---
    ,'dummy_arr2',             make_array(v_len,1,value=!values.F_nan) $ ;---
    ,'dummy_arr3',             make_array(v_len,1,value=!values.F_nan) $ ;---
    ,'dummy_arr4',             make_array(v_len,1,value=!values.F_nan) $ ; Ie_ind for N1 in case of two components
    ,'dummy1',                !values.F_nan $ ; ----- Ufloat from ion fitting (20150606)
    ,'dummy2',                !values.F_nan $ ; ----- unfixed RXA for ion (20150606)
    ,'dummy3',                !values.F_nan $ ; ----- sq_linear fit param A
    ,'Beta',                  !values.F_nan $ 
    ,'peaks',                 make_array(3,1,value = !values.F_nan) $ 
    ,'WGaussian',             make_array(3,1,value = !values.F_nan) $
    ,'HGaussian',             make_array(3,1,value = !values.F_nan) $
    ,'U_Imin',                !values.F_nan $
    ,'U_didvmax',             !values.F_nan $
    )

  return, PP
  
end
; ------------------------------------ swp_setupparam -----
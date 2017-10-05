;+
; NAME: 
;   eva_sitl_load_socs
;
; PURPOSE: 
;   To create FOMstr and/or BAKstr using Bob's Algorithm.
;   This is basically a simulation of FOMstr generation
;   at SDC.
;
;-


PRO eva_sitl_load_socs, state, str_tspan, mdq=mdq
  compile_opt idl2
  tspan = time_double(str_tspan)
  print,'EVA: (eva_sitl_load_socs) tspan:'+str_tspan[0]+' - '+str_tspan[1]

  ;-----------------
  ; TARGET TIME
  ;-----------------
  tplot_names,'mms_soca_fomstr',names=names
  if n_elements(names) ne 1 then stop; return
  get_data,'mms_soca_fomstr',data=D,dl=dl,lim=lim
  tfom = eva_sitl_tfom(lim.unix_FOMstr_org)
  
  ;============
  ; FOM
  ;============
  filename = state.PREF.EVA_CACHE_DIR+'FOMstr_socs.sav'
  
  status = eva_sitl_load_socs_getfom(tfom,filename=filename)

END
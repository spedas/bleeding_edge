;+
; PRO: REE_SET_GSM, sc
;
; PURPOSE: LOADS STATE AD SETS UP PLOTS FOR GSM
;
; INPUT: 
;       SC    -       REQUIRED. STRING. Spacecraft
;
; EXAMPLE: ree_set_gsm, 'a' 
;
; OUTPUT: GSM Coordinates are laoded into tplot. 
;
; WARNING: BE SURE TO SET TIMESPAN FIRST!
;
; INITIAL VERSION: REE 08-10-31
; MODIFICATION HISTORY: 
; LASP, CU
; 
;-
pro ree_set_gsm, sc

; LOAD STATE DATA
thm_load_state,probe=sc,/get_support


; TRANSFORM state_pos from GEI to GSE & get GSE

re=6378.16              ;Earth equatorial radius [km]
;thm_cotrans,'th'+sc+'_state_pos','th'+sc+'_state_pos_gsm',out_c='gsm'
get_data,'th'+sc+'_state_pos_gsm',data=pgsm
store_data,'th'+sc+'_state_pxgsm',data={x:pgsm.x,y:pgsm.y[*,0]/re}
store_data,'th'+sc+'_state_pygsm',data={x:pgsm.x,y:pgsm.y[*,1]/re}
store_data,'th'+sc+'_state_pzgsm',data={x:pgsm.x,y:pgsm.y[*,2]/re}
options,'th'+sc+'_state_pxgsm','ytitle','Xgsm (R!DE!N)'
options,'th'+sc+'_state_pygsm','ytitle','Ygsm (R!DE!N)'
options,'th'+sc+'_state_pzgsm','ytitle','Zgsm (R!DE!N)'

tplot_options, var_label=['th'+sc+'_state_pxgsm','th'+sc+'_state_pygsm', $
        'th'+sc+'_state_pzgsm']
time_stamp, /off

end        

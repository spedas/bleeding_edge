
;+
;Procedure:
;  thm_crib_eclean_subsolar
;
;Purpose:
;  ?
;
;Notes:
;  WARNING: This crib runs code that is under development.  
;           Query Jianbao Tao (Jianbao.Tao@colorado.edu) or
;           John Bonnel (jbonnell@ssl.berkeley.edu) about 
;           the quality of the data products.
;
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2015-05-13 18:00:26 -0700 (Wed, 13 May 2015) $
;$LastChangedRevision: 17598 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/examples/advanced/thm_crib_eclean_subsolar.pro $
;-


print, "--- Start of crib sheet ---"


; SET DAY AMD SC
timespan,'2008-08-17'    ; PICK YOR DATE
sc='e'
probe = sc               ; ONLY ONE PROBE AT A TIME!!!!

; LOAD AND SET UP TPLOT FOR GSM 
thm_load_state,probe=sc,/get_support

; LOAD AND SET UP TPLOT FOR GSM  (USE YOUR OWN)
;re=6371.2                ;tplot default
re=6378.16d              ;Earth equatorial radius [km]
thm_cotrans,'th'+sc+'_state_pos','th'+sc+'_state_pos_gsm',out_c='gsm'
get_data,'th'+sc+'_state_pos_gsm',data=pgsm
store_data,'th'+sc+'_state_pxgsm',data={x:pgsm.x,y:pgsm.y[*,0]/re}
store_data,'th'+sc+'_state_pygsm',data={x:pgsm.x,y:pgsm.y[*,1]/re}
store_data,'th'+sc+'_state_pzgsm',data={x:pgsm.x,y:pgsm.y[*,2]/re}
options,'th'+sc+'_state_pxgsm','ytitle','Xgsm (R!DE!N)'
options,'th'+sc+'_state_pygsm','ytitle','Ygsm (R!DE!N)'
options,'th'+sc+'_state_pzgsm','ytitle','Zgsm (R!DE!N)'
tplot_options, var_label=['th'+sc+'_state_pxgsm','th'+sc+'_state_pygsm', $
        'th'+sc+'_state_pzgsm']


; GET CLEAN EFIELD
; (1) TAIL IS DEFAULT. /SUBSOLAR USES SOME DIFFERENT METHODS.
; (2) MUST SUPPLY PROBE!!
; (3) MUST LOAD STATE!!
thm_efi_clean_efp, probe=probe, /subsolar

; RUNS FASTER IF TIME RANGE IS SELECTED
; SINGLE PARTICLE BURST
tpb = time_double(['2008-08-17/16:46:00','2008-08-17/17:08:00']) 
thm_efi_clean_efp, probe=probe, /subsolar, tran=tpb
Ename = 'th'+sc+'_efp_clean_gsm'    

; GET MAG DATA
thm_load_fgm, probe=sc, datatype = ['fgh'], coord=['dsl', 'gsm'], level = 'l2'
;thm_load_fit, probe=sc, datatype = ['fgs'], coord=['dsl', 'gsm']
Bname = 'th' + sc + '_fgh_gsm'

; MAKE UP SOME NAMES
Sname = 'th'+sc+'_ExB_gsm'           ; POYNTING FLUX
Vname = 'th'+sc+'_EBvel_gsm'         ; ExB VELOCITY
Btot =  'th'+sc+'_fgh_Btot_gsm'      ; INCLUDES BTOT ON PLOT
EdotB = 'th'+sc+'_EdotB_gsm'         ; INCLUDES E|| ON PLOT

; MAKE ALL SORTS OF FUN STUFF
thm_efi_exb, Ename, Bname, Sname=Sname, $
 Vname=Vname, Btot=Btot, EdotB=EdotB
tsmooth2, Vname, 129, newname=Vname  ; FILTER VELOCITY TO 1 S 

; TPLOT
tplot, [Btot, EdotB, Vname], tran=tpb


print, "--- End of crib sheet ---"

end



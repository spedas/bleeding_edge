;+
;
; $LastChangedBy: rlivi04 $
; $LastChangedDate: 2023-01-31 16:43:59 -0800 (Tue, 31 Jan 2023) $
; $LastChangedRevision: 31452 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/escapade/esa/common/esc_apdat_init.pro $
;
; TTAGS Example
;   ttags = '*SPEC CNTS DATASIZE MODE2 *BITS SOURCE COMPR_RATIO NUM_* TIME_*'
;-

PRO esc_apdat_init,reset=reset, save_flag = save_flag, rt_flag= rt_Flag, clear = clear, no_products =no_products

   ;; Check whether initialziation already happened
   COMMON esc_apdat_init, initialized
   IF keyword_set(reset) THEN initialized = 0
   IF keyword_set(initialized) THEN return
   initialized = 1
   ;; dprint,dlevel=3,/phelp ,rt_flag,save_flag

   ;;##############
   ;;# ESA APID  #
   ;;##############

   ;; Analog Housekeeping - Digital Housekeeping
   ;;esc_apdat_info,'111'x, name='esa_raw',  apid_obj='esc_fram_apdat', tname='esc_raw_',  ttags='*', save_flag=save_flag, rt_flag=rt_flag
   ;;esc_apdat_info,'10E'x, name='esa_dhkp', apid_obj='esc_dhkp_apdat', tname='esc_dhkp_', ttags='*', save_flag=save_flag, rt_flag=rt_flag
   esc_apdat_info,'10F'x, name='esa_ahkp', apid_obj='esc_ahkp_apdat', tname='esc_ahkp_', ttags='*', save_flag=save_flag, rt_flag=rt_flag

   ;;############################################
   ;; GSE APID
   ;;############################################
   esc_apdat_info,'734'x,name='moc_queue',save_flag=save_flag,rt_flag=rt_flag
   esc_apdat_info,'751'x,name='aps1',   routine='esc_power_supply_decom',tname='APS1_',   save_flag=save_flag,ttags='*P25?',           rt_flag=rt_flag
   esc_apdat_info,'752'x,name='aps2',   routine='esc_power_supply_decom',tname='APS2_',   save_flag=save_flag,ttags='*P25?',           rt_flag=rt_flag
   esc_apdat_info,'753'x,name='aps3',   routine='esc_power_supply_decom',tname='APS3_',   save_flag=save_flag,ttags='*P6? *N25V',      rt_flag=rt_flag
   esc_apdat_info,'754'x,name='aps4',   routine='esc_power_supply_decom',tname='APS4_',   save_flag=save_flag,ttags='P25?',            rt_flag=rt_flag
   esc_apdat_info,'755'x,name='aps5',   routine='esc_power_supply_decom',tname='APS5_',   save_flag=save_flag,ttags='P25?',            rt_flag=rt_flag
   esc_apdat_info,'756'x,name='aps6',   routine='esc_power_supply_decom',tname='APS6_',   save_flag=save_flag,ttags='P25?',            rt_flag=rt_flag
   esc_apdat_info,'761'x,name='bertan1',routine='esc_power_supply_decom',tname='Igun_',   save_flag=save_flag,ttags='*VOLTS *CURRENT', rt_flag=rt_flag
   esc_apdat_info,'762'x,name='bertan2',routine='esc_power_supply_decom',tname='Egun_',   save_flag=save_flag,ttags='*VOLTS *CURRENT', rt_flag=rt_flag
   esc_apdat_info,'7c3'x,name='manip',  routine='esc_manip_decom',       tname='manip_',  save_flag=save_flag,ttags='*',               rt_flag=rt_flag
   ;;esc_apdat_info,'7c0'x,name='log_msg',   apid_obj='esc_log_msg_apdat', tname='log_',    save_flag=save_flag,ttags='MSG SEQN',        rt_flag=rt_flag
   ;;esc_apdat_info,'7c1'x,name='usrlog_msg',apid_obj='esc_log_msg_apdat', tname='usrlog_', save_flag=save_flag,ttags='SEQN MSG',        rt_flag=rt_flag
   ;;esc_apdat_info,'7c4'x,name='swemulator', apid_obj='esc_swemulator_apdat'   ,tname='swemul_tns_',ttags='*',save_flag=save_flag,rt_flag=rt_flag

   if keyword_set(clear) then esc_apdat_info,/clear

end

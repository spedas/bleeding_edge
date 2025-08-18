

PRO esc_init_realtime

   rootdir = root_data_dir() + 'esc/data/sci/prelaunch/gsedata/realtime/'   
   fileformat = 'YYYY/MM/DD/esc_socket_YYYYMMDD_hh.dat.gz'
   fileres =3600.d
   host = 'abiad-sw.ssl.berkeley.edu'
   exec_proc = 'esc_raw_stream_read'
   esc_raw_recorder,title='ESCAPADE EESA RAW', port=5001, host=host, exec_proc=exec_proc, $
                    destination=fileformat,directory=rootdir+'fm1/eesa/',set_file_timeres=fileres   

   txt = ['tplot,verbose=0,trange=systime(1)+[-1,.05]*3600*.1','timebar, systime(1)']
   exec, exec_text = txt

   tplot_options,title='Real time'
   
   ;;  esc_swp_startup,/rt_flag
   esc_apdat_init, /rt_flag
   esc_apdat_info, /rt_Flag, /save_flag, /all
   
   ;;esc_swp_set_tplot_options
   
   ;;--------------------------------------------------
   ;; Useful command to see what APIDs have been loaded
   ;; esc_apid_info,/print
   ;; print_struct,ap
   ;;-------------------------------------------------

END














;;--- OLD CODE ---

   ;;if keyword_set(ion) then spani=1
   ;;if n_elements(hub) eq 0 then hub = 1
   ;;if keyword_set(rm320) then cal=1
   ;;if keyword_set(tent) then tv=1
   ;;if keyword_set(tv) then snout2=1
   
   
   ;;if keyword_set(elec) then begin
   ;;  spanea = 1
   ;;  dprint, 'Please use spanea keyword instead'
   ;;endif
   ;;if keyword_set(tvac) then snout2=1

   ;;if keyword_set(spani) then instr = 'spani'
   ;;if keyword_set(spanea) then instr='spanea'
   ;;if keyword_set(spaneb) then instr='spaneb'
   ;;if keyword_set(spc) then instr = 'spc'
   ;;if keyword_set(swem) then instr = 'swem'
   ;;if keyword_set(hermes) then instr = 'hermes'
   ;;if keyword_set(swxspe) then instr = 'swxspe'

   ;;if keyword_set(cal) then   router = 'cal'
   ;;if keyword_set(snout2) then router = 'snout2'
   ;;if keyword_set(snout1) then router = 'snout1'
   ;;if keyword_set(crypt) then router = 'crypt'
   ;;if keyword_set(apl) then router = 'APL'
   ;;if keyword_set(gsfc) then router = 'GSFC'
   

   ;;IF keyword_set(recent) THEN esc_ptp_file_read, esc_file_retrieve(raw=raw)

   
   ;;if keyword_set(itf) then begin
   ;;   recorder,title='SWEM ITF', port= hub ? 8082 : 2024, host='abiad-sw.ssl.berkeley.edu', exec_proc='esc_itf_stream_read' 
   ;;   return
   ;;endif
   ;;  if keyword_set(swemgse) then begin
   ;;    recorder,title='SWEMGSE', port= hub ? 2428 : 2024, host='abiad-sw.ssl.berkeley.edu', exec_proc='esc_ptp_stream_read' 
   ;;  endif
   ;;if keyword_set(rm133) then begin
   ;;   recorder,title='ROOM 133', port= hub ? 2028 : 2024, host='128.32.13.37', exec_proc='esc_ptp_stream_read'
   ;;   return
   ;;endif
   ;;if keyword_set(rm333) then begin
   ;;   recorder,title='ROOM 333', port= hub ? 2028 : 2023, host='ssa333-lab.ssl.berkeley.edu', exec_proc='esc_msg_stream_read'
   ;;   return
   ;;endif
   ;;IF  keyword_set(cal) THEN BEGIN
      ;;if keyword_set(spani) then esc_ptp_recorder,title='CAL SPANI PTP',  port=2028, host=host, exec_proc=exec_proc,destination=fileformat,directory=rootdir+'cal/spani/',set_file_timeres=fileres
      ;;if keyword_set(spanea) then esc_ptp_recorder,title='CAL SPANEA PTP',port=2128, host=host, exec_proc=exec_proc,destination=fileformat,directory=rootdir+'cal/spanea/',set_file_timeres=fileres
      ;;if keyword_set(spaneb) then esc_ptp_recorder,title='CAL SPANEB PTP',port=2228, host=host, exec_proc=exec_proc,destination=fileformat,directory=rootdir+'cal/spaneb/',set_file_timeres=fileres
      ;;if keyword_set(spc)    then esc_ptp_recorder,title='CAL SPC PTP',port=2328, host=host, exec_proc=exec_proc,destination=fileformat,directory=rootdir+'cal/spc/',set_file_timeres=fileres
      ;;if keyword_set(swem)   then esc_ptp_recorder,title='CAL SWEM PTP',port=2528, host=host, exec_proc=exec_proc,destination=fileformat,directory=rootdir+'cal/swem/',set_file_timeres=fileres
   ;;endif

      

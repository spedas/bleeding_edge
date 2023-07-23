

pro swx_init_realtime,filename=filename,base=base,hub=hub,itf=itf, swxspe = swxspe, hermes = hermes, SWEMGSE=SWEM, $
    router=router, instr=instr, recent=recent, hires1=hires1, sslsoc=sslsoc, $
    exec=exec0,cal=cal,snout2=snout2

  if n_elements(hub) eq 0 then hub = 1
  
  if keyword_set(swxspe) then instr = 'swx_spane'
  if keyword_set(swem) then instr = 'swem'
  if keyword_set(hermes) then instr = 'hermes'
  if keyword_set(cal) then   router = 'cal'
  if keyword_set(snout2) then router = 'snout2'
  
  rootdir = root_data_dir() + 'spp/data/sci/sweap/prelaunch/gsedata/realtime/'
  ;rootdir = root_data_dir() + 'swx/data/ ; change to the appropriate directory when it exists.
;  directory = rootdir + router+'/'+instr+'/'
  fileformat = 'YYYY/MM/DD/swx_spe_socket_YYYYMMDD_hh.dat.gz'
  fileres =3600.d

  ports= dictionary('swxspe',2328)
  hosts= dictionary('snout2','snout2router.ssl.berkeley.edu')

  ;if keyword_set(recent) then spp_ptp_file_read, spp_file_retrieve(cal=cal,snout2=snout2,snout1=snout1,recent=recent,spani=spani,spanea=spanea,spaneb=spaneb,swem=swem,router=router)

  

  if  keyword_set(cal) then begin
;    directory = rootdir + router+'/'+instr+'/'
;    host = 'abiad-sw.ssl.berkeley.edu'
;    exec_proc = 'spp_ptp_stream_read'
;    if keyword_set(spani) then spp_ptp_recorder,title='CAL SPANI PTP',  port=2028, host=host, exec_proc=exec_proc,destination=fileformat,directory=rootdir+'cal/spani/',set_file_timeres=fileres
;    if keyword_set(spanea) then spp_ptp_recorder,title='CAL SPANEA PTP',port=2128, host=host, exec_proc=exec_proc,destination=fileformat,directory=rootdir+'cal/spanea/',set_file_timeres=fileres
;    if keyword_set(spaneb) then spp_ptp_recorder,title='CAL SPANEB PTP',port=2228, host=host, exec_proc=exec_proc,destination=fileformat,directory=rootdir+'cal/spaneb/',set_file_timeres=fileres
;    if keyword_set(spc)    then spp_ptp_recorder,title='CAL SPC PTP',port=2328, host=host, exec_proc=exec_proc,destination=fileformat,directory=rootdir+'cal/spc/',set_file_timeres=fileres
;    if keyword_set(swem)   then spp_ptp_recorder,title='CAL SWEM PTP',port=2528, host=host, exec_proc=exec_proc,destination=fileformat,directory=rootdir+'cal/swem/',set_file_timeres=fileres
  endif
  if  keyword_set(snout2) then begin
    directory = rootdir + router+'/'+instr+'/'
    host = 'snout2router.ssl.berkeley.edu'
    exec_proc = 'spp_ptp_stream_read'
    if keyword_set(swem)   then spp_ptp_recorder,title='Snout2 SWEM PTP',port=2528, host=host, exec_proc=exec_proc,destination=fileformat,directory=rootdir+'Snout2/swem/',set_file_timeres=fileres
    if keyword_set(swxspe) then spp_ptp_recorder,title='Snout2 SWx SPANE PTP',port=2328,host=host,exec_proc=exec_proc,destination=fileformat,directory=rootdir+'Snout2/spane/',set_file_timeres=fileres
  endif

if  keyword_set(sslsoc) then begin
  directory = rootdir + router+'/'+instr+'/'
  host = '128.32.13.202'  ;
  exec_proc = 'spp_ptp_stream_read'
  swem = 1
  if keyword_set(swem)   then spp_ptp_recorder,title='SSLSOC SWEM PTP',port=2028, host=host, exec_proc=exec_proc,destination=fileformat,directory=rootdir+'sslsoc/swem/',set_file_timeres=fileres
endif




  if keyword_set(exec0) then begin
    exec, exec_text = ['tplot,verbose=0,trange=systime(1)+[-1,.05]*3600*.1','timebar, systime(1)'],title=title
;    exec, exec_text = ['tplot,verbose=0,trange=spp_rt()+[-1.,.05]*3600','timebar,systime(1)'],title=title
  endif
  tplot_options,title='Real time'
  
;  spp_swp_startup,/rt_flag
  spp_swp_apdat_init,/rt_flag
  spp_apdat_info,/rt_Flag,/save_flag,/all
  
  ;spp_swp_set_tplot_options
  
  ;;--------------------------------------------------
  ;; Useful command to see what APIDs have been loaded
  ;spp_apid_info,/print
  ;print_struct,ap
  ;;-------------------------------------------------

;  base = recorder_base

end



pro spp_init_realtime,filename=filename,base=base,hub=hub,itf=itf,RM133=RM133,rm320=rm320,rm333=rm333,tent=tent, $
    spani= spani, spanea=spanea, spaneb=spaneb,  spc=spc,SWEMGSE=SWEM, $
    router=router, instr=instr, recent=recent, hires1=hires1, sslsoc=sslsoc, $
    exec=exec0,ion=ion,tv=tv,cal=cal,snout2=snout2,snout1=snout1,crypt=crypt,apl=apl,moc=moc,gsfc=gsfc

  
  if keyword_set(ion) then spani=1
  if n_elements(hub) eq 0 then hub = 1
  if keyword_set(rm320) then cal=1
  if keyword_set(tent) then tv=1
  if keyword_set(tv) then snout2=1
  
  
  if keyword_set(elec) then begin
    spanea = 1
    dprint, 'Please use spanea keyword instead'
  endif
  if keyword_set(tvac) then snout2=1

  if keyword_set(spani) then instr = 'spani'
  if keyword_set(spanea) then instr='spanea'
  if keyword_set(spaneb) then instr='spaneb'
  if keyword_set(spc) then instr = 'spc'
  if keyword_set(swem) then instr = 'swem'

  if keyword_set(cal) then   router = 'cal'
  if keyword_set(snout2) then router = 'snout2'
  if keyword_set(snout1) then router = 'snout1'
  if keyword_set(crypt) then router = 'crypt'
  if keyword_set(apl) then router = 'APL'
  if keyword_set(gsfc) then router = 'GSFC'


  
  
  rootdir = root_data_dir() + 'spp/data/sci/sweap/prelaunch/gsedata/realtime/'
;  directory = rootdir + router+'/'+instr+'/'
  fileformat = 'YYYY/MM/DD/spp_socket_YYYYMMDD_hh.dat.gz'
  fileres =3600.d

  ports= dictionary('spani',2028,'spanea',2128,'spaneb',2228,'spc',2328,'swem',2528)
  hosts= dictionary('cal','abiad-sw.ssl.berkeley.edu','snout1','?????','snout2','mgse2.ssl.berkeley.edu')

  if keyword_set(recent) then spp_ptp_file_read, spp_file_retrieve(cal=cal,snout2=snout2,snout1=snout1,recent=recent,spani=spani,spanea=spanea,spaneb=spaneb,swem=swem,router=router)

  
  if keyword_set(itf) then begin
    recorder,title='SWEM ITF', port= hub ? 8082 : 2024, host='abiad-sw.ssl.berkeley.edu', exec_proc='spp_itf_stream_read' 
    return
  endif
;  if keyword_set(swemgse) then begin
;    recorder,title='SWEMGSE', port= hub ? 2428 : 2024, host='abiad-sw.ssl.berkeley.edu', exec_proc='spp_ptp_stream_read' 
;  endif
  if keyword_set(rm133) then begin
    recorder,title='ROOM 133', port= hub ? 2028 : 2024, host='128.32.13.37', exec_proc='spp_ptp_stream_read'
    return
  endif
  if keyword_set(rm333) then begin
    recorder,title='ROOM 333', port= hub ? 2028 : 2023, host='ssa333-lab.ssl.berkeley.edu', exec_proc='spp_msg_stream_read'
    return
  endif
  if  keyword_set(cal) then begin
    directory = rootdir + router+'/'+instr+'/'
    host = 'abiad-sw.ssl.berkeley.edu'
    exec_proc = 'spp_ptp_stream_read'
    if keyword_set(spani) then spp_ptp_recorder,title='CAL SPANI PTP',  port=2028, host=host, exec_proc=exec_proc,destination=fileformat,directory=rootdir+'cal/spani/',set_file_timeres=fileres
    if keyword_set(spanea) then spp_ptp_recorder,title='CAL SPANEA PTP',port=2128, host=host, exec_proc=exec_proc,destination=fileformat,directory=rootdir+'cal/spanea/',set_file_timeres=fileres
    if keyword_set(spaneb) then spp_ptp_recorder,title='CAL SPANEB PTP',port=2228, host=host, exec_proc=exec_proc,destination=fileformat,directory=rootdir+'cal/spaneb/',set_file_timeres=fileres
    if keyword_set(spc)    then spp_ptp_recorder,title='CAL SPC PTP',port=2328, host=host, exec_proc=exec_proc,destination=fileformat,directory=rootdir+'cal/spc/',set_file_timeres=fileres
    if keyword_set(swem)   then spp_ptp_recorder,title='CAL SWEM PTP',port=2528, host=host, exec_proc=exec_proc,destination=fileformat,directory=rootdir+'cal/swem/',set_file_timeres=fileres
  endif
  if  keyword_set(snout1) then begin
    directory = rootdir + router+'/'+instr+'/'
    host = 'router5.ssl.berkeley.edu'
    exec_proc = 'spp_ptp_stream_read'
    if keyword_set(spani) then spp_ptp_recorder,title='Snout1 SPANI PTP',  port=2028, host=host, exec_proc=exec_proc,destination=fileformat,directory=rootdir+'snout1/spani/',set_file_timeres=fileres
    if keyword_set(spanea) then spp_ptp_recorder,title='Snout1 SPANEA PTP',port=2128, host=host, exec_proc=exec_proc,destination=fileformat,directory=rootdir+'snout1/spanea/',set_file_timeres=fileres
    if keyword_set(spaneb) then spp_ptp_recorder,title='Snout1 SPANEB PTP',port=2228, host=host, exec_proc=exec_proc,destination=fileformat,directory=rootdir+'snout1/spaneb/',set_file_timeres=fileres
    if keyword_set(spc)    then spp_ptp_recorder,title='Snout1 SPC PTP',port=2328, host=host, exec_proc=exec_proc,destination=fileformat,directory=rootdir+'snout1/spc/',set_file_timeres=fileres
    if keyword_set(swem)   then spp_ptp_recorder,title='Snout1 SWEM PTP',port=2528, host=host, exec_proc=exec_proc,destination=fileformat,directory=rootdir+'snout1/swem/',set_file_timeres=fileres
  endif
  if  keyword_set(snout2) then begin
    directory = rootdir + router+'/'+instr+'/'
    host = 'mgse2.ssl.berkeley.edu'
    exec_proc = 'spp_ptp_stream_read'
    if keyword_set(spani) then spp_ptp_recorder,title='Snout2 SPANI PTP',  port=2028, host=host, exec_proc=exec_proc,destination=fileformat,directory=rootdir+'snout2/spani/',set_file_timeres=fileres
    if keyword_set(spanea) then spp_ptp_recorder,title='Snout2 SPANEA PTP',port=2128, host=host, exec_proc=exec_proc,destination=fileformat,directory=rootdir+'Snout2/spanea/',set_file_timeres=fileres
    if keyword_set(spaneb) then spp_ptp_recorder,title='Snout2 SPANEB PTP',port=2228, host=host, exec_proc=exec_proc,destination=fileformat,directory=rootdir+'Snout2/spaneb/',set_file_timeres=fileres
    if keyword_set(spc)    then spp_ptp_recorder,title='Snout2 SPC PTP',port=2328, host=host, exec_proc=exec_proc,destination=fileformat,directory=rootdir+'Snout2/spc/',set_file_timeres=fileres
    if keyword_set(swem)   then spp_ptp_recorder,title='Snout2 SWEM PTP',port=2528, host=host, exec_proc=exec_proc,destination=fileformat,directory=rootdir+'Snout2/swem/',set_file_timeres=fileres
  endif

if keyword_set(hires1) then begin
  exec_proc = 'spp_ptp_stream_read'
  spp_ptp_recorder,title='HIRES1 (MOC) PTP',port=2028, host='128.32.13.202', exec_proc=exec_proc,destination=fileformat,directory=rootdir+'hires1/swem/',set_file_timeres=fileres

endif

if  keyword_set(sslsoc) then begin
  directory = rootdir + router+'/'+instr+'/'
  host = '128.32.13.202'  ;
  exec_proc = 'spp_ptp_stream_read'
  swem = 1
  ;    if keyword_set(spani) then spp_ptp_recorder,title='Crypt SPANI PTP',  port=2028, host=host, exec_proc=exec_proc,destination=fileformat,directory=rootdir+'crypt/spani/',set_file_timeres=fileres
  ;    if keyword_set(spanea) then spp_ptp_recorder,title='Crypt SPANEA PTP',port=2128, host=host, exec_proc=exec_proc,destination=fileformat,directory=rootdir+'crypt/spanea/',set_file_timeres=fileres
  ;    if keyword_set(spaneb) then spp_ptp_recorder,title='Crypt SPANEB PTP',port=2228, host=host, exec_proc=exec_proc,destination=fileformat,directory=rootdir+'crypt/spaneb/',set_file_timeres=fileres
  ;    if keyword_set(spc)    then spp_ptp_recorder,title='Crypt SPC PTP',port=2328, host=host, exec_proc=exec_proc,destination=fileformat,directory=rootdir+'crypt/spc/',set_file_timeres=fileres
  if keyword_set(swem)   then spp_ptp_recorder,title='SSLSOC SWEM PTP',port=2028, host=host, exec_proc=exec_proc,destination=fileformat,directory=rootdir+'sslsoc/swem/',set_file_timeres=fileres
endif



  if  keyword_set(crypt) then begin
    directory = rootdir + router+'/'+instr+'/'
    host = 'crypt.ssl.berkeley.edu'
    exec_proc = 'spp_ptp_stream_read'
    if keyword_set(spani) then spp_ptp_recorder,title='Crypt SPANI PTP',  port=2028, host=host, exec_proc=exec_proc,destination=fileformat,directory=rootdir+'crypt/spani/',set_file_timeres=fileres
    if keyword_set(spanea) then spp_ptp_recorder,title='Crypt SPANEA PTP',port=2128, host=host, exec_proc=exec_proc,destination=fileformat,directory=rootdir+'crypt/spanea/',set_file_timeres=fileres
    if keyword_set(spaneb) then spp_ptp_recorder,title='Crypt SPANEB PTP',port=2228, host=host, exec_proc=exec_proc,destination=fileformat,directory=rootdir+'crypt/spaneb/',set_file_timeres=fileres
    if keyword_set(spc)    then spp_ptp_recorder,title='Crypt SPC PTP',port=2328, host=host, exec_proc=exec_proc,destination=fileformat,directory=rootdir+'crypt/spc/',set_file_timeres=fileres
    if keyword_set(swem)   then spp_ptp_recorder,title='Crypt SWEM PTP',port=2528, host=host, exec_proc=exec_proc,destination=fileformat,directory=rootdir+'crypt/swem/',set_file_timeres=fileres
  endif

  if  keyword_set(apl) then begin
    directory = rootdir + router+'/'+instr+'/'
    host = '128.244.182.105'
    exec_proc = 'spp_ptp_stream_read'
    if keyword_set(spani) then spp_ptp_recorder,title='Crypt SPANI PTP',  port=2028, host=host, exec_proc=exec_proc,destination=fileformat,directory=rootdir+'crypt/spani/',set_file_timeres=fileres
;    if keyword_set(spanea) then spp_ptp_recorder,title='Crypt SPANEA PTP',port=2128, host=host, exec_proc=exec_proc,destination=fileformat,directory=rootdir+'crypt/spanea/',set_file_timeres=fileres
;    if keyword_set(spaneb) then spp_ptp_recorder,title='Crypt SPANEB PTP',port=2228, host=host, exec_proc=exec_proc,destination=fileformat,directory=rootdir+'crypt/spaneb/',set_file_timeres=fileres
;    if keyword_set(spc)    then spp_ptp_recorder,title='Crypt SPC PTP',port=2328, host=host, exec_proc=exec_proc,destination=fileformat,directory=rootdir+'crypt/spc/',set_file_timeres=fileres
    if keyword_set(swem)   then spp_ptp_recorder,title='APL SWEM PTP',port=2128, host=host, exec_proc=exec_proc,destination=fileformat,directory=rootdir+'crypt/swem/',set_file_timeres=fileres
  endif

  if  keyword_set(gsfc) then begin
    directory = rootdir + router+'/'+instr+'/'
    host = '128.244.182.105'
    host = '192.168.1.106'
    exec_proc = 'spp_ptp_stream_read'
    ;    if keyword_set(spani) then spp_ptp_recorder,title='Crypt SPANI PTP',  port=2028, host=host, exec_proc=exec_proc,destination=fileformat,directory=rootdir+'crypt/spani/',set_file_timeres=fileres
    ;    if keyword_set(spanea) then spp_ptp_recorder,title='Crypt SPANEA PTP',port=2128, host=host, exec_proc=exec_proc,destination=fileformat,directory=rootdir+'crypt/spanea/',set_file_timeres=fileres
    ;    if keyword_set(spaneb) then spp_ptp_recorder,title='Crypt SPANEB PTP',port=2228, host=host, exec_proc=exec_proc,destination=fileformat,directory=rootdir+'crypt/spaneb/',set_file_timeres=fileres
    ;    if keyword_set(spc)    then spp_ptp_recorder,title='Crypt SPC PTP',port=2328, host=host, exec_proc=exec_proc,destination=fileformat,directory=rootdir+'crypt/spc/',set_file_timeres=fileres
    spp_ptp_recorder,title='GSFC SWEM PTP',port=2028, host=host, exec_proc=exec_proc,destination=fileformat,directory=rootdir+'gsfc/swem/',set_file_timeres=fileres
  endif


  if keyword_set(exec0) then begin
;    exec, exec_text = 'tplot,verbose=0,trange=systime(1)+[-1,.05]*3600*.1',title=title
    exec, exec_text = ['tplot,verbose=0,trange=spp_rt()+[-1.,.05]*3600','timebar,systime(1)'],title=title
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

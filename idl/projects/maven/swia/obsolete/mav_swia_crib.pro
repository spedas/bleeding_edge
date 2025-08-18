

;pro mav_swia_crib

if  ~keyword_set(recbase) then begin
    mav_apid_swia_handler,/reset
    recorder,recbase,port=2025,exec_proc='gseos_cmnblk_bhandler',destination='data/CMNBLK_YYYYMMDD_hhmmss.dat'
    exec,tplotbase,  exec_text=["tplot,verbose=0,wshow=0,trange=systime(1)+[-.9,.1] * 60 * 1",'timebar,systime(1)']
    dprint,recbase,tplotbase,/phelp
endif



pathname = 'maven/dpu/prelaunch/FM/20121118_045846_FM_DayInLife5/commonBlock_20121118_045846_FM_DayInLife5.dat'



;file=0
;  file = dialog_pickfile(/multiple)

if keyword_set(pathname) or keyword_set(file) then begin
  starttime = systime(1)
  recorder,recbase,get_procbutton=proc_on,set_procbutton=0,get_filename=rtfile   ; Turn realtime off if it is on
  store_data,'*',/clear         ; clear all stored data
  mav_apid_swia_handler,/reset   ; enable decomutation of SWIA data
  mav_gse_cmnblk_file_read,realtime=realtime,pathname=pathname ;,file=file   ;,last_version=1      ; read commonblock data file
  recorder,recbase,set_procbutton=proc_on                                       ; Turn realtime back on (if it had been on)
  dprint,'Done in ',systime(1)-starttime,' seconds'
endif

end


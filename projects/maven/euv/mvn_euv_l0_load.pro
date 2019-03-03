;+
; NAME:
;       mvn_euv_l0_load
; PURPOSE:
;       Load procedure for EUV L0 data. Use for looking at raw EUV data.
;       Use mvn_euv_load instead to load EUV L2 data (calibrated),
;       but EUV L2 files are currently about a month behind.
; KEYWORDS:
;   trange: specifies the time range
;   tplot: plots a time-series of the loaded data
;   save: saves tplot files of L0 data for the selected day (only works for 1 day at a time)
;   l0: loads data from L0 files instead of tplot files (slow)
;   generate: automatically generates daily tplot files for new L0 files
;   init: initial date from which to start generating L0 tplot files up to now
; HISTORY:
; VERSION:
;  $LastChangedBy: ali $
;  $LastChangedDate: 2019-03-01 19:04:44 -0800 (Fri, 01 Mar 2019) $
;  $LastChangedRevision: 26742 $
;  $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/euv/mvn_euv_l0_load.pro $
;CREATED BY:  ali 20160830
;FILE: mvn_euv_l0_load.pro
;-

pro mvn_euv_l0_load,trange=trange,tplot=tplot,verbose=verbose,save=save,l0=l0,generate=generate,init=init

  tplotpath='maven/data/sci/euv/l0/tplot/YYYY/MM/mvn_euv_l0_YYYYMMDD.tplot'

  if keyword_set(generate) then begin
    if keyword_set(init) then tstart=time_double(init) else tstart=time_double('2014-11-27')
    trange0=[tstart,systime(1)]
    res=86400L
    daynum=round(trange0/res)
    nd=daynum[1]-daynum[0]
    trange=res*double(daynum); round to days

    for i=0L,nd-1 do begin
      tr=trange[0]+[i,i+1]*res
      L0_file=mvn_pfp_file_retrieve(/l0,trange=tr,/daily_names,/valid_only,verbose=verbose) ;should be scalar
      tp_file=mvn_pfp_file_retrieve(tplotpath,trange=tr[0],/daily_names,/create_dir,verbose=verbose)

      if l0_file eq '' then continue
      L0_info=file_info(L0_file)
      tp_info=file_info(tp_file)
      L0_timestamp=max([L0_info.mtime,L0_info.ctime])
      tp_timestamp=tp_info.mtime

      if L0_timestamp gt tp_timestamp then begin ;skip if tplot file does not need to be regenerated
        dprint,'Generating EUV tplot file: '+tp_file
        mvn_euv_l0_load,trange=tr,/l0,/save
      endif
    endfor
    dprint,'EUV tplot file generation complete!
    return
  endif

  if keyword_set(save) then sav=1 else sav=0
  if keyword_set(l0) then l0s=1 else l0s=0
  if (l0s and sav) then l0sav=1 else l0sav=0
  if ~l0s or l0sav then tp_files=mvn_pfp_file_retrieve(tplotpath,trange=trange,/daily_names,create_dir=l0sav,valid_only=~l0s,verbose=verbose)
  if l0s then l0_files=mvn_pfp_file_retrieve(/l0,trange=trange,/daily_names,/valid_only,verbose=verbose) ;daily l0 files
  if l0s then files=l0_files else files=tp_files

  if files[0] eq '' then begin
    dprint,dlevel=2,'No '+(['EUV tplot','L0'])[l0s]+' files were found for the selected time range.'
    return
  endif

  nfiles=n_elements(files)
  if l0sav and (nfiles ne 1 or n_elements(tp_files) ne 1) then begin
    dprint,dlevel=2,'EUV tplot save functionality currently only works for 1 day at a time! returning...'
    return
  endif

  for i=0l,nfiles-1 do begin
    store_data,'mvn_lpw_euv',/delete,verbose=0
    if l0s then begin
      mvn_lpw_load_file,files[i],tplot_var='SCI',filetype=filetype,packet='EUV',board=board,use_compression=use_compression,/nospice ;l0 loader
    endif else tplot_restore,filename=files[i],verbose=0
    get_data,'mvn_lpw_euv',data=mvn_lpw_euv_1day,limits=limits,dlimits=dlimits ;get tplot variables
    if keyword_set(mvn_lpw_euv_1day) then begin
      if l0sav then tplot_save,'mvn_lpw_euv',filename=tp_files,/no_add_ext ;only works for 1 day
      append_array,mvn_lpw_euv_x,mvn_lpw_euv_1day.x ;append days
      append_array,mvn_lpw_euv_y,mvn_lpw_euv_1day.y
      lim2=limits
      dlim2=dlimits
    endif else dprint,'No EUV data in file: '+files[i]
  endfor
  store_data,'mvn_lpw_euv',/delete,verbose=0

  if keyword_set(mvn_lpw_euv_y) then begin
    mvn_lpw_euv_y+=4.6e5 ;adding the offset (4.5e5) plus 1e4 (for better scaling) back to the signals
    lim2.xtitle=''
    dlim2.ysubtitle+='+4.6e5'
    store_data,'mvn_euv_l0',mvn_lpw_euv_x,mvn_lpw_euv_y,limits=lim2,dlimits=dlim2
    ylim,'mvn_euv_l0',1e4,1.4e6,1
    options,'mvn_euv_l0',labflag=-1,colors='gbrk',datagap=2.
    if keyword_set(tplot) then tplot,'mvn_euv_l0'
  endif

end
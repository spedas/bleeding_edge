;+
;NAME:
; istp_fa_k0_load
;PURPOSE:
; Loads FAST K0 data from SPDF, 
;CALLING SEQUENCE:
; istp_fa_k0_load,types,trange=trange, $
;                 orbitrange=orbitrange, $
;                 downloadonly=downloadonly,$
;                 no_download=no_download,$
;                 no_update=no_uptate
;INPUT:
; types = one of: 'acf', 'dcf', 'tms', the default is 'acf'
; trange = a time range, the default is to use that from the most
;          recent timespan call
; orbitrange = load these orbits
;        NOTE THAT 'ees', 'ies', 'orb', 'tms', 'acf' data are
;        available from ssl.berkeley.edu, for FAST K0 data available
;        SSL, use FA_K0_LOAD.pro. Note also that the
;        ssl.berkeley.edu versions of K0 data are more recent than
;        those at SPDF.
;OUTPUT:
; tplot variables are loaded
; 
pro istp_fa_k0_load,types,trange=trange, $
                    orbitrange=orbitrange,latestversion=latestversion,$
                    downloadonly=downloadonly,no_download=no_download,no_update=no_uptate
  istp_init
  source = !istp
  if(keyword_set(no_download)) then source.no_download=1
  if(keyword_set(no_update)) then source.no_update=1

  if not keyword_set(types) then types = 'acf'
  if keyword_set(orbitrange) AND NOT keyword_set(trange) then begin
     orbitsarray=fa_orbit_to_time(orbitrange)
     maxtime=max(orbitsarray[2,*])
     mintime=min(orbitsarray[1,*])
     trange=[mintime,maxtime]
  endif

  for i=0,n_elements(types)-1 do begin
     
     type4dir = types[i]
     If(types[i] Eq 'tms') Then type4dir = 'teams'
     relpath = ''
     prefix = 'fa_k0_'+types[i]+'_'
     ending = '_v??.cdf'
     relpathnames = file_dailynames(relpath,prefix,ending,/YEARDIR,trange=trange)

     remote_path = source.remote_data_dir+'fast/'+type4dir+'/k0/'
     local_path = source.local_data_dir+'fast/'+types[i]+'/k0/'
        
     filenames = spd_download(remote_file=relpathnames, remote_path=remote_path, $
                              local_path = local_path, no_download = source.no_download, $
                              no_update = source.no_update, /latest_version, $
                              file_mode = '666'o, dir_mode = '777'o)
  endfor
  if keyword_set(downloadonly) then return
; load data into tplot variables

  spd_cdf2tplot,file=filenames,all=all,verbose=verbose ,prefix = 'istp_fa_'
  
end

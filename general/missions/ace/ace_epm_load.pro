;+
;NAME:
; ace_epm_load 
; 
;PURPOSE:
; Downloads ACE data from SPDF
; 
;Typical Usage:
;  ace_epm_load, trange=trange 
;  
; $LastChangedBy:$
; $LastChangedDate:$
; $LastChangedRevision:$
; $URL:$
;-

pro ace_epm_load,pathnames=pathnames,trange=trange,files=files,download_only=download_only, $
        source=source,verbose=verbose,k0=k0,h1=h1,no_download=no_download, no_update=no_update

istp_init
if not keyword_set(source) then source = !istp
      
tstart=systime(1)
dprint,'Loading ACE EPAM files at ',time_string(/local,tstart)

; Define trailing end of URL

;if keyword_set(k0) then begin
  pathname = 'ace/epam/level_2_cdaweb/epm_k0/YYYY/ac_k0_epm_YYYYMMDD_v??.cdf'  
  prefix = 'ACE_EPM_K0_'
;endif
if keyword_set(h1) then begin
  pathname = 'ace/epam/level_2_cdaweb/epm_h1/YYYY/ac_h1_epm_YYYYMMDD_v??.cdf
  prefix = 'ACE_EPM_H1_'
endif

tr = timerange(trange)

if keyword_set(no_download) && no_download ne 0 then source.no_download = 1
if keyword_set(no_update) && no_update ne 0 then source.no_update = 1

relpathnames = file_dailynames(file_format=pathname,trange=tr)
files = spd_download(remote_file=relpathnames, remote_path=source.remote_data_dir, local_path = source.local_data_dir, $
  no_download = source.no_download, no_update = source.no_update, /last_version, $
  file_mode = '666'o, dir_mode = '777'o)


dprint,/phelp,files

if keyword_set(download_only) then return


if 1 then begin
  cdf2tplot,files,prefix=prefix
  options ,prefix+'*',/ylog
  store_data,'ACE_EPM_Ion',data='ACE_EPM_??_Ion*'
  store_data,'ACE_EPM_Electron',data='ACE_EPM_*Electron*'
  ylim,'ACE_EPM_Ion',.01,1e6,1,/def
  ylim,'ACE_EPM_Electron',1,1e6,1,/def
  tn= tnames(prefix+'*')
  for i=0,n_elements(tn)-1 do begin
    get_data,tn[i],dlimit=dlim
    options,tn[i],ytitle=dlim.cdf.vatt.lablaxis,/def
    dprint,dlevel=2,tn[i],"  ",dlim.cdf.vatt.lablaxis
  endfor
endif else begin
  cdfi = cdf_load_vars(files)
  ind = where(cdfi.vars.name eq 'Ion_very_lo')
  ; not finished

endelse
  
dprint,'Done with ace_epm load'
end





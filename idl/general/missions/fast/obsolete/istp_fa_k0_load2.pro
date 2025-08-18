;+
;NAME:
; ISTP_FA_K0_LOAD
;PURPOSE:
; Loads FAST k0 data from SPDF
;CALLING SEQUENCE:
; istp_fa_k0_load,types,trange=trange,verbose=verbose
;INPUT:
; types = data types, default is ['ees', 'ies'], can load 'acf',
;         'dcf', 'tms'
;OUTPUT:
; tplot variables with prefix 'istp_fa_'
;
; $LastChangedBy: $
; $LastChangedDate: $
; $LastChangedRevision: $
; $URL: $
;-
pro istp_fa_k0_load2, types, trange=trange, verbose=verbose, $
                      no_download = no_download, no_update = no_update, $
                      downloadonly = downloadonly

istp_init
source = !istp
if(keyword_set(no_download)) then source.no_download = no_download
if(keyword_set(no_update)) then source.no_update = no_update

if not keyword_set(types) then types = ['ees','ies']

for i=0,n_elements(types)-1 do begin
     type = strlowcase(strcompress(types[i], /remove_all))
;new URL's in 2017
;ies and ees are under pub/data/fast/esa, 
;others are pub/data/fast, 2017-02-28
     if type eq 'ees' or type eq 'ies' then begin
        remote_path = source.remote_data_dir+'fast/esa/k0/'+type1+'/'
     endif else begin
     if type eq 'tms' then type1 = 'teams' else type1 = type
        remote_path = source.remote_data_dir+'fast/'+type1+'/k0/'
     endelse

     local_path = source.local_data_dir+'fast/'+type+'/'

     version = 'v0?'
     file_format = 'YYYY/fa_k0_'+type+'_YYYYMMDD_'+version+'.cdf'
     relpathnames = file_dailynames(file_format=file_format,trange=trange)

     filenames = spd_download(remote_file=relpathnames, remote_path=remote_path, $
                              local_path = local_path, no_download = source.no_download, $
                              no_update = source.no_update, $
                              file_mode = '666'o, dir_mode = '777'o)

     if keyword_set(downloadonly) then continue

     cdf2tplot, file=[files], all=all, verbose=verbose , $
                prefix = 'istp_fa_' ; load data into tplot variables
endfor

end

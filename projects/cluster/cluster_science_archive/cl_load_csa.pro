;+
; PROCEDURE:
;         cl_load_csa_postprocess
;
; PURPOSE:
;         Unpacks .tar.gz or .tgz files downloaded from CSA web services, loads CDF data into tplot variables, and optionally deletes
;         temporary files when finished
;
; KEYWORDS:
;         netobj:       IDLNetURL object used to download data
;         
;         filedir:      Directory where files should be unpacked
;         
;         filename:     File name of downloaded data
;         
;         get_support_data: If set, loads support data from downloaded CDFs
;         
;         verbose:       Higher values result in more progress/diagnostic output
;         
;         nocleanup:     If specified, do not delete downloaded and unpacked files from the temp directory
;         
;         
;         
; OUTPUT
;
;
; EXAMPLE:
;
;
; NOTES:
;
;
;$LastChangedBy: jwl $
;$LastChangedDate: 2021-10-08 16:03:55 -0700 (Fri, 08 Oct 2021) $
;$LastChangedRevision: 30344 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/cluster/cluster_science_archive/cl_load_csa.pro $
;-


pro cl_load_csa_postprocess,netobj=netobj,filedir=filedir,filename=filename,get_support_data=get_support_data,verbose=verbose, $
  nocleanup=nocleanup

; get content_disposition header
netobj->getproperty,response_header=rh
res=stregex(rh,'Content-Disposition.*filename="(.*)"',length=len,/SUBEXPR,/fold_case)
if res[0] eq -1 then begin
   dprint,dlevel=1,verbose=verbose,'Unable to get Content-Disposition filename'
   dprint,dlevel=1,verbose=verbose,'Response headers:',rh
   newname='csa_download.tar.gz'
endif else begin
  newname=strmid(rh,res[1],len[1])
endelse
dprint,dlevel=3,verbose=verbose,'Newname: '+newname
; Remove suffixes to get filename root
base1=file_basename(newname,'.tgz',/fold_case)
base2=file_basename(base1,'.tar.gz',/fold_case)
tarname=filedir+path_sep()+base2+'.tar'
dataname=filedir+path_sep()+base2
; rename file
new_full_path=filedir+path_sep()+newname
file_move,filename,new_full_path
; unzip
file_gunzip,new_full_path,tarname

dprint,dlevel=3,verbose=verbose,'Unzipped file: ' + tarname
; untar
; Untar needs a little help creating the directory structure, so we list the files first, then mkdir all the dirnames
file_untar,tarname,/list,files=files
dirs=file_dirname(files)

; There may be more than one top level directory which should get cleaned up later. Make a list (avoiding duplicates).
toplevel_dirs=[file_dirname(dirs[0])]
if n_elements(dirs) gt 1 then begin
  for i=1,n_elements(dirs)-1 do begin
    next_tld=file_dirname(dirs[i])
    idx=where(next_tld eq toplevel_dirs,tld_count)
    if tld_count eq 0 then begin
      toplevel_dirs=[toplevel_dirs,next_tld]
    endif
  endfor
endif
fully_qualified_dirs=filedir+path_sep()+dirs
dprint,dlevel=3,verbose=verbose,'Preparing directories for file_untar: '
dprint,dlevel=3,verbose=verbose,fully_qualified_dirs
file_mkdir,fully_qualified_dirs
; Now we can extract the files
file_untar,tarname,files=untarred_files,/verbose
dprint,dlevel=3,verbose=verbose,'Untarred files:'
dprint,dlevel=3,verbose=verbose,untarred_files
; find cdfs
; spd_cdf2tplot

for i=0,n_elements(untarred_files)-1 do begin
   dprint,dlevel=3,verbose=verbose,'Loading '+untarred_files[i]
   tplot_varnames = 0
   ; Parse filename
   bname=file_basename(untarred_files[i])
   res=stregex(bname,'(C.)_(.*)__(....).*\.cdf',len=len,/fold_case,/subexpr)
   if res[0] eq -1 then begin
    dprint,dlevel=1,verbose=verbose,'Unable to parse filename: '+untarred_files[i]
   endif else begin
    probe=strmid(bname,res[1],len[1])
    datatype=strmid(bname,res[2],len[2])
    year=strmid(bname,res[3],len[3])
    file_destdir=!cluster_csa.local_data_dir + path_sep() + probe + path_sep() + datatype + path_sep() + year + path_sep()
    file_dest=file_destdir+path_sep()+bname    
    dprint,dlevel=3,verbose=verbose,'Creating File destination dir: '+file_destdir
    file_mkdir,file_destdir
    dprint,dlevel=3,verbose=verbose,'Moving CDF to destination: '+file_dest
    file_copy,untarred_files[i],file_dest,/overwrite
    untarred_files[i]=file_dest
   endelse
   spd_cdf2tplot,file=untarred_files[i],tplotnames=tplot_varnames,verbose=verbose,get_support_data=get_support_data,/all,/load_labels
   dprint,dlevel=3,verbose=verbose,"tplot variables loaded:"
   dprint,dlevel=3,verbose=verbose,tplot_varnames
endfor
if n_elements(nocleanup) eq 0 || nocleanup eq 0 then begin
  ; remove gz file
  file_delete,new_full_path,/verbose
  ; remove tar file
  file_delete,tarname, /verbose
  ;Remove (possibly more than one) top level directories
  for i=0, n_elements(toplevel_dirs)-1 do begin
    if stregex(toplevel_dirs[i],'CSA_Download_.*',/fold_case) ne -1 then begin
      fq_toplevel_dir=filedir+path_sep()+toplevel_dirs[i]
      file_delete,fq_toplevel_dir,/recursive,/verbose,/allow_nonexistent
    endif else begin
      dprint,dlevel=1,verbose=verbose,'Untarred directory name not recognized, skipping deletion: ' + toplevel_dirs[i]
    endelse   
  endfor
endif else begin
  dprint,dlevel=1,verbose=verbose,'Nocleanup keyword specified, skipping cleanup of temp files.'
endelse
end

;+
; PROCEDURE:
;         cl_load_csa
;
; PURPOSE:
;         Load Cluster data via one of the Cluster Science Archive web services
;
; KEYWORDS:
;         trange:       time range of interest [starttime, endtime] containing either Unix timestamps,
;                       or strings with the format YYYY-MM-DDThh:mm:ssZ
;
;         probes:       list of probes, valid values for Cluster probes are C1, C2, C3, C4 (wildcards accepted)
;
;         datatypes:    list of datatypes to download.  Names are case sensitive!  Wildcards accepted.  See
;                       definition of master_datatypes below for valid names
;                       
;         valid_names:   If specified, returns the list of valid probes and datatypes through their respective keyword arguments
;         
;         get_support_data: If specified, load support data variables from downloaded CDFs.
;         
;         verbose:          Higher values print more diagnostic/progress information
;         
;         use_tap:          If specified, use the newer TAP interface rather than the default CAIO interface
;         
;         nocleanup:        If specified, do not remove downloaded files from the temp directory when finished
;         
; OUTPUT:
;
;
; EXAMPLE:
;
;
; NOTES:
;
;
;$LastChangedBy: jwl $
;$LastChangedDate: 2021-10-08 16:03:55 -0700 (Fri, 08 Oct 2021) $
;$LastChangedRevision: 30344 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/cluster/cluster_science_archive/cl_load_csa.pro $
;-

pro cl_load_csa,trange=trange,probes=probes,datatypes=datatypes,valid_names=valid_names,get_support_data=get_support_data, $
  verbose=verbose,nocleanup=nocleanup
  
defsysv,'!spedas',exists=exists
if not(keyword_set(exists)) then begin
  spedas_init
endif

cl_csa_init


; Start/end dates
;start_date='2001-02-01T00%3D00%3D00Z'
;end_date='2001-02-04T00%3D00%3D00Z'

start_date='2001-02-01T00:00:00Z'
end_date='2001-02-04T00:00:00Z'
; Probes

master_probes=['C1','C2','C3','C4']

;Datatypes
master_datatypes=['CE_WBD_WAVEFORM_CDF','CP_AUX_POSGSE_1M','CP_CIS-CODIF_HS_H1_MOMENTS','CP_CIS-CODIF_HS_He1_MOMENTS',$
  'CP_CIS-CODIF_HS_O1_MOMENTS','CP_CIS-CODIF_PAD_HS_H1_PF','CP_CIS-CODIF_PAD_HS_He1_PF','CP_CIS-CODIF_PAD_HS_O1_PF','CP_CIS-HIA_ONBOARD_MOMENTS',$
  'CP_CIS-HIA_PAD_HS_MAG_IONS_PF','CP_EDI_AEDC','CP_EDI_MP','CP_EDI_SPIN','CP_EFW_L2_E3D_INERT','CP_EFW_L2_P','CP_EFW_L2_V3D_INERT',$
  'CP_EFW_L3_E3D_INERT','CP_EFW_L3_P','CP_EFW_L3_V3D_INERT','CP_FGM_5VPS','CP_FGM_FULL','CP_FGM_SPIN','CP_PEA_MOMENTS',$
  'CP_PEA_PITCH_SPIN_DEFlux','CP_PEA_PITCH_SPIN_DPFlux','CP_PEA_PITCH_SPIN_PSD','CP_RAP_ESPCT6','CP_RAP_ESPCT6_R','CP_RAP_HSPCT',$
  'CP_RAP_HSPCT_R','CP_RAP_ISPCT_CNO','CP_RAP_ISPCT_He','CP_STA_CS_HBR','CP_STA_CS_NBR','CP_STA_CWF_GSE','CP_STA_CWF_HBR_ISR2',$
  'CP_STA_CWF_NBR_ISR2','CP_STA_PSD','CP_WBD_WAVEFORM','CP_WHI_ELECTRON_DENSITY','CP_WHI_NATURAL','JP_PMP','JP_PSE']
  
  ; Process arguments
  
  if keyword_set(valid_names) then begin
     probes=master_probes
     datatypes=master_datatypes
     return
  endif
  
  if n_elements(trange) eq 0 then begin
    trange=timerange()
  endif
 
 ; Create time range parameter strings, URL-encoding the ':'s, which are special characters in URLs
 ;  
  if size(trange,/type) eq 7 then begin
    ; Time range has been passed as strings, but CSA service doesn't accept default time_string format.
    ; Convert using time_double, then back to time_string ensuring RFC 1918 format.
    start_date=idlneturl.urlencode(time_string(time_double(trange[0]),tformat="YYYY-MM-DDThh:mm:ssZ"))
    end_date=idlneturl.urlencode(time_string(time_double(trange[1]),tformat="YYYY-MM-DDThh:mm:ssZ"))   
  endif else begin
    start_date=idlneturl.urlencode(time_string(trange[0],tformat="YYYY-MM-DDThh:mm:ssZ"))
    end_date=idlneturl.urlencode(time_string(trange[1],tformat="YYYY-MM-DDThh:mm:ssZ"))
  endelse
  
  ; Avoid overwriting input params
  ;uc_datatypes=strupcase(datatypes)
  ;uc_probes=strupcase(probes)
  uc_datatypes=datatypes
  uc_probes=probes
  
  ; Resolve wildcards, ensure multiple args represented as arrays
  my_datatypes=ssl_check_valid_name(uc_datatypes,master_datatypes)
  my_probes=ssl_check_valid_name(uc_probes,master_probes)
  
  ; Return if no valid probes or datatypes are specified
  
  if (strlen(my_datatypes[0]) eq 0) || (strlen(my_probes[0]) eq 0) then return;

; Delivery format

delivery_format='CDF_ISTP'

; Delivery interval

delivery_interval='ALL'

; Include reference files


; Non browser

; Make query string
; Base and query URLs

; newer TAP system; CAIO method no longer supported JWL 2021-10-08
  base_url='https://csa.esac.esa.int/csa-sl-tap/data'
  query_string='retrieval_type=PRODUCT&START_DATE='+start_date+'&END_DATE='+end_date+'&DELIVERY_FORMAT='+delivery_format+'&DELIVERY_INTERVAL='+delivery_interval+'&NON_BROWSER'

for i=0,n_elements(my_probes)-1 do begin
   for j=0,n_elements(my_datatypes)-1 do begin
      query_string=query_string + '&DATASET_ID='+my_probes[i]+'_'+my_datatypes[j]
   endfor
endfor

; Start/stop times contain ':' characters, which should be URL-encoded.  Otherwise parse_url gets confused.
dprint,dlevel=3,verbose=verbose,'query string:'
dprint,dlevel=3,verbose=verbose,query_string
;encoded_query_string=idlneturl.urlencode(query_string)
;print,'URL encoded query string'
;print,encoded_query_string
; older CAIO system
;url=base_url+'?'+query_string
;newer TAP system
url=base_url+'?'+query_string
url_struct=parse_url(base_url)
net_object=obj_new('idlneturl')
headers = array_concat('User-Agent: '+'SPEDAS IDL/'+!version.release+' ('+!version.os+' '+!version.arch+')', headers)  

; Set neturl object properties
;  -any keywords passed through _extra will take precedent
;----------------------------------------

;flag to tell if there was an exception thrown in the idlneturl callback function
callback_error = ptr_new(0b)

; the following check on url_struct.path is due to some servers (e.g., LASP) not supporting double-forward slashes
; e.g., (lasp.colorado.edu//path/to/the/file); IDLnetURL always appends a forward slash between the host and path
if strlen(url_struct.path) gt 0 && strmid(url_struct.path, 0, 1) eq '/' then url_struct.path = strmid(url_struct.path, 1, strlen(url_struct.path))

net_object->setproperty, $

  headers=headers, $

  url_scheme=url_struct.scheme, $
  url_host=url_struct.host, $
  url_path=url_struct.path, $
  url_query=query_string, $
  url_port=url_struct.port, $
  url_username=url_struct.username, $
  url_password=url_struct.password, $
  ssl_verify_peer = ssl_verify_peer, $
  ssl_verify_host = ssl_verify_host, $
  _extra=_extra

;keep core properties from being overwritten by _extra
net_object->setproperty, $
  callback_function='spd_download_callback', $
  callback_data={ $
  net_object: net_object, $
  msg_time: ptr_new(systime(/sec)), $
  msg_data: ptr_new(0ul), $
  progress_object: obj_new(), $
  error: callback_error $
}

; Download
;  -an unsuccessful get will throw an exception and halt execution,
;   the catch should allow these to be handled gracefully
;  -the file will be downloaded to temporary location to avoid
;   clobbering current files and/or leaving empty files
;   in the case of an error
;----------------------------------------

; recreate the url to display without the username and password.
; this prevents IDL from showing the username/password in the
; console output for each downloaded file
if url_struct.username ne '' then begin
  url = url_struct.scheme + '://' + url_struct.host + '/' + url_struct.path
endif


dprint, dlevel=2,verbose=verbose, 'Downloading: '+url

;manually create any new directories so that permissions can be set
;if ~keyword_set(string_array) then begin
;  spd_download_mkdir, file_dirname(filename), dir_mode
;endif

;download file to temporary location
;  -IDLnetURL creates the destination file almost immediately, clobbering any
;   existing file.  If an error occurs (e.g. incorrect URL, server timeout)
;   then an empty file will persist afterward.  Using a temporary filename
;   prevents current valid files from being immediately overwritten and allows
;   empty or incomplete files to be deleted safely in the case of an error.
file_suffix = spd_download_temp()
first_time_download = 1
filename=!spedas.temp_dir+'my_filename'
spd_download_mkdir, file_dirname(filename), dir_mode

catch, error
net_object->getproperty, response_code=response_code, response_header=response_header, url_scheme=url_scheme
if (error ne 0) && (first_time_download eq 1) && (response_code eq 401) then begin
  ; when we have two directories with usename/password,
  ; sometimes we need to try again to get the file

  first_time_download = 0
  dprint, dlevel=2,verbose=verbose, 'Download failed. Trying a second time.'

  ;get the file

  temp_filepath = net_object->get(filename=filename+file_suffix,string_array=string_array)


    ;move file to the requested location
    file_move, temp_filepath, filename, /overwrite

    ;set permissions for downloaded file
    if ~undefined(file_mode) then begin
      file_chmod, filename, file_mode
    endif

    ;output the final location
    output = filename

    dprint, dlevel=2, 'Download complete:  '+filename

endif else if error eq 0 then begin

  ;get the file
  temp_filepath = net_object->get(filename=filename+file_suffix,string_array=string_array)


    ;move file to the requested location
    file_move, temp_filepath, filename, /overwrite

    ;set permissions for downloaded file
    if ~undefined(file_mode) then begin
      file_chmod, filename, file_mode
    endif

    ;output the final location
    output = filename

    dprint, dlevel=2, 'Download complete:  '+filename
    catch,/cancel
    cl_load_csa_postprocess,netobj=net_object,filedir=file_dirname(filename),filename=filename,get_support_data=get_support_data,verbose=verbose,nocleanup=nocleanup
 
endif else begin
  catch, /cancel

  ;remove temporary file
  file_delete, filename+file_suffix, /allow_nonexistent

  ;handle exceptions from idlneturl
  spd_download_handler, net_object=net_object, $
    url=url, $
    filename=filename, $
    callback_error=*callback_error

endelse

; If there was a partial download, delete the file.
;net_object->getproperty, response_code=response_code2, response_header=response_header2, url_scheme=url_scheme2
;if (response_code2 eq 18) && file_test(filename) then begin
;  dprint, dlevel=2, 'Error while downloading, partial download will be deleted:  ' + filename
;  file_delete, filename, /allow_nonexistent
;  output = ''
;endif

; Delete a cdf or netcdf file if it can't be openned.
;if ~keyword_set(disable_cdfcheck) then begin
;  cant_open = spd_cdf_check_delete(filename, /delete_file)
;  if n_elements(cant_open) gt 0 then begin
;    dprint, dlevel=2, 'Error while downloading, corrupted download will be deleted:  ' + filename
;    output = ''
;  endif
;endif

; Delete temp_filepath, if it exists.
;if ~keyword_set(string_array) && (strlen(temp_filepath[0]) gt 12) && file_test(temp_filepath[0]) then begin
;  file_delete, temp_filepath[0], /allow_nonexistent
;end

obj_destroy, net_object


end

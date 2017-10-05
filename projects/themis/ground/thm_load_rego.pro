pro thm_load_asi_file_move_onetime   ; temporary routine: Moves ASI files to correct directories.
; Running this routine (once) will eliminate the need to download previously cached ASI files.

files= file_search(!themis.local_data_dir+'thg/l1/asi/????/20??/rego_l1_as?_????_20*.cdf',count=n)
if n ge 1 then begin
  for i=0,n-1 do begin
     bname = file_basename(files[i])
     site = strmid(bname,11,4)
     year = strmid(bname,16,4)
     mon  = strmid(bname,20,2)
     dir = !themis.local_data_dir+'thg/l1/asi/'+site+'/'+year+'/'+mon+'/'
     file_mkdir,dir
     file_move,files[i],dir+bname,/allow_same
     dprint,dlevel=1,'Moving ',bname,' to ',dir
  endfor
endif
end



;+
;Procedure: THM_LOAD_ASI
;
; KEYWORD PARAMETERS:
;  site  = Observatory name, example, thm_load_gmag, site = 'fykn', the
;          default is 'all', i.e., load all available stations . This
;          can be an array of strings, e.g., ['fykn', 'gako'] or a
;          single string delimited by spaces, e.g., 'fykn gako'
;  datatype = request 'ast' or 'asf', default is 'asf', can also be 'all'.
;  TRANGE= (Optional) Time range of interest  (2 element array), if
;          this is not set, the default is to prompt the user. Note
;          that if the input time range is not a full day, a full
;          day's data is loaded
;  level = the level of the data, the default is 'l2', or level-2
;          data. A string (e.g., 'l2') or an integer can be used. 'all'
;          can be passed in also, to get all levels.
;  /VERBOSE : set to output some useful info
;  /downloadonly, if set, then only download the data, do not load it
;                 into variables.
;  /no_download: use only files which are online locally.
;  relpathnames_all: named variable in which to return all files that are
;          required for specified timespan, probe, datatype, and level.
;          If present, no files will be downloaded, and no data will be loaded.
;  /valid_names, if set, then this will return the valid site, datatype
;                and/or level options in named variables, for example,
;
;                thm_load_gmag, site = xxx, /valid_names
;
;                will return the array of valid sites in the
;                variable xxx
;   /CURSOR	get time range with cursor
;   /TIME       specify just one time (record) for data
;
;Example:
;   thm_load_asi,site='atha',time='2007-03-23/05:00:00'
;
;Notes:
;
; To get an array of valid names make the following call;
;   thm_load_asi,site=vn,/valid_names
; No further action will be taken.
;
;
;Written by: Ken Bromund ????,   Jan 5 2007
; $LastChangedBy: pcruce $
; $LastChangedDate: 2014-03-04 16:43:24 -0800 (Tue, 04 Mar 2014) $
; $LastChangedRevision: 14490 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/ground/thm_load_asi.pro $
;-
;

; find the correct file names, based on datatype, and site
function clg_load_asi_relpath, sname=site, filetype=ft, $
                               time=time, trange=trange, _extra=_extra
; set begin and end of trange
  if keyword_set(time) then trange=[time,time]

  relpath = 'thg/l1/reg/'+ site + '/'
  ending = '_v01.cdf'
  prefix = 'clg_l1_'+ft+'_' + site + '_'

  	; asf are hour files, ast are daily files
  hour_res=(ft eq 'rgf')
  dir_format = 'YYYY/MM/'

  return, file_dailynames(relpath,prefix,ending,dir_format=dir_format,$
                          trange=trange,hour_res=hour_res)
end

; load data for a single time or a time range into tplot variables
; Added tplotnames output keyword, jmm, 26-aug-2009
pro thm_load_asi_cdf_to_tplot, files=files, all=all, verbose=verbose, $
                               get_support_data=get_support_data, $
                               time=time, tplotnames=tplotnames, _extra=_extra, suffix=suffix

	; read only one record out of CDF-file
  if keyword_set(time) then begin
    res=cdf_load_vars(files,varformat='*time',spdf_dependencies=0,/verbose)
    if size(res,/type) ne 8 then return
    ti = (where(strpos(res.vars.name,'time') ne -1))[0]
    timearr = *res.vars[ti].dataptr

	; we allow for 1.5 seconds time offset
    if (size(time,/type) eq 5) then record=where(abs(timearr-time) le 1.5,count) else $  ; double
        record=where(abs(timearr-time_double(time)) le 1,count)	; string
    if (count eq 1) then cdf2tplot,/all,varnames=varnames,file=files,verbose=verbose,record=record[0],$
                                   tplotnames=tplotnames,suffix=suffix

 endif else $
    cdf2tplot,/all,file=files,verbose=verbose,tplotnames=tplotnames,suffix=suffix
end


pro thm_load_rego,site = site, datatype = datatype, trange = trange, $
                 level = level, verbose = verbose, $
                 downloadonly = downloadonly, $
                 no_download=no_download, relpathnames_all=relpathnames_all, $
                 valid_names = valid_names, $
                 cursor=cursor, time=time, $
                 cdf_data=cdf_data, $
                 suffix=suffix,$
                 get_support_data=get_support_data, $
                 progobj=progobj, files=files
;                   _extra = _extra

;thm_load_asi_file_move_onetime    ; delete this line after local caches have had time to be corrected (i.e. after July 30, 2007

  if arg_present(relpathnames_all) then begin
     downloadonly=1
     no_download=1
  end

  if keyword_set(cursor) then begin
; get time with cursor
     ctime,t,vname=var
     trange = minmax(t)
; Use the cursor to determine what asi's to load.
     site = strmid(var,3,4,/reverse)
     if (verbose gt 10) then stop,time_string(trange),site
  endif

  thm_load_xxx,sname=site, datatype=datatype, trange=trange, $
               time=time, cursor=cursor, $
               level=level, verbose=verbose, downloadonly=downloadonly, $
               no_download=no_download, relpathnames_all=relpathnames_all, $
               cdf_data=cdf_data,get_cdf_data=arg_present(cdf_data), $
               get_support_data=get_support_data, $
               varnames=varnames, valid_names = valid_names, files=files, $
               vsnames = 'atha chbg ekat fsmi fsim fykn gako gbay gill '+ $
               'inuv kapu kian kuuj mcgr pgeo pina rank snkq tpas whit yknf '+ $
               'nrsq snap talo', $
               type_sname = 'site', $
               vdatatypes = 'asf ast rgf', $
               vlevels = 'l1', $
               deflevel = 'l1', $
               version = 'v01', $
               suffix=suffix,$
               relpath_funct = 'clg_load_asi_relpath', $
               cdf_to_tplot = 'thm_load_asi_cdf_to_tplot', $
               progobj = progobj, $
               msg_out = msg_out, $
               /no_time_clip,$
               _extra = _extra

  ;print accumulated error messages now that loading is complete
  if keyword_set(msg_out) then begin
    for i=0, n_elements(msg_out)-1 do begin
      if msg_out[i] ne '' then dprint, dlevel=1, msg_out[i]
    endfor
  endif

end


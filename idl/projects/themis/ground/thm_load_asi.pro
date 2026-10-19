pro thm_load_asi_file_move_onetime   ; temporary routine: Moves ASI files to correct directories.
; Running this routine (once) will eliminate the need to download previously cached ASI files.

files= file_search(!themis.local_data_dir+'thg/l1/asi/????/200?/thg_l1_as?_????_200*.cdf',count=n)
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
;          this is not set, the default is to prompt the user. The
;          default CDF path loads whole hourly (asf) or daily (ast)
;          CDFs without clipping; the /UCALGARY_PGM path fetches only
;          the file granules covering the range (1-min files for asf,
;          hourly files for ast) and clips the output to TRANGE unless
;          /NO_TIME_CLIP is set
;  /NO_TIME_CLIP /UCALGARY_PGM path only: store every frame of every
;          fetched file instead of clipping the output to TRANGE (output
;          then aligns to file-granule boundaries)
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
;   /UCALGARY_PGM load from the THEMIS ASI data archive
;               (api.phys.ucalgary.ca / data.phys.ucalgary.ca) instead of
;               the default Berkeley CDF path (see Notes)
;   /CDF_LEGACY explicitly select the Berkeley CDF path. This is the
;               default (decided in thm_asi_use_archive), so the keyword is a
;               no-op unless /UCALGARY_PGM is also set, in which case /CDF_LEGACY wins.
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
; By default this loader reads the Berkeley thg_l1_asf/ast CDFs, as it
; always has. With /ucalgary_pgm it instead downloads from the THEMIS ASI
; data archive (api.phys.ucalgary.ca / data.phys.ucalgary.ca):
;   asf <- THEMIS_ASI_RAW (1-min PGM bundles; pixel values are bit-identical
;          to the legacy CDFs)
;   ast <- THEMIS_ASI_VEC1024 (same 1024-superpixel bin product as the
;          legacy ast CDFs, but 8-bit scaled: legacy counts ~ 33x these
;          values)
; Archive files are cached under !themis.local_data_dir + 'thg/asi/'.
;
;
;Written by: Ken Bromund ????,   Jan 5 2007
; $LastChangedBy: nikos $
; $LastChangedDate: 2026-10-14 09:54:40 -0700 (Wed, 14 Oct 2026) $
; $LastChangedRevision: 34975 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/ground/thm_load_asi.pro $
;-
;

; find the correct file names, based on datatype, and site
function thm_load_asi_relpath, sname=site, filetype=ft, $
                               time=time, trange=trange, _extra=_extra
; set begin and end of trange
  if keyword_set(time) then trange=[time,time]

  relpath = 'thg/l1/asi/'+ site + '/'
  ending = '_v01.cdf'
  prefix = 'thg_l1_'+ft+'_' + site + '_'

  	; asf are hour files, ast are daily files
  hour_res=(ft eq 'asf')
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
    if (count eq 1) then spd_cdf2tplot,/all,varnames=varnames,file=files,verbose=verbose,record=record[0],$
                                   tplotnames=tplotnames,suffix=suffix

 endif else $
    spd_cdf2tplot,/all,file=files,verbose=verbose,tplotnames=tplotnames,suffix=suffix
end


pro thm_load_asi,site = site, datatype = datatype, trange = trange, $
                 level = level, verbose = verbose, $
                 downloadonly = downloadonly, $
                 no_download=no_download, relpathnames_all=relpathnames_all, $
                 valid_names = valid_names, $
                 cursor=cursor, time=time, no_time_clip=no_time_clip, $
                 cdf_data=cdf_data, $
                 suffix=suffix,$
                 get_support_data=get_support_data, $
                 progobj=progobj, files=files, $
                 ucalgary_pgm=ucalgary_pgm, cdf_legacy=cdf_legacy
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

; /ucalgary_pgm path: load from the data archive at data.phys.ucalgary.ca
; (api.phys.ucalgary.ca) instead of Berkeley CDFs. The default is the
; Berkeley CDF path below; /cdf_legacy selects it explicitly and takes
; precedence if both keywords are set. /valid_names and cdf_data requests
; are always handled by the CDF code since they need no data download.
  if thm_asi_use_archive(ucalgary_pgm=ucalgary_pgm, cdf_legacy=cdf_legacy) && $
     ~keyword_set(valid_names) && ~arg_present(cdf_data) then begin
     vsites = strsplit('atha chbg ekat fsmi fsim fykn gako gbay gill '+ $
              'inuv kapu kian kuuj mcgr pgeo pina rank snkq tpas whit yknf '+ $
              'nrsq snap talo', ' ', /extract)
     vdts = ['asf', 'ast']
     ; resolve site selection with the same helper the legacy path uses, so
     ; that 'all', wildcards, arrays and space-delimited strings all behave
     ; as documented (strlowcase here rather than /ignore_case, which would
     ; assign back into the caller's site/datatype variables)
     if keyword_set(site) then begin
        my_sites = ssl_check_valid_name(strlowcase(site), vsites, /include_all)
        nsites = keyword_set(my_sites) ? n_elements(my_sites) : 0
     endif else begin
        my_sites = vsites
        nsites = n_elements(vsites)
     endelse
     ; resolve datatype selection
     if keyword_set(datatype) then begin
        my_dts = ssl_check_valid_name(strlowcase(datatype), vdts, /include_all)
        ndts = keyword_set(my_dts) ? n_elements(my_dts) : 0
     endif else begin
        my_dts = vdts
        ndts = n_elements(vdts)
     endelse
     if nsites eq 0 then begin
        dprint, dlevel=0, verbose=verbose, 'thm_load_asi: no valid sites in: ' + strjoin(site, ' ')
        return
     endif
     if ndts eq 0 then begin
        dprint, dlevel=0, verbose=verbose, 'thm_load_asi: no valid datatypes in: ' + strjoin(datatype, ' ')
        return
     endif
     ; accumulate into locals across the datatype loop and assign out once:
     ; the worker appends to files/relpathnames_all, but the legacy loaders
     ; assigned them, and callers (the GUI in particular) reuse one variable
     ; across calls
     for j = 0, ndts-1 do begin
        thm_asi_load_img, sites=my_sites, datatype=my_dts[j], $
           trange=trange, time=time, no_time_clip=no_time_clip, suffix=suffix, $
           downloadonly=downloadonly, no_download=no_download, $
           verbose=verbose, files=asi_files, relpathnames_all=asi_relpaths, $
           tplotnames=tplotnames
     endfor
     files = (n_elements(asi_files) gt 0) ? asi_files : ''
     relpathnames_all = (n_elements(asi_relpaths) gt 0) ? asi_relpaths : ''
     return
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
               vdatatypes = 'asf ast', $
               vlevels = 'l1', $
               deflevel = 'l1', $
               version = 'v01', $
               suffix=suffix,$
               relpath_funct = 'thm_load_asi_relpath', $
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


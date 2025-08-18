;+
;Procedure: THM_LOAD_ASK
;
;Purpose:  Loads THEMIS All Sky Keograms
;
;keywords:
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
;  get_support_data = does nothing.  present only for consistency with other
;                load routines
;  rego		read red-line data instead of THEMIS white light
;
;Example:
;   thg_load_ask
;Notes:
;  This routine is (should be) platform independent.
;
;
; $LastChangedBy: hfrey $
; $LastChangedDate: 2021-12-29 13:22:57 -0800 (Wed, 29 Dec 2021) $
; $LastChangedRevision: Added valid_names output option$
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/ground/thm_load_ask.pro $
;-

; find the correct file names, based on trange, datatype, and site
function thm_load_ask_relpath, trange=trange, _extra=_extra

     relpath = 'thg/l1/asi/ask/'
     prefix = 'thg_l1_ask_'
     ending = '_v01.cdf'
   
   return, file_dailynames(relpath,prefix,ending,/YEARDIR,trange=trange)

end

function thm_load_rego_ask_relpath, trange=trange, _extra=_extra

     relpath = 'thg/l1/reg/ask/'
     prefix = 'clg_l1_ask_'
     ending = '_v01.cdf'
   
   return, file_dailynames(relpath,prefix,ending,/YEARDIR,trange=trange)

end

pro thm_load_ask,site = site, datatype = datatype, trange = trange, $
                 level = level, verbose = verbose, $
                 downloadonly = downloadonly, $
                 no_download=no_download, relpathnames_all=relpathnames_all, $
                 varformat=varformat, $
                 valid_names = valid_names, $
                 get_support_data=get_support_data, $
                 progobj=progob, files=files, suffix=suffix, rego=rego
;                 _extra = _extra

  if arg_present(relpathnames_all) then begin
     downloadonly=1
     no_download=1
  end

  if keyword_set(rego) then $
  thm_load_xxx,sname=site, datatype=datatype, trange=trange, $
               level=level, verbose=verbose, downloadonly=downloadonly, $
               no_download=no_download, relpathnames_all=relpathnames_all, $
               cdf_data=cdf_data,get_cdf_data=arg_present(cdf_data), $
               get_support_data=get_support_data, $
               varnames=varnames, valid_names = valid_names, files=files, $
               varformat=varformat, $
               vsnames = 'atha fsmi fsim gill kakt luck lyrn rank resu sach talo', $
               type_sname = 'site', /all_sites_in_one, $
               vdatatypes = 'ask', $
               vlevels = 'l1', $
               deflevel = 'l1', $
               version = 'v01', $
               relpath_funct = 'thm_load_rego_ask_relpath', $
               progobj = progobj, tplotnames=tplotnames, $
               suffix=suffix, msg_out=msg_out, $
               _extra = _extra $
  else $
  thm_load_xxx,sname=site, datatype=datatype, trange=trange, $
               level=level, verbose=verbose, downloadonly=downloadonly, $
               no_download=no_download, relpathnames_all=relpathnames_all, $
               cdf_data=cdf_data,get_cdf_data=arg_present(cdf_data), $
               get_support_data=get_support_data, $
               varnames=varnames, valid_names = valid_names, files=files, $
               varformat=varformat, $
               vsnames = 'atha chbg ekat fsmi fsim fykn gako gbay gill '+ $
               'inuv kapu kian kuuj mcgr pgeo pina rank snkq tpas whit yknf '+ $
               'nrsq snap talo', $
               type_sname = 'site', /all_sites_in_one, $
               vdatatypes = 'ask', $
               vlevels = 'l1', $
               deflevel = 'l1', $
               version = 'v01', $
               relpath_funct = 'thm_load_ask_relpath', $
               progobj = progobj, tplotnames=tplotnames, $
               suffix=suffix, msg_out=msg_out, $
               _extra = _extra

   options,tplotnames,ytitle='[pixels]',ztitle='[counts]',ysubtitle='',/default

  ;print accumulated error messages now that loading is complete
  if keyword_set(msg_out) then begin
    for i=0, n_elements(msg_out)-1 do begin
      if msg_out[i] ne '' then dprint, dlevel=1, msg_out[i]
    endfor
  endif

end


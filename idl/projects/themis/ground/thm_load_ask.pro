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
;  ucalgary_pgm	stitch keograms from the hourly keogram products on
;		data.phys.ucalgary.ca instead of the default Berkeley
;		daily ask CDFs (see Notes)
;  cdf_legacy	explicitly select the Berkeley CDF path. This is the
;		default (decided in thm_asi_use_archive), so the keyword is a
;		no-op unless /ucalgary_pgm is also set, in which case /cdf_legacy wins.
;
;Example:
;   thg_load_ask
;Notes:
;  This routine is (should be) platform independent.
;
;  By default keograms are read from the Berkeley daily ask CDFs, as
;  always. With /ucalgary_pgm, THEMIS keograms are instead stitched from
;  the archived hourly keogram product on data.phys.ucalgary.ca
;  (THEMIS_ASI_HOURLY_KEOGRAM_PGM, ~300 KB/site-hour). Variable names
;  and structures are unchanged.
;  Cadence is one column per 6 s (600 columns/hour) vs one column per
;  3-s frame in the legacy CDFs -- visually equivalent; column values
;  are closely correlated (0.98-0.99) but not byte-identical, since the
;  archive keograms were generated onsite with a slightly different
;  column extraction than the Berkeley CDF pipeline used.
;  With /ucalgary_pgm, REGO (/rego) keograms are likewise stitched from
;  the archived hourly keogram product (clg_ask_* variables, 1200
;  columns/hour = full 3-s cadence), read from the 16-bit grayscale PNG
;  container which covers the whole mission.
;  IMPORTANT: archive REGO keogram values are display-scaled, NOT counts
;  (the THEMIS keogram products are counts). The generator maps a fixed
;  count window onto 0-65535 and clips outside it, so faint pixels
;  bottom out at 0 and bright aurora saturates. The keograms plot
;  correctly -- structure and timing are right -- but the values are not
;  photometric. This is flagged in the variable units ('scaled'), on the
;  color bar, and by a message at load time.
;  The default Berkeley CDF path gives exact legacy values and is the
;  supported way to get count-accurate REGO keograms.
;
;
; $LastChangedBy: nikos $
; $LastChangedDate: 2026-10-14 09:54:40 -0700 (Wed, 14 Oct 2026) $
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
                 progobj=progob, files=files, suffix=suffix, rego=rego, $
                 ucalgary_pgm=ucalgary_pgm, cdf_legacy=cdf_legacy
;                 _extra = _extra

  if arg_present(relpathnames_all) then begin
     downloadonly=1
     no_download=1
  end

; /ucalgary_pgm path: load keograms from the data archive at
; data.phys.ucalgary.ca (hourly keogram datasets via api.phys.ucalgary.ca)
; instead of the Berkeley daily ask CDFs, for both THEMIS ASI and REGO
; (/rego). The default is the Berkeley CDF path below; /cdf_legacy selects
; it explicitly and takes precedence if both keywords are set.
; /valid_names requests are always handled by the CDF code.
  if thm_asi_use_archive(ucalgary_pgm=ucalgary_pgm, cdf_legacy=cdf_legacy) && $
     ~keyword_set(valid_names) then begin
     if keyword_set(rego) then $
        vsites = strsplit('atha fsmi fsim gill kakt luck lyrn rank resu '+ $
                 'sach talo', ' ', /extract) $
     else $
        vsites = strsplit('atha chbg ekat fsmi fsim fykn gako gbay gill '+ $
                 'inuv kapu kian kuuj mcgr pgeo pina rank snkq tpas whit yknf '+ $
                 'nrsq snap talo', ' ', /extract)
     ; resolve sites with the same helper the legacy path uses, so that
     ; 'all', wildcards, arrays and space-delimited strings all behave as
     ; documented (strlowcase here rather than /ignore_case, which would
     ; assign back into the caller's site variable)
     if keyword_set(site) then begin
        my_sites = ssl_check_valid_name(strlowcase(site), vsites, /include_all)
        nsites = keyword_set(my_sites) ? n_elements(my_sites) : 0
     endif else begin
        my_sites = vsites
        nsites = n_elements(vsites)
     endelse
     if nsites eq 0 then begin
        dprint, dlevel=0, verbose=verbose, 'thm_load_ask: no valid sites in: ' + strjoin(site, ' ')
        return
     endif
     ; accumulate into locals and assign out once: the workers append to
     ; files/relpathnames_all, but the legacy loaders assigned them, and
     ; callers (the GUI in particular) reuse one variable across calls
     thm_asi_load_ask, sites=my_sites, trange=trange, suffix=suffix, $
        rego=rego, downloadonly=downloadonly, no_download=no_download, $
        verbose=verbose, files=asi_files, relpathnames_all=asi_relpaths, $
        tplotnames=tplotnames
     files = (n_elements(asi_files) gt 0) ? asi_files : ''
     relpathnames_all = (n_elements(asi_relpaths) gt 0) ? asi_relpaths : ''
     ; REGO archive keograms are display-scaled, not counts -- say so on the
     ; color bar (the caveat lives in dlimits, so it survives replots).
     ; Keep the ztitle to one line: a rotated color-bar title has plenty of
     ; vertical room but very little margin width, so a !C second line
     ; collides with the frame. The wording goes on the Z axis, not
     ; ysubtitle -- tplot appends ysubtitle to the Y TITLE, which would
     ; label the pixel-row axis with the units of the image data.
     if keyword_set(rego) then $
        options,tplotnames,ytitle='[pixels]',ztitle='[scaled counts]', $
                ysubtitle='',zsubtitle='Scaled counts',/default $
     else $
        options,tplotnames,ytitle='[pixels]',ztitle='[counts]',ysubtitle='',/default
     return
  endif

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


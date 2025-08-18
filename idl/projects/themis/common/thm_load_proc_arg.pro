;+
;Procedure: THM_LOAD_PROC_ARG
;
;Purpose:  Generic argument validation routine for THEMIS Data File Loading
;   routines, meant to be called by
;   instrument-specific thm_load procedures.
;
;keywords:
;  post_process_proc: name of procedure to call after cdf2tplot is called
;                     will be called w/ keywords sname, dt (datatype), lvl,
;                     and _extra.
;  relpath_funct: name of routine to call in place of file_dailynames
;                 may simply be a wrapper.
;                 will be called w/ keywords sname, dt (datatype), lvl,
;                 and _extra.
;  cdf_to_tplot: user-supplied procedure to override cdf2tplot
;  sname  = site or probe name. The default is 'all',
;  type_sname = string, set to 'probe' or 'site'
;  vsnames = space-separated list of valid probes/sites
;  datatype = Can be any datatype from the list of valid datatypes
;             or 'all'
;  vdatatypes = space-separated list of valid data types
;  file_vdatatypes = space-separated list of file types corresponding to each
;          valid data type.  If there is a one-to-one correpspondence
;          between filetype and datatype, vfiletypes may be left undefined.
;          If all datatypes are in a single file, then vfiltypes may contain
;          a single name, rather than a list.
;  vL2datatypes= space-separated list of datatypes valid for L2 data
;  vL2coord= space-separated list of coordinates valid for L2 data
;  file_vL2datatypes=same as file_vdatatypes, but for L2 data.  Defaults to
;          value of file_vdatatypes.
;  TRANGE= (Optional) Time range of interest  (2 element array), if
;          this is not set, the default is to prompt the user. Note
;          that if the input time range is not a full day, a full
;          day's data is loaded
;  level = the level of the data, the default is 'l1', or level-1
;          data. A string (e.g., 'l2') or an integer can be used. 'all'
;          can be passed in also, to get all levels.
;  vlevels=A space-separated list of valid levels, e.g. 'l1 l2'
;  proc_type =  the type of data, i.e. 'raw' or 'calibrated'. This is
;          for validating the 'type' keyword to thm_load procs.
;  vtypes =A space-separated list of valid types, e.g. 'raw calibrated'
;          No validation on proc_type if not set.
;  deftype = default for type.  only applied to L1.  If not supplied, 
;            then 'calibrated' will be uses as the default value.
;  CDF_DATA: named variable in which to return cdf data structure: only works
;          for a single spacecraft and datafile name.
;  VARNAMES: names of variables to load from cdf: default is all.
;  /GET_SUPPORT_DATA: load support_data variables as well as data variables
;                      into tplot variables.
;  /NO_UPDATE: prevent contact to server if local file already exists.
;  /valid_names, if set, then this routine will return the valid probe, datatype
;          and/or level options in named variables supplied as
;          arguments to the corresponding keywords.
;  files   named varible for output of pathnames of local files.
;  /VERBOSE  set to output some useful info
;  msg_out:  A named variable to output an array of error messages
;            which can be printed to the console later when they
;            will be more visible to the user.  Null string is returned
;            if no applicable errors are encountered.
;             
;Output Keywords:
;  oft     distinct file types that need to be loaded.  Array of strings.
;  ofdt    datatypes corresponding to each file type in ofts. Array of
;          strings, each containing a space-separate list of datatypes .
;  odt     validated datatypes
;  olvl    validated levels.
;  otyp    validated type.
;Notes:
;  This routine is a utility function used to implement thm_load_??? routines.
;
; $LastChangedBy: aaflores $
; $LastChangedDate: 2015-04-30 15:28:49 -0700 (Thu, 30 Apr 2015) $
; $LastChangedRevision: 17458 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/common/thm_load_proc_arg.pro $
;-
pro thm_load_proc_arg,sname=sname, datatype=datatype, $
                      level=level, coord=coord, proc_type=type, $
                      verbose=verbose, $
                      varformat=varformat, valid_names = valid_names, $
                      type_sname=type_sname, $
                      vsnames=vsnames, vdatatypes=vdatatypes, $
                      file_vdatatypes=file_vdatatypes, $
                      vtypes=vtypes, deftype = deftype, $
                      vlevels=vlevels, deflevel=deflevel, $
                      vL2datatypes=vL2datatypes, vL2coord=vL2coord, $
                      file_vL2datatypes= file_vL2datatypes, $
                      no_download=no_download, $
                      progobj = progobj, $
                      osname=snames, odt=dts, olvl=lvls, my_themis=my_themis, $
                      oft = fts, ofdt = fdts, otyp = typ, $
                      no_update=no_update, $
                      load_params=load_params, $
                      use_eclipse_corrections=use_eclipse_corrections, $
                      msg_out=msg_out, $
                      _ref_extra = _extra

  thm_init
; If verbose keyword is defined, override load_params.verbose
  vb = size(verbose, /type) ne 0 ? verbose : load_params.verbose

; Valid sname names
  vsnames = strsplit(vsnames, ' ', /extract)
; Valid data names
  vdatatypes = strsplit(vdatatypes, ' ', /extract) ;for completeness
;valid data levels
  vlevels = strsplit(vlevels, ' ', /extract)
;valid types
  if keyword_set(vtypes) then vtypes = strsplit(vtypes,' ',/extract)
;return partially invalid inputs via keyword
  msg_out = ''

; parse out data level
  if keyword_set(deflevel) then lvl = deflevel else lvl = 'l1'
  if n_elements(level) gt 0 then begin
    if size(level, /type) Eq 7 then begin
      If(level[0] Ne '') Then lvl = strcompress(strlowcase(level), /remove_all)
    endif else lvl = 'l'+strcompress(string(fix(level)), /remove_all)
  endif
  lvls = ssl_check_valid_name(strlowcase(lvl), vlevels)
  if not keyword_set(lvls) then return
  if n_elements(lvls) gt 1 then begin
     dprint, 'only one value may be specified for level'
     return
  endif
  if keyword_set(vb) && vb Ge 4 then dprint, dlevel = vb, 'Level = '+lvls

;valid coordinate systems for L2
  if keyword_set(vL2coord) then $
     vL2coord = strsplit(vL2coord, ' ', /extract)

  if lvls[0] eq 'l2' && keyword_set(vL2datatypes) then $
     vdatatypes = strsplit(vL2datatypes, ' ', /extract)


;If valid_names is set, return the options
  if keyword_set(valid_names) then begin
    sname = vsnames
    dprint, dlevel = 4, $
             string(strjoin(sname, ','), $
                    format = '( "Valid '+type_sname+'s:",X,A,".")')
    datatype = vdatatypes
    dprint, dlevel = 4, $
             string(strjoin(datatype, ','), $
                    format = '( "Valid '+lvls[0]+' datatypes:",X,A,".")')

    if lvls[0] eq 'l2' && keyword_set(vL2coord) then begin
       coord = vL2coord
       dprint, dlevel = 4, $
                string(strjoin(coord, ','), $
                       format = '( "Valid '+lvls[0]+' coords:",X,A,".")')
    endif

    if lvls[0] eq 'l1' and keyword_set(vtypes) then begin
       type=vtypes
       dprint, dlevel = 4, $
               string(strjoin(type,','), $
                      format='( "Valid '+lvls[0]+' types:",X,A,".")')
    endif

    level = vlevels
    dprint, dlevel = 4, $
             string(strjoin(level, ','), format = '( "Valid levels:",X,A,".")')
    return
  endif

;parse out snames
  if n_elements(sname) eq 1 then if sname eq 'f' then vsnames = ['f']
  if not keyword_set(sname) then begin
    snames = vsnames
  endif else begin
    snames = ssl_check_valid_name(strlowcase(sname), vsnames, /include_all, $
                                  invalid=msg_snames, type='site or probe')
  endelse
  if not keyword_set(snames) then return
  if keyword_set(vb) then printdat, snames, /value, varname=type_sname+'s'

;datatype
  if not keyword_set(datatype) then begin
    dts = vdatatypes
  endif else begin
    dts = ssl_check_valid_name(strlowcase(datatype), vdatatypes, /include_all, $
                               invalid=msg_dt, type='data type')
  endelse
  if not keyword_set(dts) then return
  if keyword_set(vb) then printdat, dts, /value, varname='Datatypes'

; type
  if lvls[0] eq 'l1' then begin
     if keyword_set(vtypes) then begin
        if not keyword_set(deftype) then deftype = 'calibrated'
        if not keyword_set(type) then typ = deftype $
        else typ = ssl_check_valid_name(strlowcase(type), vtypes)
        if not keyword_set(typ) then return
        if keyword_set(vb) then printdat, typ, /value, varname='Type'
     endif else begin
        dprint, dlevel = 4, 'type keyword not validated'
     endelse
  endif else if keyword_set(type) then begin
     dprint,  'type keyword only applies to l1 data'
     return
  endif

; Level2 probe data : set varformat to get each possible combination of
; datatype and coord
  if lvls[0] eq 'l2' && strlowcase(type_sname) eq 'probe' $
     && ~keyword_set(varformat) && keyword_set(vL2coord) then begin
     if not keyword_set(coord) then begin
       crds = vL2coord
     endif else begin
       crds = ssl_check_valid_name(strlowcase(coord), vL2coord, /include_all, $
                                   invalid=msg_coord, type='coordinates')
     endelse
     if not keyword_set(crds) then return
     if keyword_set(vb) then printdat, crds, /value, varname='Coord'
     cross_dt_coord = array_cross(dts, crds)
     varformat = 'th?_' + strjoin(cross_dt_coord, '_')
; Some level 2 quantities don't have coordinate systems, this can be
; denoted by 'none' in the valid coordinates list, jmm, 15-jul-2008
     none_ok=where(strlowcase(strcompress(/remove_all,vl2coord)) Eq 'none')
     If(none_ok[0] Ne -1) Then varformat = [varformat, 'th?_'+dts]
  endif

  if vb ge 7 then printdat,load_params

  nlvls = n_elements(lvls)
  ndts = n_elements(dts)
  nsnames = n_elements(snames)

  if lvls[0] eq 'l2' && keyword_set(file_vL2datatypes) then $
     file_vdatatypes = file_vL2datatypes

  if keyword_set(file_vdatatypes) then begin
     fts=strarr(ndts)
     file_vdatatypes = strsplit(file_vdatatypes, ' ', /extract)

     if n_elements(file_vdatatypes) eq 1 then begin
        ; fill out file_vdatatypes array to same dimension as vdatatypes
        file_vdatatypes = strarr(n_elements(vdatatypes)) + file_vdatatypes[0]
     endif

     for j = 0, ndts-1 do begin
        fts[j] = file_vdatatypes[where(vdatatypes eq dts[j])]
     endfor
     fts = fts[UNIQ(fts, SORT(fts))]
     nfts = n_elements(fts)
     ;; for each filetype, get a list of requested datatypes
     fdts=strarr(nfts)
     for j = 0, nfts-1 do begin
        file_datatypes = vdatatypes[where(file_vdatatypes eq fts[j])]
        fdts[j] = strjoin(strfilter(file_datatypes,dts), ' ')
     endfor
     if vb ge 7 then printdat, fts  ;;;;
     if vb ge 7 then printdat, fdts                 ;;;;
  endif else begin
     fts = dts
     nfts = n_elements(fts)
     fdts = dts
  endelse

  ;pass out invalid portion of partially invalid inputs
  ;any fully invalid inputs should have caused a return prior to this
  if keyword_set(msg_snames) then msg_out = [msg_out,msg_snames]
  if keyword_set(msg_dt) then msg_out = [msg_out,msg_dt]
  if keyword_set(msg_coord) then msg_out = [msg_out,msg_coord]
  
  ;check output message array for null strings 
  idx = where(msg_out ne '', ni)
  msg_out = ni gt 0 ? msg_out[idx] : ''

  my_themis = load_params
  my_themis.no_download = !themis.no_download || keyword_set(no_download)
  my_themis.no_update = !themis.no_update || keyword_set(no_update)
  if keyword_set(progobj) then my_themis.progobj = progobj
  my_themis.verbose=vb

end

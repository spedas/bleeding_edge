;+
;Procedure: THM_LOAD_EFI
;
;Purpose:  Loads THEMIS EFI data
;
;Syntax:  THM_LOAD_EFI [, <optional keywords below> ]
;
;keywords:
;  PROBE:		Input, string.  Specify space-separated probe letters, or string array (e.g., 'a c', ['a', 'c']).  Defaults to all probes.
;  DATATYPE:		Input, string.  Default setting is to calibrate all raw quantites and also produce all _0 and _dot0 quantities.  Use DATATYPE
;                       kw to narrow the data products.  Wildcards and glob-style patterns accepted (e.g., ef?, *_dot0).
;  SUFFIX:		Input, scalar or array string.  Set (scalar) to append SUFFIX to all output TPLOT variable names.  Set (array with same # elements
;			as COORD) to put suffixes for corresponding COORD elements (one TPLOT variable with suffix for each element of COORD).  When COORD has
;			> 1 element, SUFFIX must have the same # of elements (or be unset).
;  TRANGE:		Input, double (2 element array).  Time range of interest.  If this is not set, the default is to prompt the user.  Note that if the
;			input time range is not a full day, a full day's data is loaded.
;  LEVEL:		I/O, string.  The level of the data, the default is 'l1', or level-1 data. A string (e.g., 'l2') or an integer can be used. Only
;			one level can be specifed at a time.  Set /VALID_NAMES to return the valid level names.
;  CDF_DATA:		Output, string.  Named variable in which to return cdf data structure: only works for a single spacecraft and datafile name.
;  VARNAMES:		*** CDF_DATA must be present ***  Output, string.  Returns CDF variable names that were loaded.
;  /GET_SUPPORT_DATA: 	Input, numeric, 0 or 1.  Set to load support_data variables as well as data variables into tplot variables.
;  /DOWNLOADONLY:	Input, numeric, 0 or 1.  Set to download file but not read it.
;  /VALID_NAMES:	Input, numeric, 0 or 1.  If set, then this routine will return the valid probe, datatype and/or level options in named variables
;			supplied as arguments to the corresponding keywords.
;  FILES:		Output, string.  Named varible for output of pathnames of local files.
;  /VERBOSE:		Input, numeric, 0 or 1.  Set to output some useful info.
;  /NO_DOWNLOAD:	Input, numeric, 0 or 1.  Set to use only files which are online locally.
;  RELPATHNAMES_ALL:	Output, string.  Named variable in which to return all files that are required for specified timespan, probe, datatype, and level.  If
;			present, no files will be downloaded, and no data will be loaded.
;  TYPE:		Input, string.  Set to 'calibrated' or 'raw'.
;  COORD:		Input, string.  What coordinate system you would like your data in.  For choices, see THEMIS Sci. Data Anal. Software Users Guide.
;  TEST:		Input, numeric, 0 or 1.  Disables selected /CONTINUE to MESSAGE.  For QA testing only.
;  /NO_TIME_CLIP:       Disables time clipping, which is the default
; use_eclipse_corrections:  Only applies when loading and calibrating
;   Level 1 data. Defaults to 0 (no eclipse spin model corrections 
;   applied).  use_eclipse_corrections=1 applies partial eclipse 
;   corrections (not recommended, used only for internal SOC processing).  
;   use_eclipse_corrections=2 applies all available eclipse corrections.
;   ONTHEFLY_EDC_OFFSET:OUTPUT, float.  Return the EDC offset array
;                       calculated on-the-fly in a structure (tag name = probe letter,
;                       subtagname =datatype).  *** WARNING: This kw can use a lot
;                       of memory, if processing many datatypes, or long time periods. ***
;
;Example:
;   thg_load_efi,/get_suppport_data,probe=['a', 'b']
;Notes:
;
;Modifications:
;  Added TEST kw to disable certain /CONTINUE to MESSAGE, and passed TEST
;    through to THM_CAL_EFI.PRO, W.M.Feuerstein, 4/7/2008 (M).
;  Fixed crash on passing an argument for RELPATHNAMES_ALL, WMF, 4/9/2008 (Tu).
;  Added _extra keyword to ease the passing of keywords to thm_cal_efi
; $LastChangedBy: jimm $
; $LastChangedDate: 2025-05-08 11:29:53 -0700 (Thu, 08 May 2025) $
; $LastChangedRevision: 33301 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/fields/thm_load_efi.pro $
;-

pro thm_load_efi, probe = probe, datatype = datatype, trange = trange, $
                  level = level, verbose = verbose, downloadonly = downloadonly, $
                  no_download = no_download, type = type, coord = coord, varformat = varformat, $
                  cdf_data = cdf_data, get_support_data = get_support_data, $
                  varnames = varnames, valid_names = valid_names, files = files, $
                  relpathnames_all = relpathnames_all, $
                  suffix = suffix, progobj = progobj, test = test, $
                  no_time_clip = no_time_clip, $
                  use_eclipse_corrections = use_eclipse_corrections, $
                  onthefly_edc_offset = onthefly_edc_offset, $
                  _extra = _extra


  thm_init

  if ~keyword_set(probe) then probe = ['a', 'b', 'c', 'd', 'e']
  
  ; Make sure SUFFIX is an array (and not just a space-separated list),
  ; and make lower case:
  if keyword_set(suffix) then begin
    if n_elements(suffix) eq 1 then begin
      suffix = strsplit(strlowcase(suffix), ' ', /extract)
    endif else begin
      suffix = strlowcase(suffix)
    endelse
  endif else begin
    suffix = ''
  endelse

  ;no eclipse correction by default
  if undefined(use_eclipse_corrections) then begin
    use_eclipse_corrections = 0
  end

  ;check !themis for undefined options
  vb = undefined(verbose) ? !themis.verbose : verbose
  downloadonly = undefined(downloadonly) ? !themis.downloadonly : downloadonly 

  ;expected behavior appears to be that this overrides defaults
  if arg_present(relpathnames_all) then begin
    downloadonly=1
    no_download=1
  end

  vl1datatypes = ['vaf', 'vap', 'vaw', 'vbf', 'vbp', 'vbw', $
                  'eff', 'efp', 'efw', 'eff_0', 'efp_0', 'efw_0', $
                  'eff_dot0', 'efp_dot0', 'efw_dot0', 'eff_e12_efs', 'eff_e34_efs' , $
                  'efp_e12_efs', 'efp_e34_efs', 'efw_e12_efs', 'efw_e34_efs', $
                  'eff_q_mag', 'eff_q_pha', 'efp_q_mag', 'efp_q_pha', $
                  'efw_q_mag', 'efw_q_pha']
  vl1datafiles = strmid(vl1datatypes, 0, 3)

;  vl2datatypes = ['vaf', 'vap', 'vaw', 'vbf', 'vbp', 'vbw', $
   vl2datatypes = ['eff_dot0', 'efs_dot0', 'eff_q_mag', 'eff_q_pha', $
                  'efs_q_mag', 'efs_q_pha', 'eff_e12_efs', 'eff_e34_efs', $
                  'efp', 'efw']

  thm_load_proc_arg, sname=probe, datatype=datatype, proc_type=type, msg_out=msg_out, $
                     level=level, verbose=verbose, no_download=no_download, $
                     valid_names = valid_names, $
                     vsnames = 'a b c d e', $
                     type_sname = 'probe', $
                     vdatatypes = strjoin(vl1datatypes, ' '), $
                     file_vdatatypes = strjoin(vl1datafiles, ' '), $
                     vL2datatypes= strjoin(vl2datatypes, ' '), $
                     file_vL2datatypes= 'efi efi efi efi efi efi efi efi efp efw', $
                     vtypes='raw calibrated', deftype = 'calibrated', $
                     vlevels = 'l1 l2', $
                     deflevel = 'l1', $
                     osname=probes, odt=dts, olvl=lvls, $
                     oft=fts, ofdt=fdts, otyp = typ, $
                     load_params=!themis,$
                     my_themis=my_themis

  nlvls = n_elements(lvls)
  lvls = lvls[0]                ;only one level at a time please
  ndts = n_elements(dts)
  nfts = n_elements(fts)
  nprobes = n_elements(probes)

  if keyword_set(valid_names) then return

  if nlvls*ndts*nfts*nprobes le 0 then return

  if arg_present(cdf_data) && nlvls*ndts*nprobes gt 1 then begin
     dprint,  'can only get cdf_data for a single datatype'
     return
  endif

;
  if lvls[0] eq 'l1' then begin
     ;; default action for loading level 1 is to calibrate
     if strmatch(typ, 'calibrated') then begin
        ;; we're calibrating, so make sure we get support data
        if not keyword_set(get_support_data) then begin
           get_support_data = 1
           delete_support_data = 1
        endif
     endif
   endif else begin             ;Off into separate routine
     If(arg_present(cdf_data)) Then Begin
       If(arg_present(relpathnames_all)) Then Begin
         thm_load_efi_l2, probe = probe, datatype = datatype, trange = trange, $
           level = level, verbose = verbose, downloadonly = downloadonly, $
           no_download = no_download, coord = coord, varformat = varformat, $
           varnames = varnames, valid_names = valid_names, files = files, $
           relpathnames_all = relpathnames_all, cdf_data = cdf_data, $
           suffix = suffix, progobj = progobj, test = test, $
           no_time_clip = no_time_clip, msg_out=msg_l2, _extra = _extra
       Endif Else Begin
         thm_load_efi_l2, probe = probe, datatype = datatype, trange = trange, $
           level = level, verbose = verbose, downloadonly = downloadonly, $
           no_download = no_download, coord = coord, varformat = varformat, $
           varnames = varnames, valid_names = valid_names, files = files, $
           cdf_data = cdf_data, suffix = suffix, progobj = progobj, test = test, $
           no_time_clip = no_time_clip, msg_out=msg_l2, _extra = _extra
       Endelse
     Endif Else Begin
       If(arg_present(relpathnames_all)) Then Begin
         thm_load_efi_l2, probe = probe, datatype = datatype, trange = trange, $
           level = level, verbose = verbose, downloadonly = downloadonly, $
           no_download = no_download, coord = coord, varformat = varformat, $
           varnames = varnames, valid_names = valid_names, files = files, $
           relpathnames_all = relpathnames_all, $
           suffix = suffix, progobj = progobj, test = test, $
           no_time_clip = no_time_clip, msg_out=msg_l2, _extra = _extra
       Endif Else Begin
         thm_load_efi_l2, probe = probe, datatype = datatype, trange = trange, $
           level = level, verbose = verbose, downloadonly = downloadonly, $
           no_download = no_download, coord = coord, varformat = varformat, $
           varnames = varnames, valid_names = valid_names, files = files, $
           suffix = suffix, progobj = progobj, test = test, $
           no_time_clip = no_time_clip, msg_out=msg_l2, _extra = _extra
       Endelse
     Endelse
     Return
   endelse

  ; If trange is not already set, take whatever was used for the
  ; last timespan command, similar to what happens inside
  ; thm_load_xxx.  This ensures that time range clipping is
  ; performed, even if a trange keyword argument is not explicitly passed.

  if ~keyword_set(trange) then begin
    trange=timerange();
  endif

    ; pad time range for calibration (1/2 hour)
  if keyword_set(trange) then begin
    trangef = 1
    tranged = minmax(time_double(trange)) ;keep double copy of original time range
    tr = tranged + [-1800, 1800]
  endif

;get file names, loop over all snames, levels and datatypes
  for k = 0, nlvls-1 do $
    for j = 0, nfts-1 do $
    for i = 0, nprobes-1 do begin
     probei = probes[i]
     ftj = fts[j]
     lvlk = lvls[k]

     relpath = 'th'+probei+'/'+lvlk+'/'+ ftj+'/'
     prefix = 'th'+probei+'_'+lvlk+'_'+ftj+'_'
     dir = 'YYYY/'
     ending = '_v01.cdf'

     relpathnames = file_dailynames(relpath, prefix, ending, dir=dir, trange = trange,addmaster=addmaster)

     if vb ge 7 then dprint,  'relpathnames : ', relpathnames

     if arg_present(relpathnames_all) then begin
        if i+j+k eq 0 then relpathnames_all = relpathnames else relpathnames_all = [relpathnames_all, relpathnames]
     endif

     ;;download files for this probe, level, and datatype

     ;; my_themis is a copy of !themis, which may have no_download set
     files = spd_download(remote_file=relpathnames, _extra=my_themis, progobj=progobj)

     if keyword_set(downloadonly) then continue

     if arg_present(cdf_data) then begin
        cdf_data = cdf_load_vars(files,varnames=varnames, verbose=vb,/all)
        return
     endif

     if  ~keyword_set(varformat) then begin
       if keyword_set(get_support_data) then $
                                ;varformat='th?_??? th?_???_hed' $
       varformat = 'th?_??? th?_???_hed th?_???_hed_ac' else varformat = 'th?_???'
     endif

     if keyword_set(vb) then dprint, transpose(['Loading...',files])

     spd_cdf2tplot, file=files, all=all, verbose=vb, varformat=varformat, tplotnames=tplotnames

     ;;Reset 'tha_hed_ac' to simulate boundary (for testing only!):
     ;;============================================================
     ;get_data,'th'+probe+'_'+'eff'+'_hed_ac',data=hed_ac
     ;;hed_ac.y[0:115] = 1b
     ;;hed_ac.y[115:224] = 1b
     ;hed_ac.y[115:224] = 255b    ;This line tests hed_ac=255.
     ;store_data,'th'+probe+'_'+'eff'+'_hed_ac',data=hed_ac


     if not keyword_set(suffix) then suffix = ''


     ;todo: Clip to desired time range here
     if ~keyword_set(no_time_clip) && keyword_set(trange) && keyword_set(trangef) then begin
       for l=0, n_elements(tplotnames)-1 do begin
         if tplotnames[l] eq '' then continue
         dprint,  'Clipping '+string(l)
         time_clip, tplotnames[l], tr[0], tr[1], /replace, error=clip_err
         if clip_err then begin
           dprint,  'Unable to clip '+tplotnames[l]+' to requested time range. Data may be out of range.'
           store_data, tplotnames[l], /del        
           if ~(~size(filtered_tplotnames, /type)) then filtered_tplotnames = [filtered_tplotnames, tplotnames[l]] else filtered_tplotnames = tplotnames[l]
         endif
       endfor
       if keyword_set(filtered_tplotnames) then tplotnames = filtered_tplotnames
     endif

     ;; add '_raw' (or whatever) suffix to tplot var name
     ;; and add DLIMIT tags to data quantities
     for l=0, n_elements(tplotnames)-1 do begin
        tplot_var = tplotnames[l]

        get_data, tplot_var, data=d_str, limit=l_str, dlimit=dl_str
        if size(/type,dl_str) eq 8 && dl_str.cdf.vatt.var_type eq 'data' then begin
           
           if n_elements( suffix ) eq 1 then begin
             tplot_var_raw = tplot_var+suffix[0]
             in_suffix = suffix[0]
           endif else tplot_var_raw = tplot_var
           data_att = { data_type:'raw', coord_sys:'efi_sensor',units:'ADC'}
           str_element, dl_str, 'data_att', data_att, /add


           if strmatch( strlowcase( tplot_var), 'th'+probei+'_v??') then begin
                 colors = [ 1, 2, 3, 4, 5, 6]
                 labels = [ 'V1', 'V2', 'V3', 'V4', 'V5', 'V6']
              endif
           if strmatch( strlowcase( tplot_var), 'th'+probei+'_e??') then begin
                 colors = [ 2, 4, 6]
                 labels = [ 'e12', 'e34', 'e56']
              endif

           str_element, dl_str, 'colors', colors, /add
           str_element, dl_str, 'labels', labels, /add
           str_element, dl_str, 'labflag', 1, /add
           str_element, dl_str, 'ytitle', string( tplot_var, 'ADC', format='(A,"!C!C[",A,"]")'), /add


           store_data, delete=tplot_var
;           store_data, tplot_var_raw, data=d_str, limit=l_str, dlimit=dl_str
           store_data, 'veryunusualprefixtempfoo_'+tplot_var_raw, data=d_str, limit=l_str, dlimit=dl_str

           etype=strmid(tplot_var,4)

        endif

     endfor
  endfor                    ;end of loop over all probes, levels and datatypes.

;downloadonly seems to get here
  if keyword_set(downloadonly) then return
  
  if keyword_set(typ) && typ eq 'calibrated' && ~arg_present(relpathnames_all) then begin

    thm_cal_efi, probe=probes, datatype=dts, coord=coord, in_suffix = in_suffix, $
                 out_suffix = suffix, test=test, stored_tnames = stored_tnames,$
                 use_eclipse_corrections=use_eclipse_corrections, $
                 onthefly_edc_offset = onthefly_edc_offset, _extra = _extra

  endif

  ;Don't care about history, so unique:
  ;
  if ~(~size(stored_tnames, /type)) then stored_tnames = stored_tnames[uniq(stored_tnames, sort(stored_tnames))] else stored_tnames = ''

  ;Convert temporary variables (that are requested as permanent) to permanent names (remove prefix):
  ;*************************************************************************************************
  tempnames= tnames('veryunusualprefixtempfoo_*')
  w=where(strlen(dts) eq 3)
  if w[0] ne -1 then primary_dts= dts[w] else primary_dts = ''
  if tempnames[0] ne '' && primary_dts[0] ne '' then begin
    for i= 0, n_elements(tempnames)-1 do begin
      ;
      ;If requested and not produced by THM_CAL_EFI, then rename to the permanent TPLOT variable name, else delete:
      ;************************************************************************************************************
      requested = 0b
      for j = 0, n_elements( suffix )-1 do begin
        if (where(strmid(tempnames[i], 2+strlen( suffix[j] ), 3, /reverse_offset) eq primary_dts))[0] ne -1 then requested = 1
      endfor ;j
;      if (where(strmid(tempnames[i], 2+strlen(suffix), 3, /reverse_offset) eq primary_dts))[0] ne -1 then begin     ;Requested?
      if requested then begin
        case 1 of
;          tnames(strmid(tempnames[i], 25)) eq '': store_data, tempnames[i], newname= strmid(tempnames[i], 25)
          (where( strmid(tempnames[i], 25) eq stored_tnames ))[0] eq -1: begin
            if tnames(strmid(tempnames[i], 25)) ne '' then store_data, strmid(tempnames[i], 25), /del
            store_data, tempnames[i], newname= strmid(tempnames[i], 25)
          end
          else: store_data, tempnames[i], /delete
        endcase
      endif
    endfor
  endif
  ;
  ;Remove remaining temp variables:
  ;********************************
  ;
  tempnames= tnames('veryunusualprefixtempfoo_*')
  if tempnames[0] ne '' then store_data, tempnames, /delete
      
  ;todo: Clip padding left in place for calibration
  if not keyword_set(no_time_clip) and n_elements(stored_tnames) ge 1 and keyword_set(trange) then begin
    for i=0, n_elements(stored_tnames)-1 do begin
      if stored_tnames[i] eq '' then continue
      time_clip, stored_tnames[i], tranged[0], tranged[1], /replace, error=clip_err
      if clip_err then begin
        dprint,  'THM_LOAD_EFI: Unable to clip '+stored_tnames[i]+' to requested time range. Data may be out of range.'
        store_data, stored_tnames[i], /del
      endif
    endfor
  endif

  if vb ge 8 && arg_present(relpathnames_all) then dprint,  'relpathnames_all: ', relpathnames_all

  ;hed variables: add suffix or delete them if get_support_data was not set
  for i = 0, n_elements(vl1datatypes)-1L do begin
    th_name_hed = 'th'+probe+'_'+vl1datatypes[i]+'_hed'
    if n_elements(tnames(th_name_hed)) gt 0 then begin          
      if keyword_set(delete_support_data) then begin  
        del_data, th_name_hed
      endif else begin
        if keyword_set(suffix) && suffix[0] ne '' then begin 
          copy_data, th_name_hed, th_name_hed +suffix[0]
          del_data, th_name_hed
        endif
      endelse
    endif
    th_name_hed = 'th'+probe+'_'+vl1datatypes[i]+'_hed_ac'
    if n_elements(tnames(th_name_hed)) gt 0 then begin
      if keyword_set(delete_support_data) then begin
        del_data, th_name_hed
      endif else begin
        if keyword_set(suffix) && suffix[0] ne '' then begin
          copy_data, th_name_hed, th_name_hed +suffix[0]
          del_data, th_name_hed
        endif
      endelse
    endif
  endfor
  
  ;print accumulated error messages now that loading is complete
  if keyword_set(msg_l2) then begin
    msg_out = keyword_set(msg_out) ? [msg_out,msg_l2]:msg_l2
  endif
  if keyword_set(msg_out) then begin
    for i=0, n_elements(msg_out)-1 do begin
      if msg_out[i] ne '' then dprint, dlevel=1, msg_out[i]
    endfor
  endif

end




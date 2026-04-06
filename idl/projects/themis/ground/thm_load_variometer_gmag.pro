;+
;Procedure: THM_LOAD_VARIOMETER_GMAG,
; thm_load_variometer_gmag, site = site, datatype = datatype, trange = trange, $
;                           level = level, verbose = verbose, $
;                           subtract_average = subavg, $
;                           subtract_median = subtract_median, $
;                           varname_out = varname_out, $
;                           subtracted_values = subtracted_values, $
;                           downloadonly = downloadonly, no_download = no_download, $
;                           relpathnames_all = relpathnames_all, $
;                           valid_names = valid_names, $
;                           get_support_data = get_support_data, $
;                           progobj = progobj, files = files, $
;                           suffix=suffix, $
;                           sampling_rate = sampling_rate, $
;                           _extra = _extra
;Keywords:
;  site : station name to load (string,array)--available options include 'all' (default), 
;  anmo casy ccm cola cor dgmt dwpf ecsd eymn e46a e62a goga hrv j47a kbs kevo kono ksu1 
;  k30b k50a mbwa mstx m63a o20a pab p57a qspa rssd r49a sba sfjd spmn sspa s61a t47a 
;  u38b wci whtx wvt 352a
;
;  datatype = The type of data to be loaded, for this case, there is only
;          one option, the default value of 'mag', so this is a
;          placeholder should there be more that one data type. 'all'
;          can be passed in also, to get all variables.
;  TRANGE= (Optional) Time range of interest  (2 element array), if
;          this is not set, the default is to prompt the user. Note
;          that if the input time range is not a full day, a full
;          day's data is loaded
;  level = the level of the data, the default is 'l2', or level-2
;          data. A string (e.g., 'l2') or an integer can be used. 'all'
;          can be passed in also, to get all levels.
;  /VERBOSE : set to output some useful info
;  /SUBTRACT_AVERAGE, if set, then the average values are subtracted
;                     from the loaded variables,
;  /SUBTRACT_MEDIAN, if set, then the median values are subtracted
;                     from the loaded variables,
;  varname_out= a string array containing the tplot variable names for
;               the loaded data, useful for the following keyword:
;  subtracted_values = returns N_elements(varname_out) by 3 array
;                      containing the average or median (or 0) values
;                      subtracted from the data.
;  /downloadonly, if set, then only download the data, do not load it
;                 into variables.
;  no_download: use only files which are online locally.
;  relpathnames_all: named variable in which to return all files that are
;          required for specified timespan, probe, datatype, and level.
;          If present, no files will be downloaded, and no data will be loaded.
;  /valid_names, if set, then this will return the valid site, datatype
;                and/or level options in named variables, for example,
;
;                thm_load_greenland_gmag, site = xxx, /valid_names
;
;                will return the array of valid sites in the
;                variable xxx
; get_support_data = does nothing.  present only for consistency with other
;                load routines
; sampling_rate : variometer sampling rate. Only options are 1 (Hz) and 10 (Hz
;Example:
;   thm_init
;   timespan,'2026-02-24/00:00:00',10,/days
;   get_timespan,trange
;   thm_load_variometer_gmag, site=['s61a','anmo'],sampling_rate=10,trange=trange,/subtract_median
;
; $LastChangedBy: dcarpenter $
; $LastChangedDate: 2026-03-30 16:04:03 -0700 (Mon, 30 Mar 2026) $
; $LastChangedRevision: 34313 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/ground/thm_load_variometer_gmag.pro $
;-
Function thm_load_variometer_gmag_relpath, sname = sname, $
                                          trange = trange, $
                                          addmaster = addmaster, $
                                          version = version, sampling_rate = sampling_rate, _extra = _extra
    if sname.contains('_100ms') then begin
        ; Data is 10 Hz
        snamei=STRSPLIT(sname,'_100ms',/EXTRACT,/REGEX)
        sname_file=sname
    endif else begin
        ; Request may or may not be for 10 Hz data. 
        ; Check if sampling rate has been set
        ; if it has, handle names accordingly
        ; if not, assume 1 Hz 
        if keyword_set(sampling_rate) then begin
            if sampling_rate eq 10 then begin
              sname_file = sname + '_100ms'
            endif else begin
              sname_file = sname
            endelse
        endif else begin
            sname_file = sname
        endelse
        snamei = sname
    endelse
  ; snamei should only be the station name
    
  if ~keyword_set(sampling_rate) then sampling_rate = 1
  
  
  relpath = 'thg/l2/variometers/'+snamei + '/'
  prefix = 'thg_l2_mag_'+sname_file + '_'
  dir = 'YYYY/'
  If(version Eq '') Then Begin
    ending = '.cdf'
  Endif Else ending = '_'+version+'.cdf'
  relpathnames = file_dailynames(relpath, prefix, ending, dir = dir, $
                                 trange = trange, addmaster = addmaster)
  Return, relpathnames
End
  
; processing for subracting average, median, and returning subracted value.
pro thm_load_variometer_gmag_post, sname=sitei, datatype=dtj, $
                                  varcount = varcount, verbose = vb, $
                                  subtract_average = subavg, $
                                  subtract_median = subtract_median, $
                                  varname_out = varname_out, $
                                  subtracted_values = subtracted_values, $
                                  suffix = suffix, sampling_rate = sampling_rate, _extra = _extra

;    varname = 'thg_'+lvlk+'_'+dtj+'_'+sitei
  If(keyword_set(suffix)) Then varname = 'thg_'+dtj+'_'+sitei+suffix $
  Else varname = 'thg_'+dtj+'_'+sitei
  
  if keyword_set(sampling_rate) then begin
    if sampling_rate eq 10 then begin
      If(keyword_set(suffix)) Then varname = 'thg_'+dtj+'_'+sitei+'_100ms'+suffix $
      else varname = 'thg_'+dtj+'_'+sitei+'_100ms'
    endif
    
  endif
;  options, /def, varname, ytitle = sitei, ysubtitle = 'B (nT)', $
;    constant = 0., labels = ['bx', 'by', 'bz'], labflag = 1
  options, /def, varname, ytitle = sitei, ysubtitle = 'B (nT)', $
    constant = 0., labels = ['H', 'D', 'Z'], labflag = 1,colors=[2,4,6]
  if varcount Eq 0 then begin
    varname_out = varname
    subtracted_values = dblarr(1, 3) ;3 field components
    varcount = varcount+1
  endif else begin
    varname_out = [varname_out, varname]
    subtracted_values = [subtracted_values, dblarr(1, 3)]
    varcount = varcount+1
  endelse

  if keyword_set(subavg) Or keyword_set(subtract_median) then begin
    get_data, varname, data = d, alim = alim
    if keyword_set(d) then begin
        lng = struct_value(alim, 'cdf.vatt.station_longitude', default = !values.f_nan)
        lat = struct_value(alim, 'cdf.vatt.station_longitude', default = !values.f_nan)
;Note 'lat' and 'lng' could be used to subtract off a model dipole
;field
        svalue = average(d.y, 1, /double, $
                         ret_median = keyword_set(subtract_median))

        d.y -= (replicate(1, n_elements(d.x)) # svalue ) ; subtract the average value
        subtracted_values[varcount-1, *] = transpose(svalue)
        store_data, varname, data = d
     endif
  endif
   ;add suffient labeling to make identification and transformation of coordinate system possible
  get_data,varname,dlimit=dl
  str_element,dl,'data_att.coord_sys','hdz',/add
  str_element,dl,'data_att.units','nT',/add
  
  str_element,dl,'cdf.vatt.station_latitude',lat,success=s
  if s then begin
    str_element,dl,'data_att.site_latitude',lat,/add
  endif
  
  str_element,dl,'cdf.vatt.station_longitude',lon,success=s
  if s then begin
    str_element,dl,'data_att.site_longitude',lon,/add
  endif
  ; Add label identifying data as USGS (currently this label is not used for anything)
  str_element, dl,'data_att.provider_name','USGS',/add
  
  store_data,varname,dlimit=dl
end

Pro thm_load_variometer_gmag, site = site, datatype = datatype, trange = trange, $
                             level = level, verbose = verbose, $
                             subtract_average = subavg, $
                             subtract_median = subtract_median, $
                             varname_out = varname_out, $
                             subtracted_values = subtracted_values, $
                             downloadonly = downloadonly, no_download = no_download, $
                             relpathnames_all = relpathnames_all, $
                             valid_names = valid_names, $
                             get_support_data = get_support_data, $
                             progobj = progobj, files = files, $
                             suffix=suffix, $
                             sampling_rate = sampling_rate, $
                             _extra = _extra

  if arg_present(relpathnames_all) then begin
     downloadonly=1
     no_download=1
  end

  varcount = 0
  
  if keyword_set(sampling_rate) then begin
      if sampling_rate eq 10 then begin
        varformat = 'thg_mag_'+site+'_100ms'
      endif else begin
        sampling_rate = 1
      endelse
  
;      if sampling_rate eq 10 then begin
;          site_input = site
;          site = site_input + '_100ms'
;          vsnames = 'anmo_100ms casy_100ms ccm_100ms cola_100ms cor_100ms dgmt_100ms dwpf_100ms ecsd_100ms eymn_100ms e46a_100ms e62a_100ms goga_100ms hrv_100ms j47a_100ms kbs_100ms kevo_100ms kono_100ms ksu1_100ms k30b_100ms k50a_100ms mbwa_100ms mstx_100ms m63a_100ms o20a_100ms pab_100ms p57a_100ms qspa_100ms rssd_100ms r49a_100ms sba_100ms sfjd_100ms spmn_100ms sspa_100ms s61a_100ms t47a_100ms u38b_100ms wci_100ms whtx_100ms wvt_100ms 352a_100ms'
;      endif else begin
;          vsnames = 'anmo casy ccm cola cor dgmt dwpf ecsd eymn e46a e62a goga hrv j47a kbs kevo kono ksu1 k30b k50a mbwa mstx m63a o20a pab p57a qspa rssd r49a sba sfjd spmn sspa s61a t47a u38b wci whtx wvt 352a'
;      endelse
  endif else begin
      sampling_rate=1
;      vsnames = 'anmo casy ccm cola cor dgmt dwpf ecsd eymn e46a e62a goga hrv j47a kbs kevo kono ksu1 k30b k50a mbwa mstx m63a o20a pab p57a qspa rssd r49a sba sfjd spmn sspa s61a t47a u38b wci whtx wvt 352a'
  endelse
  vsnames = '154a 352a 456a anmo bouv casy ccm cola cor dgmt dwpf e46a e62a ecsd eymn goga hrv j47a k30b k50a k62a kbs kevo kono ksu1 m63a mbwa midw mstx n51a n53a o20a p57a pab qspa r49a rssd s39b s61a sba sfjd spmn sspa t47a t57a u38b wci whtx wvt x48a y49a' 
  
  thm_load_xxx,sname=site, datatype=datatype, trange=trange, $
               level=level, verbose=verbose, downloadonly=downloadonly, $
               no_download=no_download, relpathnames_all=relpathnames_all, $
               cdf_data=cdf_data,get_cdf_data=arg_present(cdf_data), $
               varnames=varnames, valid_names = valid_names, files=files, $
               vsnames = vsnames, $
               varformat = varformat, $
               type_sname = 'site', $
               vdatatypes = 'mag', $
               get_support_data=get_support_data, $
               vlevels = 'l2', $
               deflevel = 'l2', $
               version = 'v01', $
               post_process_proc = 'thm_load_variometer_gmag_post', $
               subtract_average = subavg, $
               subtract_median = subtract_median, $
               varname_out = varname_out, $
               subtracted_values = subtracted_values, $
               varcount = varcount, $
               progobj = progobj, $
               relpath_funct = 'thm_load_variometer_gmag_relpath', $
               suffix=suffix,$
               sampling_rate=sampling_rate, $
               _extra = _extra

end


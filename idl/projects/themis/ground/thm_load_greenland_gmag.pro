;+
;Procedure: THM_LOAD_GREENLAND_GMAG,
; thm_load_greenland_gmag, site = site, datatype = datatype, trange = trange, $
;                level = level, verbose = verbose, $
;                subtract_average = subtract_average, $
;                subtract_median = subtract_median, $
;                varname_out = varname_out, $
;                subtracted_values = subtracted_values, $
;                downloadonly = downloadonly, $
;                valid_names = valid_names
;keywords:
;  site  = Observatory name, example, thm_load_greenland_gmag, site = 'amk', the
;          default is 'all', i.e., load all available stations . This
;          can be an array of strings, e.g., ['amk', 'atu'] or a
;          single string delimited by spaces, e.g., 'amk atu'. The
;          valid site names for this case are:
;
;          amk and atu bfe bjn dmh dob don fhb gdh ghb hop jck kar kuv lyr
;          nal naq nor nrd roe rvk sco skt sol sor stf svs tdc thl tro umq upn
;
;          These names correspond to gmags at these locations:
;          Ammassalik(Tasiilaq) Andenes Attu Brorfelde Bjornoya Danmarkshavn Dombas Donna Paamiut(Frederickshap) Qeqertarsuaq(Godhavn) Nuuk(Godthap) Hopen Jackvik Karmoy
;          Kullorsuaq Longyearbyen NyAlesund Naqsarsuaq Nordkapp Nord Roemoe Rorvik Ittoqqortoormiit Maniitsoq(SukkerToppen) Solund Soroya
;          Kangerlussuaq(SondreStromFjord) Savissivik TristanDaCunha Qaanaaq(Thule) Tromso Umanaq Upernavik
;          
;          Note that the station 'naq' is the THEMIS GMAG
;            station 'NRSQ'
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
;
;Example:
;   timespan, '2007-06-04',1
;   thm_load_greenland_gmag, site = 'amk'
;
; 19-mar-2007, jmm, chnaged name from thm_load_gmag, to read greenland
;              gmag stations not included in the usual GMAG distribution
; 05-may-2011 lphilpott, updated site lists
; $LastChangedBy: crussell $
; $LastChangedDate: 2017-01-10 09:41:22 -0800 (Tue, 10 Jan 2017) $
; $LastChangedRevision: 22560 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/ground/thm_load_greenland_gmag.pro $
;-
Function thm_load_greenland_gmag_relpath, sname = sname, $
                                          trange = trange, $
                                          addmaster = addmaster, $
                                          version = version, _extra = _extra
  If(keyword_set(sname)) Then snamei = sname Else sname = 'amk'
  relpath = 'thg/greenland_gmag/l2/'+snamei + '/'
  prefix = 'thg_l2_mag_'+snamei + '_'
  dir = 'YYYY/'
  If(version Eq '') Then Begin
    ending = '.cdf'
  Endif Else ending = '_'+version+'.cdf'
  relpathnames = file_dailynames(relpath, prefix, ending, dir = dir, $
                                 trange = trange, addmaster = addmaster)
  Return, relpathnames
End
  
; processing for subracting average, median, and returning subracted value.
pro thm_load_greenland_gmag_post, sname=sitei, datatype=dtj, $
                                  varcount = varcount, verbose = vb, $
                                  subtract_average = subavg, $
                                  subtract_median = subtract_median, $
                                  varname_out = varname_out, $
                                  subtracted_values = subtracted_values, $
                                  suffix = suffix, _extra = _extra

;    varname = 'thg_'+lvlk+'_'+dtj+'_'+sitei
  If(keyword_set(suffix)) Then varname = 'thg_'+dtj+'_'+sitei+suffix $
  Else varname = 'thg_'+dtj+'_'+sitei
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
  
  str_element,dl,'cdf.vatt.station_latitude',lat,success=s
  if s then begin
    str_element,dl,'data_att.site_latitude',lat,/add
  endif
  
  str_element,dl,'cdf.vatt.station_longitude',lon,success=s
  if s then begin
    str_element,dl,'data_att.site_longitude',lon,/add
  endif
  ; Add label identifying data as DTU/TGO (currently this label is not used for anything)
  str_element, dl,'data_att.provider_name','DTU/TGO',/add
  
  store_data,varname,dlimit=dl
end

Pro thm_load_greenland_gmag, site = site, datatype = datatype, trange = trange, $
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
                             suffix=suffix,$
                             _extra = _extra

  if arg_present(relpathnames_all) then begin
     downloadonly=1
     no_download=1
  end

  varcount = 0

  vsnames = 'amk and atu bfe bjn dob dmh dnb don fhb gdh ghb hop hov jan jck kar kuv lyr nal naq nor nrd roe rvk sco skt sol sor stf sum svs tab tdc thl tro umq upn'
  thm_load_xxx,sname=site, datatype=datatype, trange=trange, $
               level=level, verbose=verbose, downloadonly=downloadonly, $
               no_download=no_download, relpathnames_all=relpathnames_all, $
               cdf_data=cdf_data,get_cdf_data=arg_present(cdf_data), $
               varnames=varnames, valid_names = valid_names, files=files, $
               vsnames = vsnames, $
               type_sname = 'site', $
               vdatatypes = 'mag', $
               get_support_data=get_support_data, $
               vlevels = 'l2', $
               deflevel = 'l2', $
               version = 'v01', $
               post_process_proc = 'thm_load_greenland_gmag_post', $
               subtract_average = subavg, $
               subtract_median = subtract_median, $
               varname_out = varname_out, $
               subtracted_values = subtracted_values, $
               varcount = varcount, $
               progobj = progobj, $
               relpath_funct = 'thm_load_greenland_gmag_relpath', $
               suffix=suffix,$
               _extra = _extra

end


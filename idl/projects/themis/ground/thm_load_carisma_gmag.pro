;+
;Procedure: THM_LOAD_CARISMA_GMAG,
; thm_load_carisma_gmag, site = site, datatype = datatype, trange = trange, $
;                level = level, verbose = verbose, $
;                subtract_average = subtract_average, $
;                subtract_median = subtract_median, $
;                varname_out = varname_out, $
;                subtracted_values = subtracted_values, $
;                downloadonly = downloadonly, $
;                valid_names = valid_names
;                
; NOTE: 
; 1. Data from the CARISMA gmag sites loaded by this routine is not mirrored by THEMIS. The data is downloaded
; directly from CARISMA (UAlberta) to the user's computer.
; Users of CARISMA data should be sure to read the Data Policy information at http://themis.ssl.berkeley.edu/roadrules.shtml
; before using this data for publication.
; 
; 2. The data for some sites in the CARISMA network is mirrored by THEMIS: namely Rankin Inlet, Fort Smith, Gillam, Pinawa
; Fort Simpson. Data for these sites is loaded using the standard thm_load_gmag process.
; 
; 
;
;keywords:
;  site  = Observatory name, example, thm_load_carisma_gmag, site = 'daws', the
;          default is 'all', i.e., load all available stations . This
;          can be an array of strings, e.g., ['daws', 'isll'] or a
;          single string delimited by spaces, e.g., 'daws isll'. The
;          valid site names for this case are:
;
;          anna back cont daws eski fchp fchu 
;          gull isll lgrr mcmu mstk norm
;          osak oxfo pols rabb sach talo 
;          thrf vulc weyb wgry 
;
;          These names correspond to gmags at these locations:
;          Ann Arbor, Back Lake, Contwoyto, Dawson City, Eskimo Point, Fort Chipewyan, Fort Churchill, 
;          Gull Lake, Island Lake, Little Grand Rapids, Fort McMurray, Ministik Lake, Norman Wells,
;          Osakis, Oxford House, Polson, Rabbit Lake, Rankin Inlet, Sachs Harbour, Taloyoak,
;          Thief River Falls, Vulcan, Weyburn, Wells Gray.
;          
;          NB: 
;          1. The CARISMA fchu (Fort Churchill) magnetometer is distinct from the CANMOS fcc magnetometer at Fort Churchill.
;          2. The gmag site TALO is a CARISMA site. There is also a THEMIS ASI site TALO.
;          3. Data for some sites may not yet be available.  
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
;          data. A string (e.g., 'l2') or an integer can be used. 
;          (in this case there is only one level of data available)
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
;                thm_load_carisma_gmag, site = xxx, /valid_names
;
;                will return the array of valid sites in the
;                variable xxx
; get_support_data = does nothing.  present only for consistency with other
;                load routines
;
;Example:
;   timespan, '2010-06-04',1
;   thm_load_carisma_gmag, site = 'daws'
;

; $LastChangedBy: egrimes $
; $LastChangedDate: 2014-02-13 12:14:35 -0800 (Thu, 13 Feb 2014) $
; $LastChangedRevision: 14372 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/ground/thm_load_carisma_gmag.pro $
;-
Function thm_load_carisma_gmag_relpath, sname = sname, $
                                        trange = trange, $
                                        addmaster = addmaster, $
                                        version = version, _extra = _extra
  If(keyword_set(sname)) Then snamei = sname Else sname = 'daws'
  relpath = ''
  prefix = 'thg_l2_mag_'+snamei + '_'
  dir = 'YYYY/MM/DD/'
  If(version Eq '') Then Begin
    ending = '.cdf'
  Endif Else ending = '_'+version+'.cdf'
  relpathnames = file_dailynames(relpath, prefix, ending, dir = dir, $
                                 trange = trange, addmaster = addmaster)
  Return, relpathnames
End
  
; processing for subracting average, median, and returning subracted value.
pro thm_load_carisma_gmag_post, sname=sitei, datatype=dtj, $
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
  options, /def, varname, ytitle = 'CARISMA_'+sitei, ysubtitle = 'B (nT)', $
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
  ; Add label identifying data as CARISMA
  str_element, dl,'data_att.provider_name','CARISMA',/add
  
  store_data,varname,dlimit=dl
end

Pro thm_load_carisma_gmag, site = site, datatype = datatype, trange = trange, $
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

  ; if this list of valid names changes, please also update version in thm_load_gmag
  vsnames = 'anna back cont daws eski fchp fchu gull isll lgrr mcmu mstk norm osak '+$
            'oxfo pols rabb sach talo thrf vulc weyb wgry'
;'cdrt crvr gjoa iglo nain pang rbay';  

  ; set up alternative load params (set the remote directory to the CARISMA location)
  thm_init
  alternate_load_params=!themis
  ;alternate_load_params.remote_data_dir = 'http://magneto.physics.ualberta.ca/themis_carisma_cdf/'
  alternate_load_params.remote_data_dir = 'http://www.carisma.ca/themis_carisma_cdf/'
  ;alternate_load_params.remote_data_dir = 'http://bluebird.physics.ualberta.ca/carisma/themis_carisma_cdf/'
  alternate_load_params.local_data_dir = !themis.local_data_dir+'thg/CARISMA/'; this allows files to be clearly identified on user's computer as belonging to CARISMA
  
     ; print out acknowledgement - wording needs to be checked with CARISMA
    dprint, '**********************************************************************************', dlevel=2
    dprint, 'Data for sites: ',dlevel=2
    dprint, vsnames,dlevel=2
    dprint, 'is provided by CARISMA.',dlevel=2
    dprint, 'CARISMA is operated by the University of Alberta, funded by the Canadian Space Agency.',dlevel=2
    dprint, 'Please see data use requirements at http://www.carisma.ca/carisma-data/data-use-requirements', dlevel=2
    dprint, 'NOTE: Not all data sets are complete.'
    dprint, '**********************************************************************************', dlevel=2
  
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
               post_process_proc = 'thm_load_carisma_gmag_post', $
               subtract_average = subavg, $
               subtract_median = subtract_median, $
               varname_out = varname_out, $
               subtracted_values = subtracted_values, $
               varcount = varcount, $
               progobj = progobj, $
               relpath_funct = 'thm_load_carisma_gmag_relpath', $
               suffix=suffix,$
               alternate_load_params=alternate_load_params,$
               _extra = _extra

end


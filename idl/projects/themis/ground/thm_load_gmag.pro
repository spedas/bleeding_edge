;+
;Procedure: THM_LOAD_GMAG,
; thm_load_gmag, site = site, datatype = datatype, trange = trange, $
;                level = level, verbose = verbose, $
;                subtract_average = subtract_average, $
;                subtract_median = subtract_median, $
;                varname_out = varname_out, $
;                subtracted_values = subtracted_values, $
;                downloadonly = downloadonly, $
;                valid_names = valid_names
;keywords:
;  site  = Observatory name, example, thm_load_gmag, site = 'bmls', the
;          default is 'all', i.e., load all available stations . This
;          can be an array of strings, e.g., ['bmls', 'ccmv'] or a
;          single string delimited by spaces, e.g., 'bmls ccnv'
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
;0
;                thm_load_gmag, site = xxx, /valid_names
;
;                will return the array of valid sites in the
;                variable xxx
;                Valid names will be returned sorted by network unless the keyword /sort_by_alpha
;                is set in which case the sites will be alphabetized
; /sort_by_alpha = Set this keyword to return the list of valid names sorted alphabetically rather
;                  than by network                
; get_support_data = does nothing.  present only for consistency with other
;                load routines
;       
; /thm_sites = Set this keyword to load magnetometer from the THEMIS GBO network
; 
; /tgo_sites = Set this keyword to load magnetometers from the TGO magnetometer network(Courtesy of DTU, Norway)
; 
; /dtu_sites = Set this keyword to load magnetometers from the DTU magnetometer network
; (note that this keyword does not currently load (dnb, nrd) as only old uncalibrated data is available)
; /ua_sites = Set this keyword to load magnetometers from the University of Alaska magnetometer network.
; 
; /maccs_sites = Set this keyword to load magnetometers from the MACCS network.
; 
; /usgs_sites = Set this keyword to load magnetometers from the USGS network.
;
; /atha_sites = Set this keyword to load magnetometers from the U Athabasca or AUTUMN network.
; 
; /epo_sites = Set this keyword to load magnetometers that are EPO sites
;
; /falcon_sites = Set this keyword to load magnetometers that are Falcon netword sites
;
; /carisma_sites = Set this keyword to load magnetometers that are carisma sites
;
; /mcmac_sites = Set this keyword to load magnetometers that are mcmac sites
;
; /nrcan_sites = Set this keyword to load magnetometers that are nrcan sites
;
; /step_sites = Set this keyword to load magnetometers that are STEP sites
;
; /fmi_sites = Set this keyword to load magnetometers that are FMI sites
; 
; /aari_sites = Set this keyword to load magnetometers that are AARI sites
; 
; /bas_sites = Set this keyword to load magnetometers that are BAS sites
; 
; /magstar_sites = Set this keyword to load magnetometers that are MagStar sites
;
;Example:
;   thm_load_gmag, site = 'bmls', trange =
;   ['2007-01-22/00:00:00','2007-01-24/00:00:00']
;
; WARNING:  As with all GMAG data, users should be careful to verify data units and coordinate
;           systems, as calibrations can drift from true values over time.  Users should be particularly
;           careful with the older data from the DMI/DTU network.
;
;Written by: Davin Larson,   Dec 2006
; 22-jan-2007, jmm, jimm@ssl.berkeley.edu rewrote argument list, added
; keywords,
; 1-feb-2007, jmm, added subtract_median, subtracted_value keywords
; 19-mar-2007, jmm, fixed the station list...
; 1-may-2009, jmm, removed greenland_data keyword, the greenland
;                  stations are now valid site names
; 3-jun-2009, jmm, added stations cdrt, crvr, gjoa, rbay, pang, tbdl
;                  MACCS data from Augsburg
; 1-Jan-2011, prc, Extended support for DTU gmag provider. (DTU & TGO networks) Detailed info on sites is here: http://flux.phys.uit.no/geomag.html
; 7-Jan-2011, prc, Added site selection keywords for MACCS and University of Alaska. 
; 6-May-2011, lphilpott, Updated site lists for DTU and TGO ('greenland') networks and added a warning about uncalibrated data.
; 20_Aug-2012, clrussell, Added new USGS sites and new site VLDR to list of valid sites
; 11-Sep-2012, clrussell, Added site network keywords for UAthabasca (AUTUMN) and USGS and EPO
; 24-Sep-2012, clrussell, Added new keyword /sort_by_alpha which will return the list of valid stations sorted by order 
;                         rather than by network.
; 04-Apr-2012, clrussell, Added units to the data_att structure
; 
; $LastChangedBy: crussell $
; $LastChangedDate: 2024-02-23 05:59:59 -0800 (Fri, 23 Feb 2024) $
; $LastChangedRevision: 32454 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/ground/thm_load_gmag.pro $
;-

; processing for subracting average, median, and returning subracted value.
pro thm_load_gmag_post, sname=sitei, datatype=dtj, $
                        varcount = varcount, verbose = vb, $
                        subtract_average = subavg, $
                        subtract_median = subtract_median, $
                        varname_out = varname_out, $
                        subtracted_values = subtracted_values, $
                        suffix = suffix, _extra = _extra

;    varname = 'thg_'+lvlk+'_'+dtj+'_'+sitei
  If(keyword_set(suffix)) Then varname = 'thg_'+dtj+'_'+sitei+suffix $
  Else varname = 'thg_'+dtj+'_'+sitei
  ; sites are now being rotated to local magnetic coordinates (April 2012)
;  xyzsite = ['abk','fcc','ykc'];sites with geographic xyz data rather than THEMIS geomag HDZ
;  xyzvar = where(xyzsite eq sitei, count)
;  if count gt 0 then begin
;    options, /def, varname, ytitle = sitei,ysubtitle='B (nT)', $
;           constant = 0.,labels=['X','Y','Z'],labflag=1,colors=[2,4,6]
;  endif else

  ;AARI stations provide only the variation in the field
  ; components are labelled as dH dD dZ so that this is clear to user
  variation_site = ['amd','bbg','brn','dik','loz','pbk','tik','viz'];AARI stations provide only the variation in the field
  var = where(variation_site eq sitei, count)
  if count gt 0 then begin
    options, /def, varname, ytitle = sitei,ysubtitle='B (nT)', $
           constant = 0.,labels=['dH','dD','dZ'],labflag=1,colors=[2,4,6]
  endif else options, /def, varname, ytitle = sitei,ysubtitle='B (nT)', $
           constant = 0.,labels=['H','D','Z'],labflag=1,colors=[2,4,6]
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
  
  store_data,varname,dlimit=dl

end

Pro thm_load_gmag, site = site, datatype = datatype, trange = trange, $
                   level = level, verbose = verbose, $
                   subtract_average = subavg, $
                   subtract_median = subtract_median, $
                   varname_out = varname_out, $
                   subtracted_values = subtracted_values, $
                   downloadonly = downloadonly, no_download=no_download, $
                   relpathnames_all=relpathnames_all, $
                   valid_names = valid_names, $
                   sort_by_alpha = sort_by_alpha, $
                   get_support_data=get_support_data, $
                   progobj = progobj, files=files, $
                   thm_only = thm_only, $
                   thm_sites= thm_sites, $
                   tgo_sites = tgo_sites, $
                   dtu_sites = dtu_sites, $
                   ua_sites = ua_sites, $
                   maccs_sites = maccs_sites, $
                   usgs_sites = usgs_sites, $
                   atha_sites = atha_sites, $
                   epo_sites = epo_sites, $
                   falcon_sites = falcon_sites, $
                   mcmac_sites = mcmac_sites, $
                   nrcan_sites = nrcan_sites, $
                   step_sites = step_sites, $
                   fmi_sites = fmi_sites, $
                   aari_sites = aari_sites, $
                   bas_sites = bas_sites, $
                   magstar_sites = magstar_sites, $
                   suffix=suffix
;                   _extra = _extra ;krb 5/4

;figure out sites here
  If(keyword_set(thm_only)) Then Begin
    vsnames = 'atha chbg ekat fsim fsmi fykn gbay glyn '+$
              'gill inuv kapu kian kuuj mcgr nrsq pgeo '+$
              'pina rank snap snkq tpas whit yknf'
    vsnames_arr = strsplit(vsnames, ' ', /extract)
    vsnames_all = vsnames_arr
    vsnames_g_arr = ''
    If(is_string(site)) Then Begin
      dprint, 'Use of site keyword is incompatible with /thm_only keyword, setting site to ALL'
      site = 'all'
    Endif
  Endif else begin
    vsnames = 'abk akul amd amer arct atha bbg benn bett blc bmls bou brn brw bsl cbb ccnv cdrt chbr chbg cigo cmo col crvr dat dbo dct ded dhe '+ $
       'dik drby dma dme dmo doh dsh dtx dva eagl ekat fcc frd frn fsim fsj fsmi ftn fykn '+ $
      'fyts gako gbay gill gjoa glyn gua han hlms homr hon hots hris hrp iglo inuk inuv iqa iva kako kapu kena kev kian kil kjpk kodk '+ $
      'kuuj larg lcl leth loys loz lrel lrg lrv lyfd mas mcgr mea mek nain new muo nrsq nur '+ $
      'ott ouj pang pbk pblo pcel pel pg0 pg1 pg2 pg3 pg4 pg5 pgeo pina pine pks pokr ptrs puvr radi ran rank rbay redr rich rmus roth salu satx schf sept shu sit sjg snap snkq stfd stfl stj '+ $
      'swno tar tik tpas trap tuc ukia vic viz vldr whit whs wlps wrth ykc yknf'
    vsnames_arr = strsplit(vsnames, ' ', /extract)
    vsnames_g =  'amk and atu bfe bjn dob dmh dnb don fhb gdh ghb hop hov jan jck kar kuv lyr nal naq nor nrd roe rvk sco skt sol sor stf sum svs tab tdc thl tro umq upn'
    vsnames_g_arr = strsplit(vsnames_g, ' ', /extract)
    vsnames_c = 'anna back cont daws eski fchp fchu gull isll lgrr mcmu mstk norm osak '+$
            'oxfo pols rabb sach talo thrf vulc weyb wgry'
    vsnames_c_arr = strsplit(vsnames_c, ' ', /extract)
    vsnames_b = 'M65-297 M66-294 M67-292 M78-337 M79-336 M81-003 M81-338 ' + $
      'M83-347 M83-348 M84-336 M85-002 M85-096 M87-028 M87-068 M88-316'
    vsnames_m = 'col dat dbo dct dhe dma dme dmo doh dsh dtx dva'
    vsnames_m_arr = strsplit(vsnames_m, ' ', /extract)
;    'M65-279 M67_292 M70_039 M72_078 M77_077 M78_337 M79_336 M80_077 '+ $
;      'M81_338 M83_348 M84_336 M85_002 M87_028 M87_068 M88_316 M73_159 '+ $
;      'M74_043 M81_003 M83_347 M85_096 M66_294 M68_041 M69_041 M70_044 '+ $
;      'M77_040 M65-297'
    vsnames_b_arr = strsplit(vsnames_b, ' ', /extract)
    vsnames_b_arr_low = strlowcase(vsnames_b_arr)
    vsnames_all = [vsnames_arr, vsnames_g_arr, vsnames_c_arr, vsnames_b_arr_low, vsnames_m_arr]
  Endelse
  
  If(keyword_set(site)) Then site_in = site 

  if n_elements(site_in) eq 1 then begin
    site_in = strsplit(site_in,' ',/extract)
  endif

  if keyword_set(thm_sites) then begin
    site_in = array_concat(strsplit('atha chbg ekat fsim fsmi fykn gbay '+$
                                 'gill inuv kapu kian kuuj mcgr nrsq pgeo '+$
                                 'pina rank snap snkq tpas whit yknf',' ',/extract),site_in)
  endif

;  
  if ~keyword_set(thm_only) then begin
    if keyword_set(tgo_sites) then begin 
      site_in =  array_concat(['nal','lyr','hop','bjn','nor','sor','tro','and','don','rvk','sol','kar', 'jan', 'jck', 'dob'],site_in)
    endif 
  
    if keyword_set(dtu_sites) then begin; dnb (not operational), nrd currently excluded because only old uncalibrated DMI data is available (atu, dmh, svs added back in in 2012)
      site_in = array_concat(['atu','dmh','svs','tdc','bfe','roe','thl','kuv','upn','umq','gdh','stf','skt','ghb','fhb','naq','amk','sco', 'tab', 'sum', 'hov'],site_in)
    endif

    if keyword_set(ua_sites) then begin
      site_in = array_concat(['arct','bett','cigo','eagl','fykn','gako','hlms','homr','kako','pokr','trap'],site_in)
    endif 
    
    if keyword_set(maccs_sites) then begin
      site_in = array_concat(['cdrt','chbr','crvr','gjoa','iglo','nain','pang','rbay'],site_in)
    endif 
 
    if keyword_set(usgs_sites) then begin
      site_in = array_concat(['bou','brw','bsl','cmo','ded','frd','frn','gua','hon','new','shu','sit','sjg','tuc'],site_in)
    endif 

    if keyword_set(atha_sites) then begin
      site_in = array_concat(['roth', 'leth', 'redr', 'larg', 'vldr', 'salu', 'akul', 'puvr', 'inuk', 'kjpk', 'radi', 'stfl', 'sept', 'schf'],site_in)
    endif 

    if keyword_set(epo_sites) then begin
      site_in = array_concat(['bmls','ccnv','drby','fyts','hots','loys','pgeo','pine','ptrs','rmus','swno','ukia'],site_in)
    endif 

    if keyword_set(falcon_sites) then begin
      site_in = array_concat(['hris', 'kodk', 'lrel', 'pblo', 'stfd', 'wlps'],site_in)
    endif

    if keyword_set(mcmac_sites) then begin
      site_in = array_concat(['amer', 'benn', 'glyn', 'lyfd', 'pcel', 'rich', 'satx', 'wrth'],site_in)
    endif 

    if keyword_set(nrcan_sites) then begin
      site_in = array_concat(['blc', 'cbb', 'iqa', 'mea', 'ott', 'stj', 'vic'],site_in)
    endif 
    
    if keyword_set(step_sites) then begin
      site_in = array_concat(['fsj', 'ftn', 'hrp', 'lcl', 'lrg', 'pks', 'whs'],site_in)
    endif 
    
    if keyword_set(fmi_sites) then begin
      site_in = array_concat(['han', 'iva', 'kev', 'kil', 'mas', 'mek', 'muo', 'nur', 'ouj', 'pel', 'ran', 'tar'],site_in)
    endif

    if keyword_set(aair_sites) then begin
      site_in = array_concat(['amd','bbg','brn','dik','loz','pbk','tik','viz'],site_in)
    endif
    
    if keyword_set(bas_sites) then begin
      site_in = array_concat(['M65-297','M66-294','M67-292','M78-337','M79-336','M81-003','M81-338', $
        'M83-347','M83-348','M84-336','M85-002','M85-096','M87-028','M87-068','M88-316'],site_in)
;        'M65_279','M67_292','M70_039','M72_078','M77_077','M78_337', $
;        'M79_336','M80_077','M81_338','M83_348','M84_336','M85_002','M87_028','M87_068', $
;        'M88_316','M73_159','M74_043','M81_003','M83_347','M85_096','M66_294','M68_041', $
;        'M69_041','M70_044','M77_040','M65-297'],site_in)
    endif

    if keyword_set(magstart_sites) then begin
      site_in = array_concat(['col','dat','dbo','dct','dhe','dma','dme','dmo','doh','dsh','dtx','dva'],site_in)
    endif

  ; if this list of valid names changes, please also update version in thm_load_gmag
    if keyword_set(carisma_sites) then begin
       site_in = array_concat(['anna', 'back', 'cont', 'daws', 'eski', 'fchp', 'fchu', $
                 'gull', 'isll', 'lgrr', 'mcmu', 'mstk', 'norm', 'osak', 'oxfo', $
                 'pols', 'rabb', 'sach', 'talo', 'thrf', 'vulc', 'weyb', 'wgry'],site_in)
    endif      
  
  endif
  
  if ~keyword_set(site_in) then begin
    site_in = 'all'
  endif

  thm_sites = ssl_check_valid_name(site_in, vsnames_arr, /ignore_case, /include_all, /no_warning)
  green_sites = ssl_check_valid_name(site_in, vsnames_g_arr, /ignore_case, /include_all, /no_warning)
  crsm_sites = ssl_check_valid_name(site_in, vsnames_c_arr, /ignore_case, /include_all, /no_warning)
  bas_sites = ssl_check_valid_name(site_in, vsnames_b_arr, /ignore_case, /include_all, /no_warning)
  bas_sites=strupcase(bas_sites)
  magstar_sites = ssl_check_valid_name(site_in, vsnames_m_arr, /ignore_case, /include_all, /no_warning)
 
  ; If no sites are valid issue a warning to the user
  ; Not using the default warning issued by ssl_check_valid_name above because that step needs to check green and thm sites separately
  ; We don't want to issue a warning unless site is neither thm nor green.
  ; Check should be performed anyway in order to notify the user of partially invalid input later.
  sites_found = is_string(crsm_sites) || is_string(green_sites) || is_string(thm_sites) || is_string(bas_sites)
  tempallsites = ssl_check_valid_name(site_in, vsnames_all[sort(vsnames_all)],/ignore_case, $
                           /include_all, invalid=msg_site, type='site name', no_warning=sites_found)

  If(keyword_set(valid_names)) Then Begin ;need to handle valid_names here too, jmm, 4-may-2009
    thm_load_greenland_gmag, site = gsites, datatype = datatype, $
      level = level, suffix=suffix, /valid_names
    thm_load_carisma_gmag, site = csites, datatype = datatype, $
      level = level, suffix=suffix, /valid_names 
;    thm_load_bas_gmag, site = strupcase(bsites), /valid_names
    thm_load_bas_gmag, site = bsites, /valid_names
    thm_load_xxx, sname = tsites, datatype = datatype, $
      level = level, /valid_names, vsnames = vsnames, $
      type_sname = 'site', $
      vdatatypes = 'mag', $
      vlevels = 'l2', $
      suffix=suffix,$
      deflevel = 'l2'
      site = [csites, gsites, tsites, bsites]
    If (keyword_set(sort_by_alpha)) Then site=strlowcase(strcompress(site[sort(site)], /remove_all))
    Return
  Endif

  If(is_string(green_sites)) Then Begin ;go to greenland_gmag for these
    ;Issue warning if user is loading potentially uncalibrated data
    ; lphilpott 2-mar-2012
    ; There is still some confusion over data from the DTU and TGO sites. Current data is downloaded in 'XYZ(2)' format,
    ; this should be geomag XYZ similar to THEMIS gmag sites, but from the values it appears to be the variation in field rather absolute values.
    ; At this point I think users should be warned to take care with all DTU and TGO data.
    ; This will be revised in the future when more is known about the data or the data is downloaded in a different form.
    ;uncal_site =['amk','atu','dmh','dnb','gdh','kuv','naq','nrd','sco','skt','svs','thl','umq','upn']
    ;matching_sites = strfilter(green_sites,uncal_site, count=count)
    ;if(count gt 0) then begin
    dprint, 'Care should be taken with data from sites in the DTU or TGO networks as this data may be uncalibrated.', dlevel=2
    ;endif
    If(keyword_set(relpathnames_all)) Then Begin ;this is a mess...
      thm_load_greenland_gmag, site = green_sites, datatype = datatype, trange = trange, $
        level = level, verbose = verbose, subtract_average = subavg, $
        subtract_median = subtract_median, varname_out = varname_out, $
        subtracted_values = subtracted_values, downloadonly = downloadonly, $
        no_download = no_download, relpathnames_all = relpathnames_all, $
        valid_names = valid_names, get_support_data = get_support_data, $
        progobj = progobj, files = files, suffix=suffix
    Endif Else Begin
      thm_load_greenland_gmag, site = green_sites, datatype = datatype, trange = trange, $
        level = level, verbose = verbose, subtract_average = subavg, $
        subtract_median = subtract_median, varname_out = varname_out, $
        subtracted_values = subtracted_values, downloadonly = downloadonly, $
        no_download = no_download, valid_names = valid_names, $
        get_support_data = get_support_data, progobj = progobj, files = files, suffix=suffix
    Endelse
  Endif

  If(is_string(crsm_sites)) Then Begin 
    If(keyword_set(relpathnames_all)) Then Begin ;this is a mess...
      thm_load_carisma_gmag, site = crsm_sites, datatype = datatype, trange = trange, $
        level = level, verbose = verbose, subtract_average = subavg, $
        subtract_median = subtract_median, varname_out = varname_out, $
        subtracted_values = subtracted_values, downloadonly = downloadonly, $
        no_download = no_download, relpathnames_all = relpathnames_all, $
        valid_names = valid_names, get_support_data = get_support_data, $
        progobj = progobj, files = files, suffix=suffix
    Endif Else Begin
      thm_load_carisma_gmag, site = crsm_sites, datatype = datatype, trange = trange, $
        level = level, verbose = verbose, subtract_average = subavg, $
        subtract_median = subtract_median, varname_out = varname_out, $
        subtracted_values = subtracted_values, downloadonly = downloadonly, $
        no_download = no_download, valid_names = valid_names, $
        get_support_data = get_support_data, progobj = progobj, files = files, suffix=suffix
    Endelse
  Endif

  If(is_string(bas_sites)) Then Begin
      thm_load_bas_gmag, site=bas_sites, trange=trange, no_download=no_download, suffix=suffix, $
                         files=files                    
  Endif

  If(is_string(thm_sites)) Then Begin
    if arg_present(relpathnames_all) then begin
      downloadonly = 1
      no_download = 1
    end
    varcount = 0
    thm_load_xxx, sname = thm_sites, datatype = datatype, trange = trange, $
      level = level, verbose = verbose, downloadonly = downloadonly, $
      no_download = no_download, relpathnames_all = relpathnames_all, $
      cdf_data = cdf_data, get_cdf_data = arg_present(cdf_data), $
      varnames = varnames, valid_names = valid_names, files = files, $
      vsnames = vsnames, $
      type_sname = 'site', $
      vdatatypes = 'mag', $
      get_support_data = get_support_data, $
      vlevels = 'l2', $
      deflevel = 'l2', $
      version = 'v01', $
      post_process_proc = 'thm_load_gmag_post', $
      subtract_average = subavg, $
      subtract_median = subtract_median, $
      varname_out = varname_out, $
      subtracted_values = subtracted_values, $
      varcount = varcount, $
      progobj = progobj, $
      suffix=suffix,$
      _extra = _extra
  Endif
  
  ;print accumulated error messages now that loading is complete
  if keyword_set(msg_site) && sites_found then begin
    for i=0, n_elements(msg_site)-1 do begin
      if msg_site[i] ne '' then dprint, dlevel=1, msg_site[i]
    endfor
  endif
  
end

;+
;Procedure: THM_LOAD_SLP,
; thm_load_slp, datatype = datatype, trange = trange, $
;                verbose = verbose, $
;                varname_out = varname_out, $
;                downloadonly = downloadonly, $
;                no_download=no_download,
;                relpathnames_all=relpathnames_all,$
;                files=files,$
;                valid_names = valid_names,$
;                suffix=suffix
;                
;Purpose:
;  Loads Solar and Lunar Ephemeris data from a CDF.  
;  
;  1. Data is generated using the JPL SPICE/ICY library.  Extensive documentation
;  can be found on the SPICE/ICY website:
;  http://naif.jpl.nasa.gov/pub/naif/toolkit_docs/IDL/req/index.html
;  
;  2. All quantities are in GEI coordinates. GEI Epoch is True of Date(this 
;  is the THEMIS standard).
;  
;  3. All data have abberational corrections for light time and stellar abberation.
;  Thus the data represent the state of the Moon and the Sun as they would be
;  observed on earth at a particular time. A more detailed discussion of this topic 
;  can be found in the SPICE/ICY 'SPK' required reading document. The SPICE/ICY 
;  abberation used is called 'LT+S'.
;  
;  4. GEI True of Date are not built into SPICE/ICY.  A custom kernel is used when
;  generating these data that accounts for earth precession using the IAU_1976 
;  precessional model and accounts for earth nutation using the IAU_1980 nutational
;  model which are built into SPICE/ICY.
;  
;  The quantities returned and their descriptions follow.
;  
;  1. slp_sun_pos:    Sun position X,Y,Z in km.
;    
;  2. slp_sun_vel:    Sun velocity X,Y,Z in km/sec.
;  
;  3. slp_sun_att_x:  IAU_SUN coordinate system X-axis(X,Y,Z).  (unitless/normalized)
;                     A. This axis lies in the Solar equatorial plane and the plane containing the Solar prime meridian   
;                     B. This axis points towards a fixed point on the solar surface and rotates with the sun.
;                     C. This axis rotates with sidereal rotation period of the sun.~24.47 days.
;                     D. This quantity created by rotation the basis vector [1,0,0] from IAU_SUN
;                     into GEI coordinate orientation. 
;                     E.  While this quantity is oriented relative to the GEI coordinate system, it is not technically earth centered.  Only
;                     the rotational component of the transformation is performed, not the translation into earth-center.      
;                     F.  slp_sun_att_z and slp_sun_att_x are orthognal axes, thus
;                     slp_sun_att_y = slp_sun_att_z x slp_sun_att_x, and this set of axes can be used to 
;                     transform between GEI and IAU_SUN coordinates 
;                    
;  4. slp_sun_att_z:  IAU_SUN coordinate system Z-axis(X,Y,Z). (unitless/normalized)
;                     A.  This axis points in the direction of the mean rotational axis of the sun.
;                     B. This quantity created by rotation the basis vector [0,0,1] from IAU_SUN
;                     into GEI coordinate orientation. 
;                     C. While this quantity is oriented relative to the GEI coordinate system, it is not technically earth centered.  Only
;                     the rotational component of the transformation is performed, not the translation into earth-center.     
;                     D.  slp_sun_att_z and slp_sun_att_x are orthognal axes, thus
;                     slp_sun_att_y = slp_sun_att_z x slp_sun_att_x, and this set of axes can be used to 
;                     transform between GEI and IAU_SUN coordinates 
;                      
;  5. slp_sun_ltime:  The time, in seconds, it takes for light to travel from the sun to the earth at the time of observation..
;                     To translate data from light corrected to uncorrected data subtract these corrections from the data times.
;                    
;  6. slp_lun_pos:    Lunar position X,Y,Z in km.
;  
;  7. slp_lun_pos:    Lunar velocity X,Y,Z in km/s.
;  
;  8. slp_lun_att_x:  IAU_MOON coordinate system X-axis (X,Y,Z)
;                     A.  This axis lies in the Lunar equatorial plane and the plane containing the Lunar prime meridian
;                     B.  This axis points towards a fixed point on the moon's surface and rotates with the moon.
;                     C.  This quantity created by rotation the basis vector [0,0,1] from IAU_MOON
;                     into GEI coordinate orientation..  
;                     D.  While this quantity is oriented relative to the GEI coordinate system, it is not technically earth centered.  Only
;                     the rotational component of the transformation is performed, not the translation into earth-center. 
;                     E.  slp_lun_att_z and slp_lun_att_x are orthognal axes, thus
;                     slp_lun_att_y = slp_lun_att_z x slp_lun_att_x, and this set of axes can be used to 
;                     transform between GEI and IAU_SUN coordinates 
;  9. slp_lun_att_z:  IAU_MOON coordinate system Z-axis(X,Y,Z). (unitless/normalized)
;                     A.  This axis points in the direction of the mean rotational axis of the moon.
;                     B.  This quantity created by rotation the basis vector [0,0,1] from IAU_MOON
;                     into GEI coordinates. 
;                     C. While This quantity is in GEI coordinates, it is not technically earth centered.  Only
;                     the rotational component of the transformation is performed, not the translation into earth-center.   
;                     D.  slp_lun_att_z and slp_;un_att_x are orthognal axes, thus
;                     slp_lun_att_y = slp_lun_att_z x slp_lun_att_x, and this set of axes can be used to 
;                     transform between GEI and IAU_MOON coordinates. 
; 10. slp_lun_ltime:  The time, in seconds, it takes for light to travel from the moon to the earth at the time of observation.
;                     To translate data from light corrected to uncorrected data subtract these corrections from the data times.
;  
;keywords:
;  datatype = The type of data to be loaded.  Allowed values are:
;           'sun_pos','sun_vel','sun_att_x','sun_att_z','sun_ltime',
;           'lun_pos','lun_vel','lun_att_x','lun_att_z','lun_ltime'
;  TRANGE= (Optional) Time range of interest  (2 element array), if
;          this is not set, the default is to prompt the user. Note
;          that if the input time range is not a full day, a full
;          day's data is loaded
;   level = ignored, only one level for this datatype: L1
;  /VERBOSE : set to output some useful info
;  varname_out= a string array containing the tplot variable names for
;               the loaded data
;  /downloadonly, if set, then only download the data, do not load it
;                 into variables.
;  /no_download: use only files which are online locally.
;  relpathnames_all: named variable in which to return all files that are
;          required for specified timespan, probe, datatype, and level.
;          If present, no files will be downloaded, and no data will be loaded.
;  files   named varible for output of pathnames of local files.
;  /valid_names, if set, then this will return the valid site, datatype
;                and/or level options in named variables, for example,
;                thm_load_gmag, site = xxx, /valid_names
;                will return the array of valid sites in the
;                variable xxx
;  suffix= suffix to add to output data quantity (not added to support data)

;Examples:
;   timespan,'2007-03-23'
;   thm_load_slp
;   thm_load_slp,datatype='sun_pos',trange=['2007-01-22/00:00:00','2007-01-24/00:00:00']
;
; $LastChangedBy: aaflores $
; $LastChangedDate: 2015-05-08 18:56:06 -0700 (Fri, 08 May 2015) $
; $LastChangedRevision: 17543 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/state/thm_load_slp.pro $
;-
function thm_load_slp_relpath,trange=trange

  compile_opt idl2,hidden

  relpath = 'slp/l1/eph/'
  prefix = 'slp_l1_eph_'
  ending = '_v01.cdf'
  return,file_dailynames(relpath,prefix,ending,/yeardir,trange=trange)

end

pro thm_load_slp,datatype = datatype, trange = trange, $
                verbose = verbose, $
                varname_out = tplotnames, $
                downloadonly = downloadonly, $
                no_download=no_download,$
                level=level,$
                relpathnames_all=relpathnames_all,$
                files=files,$
                valid_names = valid_names,$
                suffix=suffix

  compile_opt idl2
                
  thm_init
                
  if arg_present(relpathnames_all) then begin
     downloadonly=1
     no_download=1
  end
  
  if ~keyword_set(suffix) then suffix = ''
    
  vdatatypes = ['sun_pos','sun_vel','sun_att_x','sun_att_z','sun_ltime',$
                'lun_pos','lun_vel','lun_att_x','lun_att_z','lun_ltime']
               
  vlevels = 'l1'
  
  if keyword_set(valid_names) then begin
    datatype = vdatatypes
    level = vlevels
    return
  endif
  
  if ~keyword_set(datatype) then begin
    datatype = 'all'
  endif
  
  dt = strlowcase(ssl_check_valid_name(datatype,vdatatypes,/include_all,/ignore_case))
  
  if ~keyword_set(dt) then return
  
  relpathnames_all = thm_load_slp_relpath(trange=trange) 
  
  if arg_present(relpathnames_all) then begin
    return
  endif
  
  names = 'slp_'+dt
  
  params = !themis

  if n_elements(no_download) gt 0 then begin
    params.no_download = no_download
  endif
  
  if n_elements(downloadonly) gt 0 then begin
    params.downloadonly = downloadonly
  endif
  
  if n_elements(verbose) gt 0 then begin
    params.verbose = verbose
  endif
  
  files = spd_download(remote_file=relpathnames_all,_extra=params)

  if ~params.downloadonly then begin
    cdf2tplot,file=files,verbose=params.verbose,tplotnames=tplotnames,varformat=names,suffix=suffix
  
    if ~is_string(tplotnames) then begin
      dprint, dlevel=1, 'Error loading CDF; verify file is present'
      return
    endif

    for i = 0,n_elements(tplotnames)-1 do begin
      if n_elements(trange) EQ 0 then trange = timerange(/current)
      ;clip data to requested interval
      time_clip, tplotnames[i], min(trange), max(trange), /replace, error = tr_err
      if tr_err then begin 
        del_data, tplotnames[i]
        continue
      endif
      
      get_data,tplotnames[i],dlimit=dl
      if stregex(tplotnames[i],'^slp_sun_pos',/boolean) ||$
         stregex(tplotnames[i],'^slp_lun_pos',/boolean) then begin
         str_element,dl,'data_att.units','km',/add
         str_element,dl,'data_att.coord_sys','gei',/add
         str_element,dl,'data_att.st_type','pos',/add  
      endif else if stregex(tplotnames[i],'^slp_sun_vel',/boolean) ||$
                    stregex(tplotnames[i],'^slp_lun_vel',/boolean) then begin
         str_element,dl,'data_att.units','km/s',/add
         str_element,dl,'data_att.coord_sys','gei',/add
         str_element,dl,'data_att.st_type','vel',/add
      endif else if stregex(tplotnames[i],'^slp_sun_att',/boolean) ||$
                    stregex(tplotnames[i],'^slp_lun_att',/boolean) then begin
         str_element,dl,'data_att.coord_sys','gei',/add
         str_element,dl,'data_att.st_type','none',/add
         str_element,dl,'data_att.units','unitvec',/add         
      endif
      store_data,tplotnames[i],dlimit=dl
    endfor
  endif
end

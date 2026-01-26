;+
;PROCEDURE: 
;  thm_part_products_data3d
;PURPOSE:
;  Generate 3d data structures from THEMIS particle data. For output
;  to CDF files
;DATA PRODUCTS:
;  data3d = An array of 3d data structures, units are 'eflux'
;            'eflux'  -  eV / (cm^2 * s * sr * eV)
;CALLING SEQUENCE:
;  data3d = thm_part_products_data3d(probe=probe, datatype=datatype)
;INPUT KEYWORDS:
;  probe:  Spacecraft designation, e.g. 'a','b'
;  datatype:  Particle datatype, e.g. 'psif, 'peib'
;  trange:  Two element time range [start,end]
;  sst_sun_bins:  Array of which sst bins to decontaminate
;                 (list of bins numbers, not the old mask array)
;                 Set to -1 to disable.
;  esa_bgnd_remove:  Set to 0 to disable ESA background removal, 
;                    otherwise default anode-based background will be subtracted.
;                    See thm_crib_esa_bgnd_remove for more keyword options.
;  esa_bgnd_advanced:  Apply advanced ESA background subtraction. 
;                      Must call thm_load_esa_bkg first to calculate background.
;                      Disables default background removal.
;  get_error:  Flag to return error estimates (*_sigma variables)
;  return_struct_array: If set, returns an arrasy of 3d structures,
;                       suitable for input to moments_3d
;                       calculation. The default is to return a
;                       single structure for output into an L2
;                       CDF. 
;NOTES:
;  Hacked from thm_part_products.pro for gneration of L2 SST
;  distribution files, jmm, 2025-10-20
;$LastChangedBy: $
;$LastChangedDate: $
;$LastChangedRevision: $
;$URL: $
;-
Function thm_part_products_data3d, probe=probe,$ ;The requested spacecraft ('a','b','c','d','e','f')
                                   datatype=datatype,$ ;The requested data type (e.g 'psif', 'peib', 'peer', etc...) 
                                   trange=trange,$ ;required for now
                                   dist_array=dist_array,$
;see thm_pgs_clean_sst.pro to see how decontamination is done for SST 
;see thm_crib_sst.pro for examples on using the decontamination keywords
                                   sst_sun_bins=sst_sun_bins,$ ; which sst bins to decontaminate(list of bins numbers, not the old mask array)
                                   sst_method_clean=sst_method_clean,$ ;how to decontaminate sst data (default/only: manual)
                                   error=error,$ ;indicate error to calling routine 1=error,0=success
                                   sst_cal=sst_cal,$
                                   esa_bgnd_remove=esa_bgnd_remove,$
                                   esa_bgnd_advanced=esa_bgnd_advanced,$
                                   return_struct_array=return_struct_array,$
                                   _extra=_extra

  compile_opt idl2

  twin = systime(/sec)
  error = 1
  otp = -1
  if n_elements(probe) gt 1 then begin
    dprint,"ERROR: thm_part_products doesn't support multiple probes. ",dlevel=1
    return, otp
  endif else if n_elements(probe) eq 1 && n_elements(strsplit(probe,' ',/extract)) gt 1 then begin
    dprint,"ERROR: thm_part_products doesn't support multiple probes. ",dlevel=1
    return, otp
  endif
  
  if n_elements(datatype) gt 1 then begin
    dprint,"ERROR: thm_part_products doesn't support multiple datatypes. It can be called multiple times instead.",dlevel=1
    return, otp
  endif else if n_elements(datatype) eq 1 && n_elements(strsplit(datatype,' ',/extract)) gt 1 then begin
    dprint,"ERROR: thm_part_products doesn't support multiple datatypes. It can be called multiple times instead.",dlevel=1
    return, otp
  endif
  
  if ~undefined(erange) then begin
    dprint,'ERROR: erange= keyword deprecated.  Using "energy=" instead.',dlevel=1
    return, otp
  endif
  
  ;get probe, datatype, and units from input structures if provided
  ;this will not overwrite variables that are already set
  thm_pgs_get_datatype, dist_array, probe=probe, datatype=datatype, units=units

  if undefined(datatype) then begin
    dprint,dlevel=1,"ERROR: no datatype specified."
    return, otp
  endif
  
  if undefined(probe) then begin
    dprint,dlevel=1,"ERROR: no probe specified."
    return, otp
  endif
  
  datatype_lc = strlowcase(datatype[0])
  probe_lc = strlowcase(probe[0])
  
  inst_format = 'th'+probe_lc+'_'+datatype_lc
  
  esa = strmid(datatype_lc,1,1) eq 'e'
  sst = strmid(datatype_lc,1,1) eq 's'
  combined = strmid(datatype_lc,1,1) eq 't'

  ;enable "best practices" keywords by default
  
  if sst && undefined(sst_cal) && strlowcase(strmid(datatype,3,1)) ne 'r' then begin
    sst_cal = 1
    dprint,'New SST calibrations being enabled by default(disable with sst_cal=0)',dlevel=1
  endif
  
  if keyword_set(sst_cal) && strlowcase(strmid(datatype,3,1)) eq 'r' then begin
    dprint,"Warning, new SST calibrations do not work with reduced distribution data",dlevel=1 
  endif
  
  if esa then begin
    if keyword_set(esa_bgnd_advanced) then begin
      if keyword_set(esa_bgnd_remove) then $
        dprint, 'Disabling default ESA background subtraction', dlevel=1
      esa_bgnd_remove = 0
    endif
    if undefined(esa_bgnd_remove) then begin
      esa_bgnd_remove = 1
      dprint,'ESA background removal enabled by default (disable with esa_bgnd_remove=0)',dlevel=1
    endif
  endif
  
  ;--------------------------------------------------------
  ;Get array of sample times and initilize indices for loop
  ;--------------------------------------------------------
  
  if size(dist_array,/type) eq 10 then begin
    ;extract 1-d time_array from dist_array
    thm_pgs_dist_array_times,dist_array,times=times
  endif else begin
     times= thm_part_dist(inst_format,/times,sst_cal=sst_cal,_extra=_extra)
  endelse

  if size(times,/type) ne 5 then begin
    dprint,dlevel=1, 'No ',inst_format,' data has been loaded.  Use thm_part_load to load particle data.'
    return, otp
  endif

  if ~undefined(trange) then begin

    trd = time_double(trange)
    time_idx = where(times ge trd[0] and times le trd[1], nt)

    if nt lt 1 then begin
      dprint,dlevel=1, 'No ',inst_format,' data for time range ',time_string(trd)
      return, otp
    endif
    
  endif else begin
    time_idx = lindgen(n_elements(times))
  endelse

  if (size(dist_array,/type)) eq 10 then begin
;identify the starting indexes for the dist array iterator at requested trange
    thm_pgs_dist_array_start,dist_array,time_idx,dist_ptr_idx=dist_ptr_idx,dist_seg_idx=dist_seg_idx
  endif

  all_times=times[time_idx]

;--------------------------------------------------------
;Loop over time to build the data structure
;--------------------------------------------------------
  count = 0L
  For i = 0L,n_elements(time_idx)-1L Do Begin
  
    ;Get the data structure for this sample
    if size(dist_array,/type) eq 10 then begin
      ;get the data from the dist_array for current index
       thm_pgs_dist_array_data, dist_array, data=data, dist_ptr_idx=dist_ptr_idx, $
                                dist_seg_idx=dist_seg_idx
    endif else begin
       data = thm_part_dist(inst_format,index=time_idx[i],sst_cal=sst_cal,_extra=_extra)
    endelse
    
    ;Apply eclipse corrections if present
    thm_part_apply_eclipse, data, eclipse=eclipse
    
    ;Sanitize Data.
    ;#1 removes uneeded fields from struct to increase efficiency
    ;#2 performs some basic transforms so that esa and sst are represented more consistently
    ;#3 converts to physical units
    if esa then begin
       thm_pgs_clean_esa,data,units_lc,output=clean_data,$
                         esa_bgnd_advanced=esa_bgnd_advanced,$
                         bgnd_remove=esa_bgnd_remove,_extra=_extra ;output is anonymous struct of goodies
    endif else if sst then begin
       thm_pgs_clean_sst,data,units_lc,output=clean_data,sst_sun_bins=sst_sun_bins,$
                         sst_method_clean=sst_method_clean,_extra=_extra
    endif else if combined then begin
       thm_pgs_clean_cmb,data,units_lc,output=clean_data
    endif else begin
       dprint,dlevel=1,'Instrument type unrecognized'
       return, otp
    endelse
    
;Insert cleaned data back into the 'data' structure, add 'scaling' to
;data first
    If(tag_exist(clean_data, 'scaling')) Then Begin
       count++
       tmp_scaling = data.data & tmp_scaling[*] = 0.0
       nenergy_clean = n_elements(clean_data.data[*, 0]) ;some energies are gone
       For ibin = 0, data.nbins-1 Do Begin
          tmp_scaling[0:nenergy_clean-1, ibin] = clean_data.scaling[*, ibin]
       Endfor
       str_element, data, 'scaling', tmp_scaling, /add_replace
;Replace data.data with clean_data.data
       tmp_data = data.data & tmp_data[*] = 0.0
       For ibin = 0, data.nbins-1 Do Begin
          tmp_data[0:nenergy_clean-1, ibin] = clean_data.data[*, ibin]
       Endfor
       str_element, data, 'data', tmp_data, /add_replace
;Units are 'eflux'
       data.units_name = 'eflux'
    Endif Else Begin
       dprint, 'No data??'
    Endelse
;Append to structure
    t = tag_names(data)
    ntimes = n_elements(time_idx)
    If(count Eq 1) Then Begin
       If(keyword_set(return_struct_array)) Then Begin
          all_dat = data
       Endif Else Begin
;Any tag that's an array, or 'time' or 'end_time' gets added to
;output array
          all_dat = {project_name:data.project_name}
          For k = 0, n_elements(t)-1 Do Begin
             If(t[k] Ne 'PROJECT_NAME' And t[k] Ne 'TRANGE' And t[k] Ne 'INDEX') Then Begin
                If(t[k] Eq 'TIME') Then Begin
                   str_element, all_dat, t[k], dblarr(ntimes), /add_replace
                   all_dat.time[0] = data.time
                Endif Else If(If(t[k] Eq 'END_TIME') Then Begin
                   str_element, all_dat, t[k], dblarr(ntimes), /add_replace
                   all_dat.end_time = data.end_time
                Endif Else If(If(t[k] Eq 'NSPINS') Then Begin
                   str_element, all_dat, t[k], intarr(ntimes), /add_replace
                   all_dat.nspins = data.nspins
                Endif Else Begin
                   nkk = n_elements(data.(k))
                   If(nkk Gt 1) Then Begin
;create an ntimes, nkk array and add it to the output structure
                      skk = size(data.(k), /dimensions)
                      If(n_elements(skk) Eq 1) Then Begin
                         b = make_array(ntimes, skk, type = size(data.(k), /type))
                         b[*] = 0
                         b[0, *] = data.(k)
                      Endif Else If(n_elements(skk) Eq 2) Then Begin
                         b = make_array(ntimes, skk[0], skk[1], type = size(data.(k), /type))
                         b[*] = 0
                         b[0, *, *] = data.(k)
                      Endif Else Begin
                         dprint, 'Unexpected 3d array size: '+t[k]
                         Return
                      Endelse
                      str_element, all_dat, t[k], b, /add_replace
                   Endif Else Begin
;Not record varying
                      str_element, all_dat, t[k], data.(k), /add_replace
                   Endelse
                Endelse
             Endif
          Endfor
;Done adding tags
          t1 = tag_names(all_dat)
       Endelse
    Endif Else Begin
       If(keyword_set(return_struct_array)) Then Begin
          all_dat = [temporary(all_dat), temporary(data)]
       Endif Else Begin
          For k = 0, n_elements(t)-1 Do Begin
             k1 = where(t1 Eq t[k], nk1)
             If(nk1 Gt 0) Then Begin
                If(t[k] Eq 'TIME') Then Begin
                   all_dat.time[i] = data.time
                Endif Else If(If(t[k] Eq 'END_TIME') Then Begin
                   all_dat.end_time[i] = data.end_time
                Endif Else Begin
;create an ntimes, nkk array and add it to the output structure
                   skk1 = size(all_dat.(k1), /n_dim)
                   If(skk1 Eq 2) Then Begin
                      all_dat.(k1)[i, *] = data.(k)
                   Endif Else If(skk1 Eq 3) Then Begin
                      all_dat.(k1)[i, *, *] = data.(k)
                   Endif Else Begin
                      dprint, 'Unexpected 3d array size: '+t[k]
                      Return
                   Endelse
                Endif
             Endif
          Endfor
                   
             
             
    Endelse
 Endfor
  error = 0

  dprint,'Complete. Runtime: ',systime(/sec) - twin,' secs'
  Return, all_dat
End

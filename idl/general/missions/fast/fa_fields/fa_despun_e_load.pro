;Helper function to load one data type at a time
Pro fa_despun_e_load_type, type, trange = trange, orbit = orbit, $
                           no_time_clip = no_time_clip, version = version, $
                           force = force, _extra = _extra

  common fa_esv_saved_tranges, tr0_esv, tr0_e4k, tr0_e16k, tr0_esv_long
;Keep track of software versioning here
  If(keyword_set(version)) Then Begin
     sw_vsn = version
  Endif Else sw_vsn = 1
  vxx = 'v'+string(sw_vsn, format='(i2.2)')
;Here we are loading one type
  type = strlowcase(strcompress(/remove_all, type[0]))
  If(keyword_set(orbit)) Then Begin
     start_orbit = long(min(orbit))
     end_orbit = long(max(orbit))
     ott = fa_orbit_to_time([start_orbit, end_orbit])
;ott is a 3X2 array, orbit number, start and end time, so the overall
;time range is:
     tr0 = [ott[1, 0], ott[2, 1]]
  Endif Else Begin
;handle time range
     tr0 = timerange(trange)
;Get orbits, 
     start_orbit = long(fa_time_to_orbit(tr0[0]))
     end_orbit = long(fa_time_to_orbit(tr0[1]))
  Endelse
;Only load data if no_time_clip is set, and the saved trange does not
;match the new one
  tr0_test = [0.0d0, 0.0d0]
  Case type of
     'esv' : Begin
        If(n_elements(tr0_esv) Eq 2) Then tr0_test = tr0_esv
     End
     'e4k' : Begin
        If(n_elements(tr0_e4k) Eq 2) Then tr0_test = tr0_e4k
     End
     'e16k' : Begin
        If(n_elements(tr0_e16k) Eq 2) Then tr0_test = tr0_e16k
     End
     'esv_long' : Begin
        If(n_elements(tr0_esv_long) Eq 2) Then tr0_test = tr0_esv_long
     End
     Else: Begin
        dprint, 'Bad Input Data Type, Returning'
        Return
     End
  Endcase
  timetest = total(abs(tr0-tr0_test))
  If(timetest Gt 0.0 || keyword_set(no_time_clip) || keyword_set(force)) Then Begin
;reset saved time
     Case type of
        'esv' : tr0_esv = tr0
        'e4k' : tr0_e4k = tr0
        'e16k' : tr0_e16k = tr0
        'esv_long' : tr0_esv_long = tr0
     Endcase
     orbits = indgen(end_orbit-start_orbit+1)+start_orbit
     orbits_str = strcompress(string(orbits,format='(i05)'), /remove_all)
     orbit_dir = strmid(orbits_str,0,2)+'000'
     relpathnames='l2/'+type+'/'+orbit_dir+'/fa_despun_'+type+'_l2_*_'+orbits_str+'_'+vxx+'.cdf'
     filex=file_retrieve(relpathnames,_extra = !fast)
;Only files that exist here
     filex = file_search(filex)
     If(~is_string(filex)) Then Begin
        dprint, 'No files found for time range and type:'+type
        Return
     Endif
;Only unique files here
     filex_u = filex[bsort(filex)]
     filex = filex_u[uniq(filex_u)]
     cdf2tplot, files = filex, varformat = '*', tplotnames = tvars
     If(~is_string(tnames(tvars))) Then Begin
        dprint, 'No Variables Loaded'
        Return
     Endif
;Check time range
     If(~keyword_set(files) and ~keyword_set(no_time_clip)) Then Begin
        time_clip, tnames(tvars), tr0[0], tr0[1], /replace
     Endif
;Add labels for 3D fields
     colors = [ 2, 4, 6]
     labels = [ 'Ex', 'Ey', 'Ez']
     get_data,'fa_e0_s_dsc',data = edsc
     If(is_struct(edsc)) Then Begin
        options, 'fa_e0_s_dsc', 'colors', colors
        options, 'fa_e0_s_dsc', 'labels', labels+' (DSC)'
     Endif
     get_data,'fa_e0_s_gse',data = egse
     If(is_struct(egse)) Then Begin
        options, 'fa_e0_s_gse', 'colors', colors
        options, 'fa_e0_s_gse', 'labels', labels+' (GSE)'
     Endif
     get_data,'fa_e0_s_gsm',data = egsm
     If(is_struct(egsm)) Then Begin
        options, 'fa_e0_s_gsm', 'colors', colors
        options, 'fa_e0_s_gsm', 'labels', labels+' (GSM)'
     Endif
;Add bitplot and labels for data quality
     options, 'fa_data_quality', 'ytitle' ,'1-B Notch,2-S Notch!C3-Both'
     options, 'fa_data_quality', 'ysubtitle' ,0
     options, 'fa_data_quality', 'yrange', [0,4]
  Endif Else Begin
     dprint, dlevel=2, 'Not reloading '+type+' data'
  Endelse
  Return
End

;+
;NAME:
; fa_despun_e_load
;PURPOSE:
; Loads FAST ESA L2 data for a given file(s), or time_range, or orbit range
;CALLING SEQUENCE:
; fa_despun_e_load, trange=trange, type=type, datatype=datatype, orbit=orbit
;INPUT:
; All via keyword, if none are set, then the output of timerange() is
; used for the time range, which may prompt for a time interval
;KEYWORDS:
; datatype, type = ['esv', 'e4k', 'e16k'], 'esv' (Survey data) is the default
; trange = read in the data from this time range, note that if both
;          files and time range are set, files, and orbits take precedence in
;          finding files.
; orbit = if set, load the given orbit(s) 
; no_time_clip = if set do not clip the data to the time range. The
;                trange is only used for file selection. Note that
;                setting no_time_clip will always generate a reload of data
;OUTPUT:
; tplot variables, ['E_ALONG_V', 'E_NEAR_V']
;HISTORY:
; Hacked from ESA L2 load, 2024-03-27, jmm
; $LastChangedBy: $
; $LastChangedDate: $
; $LastChangedRevision: $
; $URL: $
;-
Pro fa_despun_e_load, datatype = datatype, type = type, $
                      files = files, trange = trange, orbit = orbit, $
                      no_time_clip = no_time_clip, _extra = _extra

;fa_init, initializes a system variable
  fa_init

;work out the datatype
  If(keyword_set(datatype)) Then Begin
     type = datatype
  Endif Else Begin
     If(~keyword_set(type)) Then type='esv' ;only 'esv' for now
  Endelse
;call for different types, 
  For j = 0, n_elements(type)-1 Do fa_despun_e_load_type, type[j], $
     trange = trange, orbit = orbit, no_time_clip = no_time_clip, _extra = _extra

  Return
End


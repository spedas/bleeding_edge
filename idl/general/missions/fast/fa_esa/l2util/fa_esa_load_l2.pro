;Helper function to load one data type at a time
Pro fa_esa_load_l2_type, type, trange = trange, orbit = orbit, $
                         no_time_clip = no_time_clip, _extra = _extra

;Keep track of software versioning here
  sw_vsn = fa_esa_current_sw_version()
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
;Need orbits, hacked from fa_load_esa_l1.pro
     start_orbit = long(fa_time_to_orbit(tr0[0]))
     end_orbit = long(fa_time_to_orbit(tr0[1]))
  Endelse

  orbits = indgen(end_orbit-start_orbit+1)+start_orbit
  orbits_str = strcompress(string(orbits,format='(i05)'), /remove_all)
  orbit_dir = strmid(orbits_str,0,2)+'000'
  relpathnames='l2/'+type+'/'+orbit_dir+'/fa_esa_l2_'+type+'_*_'+orbits_str+'_'+vxx+'.cdf'
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
;Ok, load the files
  nfiles = n_elements(filex)
  dat = -1
  ck = 0
  For j = 0, nfiles-1 Do Begin
     datj = fa_esa_cmn_l2read(filex[j])
     If(is_struct(datj)) Then Begin
        If(~is_struct(dat)) Then dat = temporary(datj) $
        Else dat = fa_esa_cmn_concat(temporary(dat), temporary(datj))
     Endif
  Endfor
;Check time range
  If(~keyword_set(files) and ~keyword_set(no_time_clip)) Then Begin
     If(is_struct(dat)) Then dat = fa_esa_cmn_tclip(dat, tr0) $
     Else Begin
        dprint, 'No data for type: '+type
     Endelse
  Endif
;Which type?
  Case type of
     'ies': Begin
        common fa_ies_l2, get_ind_ies, all_dat_ies
        all_dat_ies = dat & get_ind_ies = 0L
     End
     'ees': Begin
        common fa_ees_l2, get_ind_ees, all_dat_ees
        all_dat_ees = dat & get_ind_ees = 0L
     End
     'ieb': Begin
        common fa_ieb_l2, get_ind_ieb, all_dat_ieb
        all_dat_ieb = dat & get_ind_ieb = 0L
     End
     'eeb': Begin
        common fa_eeb_l2, get_ind_eeb, all_dat_eeb
        all_dat_eeb = dat & get_ind_eeb = 0L
     End
  Endcase
End

;+
;NAME:
; fa_esa_load_l2
;PURPOSE:
; Loads FAST ESA L2 data for a given file(s), or time_range, or orbit range
;CALLING SEQUENCE:
; fa_esa_load_l2, trange=trange, type=type, datatype=datatype, orbit=orbit
;INPUT:
; All via keyword, if none are set, then the output of timerange() is
; used for the time range, which may prompt for a time interval
;KEYWORDS:
; datatype, type = ['ies','ieb', 'ees', 'eeb' ] is the default
; trange = read in the data from this time range, note that if both
;          files and time range are set, files, and orbits take precedence in
;          finding files.
; orbit = if set, load the given orbit(s) 
; no_time_clip = if set do not clip the data to the time range. The
;                trange is only used for file selection. Note that
;                setting no_time_clip will always generate a reload of data
;OUTPUT:
; No variables, data are loaded into common blocks
;HISTORY:
; 1-sep-2015, jmm, jimm@ssl.berkeley.edu
; 18-oct-2016, jmm, Checks to see if the time range is different than
;                   the saved time range before loading data
; $LastChangedBy: jimm $
; $LastChangedDate: 2025-08-27 10:20:33 -0700 (Wed, 27 Aug 2025) $
; $LastChangedRevision: 33579 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/fast/fa_esa/l2util/fa_esa_load_l2.pro $
;-
Pro fa_esa_load_l2, datatype = datatype, type = type, $
   files = files, trange = trange, orbit = orbit, $
   no_time_clip = no_time_clip, tplot = tplot, _extra = _extra

;fa_init, initializes a system variable
  fa_esa_init

;Don't clear the L2 common blocks
;  fa_esa_clear_common_blocks, /l2
;work out the datatype
  If(keyword_set(datatype)) Then Begin
     type = datatype
  Endif Else Begin
     If(~keyword_set(type)) then type=['ees','ies','eeb','ieb']
  Endelse
;Don't use recursive call for different types, because of
;common block clearing issues
  For j = 0, n_elements(type)-1 Do fa_esa_load_l2_type, type[j], $
     trange = trange, orbit = orbit, no_time_clip = no_time_clip, _extra = _extra

  If(keyword_set(tplot)) Then Begin
     For j = 0, n_elements(type)-1 Do fa_esa_l2_tplot, type = type[j], /all, _extra = _extra
  Endif

  Return
End


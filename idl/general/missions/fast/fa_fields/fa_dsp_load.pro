;+
;NAME:
; fa_dsp_load
;PURPOSE:
; Loads FAST EFI DSP (Digital Signal Processor) L2 data for a given
; time range, or orbit range
;CALLING SEQUENCE:
; fa_dsp_load, trange=trange, orbit=orbit
;INPUT:
; All via keyword, if none are set, then the output of timerange() is
; used for the time range, which may prompt for a time interval
;KEYWORDS:
; trange = read in the data from this time range, note that if both
;          files and time range are set, orbits take precedence in
;          finding files.
; orbit = if set, load the given orbit(s) 
; no_time_clip = if set do not clip the data to the time range. The
;                trange is only used for file selection. Note that
;                setting no_time_clip will always generate a reload of data
;OUTPUT:
; tplot variables, 'dspadc_mag3ac', and similar
;HISTORY:
; Hacked from EFI L2 load, 2024-11-12, jmm
; $LastChangedBy: $
; $LastChangedDate: $
; $LastChangedRevision: $
; $URL: $
;-
Pro fa_dsp_load, trange = trange, orbit = orbit, $
                 no_time_clip = no_time_clip, $
                 version = version, _extra = _extra

;fa_init, initializes a system variable
  fa_init
;Keep track of software versioning here
  If(keyword_set(version)) Then Begin
     sw_vsn = version
  Endif Else sw_vsn = 1
  vxx = 'v'+string(sw_vsn, format='(i2.2)')
;Here we are loading one type
  type = 'dsp'
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
  orbits = indgen(end_orbit-start_orbit+1)+start_orbit
  orbits_str = strcompress(string(orbits,format='(i05)'), /remove_all)
  orbit_dir = strmid(orbits_str,0,2)+'000'
  relpathnames='l2/'+type+'/'+orbit_dir+'/fa_'+type+'_l2_*_'+orbits_str+'_'+vxx+'.cdf'
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
;Add spec for variables
  vars = tnames(tvars)
  For j = 0, n_elements(vars)-1 Do Begin
     options, vars[j], 'spec', 1, /default
     options, vars[j], 'datagap', 600.0, /default
  Endfor
  Return
End

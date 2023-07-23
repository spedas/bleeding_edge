;+
;
;FUNCTION:        VEX_ASP_ELS_GET
;
;PURPOSE:         Returns an ELS data structure extracted from the common blocks.
;
;INPUTS:          Time for extracting one ELS data structure.
;
;KEYWORDS:
;
;     INDEX:      If set, extracts the data at the index that the user specified.
;
;     UNITS:      Converts data to these units. Default = 'counts'.
;
;     TIMES:      If set, returns an array of times for all the data.
;
;CREATED BY:      Takuya Hara on 2023-06-30.
;
;LAST MODIFICATION:
; $LastChangedBy: hara $
; $LastChangedDate: 2023-07-02 16:49:00 -0700 (Sun, 02 Jul 2023) $
; $LastChangedRevision: 31925 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/vex/aspera/vex_asp_els_get.pro $
;
;-
FUNCTION vex_asp_els_get, itime, index=index, units=units, verbose=verbose, times=times

  COMMON vex_asp_dat, vex_asp_ima, vex_asp_els

  IF undefined(itime) THEN BEGIN
     IF undefined(index) THEN BEGIN
        dprint, dlevel=2, verbose=verbose, 'You must specify a time.'
        RETURN, 0
     ENDIF 
  ENDIF 

  IF ~is_struct(vex_asp_els) THEN BEGIN
     dprint, dlevel=2, verbose=verbose, 'No ELS data found.'
     RETURN, 0
  ENDIF 

  ctime = 0.5d0 * (vex_asp_els.time + vex_asp_els.end_time)
  IF KEYWORD_SET(times) THEN RETURN, ctime

  IF undefined(index) THEN BEGIN
     time = itime
     IF is_string(time) THEN time = time_double(time)
     n = nn2(ctime, time)

     tdiff = ABS(ctime[n] - time)
     IF tdiff GT 10.d0 THEN dprint, dlevel=2, verbose=verbose, 'Warning: Big difference (sec) from the input time: ' + STRING(tdiff, '(F0.1)')
  ENDIF ELSE n = index

  els = {project_name: 'VEX', data_name: 'ASPERA-4/ELS', units_procedure: 'vex_asp_els_convert_units'}

  extract_tags, els, vex_asp_els[n], tags=['units_name', 'time', 'end_time']
  str_element, els, 'integ_t', 3.6d0/128.d0, /add

  extract_tags, els, vex_asp_els[n], tags=['mode', 'nsweep', 'nenergy']
  str_element, els, 'nbins', 16, /add

  c = 2.99792458D5
  mass = (5.10998910D5)/(c*c)
  str_element, els, 'mass', mass, /add
  str_element, els, 'magf', DBLARR(3), /add
  
  str_element, els, 'eff', 0.87, /add
  extract_tags, els, vex_asp_els[n], tags=['gf', 'energy', 'data']

  IF tag_exist(vex_asp_els[n], 'bkg', /quiet) THEN bkg = vex_asp_els[n].bkg $
  ELSE BEGIN
     bkg = els.data
     bkg[*] = 0.
  ENDELSE 
  str_element, els, 'bkg', bkg, /add
  str_element, els, 'cnts', vex_asp_els[n].cnts, /add
  
  IF ~undefined(units) THEN vex_asp_els_convert_units, els, units, verbose=verbose

  ;;;els = CREATE_STRUCT(name='vex_asp_els', TEMPORARY(els))
  RETURN, els
END

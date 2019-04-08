;+
; PROCEDURE aacgmloadcoef
;
; :PURPOSE:
; A wrapper procedure to choose AACGM DLM or IDL-native routines
; to load the coefficients of AACGM conversion. Actually this procedure
; does load the coefficients for given year if AACGM DLM is available.
;
; The wrapper procedures/functions check !sdarn.aacgm_dlm_exists
; (if not defined, then define it by sd_init) to select appropriate
; AACGM routines (DLM, or IDL native ones attached to TDAS).
;
; :Params:
;   year:   4-digit year for which the AACGM coefficients are loaded.
;
; :Examples:
;   aacgmloadcoef, 2005
;
; :AUTHOR:
;   Tomo Hori (E-mail: horit@stelab.nagoya-u.ac.jp)
;
; :HISTORY:
;   2011/10/04: created and got through the initial bug fixes
;
; $LastChangedDate: 2019-03-17 21:51:57 -0700 (Sun, 17 Mar 2019) $
; $LastChangedRevision: 26838 $
;-
pro aacgmloadcoef, year

  ;Initialize !sdarn if not defined
  help, name='!sdarn',out=out
  if out eq '' then sd_init
  
  ;Exit unless the argument is given
  npar = n_params()
  if npar ne 1 then return
  
  year = year[0] ;Use the first element if mistakenly given as an array
  
  ;Choose the coef. file of the year closest to the one given as an argument
  yrlist = !sdarn.aacgm.coefyrlist
  if yrlist[0] le year then begin
    yr_selected = max( yrlist[ where( yrlist le year ) ] )
  endif else begin
    yr_selected = yrlist[0]
    print, 'Year given is out of range: will use the coefficients for '+string(yr_selected,'(i4.4)')
  endelse
  
  if !map2d.aacgm_dlm_exists then begin
    ;print, 'using AACGM_DLM'
    aacgm_load_coef, yr_selected
  endif else begin
    coef_fpath = !sdarn.aacgm.coefprefix+string(yr_selected,'(i4)')+'.asc'
    if file_test(coef_fpath) then begin
      load_coef, coef_fpath
      print, '%load_coef: Coefficients loaded for year '+string(yr_selected,'(i4)')+'.'
    endif
  endelse
  
  return
end



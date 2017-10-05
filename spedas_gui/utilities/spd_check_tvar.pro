;+
; NAME:
;     spd_check_tvar (FUNCTION)
;
; PURPOSE:
;     This routine check whether the given tplot variable TVAR exists in the
;     memory. If not, return 0. Otherwise, then check whether it contains data
;     of the current date. If yes, return 1. If not, return 0.
;
; ARGUMENTS:
;     tvar: (INPUT, REQUIRED) The name of a tplot variable to be checked.
;
; KEYWORDS:
;     None.
;
; HISTORY:
;     2009-05-10: written by Jianbao Tao, in CU/LASP.
;
; $LastChangedBy: nikos $
; $LastChangedDate: 2016-10-06 15:10:51 -0700 (Thu, 06 Oct 2016) $
; $LastChangedRevision: 22057 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/utilities/spd_check_tvar.pro $
;-

function spd_check_tvar, tvar

  head = 'SPD_CHECK_TVAR: '

  ; check data type of tvar
  if size(tvar,/type) ne 7 then begin
    print, 'SPD_CHECK_TVAR: ' + $
      'Argument TVAR must be a string of the name of a tplot varialbe.'
    return, 0
  endif

  ;tvar = strlowcase(tvar)

  ; get current date
  get_timespan, tspan
  tmp = (time_string(tspan))[0]
  cur_date = strmid(tmp,0,10)

  if ~strcmp(tvar, tnames(tvar), /fold) then begin
    return, 0
  endif else begin
    get_data, tvar, data=data
    if size(data, /type) ne 8 then return, 0
    tmp = minmax(data.x)
    if tmp[0] le tspan[0] and tmp[1] ge tspan[1] then return, 1
    date = strmid(time_string(mean(data.x)), 0, 10)
    if strcmp(date, cur_date) then return, 1
    return, 0
  endelse

end



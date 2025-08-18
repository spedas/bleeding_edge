;+
; NAME:
;      tcs_is_array
;
; PURPOSE:
;  Helper function: tests if argument is array, 1L on success 0L on failure
;
;
;;$LastChangedBy: lphilpott $
;$LastChangedDate: 2012-06-25 15:20:30 -0700 (Mon, 25 Jun 2012) $
;$LastChangedRevision: 10638 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/misc/tcs_is_array.pro $
;-


function tcs_is_array, a

  if 0 eq (size(a))(0) then return, 0L

  return, 1L
  
end
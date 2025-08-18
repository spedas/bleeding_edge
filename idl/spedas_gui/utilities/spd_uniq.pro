;+
;Procedure:
;  spd_uniq
;
;Purpose:
;  Implement most common usage of IDL uniq() function
;
;Calling Sequence:
;  output = spd_uniq(array)
;
;Input:
;  array: An array
;
;Return Value:
;  Sorted, unique values from input
;
;Notes:
;  
;
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2015-08-06 20:01:43 -0700 (Thu, 06 Aug 2015) $
;$LastChangedRevision: 18419 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/utilities/spd_uniq.pro $
;-
function spd_uniq, array

  compile_opt idl2, hidden

return, array[  uniq( array, sort(array) )  ]

end
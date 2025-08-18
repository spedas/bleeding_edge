;+
;Procedure:
;  spd_slice2d_translate
;
;Purpose:
;  Shift xyz by specified vector
;
;Calling Sequence:
;  spd_slice2d_translate, vectors=vectors, translate=translate, fail=fail
;
;Input:
;  vectors:  Nx3 array 
;  translate:  3-vector to shift by
;Keyword:
;  truncate: cut the data of the exeded domain 
;
;Output:
;  fail:  contains error message if error occurs
;
;Notes:
;
;
;$LastChangedBy: adrozdov $
;$LastChangedDate: 2018-05-21 12:46:11 -0700 (Mon, 21 May 2018) $
;$LastChangedRevision: 25240 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/science/spd_slice2d/core/spd_slice2d_translate.pro $
;-

pro spd_slice2d_translate, vectors=xyz, translate=tv, data=data, truncate=truncate, fail=fail

    compile_opt idl2, hidden


if undefined(xyz) then return
if undefined(tv) then return

if dimen2(xyz) ne 3 or n_elements(tv) ne 3 then begin
  fail = 'Invalid vector dimensions'
  dprint, dlevel=0, fail 
  return
endif

if total( ~finite(tv) ) gt 0 then begin
  fail = 'Invalid translation vector'
  dprint, dlevel=0, fail
  return
endif

if keyword_set(truncate) then begin
  x_range = minmax(xyz[*,0])
  y_range = minmax(xyz[*,1])
  z_range = minmax(xyz[*,2])
endif


xyz[*,0] = xyz[*,0] + tv[0]
xyz[*,1] = xyz[*,1] + tv[1]
xyz[*,2] = xyz[*,2] + tv[2]


if keyword_set(truncate) and keyword_set(data) then begin
  ; TODO: add check the and size of the data
  index = where(xyz[*,0] gt x_range[0] and xyz[*,0] lt x_range[1] and $
                xyz[*,1] gt y_range[0] and xyz[*,1] lt y_range[1] and $
                xyz[*,2] gt z_range[0] and xyz[*,2] lt z_range[1])
  
  xyz = xyz[index,*]
  data = data[index]  
endif

end
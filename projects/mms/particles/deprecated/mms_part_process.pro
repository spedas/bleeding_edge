;+
;Procedure:
;  mms_part_process
;
;Purpose:
;  Apply standard processing to particle distribution array 
;  and pass out the processed copy.  This routine will apply
;  perform a unit conversion and call the standard processing 
;  routines.
;
;Calling Sequence:
;  mms_part_process, in, out [,units=units]
;
;Input:
;  in:  Pointer array from mms_get_???_dist
;  units:  String specifying new units
;  _extra: Passed to sanitization routines
;
;Output:
;  out:  Pointer array to processed copy of the data
;
;Notes:
;
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2017-03-10 09:00:31 -0800 (Fri, 10 Mar 2017) $
;$LastChangedRevision: 22936 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/particles/deprecated/mms_part_process.pro $
;-
pro mms_part_process, in, out, units=units, _extra=_extra

    compile_opt idl2, hidden


if in_set(ptr_valid(in),0) then return

units_lc = strlowcase(units)

out = ptrarr(n_elements(in))

for i=0, n_elements(in)-1 do begin
  
  for j=0, n_elements(*in[i])-1 do begin

    dist = (*in[i])[j]

    ;general processing including unit conv & sst contamination removal
    mms_convert_flux_units, dist, units=units, output=clean_dist

    ;build new array
    array = array_concat(clean_dist, array, /no_copy) 

  endfor

  out[i] = ptr_new(array, /no_copy)

endfor


end
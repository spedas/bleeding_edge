;+
;Procedure:
;  spd_dist_to_hash
;
;Purpose:
;  Convert standard 3D partical distribution structure into hash
;  compatible with ISEE_3D 
;
;Calling Sequence:
;  hash = spd_dist_to_hash( dist [,counts=dist_counts]
;
;Input:
;  dist:  Standard distribution structure array (pointer) in df units
;  counts:  Optional copy of dist in counts
;
;Output:
;  return value: A hash whose elements are each single distributions,
;                The keys are the sample time in millisecond precision.
;
;Notes:
;  -Requires IDL 8.0+, 8.2+ recommended
;
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2016-05-23 18:52:50 -0700 (Mon, 23 May 2016) $
;$LastChangedRevision: 21180 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/science/spd_part_products/spd_dist_to_hash.pro $
;-

function spd_dist_to_hash, d, counts=counts

    compile_opt idl2, hidden


if !version.release lt 8.0 then begin
  message, 'IDL 8.0 or higher is required to use this function'
endif

if in_set(ptr_valid(d),0) || ~is_struct(*d[0]) then begin
  dprint, dlevel=0, 'Invalid input data'
  return, !null
endif

counts_set = ~undefined(counts) 
if counts_set then begin
  if ~ptr_valid(counts) || ~is_struct(*counts[0]) then begin
    dprint, dlevel=0, 'Invalid counts data'
    return, !null
  endif
endif


c = 299792458d ;m/s
erest = (*d[0])[0].mass * c^2 / 1e6 ;convert mass from eV/(km/s)^2 to eV/c^2


out = hash()

for i=0, n_elements(d)-1 do begin

  ;all fields must be reformed to single dimension later
  n = n_elements((*d[i])[0].data)

  for j=0, n_elements(*d[i])-1 do begin

    time = time_string( (*d[i])[j].time, /msec )

    ;calculate velocity in km/s
    ;use lat instead of co-lat
    ;fill counts if not set
    out[time] = hash( 'energy', reform( (*d[i])[j].energy ,n), $
                      'v', reform( c * sqrt( 1 - 1/(((*d[i])[j].energy/erest + 1)^2) )  /  1000. ,n), $
                      'azim', reform( (*d[i])[j].phi ,n), $
                      'elev', 90-reform( (*d[i])[j].theta ,n), $
                      'count', reform( counts_set ? (*counts[i])[j].data : fltarr(n) ,n), $
                      'psd', reform( (*d[i])[j].data ,n)  )

  endfor
endfor

if out.isempty() then return, !null

return, out

end
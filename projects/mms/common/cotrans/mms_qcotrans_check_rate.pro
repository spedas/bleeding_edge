;+
;Procedure:
;  mms_qcotrans_check_rate
;
;Purpose:
;  Verify that quaternion transformations have sufficient time
;  resolution for spinning/despinning data.
;
;Calling Sequence:
;  bool = mms_qcotrans_check_times(in_coord, out_coord, probe)
;
;Input:
;  in_coord:  input coordinates string
;  out_coord:  output coordinates
;  probe:  probe designation
;
;Output:
;  return value:
;    1 if required quaternion are present and have insufficient resolution
;    0 otherwise
;
;Notes:
;  -Assumes all tranformations performed through ECI
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2016-05-25 15:38:52 -0700 (Wed, 25 May 2016) $
;$LastChangedRevision: 21208 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/cotrans/mms_qcotrans_check_rate.pro $
;-
function mms_qcotrans_check_rate, in_coord, out_coord, probe

    compile_opt idl2, hidden

  ;intersection check bellow fails for inputs with repeated elements
  if in_coord eq out_coord then return, 0
  
  spinning_frames = ['bcs','smpa','ssl']

  matches = ssl_set_intersection(spinning_frames,[in_coord,out_coord])

  if is_string(matches,/blank) then begin
    for i=0, n_elements(matches)-1 do begin
  
      q_name = 'mms'+probe+'_mec_quat_eci_to_'+matches[i]
      
      get_data, q_name, ptr=ptr
      
      ;ignore non-existent data, will be checked elsewhere
      if ~is_struct(ptr) then continue 
      
      dt = median( (*ptr.x)[1:*] - *ptr.x )
    
      if dt gt 10 then begin
        dprint, dlevel=0, 'Quaternion rotation "'+q_name+ $
                '" does not have sufficient time resolution to transform '+ $
                'to/from a spinning frame.  Please load burst data if available.'
        return, 1
      endif
  
    endfor
  endif

  return, 0

end
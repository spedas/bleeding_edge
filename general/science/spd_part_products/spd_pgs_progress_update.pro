
;+
;Procedure:
;  spd_pgs_progress_update
;
;Purpose:
;  Helper routine prints status message indicating completion percent
;
;
;Input:
;  last_update_time: The last time an update was posted(you can just set this to an undefined variable name)
;  current_sample: The current sample index
;  total_samples: The total number of samples
;  display_object=display_object(optional): dprint display object
;  type_string=type_string(optional): set to specify a type in the output message
;
;
;Notes:
;  
;
;$LastChangedBy: pcruce $
;$LastChangedDate: 2016-01-04 15:09:48 -0800 (Mon, 04 Jan 2016) $
;$LastChangedRevision: 19671 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/science/spd_part_products/spd_pgs_progress_update.pro $
;-

pro spd_pgs_progress_update, last_update_time,current_sample,total_samples, $
                             display_object=display_object,type_string=type_string

    compile_opt idl2, hidden
  
    if undefined(last_update_time) then begin
      last_update_time = systime(1)
    endif
    
    if ~is_string(type_string) then begin
      type_string = "Data"  
    endif
    
    if (systime(1)-last_update_time gt 10.) then begin
      msg = type_string +' is ' + strcompress(string(long(100*float(current_sample)/total_samples)),/remove) + '% done.'
      ;dlevel=2 indicates low priority
      ;sublevel=1 indicates that message should appear to come from caller
      dprint, msg, display_object=display_object, dlevel=2, sublevel=1 
      last_update_time=systime(1)
    endif
  
end

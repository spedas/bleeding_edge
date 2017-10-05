;+
;Procedure:
;  thm_pgs_expand_yaxis
;
;Purpose:
;  Convert single-dimension y axes from new spectrogram code 
;  to two dimensions to match the output from the old code.
;
;Calling Sequence
;  thm_pgs_expand_axis, tplotnames
;
;Inputs:
;  tplotnames: list of tplot variables whose y axes may need 
;              expansion to two dimensions
;
;Outputs:
;  none
;
;Keywords:
;  none
;
;Notes: 
;  
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2013-09-11 16:40:34 -0700 (Wed, 11 Sep 2013) $
;$LastChangedRevision: 13023 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/particles/thm_part_products/thm_pgs_expand_yaxis.pro $
;-


pro thm_pgs_expand_yaxis, tplotnames

    compile_opt idl2, hidden


  if undefined(tplotnames) then return

  
  ;loop over tplot variable names
  for i=0, n_elements(tplotnames)-1 do begin
  
    get_data, tplotnames[i], data=data
    
    ;ignore invalid data
    if is_struct(data) then begin
    
      ;ignore variables that already have two dimensions
      if (size(data.v))[0] lt 2 then begin
      
        ;expand single dimension y axis to two dimensions
        store_data, tplotnames[i], $
          data = {x:data.x, y:data.y, v:data.v ## replicate(1.,n_elements(data.x))}
      
      endif
    
    endif
  
  endfor
  
  
end
    
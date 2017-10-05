;+
;Procedure:
;  spd_pgs_concat_spec
;
;Purpose:
;  Concatenates spectrograms pieces from across a mode change
;
;Input:
;  a: First spectrogram piece (in time) 
;  b: Second spectrogram piece (in time)
;
;Output:
;  None, appends b to end of a; b will be undefined afterwards.
;
;Notes:
;
;
;$LastChangedBy: pcruce $
;$LastChangedDate: 2016-01-04 15:09:48 -0800 (Mon, 04 Jan 2016) $
;$LastChangedRevision: 19671 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/science/spd_part_products/spd_pgs_concat_spec.pro $
;-
pro spd_pgs_concat_spec, a, b

    compile_opt idl2, hidden
  
  
  flag = !values.f_nan
  
  adim = size(a,/dim) > 1
  bdim = size(b,/dim) > 1
  
  if n_elements(adim) eq 1 then adim = [adim,1]
  if n_elements(bdim) eq 1 then bdim = [bdim,1]
  
  
  ;expand elements in second piece to match the first
  if adim[0] gt bdim[0] then begin
    
    b = [ temporary(b), replicate(flag, adim[0]-bdim[0], bdim[1]) ]
  
  ;expand elements in first piece to match the second
  endif else if adim[0] lt bdim[0] then begin
    
    a = [ temporary(a), replicate(flag, bdim[0]-adim[0], adim[1]) ]
    
  endif
  
  
  ;concatenate
  a = [ [temporary(a)], [temporary(b)] ]
  
end
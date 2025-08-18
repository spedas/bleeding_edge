;+
;
;NAME: spd_ui_cleanup_tplot
;
;PURPOSE:
;  Abstracts the oft-repeated operation which identifies new tplot variables,
;  and identifies variables that should be deleted 
;
;CALLING SEQUENCE:
;   tnames_before = tnames('*',create_time=cn_before)
;   thm_load_state ;some operation
;   spd_ui_cleanup_tplot,tnames_before,create_time_before=cn_before,del_vars=del_vars,new_vars=new_vars
;
;Inputs:
;  tnames_before: a list of tplot names from before the operation in question
;  
;Keywords:
;  create_time_before(optional,input): This is an array of the create times associated with tnames_before
;                                      This argument is only required if you want the list of new_vars
;  new_vars(output):  This will output an array of new tplot variable names, if create_time_before was specified                                      
;  del_vars(output):  This will output an array of tplot variable names to delete.
;
;Note:  
;  The list of new variables and delete variables is generally not the same. Delete variables contains only names
;  that did not exist before the operation, whereas new variables may contain names that pre-existed but were overwritten
;
;$LastChangedBy: jimm $
;$LastChangedDate: 2014-02-11 10:54:32 -0800 (Tue, 11 Feb 2014) $
;$LastChangedRevision: 14326 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/utilities/spd_ui_cleanup_tplot.pro $
;----------



pro spd_ui_cleanup_tplot,tnames_before,create_time_before=create_time_before,del_vars=del_vars,new_vars=new_vars

  compile_opt idl2,hidden
  
  del_vars = ''
  new_vars = ''
  
  tn_before = tnames_before
  
  if keyword_set(create_time_before) then begin
    cn_before = create_time_before
    tn_before_time_hash = [tn_before + time_string(double(cn_before),/msec)]
  endif
  
  tn_after = [tnames('*',create_time=cn_after)]
  tn_after_time_hash = [tn_after + time_string(double(cn_after),/msec)] 
  
  if tn_before[0] ne '' && tn_after[0] ne '' then begin
    del_vars = ssl_set_complement([tn_before],[tn_after])
    ;identifying new variables is trickier because replacement may be a factor
    if keyword_set(cn_before) then begin
      new_var_time_hash = ssl_set_complement([tn_before_time_hash],ssl_set_union([tn_before_time_hash],[tn_after_time_hash])) 
      if size(new_var_time_hash,/n_dim) gt 0 && is_string(new_var_time_hash) then begin
        strmidarray = strmid(new_var_time_hash,0,strlen(new_var_time_hash)-23) ;strip off the times to get the remaining variables for adding
        strmiddims = dimen(strmidarray)
        if n_elements(strmiddims) eq 2 then begin
          new_vars = strmidarray[lindgen(strmiddims[0]),lindgen(strmiddims[1])]
        endif else begin
          new_vars = strmidarray[0]
        endelse
      endif
    endif
  endif else if tn_after[0] ne '' then begin
    del_vars = tn_after
    new_vars = tn_after
  endif
  
  if ~is_string(del_vars) then begin
    del_vars = ['']
  endif
  
  if ~is_string(new_vars) then begin
    new_vars = ['']
  endif
  
  
end

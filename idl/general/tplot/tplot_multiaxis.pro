;+
;Procedure:
;  tplot_multiaxis
;
;Purpose:
;  This procedure functions as a workaround to allow 
;  two y axes when creating line plots with tplot.
;
;Calling Sequence:
;  tplot_multiaxis, left_names, right_names [,positions] [,_extra=extra]
;
;Input:
;  left_names:  String array or space separated list of tplot variables.
;               Each variable will be plotted in a separate panel with a
;               left-aligned y axis.
;  right_names:  String array or space separate list of tplot variables.
;                Each variable will be added to the appropriate panel
;                with a righ-aligned y axis.  If positions are not 
;                specified then this must be the same size as left_names.
;  positions:  Integer array specifying the vertical position [1,N] of 
;              the correspond entry in right_names.  This keyword must
;              be used if left_names has more entries than right_names.  
;  
;  _extra:  Keywords to tplot can also be used here.
;
;Output:
;  None, calls tplot with current settings.
;
;Notes:
;  -Y axis graphical keywords set with "options, 'tvar', ..." should be applied.
;  -Existing "ystyle" and "axis" elements will be clobbered (from limits structure).
;
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2019-02-07 12:15:26 -0800 (Thu, 07 Feb 2019) $
;$LastChangedRevision: 26569 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/tplot/tplot_multiaxis.pro $
;-

pro tplot_multiaxis, left_names, right_names, positions, no_zoffset=no_zoffset, _extra=_extra

    compile_opt idl2

    
    if n_params() lt 2 then begin
      dprint, dlevel=1, 'Please specify lists of left and right hand variables'
      return
    endif
    
    ; the following allows for wildcards to be used in the list of tplot names
    for left_name_idx = 0, n_elements(left_names)-1 do begin
      append_array, left_names_clean, tnames(left_names[left_name_idx])
    endfor
    for right_name_idx = 0, n_elements(right_names)-1 do begin
      append_array, right_names_clean, tnames(right_names[right_name_idx])
    endfor
    
    left_names = left_names_clean
    right_names = right_names_clean
    
    ;if inputs are single element assume they may be space separated list
    left = n_elements(left_names) eq 1 ? strsplit(left_names,' ',/ext) : left_names
    right = n_elements(right_names) eq 1 ? strsplit(right_names,' ',/ext) : right_names
    
    ;check that all requested variables are present
    missing = ssl_set_complement([tnames([left,right])],[left,right])
    if is_string(missing) then begin
      dprint, 'Cannot find variables: '+strjoin(missing,', ')
      return
    endif
    
    ;check that the same variable isn't on both lists
    ;(left/right variables require different options)
    duplicates = ssl_set_intersection([tnames(left)],[tnames(right)]) 
    if is_string(duplicates) then begin
      dprint, 'Cannot plot the same variable(s) on both axes:  '+strjoin(duplicates,', ')
      return
    endif
    
    ;if positions are given then check the input and rebuild the right list
    if n_params() eq 3 then begin
      if ~is_num(positions,/int) || n_elements(positions) ne n_elements(right) then begin
        dprint, dlevel=1, 'Number of positions does not match number of right hand variables '+ $ 
                          'found.  Positions or variable list may be incorrect.'
        return
      endif
      pos_range = minmax(positions)
      if pos_range[0] lt 1 || pos_range[1] gt n_elements(left) then begin
        dprint, dlevel=1, 'Right hand positions out of range'
        return
      endif
      right_temp = strarr(n_elements(left))
      right_temp[positions-1] = right
      right = right_temp
    endif
    
    ;final check just in case
    if n_elements(left) ne n_elements(right) then begin
      dprint, dlevel=1, 'Cannot match left and right lists.  '+ $
        'Make sure names are correct and lists are the same size or positions are specified.'
      return
    endif
    
    ;get indices & lists of left variables with and without right axes
    left_idx = where(right eq '', n_left_only, comp=right_idx, ncomp=n_right)
    left_only = n_left_only gt 0 ? left[left_idx] : ''
    both = n_right gt 0 ? left[right_idx] : ''
    
    ;create lists to be passed to tplot
    ;  -the first call plots left hand variables
    ;  -the second call plots right hand variables but
    ;   must include left_only variables as placeholders
    left_plot_list = left
    right_plot_list = right
    if n_left_only gt 0 then right_plot_list[left_idx] = left_only
    
    ;set appropriate options for variables on plots with left and right axes
    tplot_multiaxis_kludge, both, /left, no_zoffset=no_zoffset
    tplot_multiaxis_kludge, right, /right, no_zoffset=no_zoffset
    
    ;plot
    tplot, left_plot_list, _extra=_extra
    tplot, right_plot_list, /oplot, _extra=_extra
    
    ;remove options that were changed so that variables can be plotted normally again
    ;presumably most users don't touch these, if they do we'll have to store limits structs, barf
    tplot_multiaxis_kludge, [both,right], /reset, no_zoffset=no_zoffset

end
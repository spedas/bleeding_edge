;+
; Fix labeling for L2 esvy_despun.
;
; old_root=. The root dir down to the old CDFs of esvy_despun.
; new_root=. The root dir for the new CDFs.
;-

pro rbsp_efw_phasef_fix_labeling_for_l2_esvy_despun, $
    old_root=old_root

    if n_elements(old_root) eq 0 then message, 'No root dir for old data ...'
    if file_test(old_root) eq 0 then message, old_root+' does not exist ...'

    if n_elements(new_root) eq 0 then message, 'No root dir for new data ...'
    if new_root eq old_root then message, 'Cannot over write ...'
    if file_test(new_root) eq 0 then file_mkdir, new_root


    replace_var_list = list()
    replace_var_list.add, dictionary($
        'old_var', 'vel_gse', $
        'new_var', 'velocity_gse' )
    replace_var_list.add, dictionary($
        'old_var', 'pos_gse', $
        'new_var', 'position_gse' )

    missing_var_list = list()
    missing_var_list.add, dictionary($
        'var', 'flags_all')

end

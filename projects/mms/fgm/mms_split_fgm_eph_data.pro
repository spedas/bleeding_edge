;+
; PROCEDURE:
;         mms_split_fgm_eph_data
;
; PURPOSE:
;         Helper routine for splitting 4-vector position data (X, Y, Z, R)
;         into 2 tplot variables, one for the vector (X, Y, Z), and one for 
;         the magnitude
;
; DFG QL position variables:
;  mms1_ql_pos_gse
;  mms1_ql_pos_gsm
; FGM L2 position variables:
;  mms1_fgm_r_gse_srvy_l2
;  mms1_fgm_r_gsm_srvy_l2
; DFG/L2pre:
;  mms1_pos_gse
;  mms1_pos_gsm
;
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2016-05-03 09:57:57 -0700 (Tue, 03 May 2016) $
;$LastChangedRevision: 21004 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/fgm/mms_split_fgm_eph_data.pro $
;-


pro mms_split_fgm_eph_data, probe=probe, level = level, suffix = suffix, data_rate=data_rate, $
    instrument=instrument, tplotnames = tplotnames
    if undefined(instrument) then instrument = 'fgm'
    if undefined(probe) then probe = 'mms1'
    if undefined(level) then level = 'l2'
    if undefined(data_rate) then data_rate = 'srvy'
    
    if level eq 'ql' then vars = probe + ['_ql_pos_gse', '_ql_pos_gsm']+suffix
    if level eq 'l2pre' then vars = probe + ['_pos_gse', '_pos_gsm', '_'+instrument+'_r_gse_'+data_rate+'_l2pre', '_'+instrument+'_r_gsm_'+data_rate+'_l2pre']+suffix
    if level eq 'l2' then vars = probe + ['_'+instrument+'_r_gse_'+data_rate+'_l2', '_'+instrument+'_r_gsm_'+data_rate+'_l2']+suffix

    for tvar_idx = 0, n_elements(vars)-1 do begin
        tplot_name = vars[tvar_idx]
        get_data, tplot_name, data=pos_data, dlimits=pos_dlimits
        if is_struct(pos_data) && is_struct(pos_dlimits) then begin
            
          store_data, tplot_name + '_vec'+suffix, data={x: pos_data.X, y: [[pos_data.Y[*, 0]], [pos_data.Y[*, 1]], [pos_data.Y[*, 2]]]}, dlimits=pos_dlimits
          store_data, tplot_name + '_mag'+suffix, data={x: pos_data.X, y: pos_data.Y[*, 3]}, dlimits=pos_dlimits

          options, tplot_name + '_mag'+suffix, labels='R'
          options, tplot_name + '_mag'+suffix, ytitle=probe

          ; need to add the newly created variables from the previous procedure to the list of tplot names
          append_array, tplotnames, tplot_name + '_vec'+suffix
          append_array, tplotnames, tplot_name + '_mag'+suffix
        endif else begin
            dprint, dlevel = 0, 'Error, couldn''t split the position variable: ' + vars[tvar_idx]
        endelse
    endfor
end
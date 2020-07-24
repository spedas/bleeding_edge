;+
; PROCEDURE:
;         mms_edp_fix_metadata
;
; PURPOSE:
;         Helper routine for setting EDP metadata
;
;
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2020-07-23 14:51:27 -0700 (Thu, 23 Jul 2020) $
;$LastChangedRevision: 28930 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/edp/mms_edp_fix_metadata.pro $
;-

pro mms_edp_fix_metadata, tplotnames, prefix = prefix, instrument = instrument, data_rate = data_rate, suffix = suffix, level=level
    if undefined(prefix) then prefix = ''
    if undefined(suffix) then suffix = ''
    if undefined(level) then level = ''
    if undefined(instrument) then instrument = 'edp'
    if undefined(data_rate) then data_rate = 'fast'
    
    for data_rate_idx = 0, n_elements(data_rate)-1 do begin
        this_data_rate = data_rate[data_rate_idx]
        
        for sc_idx = 0, n_elements(prefix)-1 do begin
            for name_idx = 0, n_elements(tplotnames)-1 do begin
                tplot_name = tplotnames[name_idx]
    
                case tplot_name of
                    prefix[sc_idx] + '_'+instrument+'_dce_par_epar_'+data_rate+'_'+level+suffix: begin
                      options, /def, tplot_name, 'colors', [1, 0]
                      options, /def, tplot_name, 'labels', ['Error', 'E!D||!N']
                    end
                    prefix[sc_idx] + '_'+instrument+'_dce_gse_'+data_rate+'_'+level+suffix: begin
                      options, /def, tplot_name, 'labflag', 1
                      options, /def, tplot_name, 'colors', [2,4,6]
                      options, /def, tplot_name, 'ytitle', strupcase(prefix[sc_idx]) + '!C' + strupcase(instrument)
                      options, /def, tplot_name, 'labels', ['Ex GSE', 'Ey GSE', 'Ez GSE']
                    end
                    prefix[sc_idx] + '_'+instrument+'_dce_dsl_'+data_rate+'_'+level+suffix: begin
                      options, /def, tplot_name, 'labflag', 1
                      options, /def, tplot_name, 'colors', [2,4,6]
                      options, /def, tplot_name, 'ytitle', strupcase(prefix[sc_idx]) + '!C' + strupcase(instrument)
                      options, /def, tplot_name, 'labels', ['Ex DSL', 'Ey DSL', 'Ez DSL']
                    end
                    prefix[sc_idx] + '_'+instrument+'_hfesp_'+data_rate+'_'+level+suffix: begin
                      options, /def, tplot_name, ylog=1, zlog=1, ysubtitle='[Hz]', ztitle='(V/m)^2/Hz'
                    end
                    else: ; not doing anything
                endcase
            endfor
        endfor
    endfor
end
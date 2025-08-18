;+
; PROCEDURE:
;         mms_fgm_fix_metadata
;
; PURPOSE:
;         Helper routine for setting FGM metadata
;
;
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2016-05-04 07:26:07 -0700 (Wed, 04 May 2016) $
;$LastChangedRevision: 21015 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/fgm/mms_fgm_fix_metadata.pro $
;-

pro mms_fgm_fix_metadata, tplotnames, prefix = prefix, instrument = instrument, data_rate = data_rate, suffix = suffix, level=level
    if undefined(prefix) then prefix = ''
    if undefined(suffix) then suffix = ''
    if undefined(level) then level = ''
    if undefined(instrument) then instrument = 'fgm'
    if undefined(data_rate) then data_rate = 'srvy'
    instrument = strlowcase(instrument) ; just in case we get an upper case instrument
    
    if instrument ne 'fgm' then begin
        instrument_str = level eq 'ql' ? 'FGM QL' : 'FGM'
    endif else instrument_str = 'FGM'
    
    for data_rate_idx = 0, n_elements(data_rate)-1 do begin
        this_data_rate = data_rate[data_rate_idx]
        if level eq 'l2pre' then data_rate_mod = this_data_rate + '_l2pre' else data_rate_mod = this_data_rate

        for sc_idx = 0, n_elements(prefix)-1 do begin
            for name_idx = 0, n_elements(tplotnames)-1 do begin
                tplot_name = tplotnames[name_idx]
    
                case tplot_name of
                    prefix[sc_idx] + '_'+instrument+'_b_bcs_'+data_rate+'_'+level+'_bvec'+suffix: begin
                      options, /def, tplot_name, 'labflag', 1
                      options, /def, tplot_name, 'colors', [2,4,6]
                      options, /def, tplot_name, 'ytitle', strupcase(prefix[sc_idx]) + '!C' + strupcase(instrument_str)
                      options, /def, tplot_name, 'labels', ['Bx BCS', 'By BCS', 'Bz BCS']
                    end
                    prefix[sc_idx] + '_'+instrument+'_b_gse_'+data_rate+'_'+level+'_bvec'+suffix: begin
                      options, /def, tplot_name, 'labflag', 1
                      options, /def, tplot_name, 'colors', [2,4,6]
                      options, /def, tplot_name, 'ytitle', strupcase(prefix[sc_idx]) + '!C' + strupcase(instrument_str)
                      options, /def, tplot_name, 'labels', ['Bx GSE', 'By GSE', 'Bz GSE']
                    end
                    prefix[sc_idx] + '_'+instrument+'_b_dmpa_'+data_rate+'_'+level+'_bvec'+suffix: begin
                      options, /def, tplot_name, 'labflag', 1
                      options, /def, tplot_name, 'colors', [2,4,6]
                      options, /def, tplot_name, 'ytitle', strupcase(prefix[sc_idx]) + '!C' + strupcase(instrument_str)
                      options, /def, tplot_name, 'labels', ['Bx DMPA', 'By DMPA', 'Bz DMPA']
                    end
                    prefix[sc_idx] + '_'+instrument+'_b_gsm_'+data_rate+'_'+level+'_bvec'+suffix: begin
                      options, /def, tplot_name, 'labflag', 1
                      options, /def, tplot_name, 'colors', [2,4,6]
                      options, /def, tplot_name, 'ytitle', strupcase(prefix[sc_idx]) + '!C' + strupcase(instrument_str)
                      options, /def, tplot_name, 'labels', ['Bx GSM', 'By GSM', 'Bz GSM']
                    end
                    prefix[sc_idx] + '_'+instrument+'_b_gse_'+data_rate+'_'+level+suffix: begin
                      options, /def, tplot_name, 'labflag', 1
                      options, /def, tplot_name, 'colors', [2,4,6,8]
                      options, /def, tplot_name, 'ytitle', strupcase(prefix[sc_idx]) + '!C' + strupcase(instrument_str)
                      options, /def, tplot_name, 'labels', ['Bx GSE', 'By GSE', 'Bz GSE', 'B_total']
                      ; options, /def, tplot_name, 'data_att.coord_sys', 'gsm'
                    end
                    prefix[sc_idx] + '_'+instrument+'_b_dmpa_'+data_rate+'_'+level+suffix: begin
                      options, /def, tplot_name, 'labflag', 1
                      options, /def, tplot_name, 'colors', [2,4,6,8]
                      options, /def, tplot_name, 'ytitle', strupcase(prefix[sc_idx]) + '!C' + strupcase(instrument_str)
                      options, /def, tplot_name, 'labels', ['Bx DMPA', 'By DMPA', 'Bz DMPA', 'B_total']
                    end
                    prefix[sc_idx] + '_'+instrument+'_b_gsm_'+data_rate+'_'+level+suffix: begin
                      options, /def, tplot_name, 'labflag', 1
                      options, /def, tplot_name, 'colors', [2,4,6,8]
                      options, /def, tplot_name, 'ytitle', strupcase(prefix[sc_idx]) + '!C' + strupcase(instrument_str)
                      options, /def, tplot_name, 'labels', ['Bx GSM', 'By GSM', 'Bz GSM', 'B_total']
                     ; options, /def, tplot_name, 'data_att.coord_sys', 'gsm'
                    end
                ;; old stuff
                    prefix[sc_idx] + '_'+instrument+'_'+data_rate_mod+'_gse_bvec'+suffix: begin
                        options, /def, tplot_name, 'labflag', 1
                        options, /def, tplot_name, 'colors', [2,4,6]
                        options, /def, tplot_name, 'ytitle', strupcase(prefix[sc_idx]) + '!C' + strupcase(instrument_str)
                        options, /def, tplot_name, 'labels', ['Bx GSE', 'By GSE', 'Bz GSE']
                        options, /def, tplot_name, 'data_att.coord_sys', 'gse'
                    end
                    prefix[sc_idx] + '_'+instrument+'_'+data_rate_mod+'_gse_btot'+suffix: begin
                        options, /def, tplot_name, 'labflag', 1
                        options, /def, tplot_name, 'colors', [0]
                        options, /def, tplot_name, 'ytitle',  strupcase(prefix[sc_idx]) + '!C' + strupcase(instrument_str)
                        options, /def, tplot_name, 'labels', ['B_total']
                    end 
                    prefix[sc_idx] + '_'+instrument+'_'+data_rate_mod+'_gsm_bvec'+suffix: begin
                      options, /def, tplot_name, 'labflag', 1
                      options, /def, tplot_name, 'colors', [2,4,6]
                      options, /def, tplot_name, 'ytitle', strupcase(prefix[sc_idx]) + '!C' + strupcase(instrument_str)
                      options, /def, tplot_name, 'labels', ['Bx GSM', 'By GSM', 'Bz GSM']
                      options, /def, tplot_name, 'data_att.coord_sys', 'gsm'
                    end
                    prefix[sc_idx] + '_'+instrument+'_'+data_rate_mod+'_gsm_btot'+suffix: begin
                      options, /def, tplot_name, 'labflag', 1
                      options, /def, tplot_name, 'colors', [0]
                      options, /def, tplot_name, 'ytitle',  strupcase(prefix[sc_idx]) + '!C' + strupcase(instrument_str)
                      options, /def, tplot_name, 'labels', ['B_total']
                    end
                    prefix[sc_idx] + '_'+instrument+'_'+data_rate_mod+'_dmpa_bvec'+suffix: begin
                        options, /def, tplot_name, 'labflag', 1
                        options, /def, tplot_name, 'colors', [2,4,6]
                        options, /def, tplot_name, 'ytitle', strupcase(prefix[sc_idx]) + '!C' + strupcase(instrument_str)
                        options, /def, tplot_name, 'labels', ['Bx DMPA', 'By DMPA', 'Bz DMPA']
                        options, /def, tplot_name, 'data_att.coord_sys', 'dmpa'
                    end
                    prefix[sc_idx] + '_'+instrument+'_'+data_rate_mod+'_dmpa_btot'+suffix: begin
                        options, /def, tplot_name, 'labflag', 1
                        options, /def, tplot_name, 'colors', [0]
                        options, /def, tplot_name, 'ytitle',  strupcase(prefix[sc_idx]) + '!C' + strupcase(instrument_str)
                        options, /def, tplot_name, 'labels', ['B_total']
                    end
                    prefix[sc_idx] + '_'+instrument+'_'+data_rate_mod+'_gsm_dmpa'+suffix: begin
                        options, /def, tplot_name, 'labflag', 1
                        options, /def, tplot_name, 'colors', [2,4,6,8]
                        options, /def, tplot_name, 'ytitle', strupcase(prefix[sc_idx]) + '!C' + strupcase(instrument_str)
                        options, /def, tplot_name, 'labels', ['Bx GSM', 'By GSM', 'Bz GSM', 'Btotal']
                    end
                    prefix[sc_idx] + '_'+instrument+'_'+data_rate_mod+'_dmpa'+suffix: begin
                        options, /def, tplot_name, 'labflag', 1
                        options, /def, tplot_name, 'colors', [2,4,6,8]
                        options, /def, tplot_name, 'ytitle', strupcase(prefix[sc_idx]) + '!C' + strupcase(instrument_str)
                        options, /def, tplot_name, 'labels', ['Bx DMPA', 'By DMPA', 'Bz DMPA', 'Btotal']
                    end
                    prefix[sc_idx] + '_'+instrument+'_'+data_rate_mod+'_omb'+suffix: begin
                        options, /def, tplot_name, 'labflag', 1
                        options, /def, tplot_name, 'colors', [2,4,6,8]
                        options, /def, tplot_name, 'ytitle', strupcase(prefix[sc_idx]) + '!C' + strupcase(instrument_str) + ' OMB'
                    end
                    prefix[sc_idx] + '_'+instrument+'_'+data_rate_mod+'_bcs'+suffix: begin
                        options, /def, tplot_name, 'labflag', 1
                        options, /def, tplot_name, 'colors', [2,4,6,8]
                        options, /def, tplot_name, 'ytitle', strupcase(prefix[sc_idx]) + '!C' + strupcase(instrument_str) + ' BCS'
                    end
                    prefix[sc_idx] + '_ql_pos_gsm'+suffix: begin
                        options, /def, tplot_name, 'labflag', 1
                        options, /def, tplot_name, 'colors', [2,4,6,8]
                        options, /def, tplot_name, 'labels', ['Xgsm', 'Ygsm', 'Zgsm', 'R']
                    end
                    prefix[sc_idx] + '_ql_pos_gse'+suffix: begin
                        options, /def, tplot_name, 'labflag', 1
                        options, /def, tplot_name, 'colors', [2,4,6,8]
                        options, /def, tplot_name, 'labels', ['Xgse', 'Ygse', 'Zgse', 'R']
                    end
                    else: ; not doing anything
                endcase
            endfor
        endfor
    endfor
end
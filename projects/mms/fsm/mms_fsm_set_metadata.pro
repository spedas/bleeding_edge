;+
; PROCEDURE:
;         mms_fsm_set_metadata
;
; PURPOSE:
;         Sets FSM metadata after loading the data; called from mms_load_fsm
;
;
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2018-02-14 13:56:33 -0800 (Wed, 14 Feb 2018) $
; $LastChangedRevision: 24712 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/fsm/mms_fsm_set_metadata.pro $
;-

pro mms_fsm_set_metadata, tplotnames, data_rate=data_rate, prefix=prefix, level=level, suffix=suffix
  
  for tvar_idx=0, n_elements(tplotnames)-1 do begin
    tplot_name = tplotnames[tvar_idx]

    case tplot_name of
      prefix + '_fsm_b_gse_'+data_rate+'_'+level+suffix: begin
        options, /def, tplot_name, 'labflag', -1
        options, /def, tplot_name, 'colors', [2,4,6]
        options, /def, tplot_name, 'ytitle', strupcase(prefix) + '!CFSM'
        options, /def, tplot_name, 'labels', ['Bx GSE', 'By GSE', 'Bz GSE']
      end
      prefix + '_fsm_b_mag_'+data_rate+'_'+level+suffix: begin
        options, /def, tplot_name, 'labflag', 1
        options, /def, tplot_name, 'ytitle', strupcase(prefix) + '!CFSM'
        options, /def, tplot_name, 'labels', ['B magnitude']
      end

      else: ; not doing anything
    endcase
  endfor
end
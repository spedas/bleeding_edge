;+
; PROCEDURE:
;         mms_set_scm_options
;
; PURPOSE:
;         This procedure sets some default metadata for SCM data products
;
; KEYWORDS:
; 
;$LastChangedBy: egrimes $
;$LastChangedDate: 2016-05-26 14:23:09 -0700 (Thu, 26 May 2016) $
;$LastChangedRevision: 21227 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/scm/mms_set_scm_options.pro $
;-

pro mms_set_scm_options, tplotnames, prefix = prefix,datatype = datatype, coord=coord
  if undefined(prefix) then prefix = ''
  if undefined(coord) then coord = 'gse'

  for sc_idx = 0, n_elements(prefix)-1 do begin
    for name_idx = 0, n_elements(tplotnames)-1 do begin
      tplot_name = tplotnames[name_idx]

      case tplot_name of
        prefix[sc_idx] + '_scm_'+datatype+'_'+coord : begin
          options, /def, tplot_name, 'labflag', 1
          options, /def, tplot_name, 'colors', [2,4,6]
          options, /def, tplot_name, 'ytitle', strupcase(prefix[sc_idx]) +' '+ datatype +' ('+coord+')' ;' SCM'
          options, /def, tplot_name, 'labels', ['1', '2', '3']

        end
        prefix[sc_idx] + '_scm_acb_'+coord+'_scsrvy_srvy_l2': begin
          options, /def, tplot_name, 'labflag', 1
          options, /def, tplot_name, 'colors', [2,4,6]
        end
        prefix[sc_idx] + '_scm_acb_'+coord+'_scb_brst_l2': begin
          options, /def, tplot_name, 'labflag', 1
          options, /def, tplot_name, 'colors', [2,4,6]
        end
        prefix[sc_idx] + '_scm_acb_'+coord+'_schb_brst_l2': begin
          options, /def, tplot_name, 'labflag', 1
          options, /def, tplot_name, 'colors', [2,4,6]
        end
        else: ; not doing anything
      endcase
    endfor
  endfor
end
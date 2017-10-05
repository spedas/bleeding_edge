;+
; PROCEDURE:
;         mms_edi_set_metadata
;
; PURPOSE:
;         Helper routine for setting EDI metadata.
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2016-04-27 15:58:35 -0700 (Wed, 27 Apr 2016) $
;$LastChangedRevision: 20954 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/edi/mms_edi_set_metadata.pro $
;-

pro mms_edi_set_metadata, tplotnames, prefix = prefix, data_rate = data_rate, suffix = suffix
  if undefined(prefix) then prefix = 'mms1'
  if undefined(instrument) then instrument = 'edi'
  if undefined(data_rate) then data_rate = 'srvy'
  if undefined(suffix) then suffix = ''
  instrument = strlowcase(instrument) ; just in case we get an upper case instrument

  for sc_idx = 0, n_elements(prefix)-1 do begin
    for name_idx = 0, n_elements(tplotnames)-1 do begin
      tplot_name = tplotnames[name_idx]

      case tplot_name of
        prefix[sc_idx] + '_'+instrument+'_E_dmpa'+suffix: begin
          options, /def, tplot_name, 'labflag', 1
          options, /def, tplot_name, 'colors', [2,4,6]
          options, /def, tplot_name, 'ytitle', strupcase(prefix[sc_idx]) + ' ' + strupcase(instrument)
          options, /def, tplot_name, 'labels', ['Ex', 'Ey', 'Ez']
        end
        prefix[sc_idx] + '_'+instrument+'_E_bc_dmpa'+suffix: begin
          options, /def, tplot_name, 'labflag', 1
          options, /def, tplot_name, 'colors', [2,4,6]
          options, /def, tplot_name, 'ytitle', strupcase(prefix[sc_idx]) + ' ' + strupcase(instrument) + ' BC'
          options, /def, tplot_name, 'labels', ['Ex', 'Ey', 'Ez']
        end
        prefix[sc_idx] + '_'+instrument+'_v_ExB_dmpa'+suffix: begin
          options, /def, tplot_name, 'labflag', 1
          options, /def, tplot_name, 'colors', [2,4,6]
          options, /def, tplot_name, 'ytitle', strupcase(prefix[sc_idx]) + ' ' + strupcase(instrument)
          options, /def, tplot_name, 'labels', ['Vx', 'Vy', 'Vz']
        end
        prefix[sc_idx] + '_'+instrument+'_v_ExB_bc_dmpa'+suffix: begin
          options, /def, tplot_name, 'labflag', 1
          options, /def, tplot_name, 'colors', [2,4,6]
          options, /def, tplot_name, 'ytitle', strupcase(prefix[sc_idx]) + ' ' + strupcase(instrument) + ' BC'
          options, /def, tplot_name, 'labels', ['Vx', 'Vy', 'Vz']
        end
        else:
      endcase
    endfor
  endfor

end
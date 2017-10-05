;+
; PROCEDURE:
;         mms_dsp_fix_metadata
;
; PURPOSE:
;         Helper routine for setting DSP metadata
;
;
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2016-07-25 14:58:36 -0700 (Mon, 25 Jul 2016) $
;$LastChangedRevision: 21523 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/dsp/mms_dsp_fix_metadata.pro $
;-

pro mms_dsp_fix_metadata, tplotnames, prefix = prefix, instrument = instrument, data_rate = data_rate, suffix = suffix, level=level
  if undefined(prefix) then prefix = ''
  if undefined(suffix) then suffix = ''
  if undefined(level) then level = ''
  if undefined(instrument) then instrument = 'dsp'
  if undefined(data_rate) then data_rate = 'fast'

  for data_rate_idx = 0, n_elements(data_rate)-1 do begin
    this_data_rate = data_rate[data_rate_idx]

    for sc_idx = 0, n_elements(prefix)-1 do begin
      for name_idx = 0, n_elements(tplotnames)-1 do begin
        tplot_name = tplotnames[name_idx]
        case tplot_name of
          prefix[sc_idx] + '_'+instrument+'_bpsd_scm1_'+data_rate+'_'+level+suffix: begin
            options, /def, tplot_name, ysubtitle='[Hz]', ztitle='nT^2/Hz'
            ylim, tplot_name, 0, 0, 1
            zlim, tplot_name, 0, 0, 1
            options, tplot_name, ystyle=1
          end
          prefix[sc_idx] + '_'+instrument+'_bpsd_scm2_'+data_rate+'_'+level+suffix: begin
            options, /def, tplot_name, ysubtitle='[Hz]', ztitle='nT^2/Hz'
            ylim, tplot_name, 0, 0, 1
            zlim, tplot_name, 0, 0, 1
            options, tplot_name, ystyle=1
          end
          prefix[sc_idx] + '_'+instrument+'_bpsd_scm3_'+data_rate+'_'+level+suffix: begin
            options, /def, tplot_name, ysubtitle='[Hz]', ztitle='nT^2/Hz'
            ylim, tplot_name, 0, 0, 1
            zlim, tplot_name, 0, 0, 1
            options, tplot_name, ystyle=1
          end
          prefix[sc_idx] + '_'+instrument+'_bpsd_omni_'+data_rate+'_'+level+suffix: begin
            options, /def, tplot_name, ysubtitle='[Hz]', ztitle='nT^2/Hz'
            ylim, tplot_name, 0, 0, 1
            zlim, tplot_name, 0, 0, 1
            options, tplot_name, ystyle=1
          end
          prefix[sc_idx] + '_'+instrument+'_epsd_omni'+suffix: begin
            options, /def, tplot_name, ysubtitle='[Hz]', ztitle='[(V/m)^2/Hz]', ystyle=1
            ylim, tplot_name, 0, 0, 1
            zlim, tplot_name, 0, 0, 1
          end
          prefix[sc_idx] + '_'+instrument+'_epsd_x'+suffix: begin
            options, /def, tplot_name, ysubtitle='[Hz]', ztitle='[(V/m)^2/Hz]'
            ylim, tplot_name, 0, 0, 1
            zlim, tplot_name, 0, 0, 1
            options, tplot_name, ystyle=1
          end
          prefix[sc_idx] + '_'+instrument+'_epsd_y'+suffix: begin
            options, /def, tplot_name, ysubtitle='[Hz]', ztitle='[(V/m)^2/Hz]'
            ylim, tplot_name, 0, 0, 1
            zlim, tplot_name, 0, 0, 1
            options, tplot_name, ystyle=1
          end
          prefix[sc_idx] + '_'+instrument+'_epsd_z'+suffix: begin
            options, /def, tplot_name, ysubtitle='[Hz]', ztitle='[(V/m)^2/Hz]'
            ylim, tplot_name, 0, 0, 1
            zlim, tplot_name, 0, 0, 1
            options, tplot_name, ystyle=1
          end
          else: ; not doing anything
        endcase
      endfor
    endfor
  endfor
end
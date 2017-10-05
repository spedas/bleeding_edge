;+
; FUNCTION:
;     mms_gui_levels
;
; PURPOSE:
;     Returns list of valid levels for a given instrument
;      (for populating the level listbox in the GUI)
;
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2016-06-28 08:28:42 -0700 (Tue, 28 Jun 2016) $
; $LastChangedRevision: 21380 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/gui/mms_gui_levels.pro $
;-
function mms_gui_levels, instrument
  instrument = strlowcase(instrument)
  valid_levels = hash()
  valid_levels['fgm'] = ['L2']
  valid_levels['hpca'] = ['L2']
  valid_levels['eis'] = ['L2', 'L1b']
  valid_levels['feeps'] = ['L2']
  valid_levels['fpi'] = ['L2']
  valid_levels['scm'] = ['L2']
  valid_levels['edi'] = ['L2']
  valid_levels['edp'] = ['L2']
  valid_levels['dsp'] = ['L2']
  valid_levels['aspoc'] = ['L2']
  valid_levels['mec'] = ['L2']

  if valid_levels.haskey(instrument) then begin
    return, valid_levels[instrument]
  endif else begin
    return, -1 ; not found
  endelse
end
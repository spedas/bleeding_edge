;+
; FUNCTION:
;     mms_gui_datatypes
;
; PURPOSE:
;     Returns list of valid datatypes for a given instrument, data rate and level
;      (for populating the datatype listbox in the GUI)
;
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2016-07-29 09:01:51 -0700 (Fri, 29 Jul 2016) $
; $LastChangedRevision: 21571 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/gui/mms_gui_datatypes.pro $
;-

function mms_gui_datatypes, instrument, rate, level
  instrument = strlowcase(instrument)
  ; default to srvy data for most instruments, fast for FPI/EDP/DSP
  if undefined(rate) && ~array_contains(['fpi', 'edp', 'dsp'], instrument) then rate = 'srvy'
  if undefined(rate) && array_contains(['fpi', 'edp', 'dsp'], instrument) then rate = 'fast'
  if undefined(level) then level = 'l2' else level = strlowcase(level)

  valid_datatypes = hash()
  valid_datatypes['fgm-srvy-l2'] = ['']
  valid_datatypes['fgm-brst-l2'] = ['']
  valid_datatypes['hpca-srvy-l2'] = ['ion', 'moments']
  valid_datatypes['hpca-brst-l2'] = ['ion', 'moments']
  valid_datatypes['eis-brst-l2'] = ['extof', 'phxtof']
  valid_datatypes['eis-srvy-l2'] = ['electronenergy', 'extof', 'phxtof']
  valid_datatypes['eis-srvy-l1b'] = ['electronenergy', 'extof', 'phxtof']
  valid_datatypes['eis-brst-l1b'] = ['electronenergy', 'extof', 'phxtof']
  valid_datatypes['feeps-srvy-l2'] = ['electron', 'ion']
  valid_datatypes['feeps-brst-l2'] = ['electron', 'ion']
  valid_datatypes['fpi-fast-l2'] = ['des-dist', 'dis-dist', 'des-moms', 'dis-moms']
  valid_datatypes['fpi-brst-l2'] = ['des-dist', 'dis-dist', 'des-moms', 'dis-moms']
  valid_datatypes['scm-brst-l2'] = ['scb', 'schb']
  valid_datatypes['scm-fast-l2'] = ['scf']
  valid_datatypes['scm-slow-l2'] = ['scs']
  valid_datatypes['scm-srvy-l2'] = ['scsrvy']
  valid_datatypes['edi-srvy-l2'] = ['amb', 'efield', 'q0']
  valid_datatypes['edi-brst-l2'] = ['amb', 'efield', 'q0']
  valid_datatypes['edp-brst-l2'] = ['dce', 'hmfe', 'scpot']
  valid_datatypes['edp-fast-l2'] = ['dce', 'scpot']
  valid_datatypes['edp-slow-l2'] = ['dce', 'scpot']
  valid_datatypes['edp-srvy-l2'] = ['hfesp']
  valid_datatypes['dsp-fast-l2'] = ['bpsd', 'epsd', 'swd']
  valid_datatypes['dsp-slow-l2'] = ['bpsd', 'epsd']
  valid_datatypes['aspoc-srvy-l2'] = ['aspoc']
  valid_datatypes['mec-srvy-l2'] = ['epht89d', 'epht89q', 'ephts04d']

  if valid_datatypes.haskey(instrument+'-'+rate+'-'+level) then begin
    return, valid_datatypes[instrument+'-'+rate+'-'+level]
  endif else begin
    return, -1 ; not found
  endelse
end
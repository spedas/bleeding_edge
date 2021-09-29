;+
; PROCEDURE:
;         elf_cal_mrmi
;
; PURPOSE:
;         Calibrate ELFIN MRM IDPU data
;
; KEYWORDS:
;         tvars:       tplot variable names to be calibrated
;         level:       'l1' or 'l2', default is 'l1'
;
; EXAMPLES:
;
;         elf> elf_cal_mrmi, tvars
;
; NOTES:
;
;
; HISTORY:
;
;$LastChangedBy: clrussell $
;$LastChangedDate: 2018-12-06 11:58:25 -0700 (Mon, 06 Aug 2018) $
;$LastChangedRevision: 25588 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/elfin/elf_cal_mrmi.pro $
;-
pro elf_cal_mrmi, tvars, level=level

  ; check and initialize parameters
  error = 0
  if undefined(tvars) or tvars[0] EQ '' then begin
    dprint, dlevel=1, 'You must pass at least one tplot variable into elf_cal_mrmi.'
    error = 1
    return
  endif
  if undefined(level) then level = 'l1'

  ; calibration data
  ; TO DO: this should be in a calibration file, for now it's hard coded
  ; elf_get_fgm_cal
  scale_param1 = 1.e5
  scale_param2 = 390.

  ; calibrate mrm data (only level 1 is available at this time)
  if level EQ 'l1' then begin
    for i=0,n_elements(tvars)-1 do begin
      get_data, tvars[i], data=d, dlimits=dl, limits=l
      if is_struct(d) then begin
        bx_nt = scale_param1 * d.y[*,0] / scale_param2
        by_nt = scale_param1 * d.y[*,1] / scale_param2
        bz_nt = scale_param1 * d.y[*,2] / scale_param2        
        b_nt = [[bx_nt], [by_nt], [bz_nt]]
        dl.ysubtitle='[nT]'
        cal_data = {x:d.x, y:b_nt}
        store_data, tvars[i], data=cal_data, dlimits=dl, limits=l
      endif else begin
        dprint, dlevel=1, 'The tplot variable ' + tvars[i] + ' contains no data or is incorrect'
        dprint, dlevel=1, 'Unable to calibrate data.'
        error = 1
        return
      endelse
    endfor
  endif

end
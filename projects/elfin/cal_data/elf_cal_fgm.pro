;+
; PROCEDURE:
;         elf_cal_fgm
;
; PURPOSE:
;         Calibrate ELFIN FGM data
;
; INPUT:
;         tvars:       tplot variable names to be calibrated
; 
; KEYWORDS:
;         level:       processing level 
;         error:       1 indicates an error occurred, 0 indicates success
;         
; EXAMPLES:
;         
;         elf> elf_cal_fgm, tvars, level='l1' 
;
; NOTES:
;
; HISTORY:
;         - egrimes, fixed bug in calibration calculations reported by Andrei, 14 March 2019
;
;$LastChangedBy: clrussell $
;$LastChangedDate: 2018-12-06 11:58:25 -0700 (Mon, 06 Aug 2018) $
;$LastChangedRevision: 25588 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/elfin/elf_cal_fgm.pro $
;-
pro elf_cal_fgm, tvars, level=level, error=error

  ; check and initialize parameters
  error = 0
  if undefined(tvars) or tvars[0] EQ '' then begin
     dprint, dlevel=1, 'You must pass at least one tplot variable into elf_cal_fgm.'
     error = 1
     return
  endif
  if undefined(level) then level = 'l1'
  
  ; calibration data 
  ; TO DO: this should be in a calibration file, for now it's hard coded
  ; elf_get_fgm_cal
  ax1_off=-251.
  ax1_scl=109.2
  ax2_off=-35.
  ax2_scl=111.4
  ax3_off=470.
  ax3_scl=103.4  

  ; get fgm data and calibrate it
  if level EQ 'l1' then begin
     for i=0,n_elements(tvars)-1 do begin
         get_data, tvars[i], data=d, dlimits=dl, limits=l
         if is_struct(d) then begin
            bx_nt = d.y[*,0]/ax1_scl - ax1_off
            by_nt = d.y[*,1]/ax2_scl - ax2_off
            bz_nt = d.y[*,2]/ax3_scl - ax3_off            
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
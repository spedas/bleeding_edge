;+
; PROCEDURE:
;         elf_load_fgm_survey_segments
;
; PURPOSE:
;         Loads the FGM survey segment intervals into a bar that can be plotted
;
; KEYWORDS:
;         tplotname:    name of tplot variable (should be ela_fgs or elb_fgs)
;         no_download:  set this flag to use local data only
;          
;$LastChangedBy: egrimes $
;$LastChangedDate: 2017-08-08 09:33:48 -0700 (Tue, 08 Aug 2017) $
;$LastChangedRevision: 23763 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/elf/common/data_status_bar/elf_load_fast_segments.pro $
;-
pro elf_load_fgm_survey_segments, tplotname=tplotname, no_download=no_download

  ; Get epd fast mode data and create an array of times for the bar display
  get_data, tplotname, data=fgm
  if size(fgm, /type) NE 8 then begin
    dprint, 'No data loaded for '+tplotname
  endif else begin
    for i=0, n_elements(fgm.x)-2 do begin
      append_array, fgm_survey_bar_x, [fgm.x[i],fgm.x[i],fgm.x[i]+1.,fgm.x[i]+1.]
      append_array, fgm_survey_bar_y, [!values.f_nan, 0.,0., !values.f_nan]
    endfor
  endelse

  ; no fast mode data found so nothing to load into tplot
  if undefined(fgm_survey_bar_x) then return
  store_data, 'fgm_survey_bar', data={x:fgm_survey_bar_x, y:fgm_survey_bar_y}
  options, 'fgm_survey_bar',thick=5.5,xstyle=4,ystyle=4,yrange=[-0.001,0.001],ytitle='',$
    ticklen=0,panel_size=0.1, charsize=2.

end
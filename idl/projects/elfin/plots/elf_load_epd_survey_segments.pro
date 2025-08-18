;+
; PROCEDURE:
;         elf_load_epd_survey_segments
;
; PURPOSE:
;         Loads the EPD survey segment intervals into a bar that can be plotted
;
; KEYWORDS:
;         tplotname:    name of tplot variable (should be ela_epdes or elb_ela_epdis)
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2017-08-08 09:33:48 -0700 (Tue, 08 Aug 2017) $
;$LastChangedRevision: 23763 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/elf/common/data_status_bar/elf_load_fast_segments.pro $
;-
pro elf_load_epd_survey_segments, tplotname=tplotname

  ; Get epd survey mode data and create an array of times for the bar display
  get_data, tplotname, data=epd
  if size(epd, /type) NE 8 then begin
    dprint, 'No data loaded for '+tplotname
  endif else begin
    for i=0, n_elements(epd.x)-2 do begin
      append_array, epd_survey_bar_x, [epd.x[i],epd.x[i],epd.x[i]+1.,epd.x[i]+1.]
      append_array, epd_survey_bar_y, [!values.f_nan, 0.,0., !values.f_nan]
    endfor
  endelse

  ; no survey mode data found so nothing to load into tplot
  if undefined(epd_survey_bar_x) then return

  store_data, 'epd_survey_bar', data={x:epd_survey_bar_x, y:epd_survey_bar_y}
  options,'epd_survey_bar',thick=5.5,xstyle=4,ystyle=4,yrange=[-0.001,0.001],ytitle='',$
    ticklen=0,panel_size=0.1, charsize=2., colors=6

end
;+
; PROCEDURE:
;         elf_load_fgm_fast_segments
;
; PURPOSE:
;         Loads the FGM fast segment intervals into a bar that can be plotted
;
; KEYWORDS:
;         tplotname:    name of tplot variable (should be ela_fgf or elb_fgf)
;         probe:        elfin spacecraft name, 'a' or 'b'
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2017-08-08 09:33:48 -0700 (Tue, 08 Aug 2017) $
;$LastChangedRevision: 23763 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/elf/common/data_status_bar/elf_load_fast_segments.pro $
;-
pro elf_load_fgm_fast_segments, tplotname=tplotname, probe=probe 

  ; initialize variables if needed
  if ~keyword_set(tplotname) then tplotname='el'+probe+'_f'

  ; Get FGM fast mode data and create an array of times for the bar display
  fgf_idx = where(tnames('el*') EQ tplotname, ncnt)
  if ncnt EQ 0 then begin
    dprint, 'No fgf fast data loaded'
  endif else begin
    get_data, 'el'+probe+'_fgf', data=fgf
    for i=0, n_elements(fgf.x)-2 do begin
      append_array, fgf_bar_x, [fgf.x[i],fgf.x[i],fgf.x[i]+1.,fgf.x[i]+1.]
      append_array, fgf_bar_y, [!values.f_nan, 0.,0., !values.f_nan]
    endfor
  endelse
  
  ; no fast mode data found so nothing to load into tplot 
  if undefined(fgf_bar_x) then return

  store_data, 'fgf_bar', data={x:fgf_bar_x, y:fgf_bar_y}
  options,'fgf_bar',thick=5.5,xstyle=4,ystyle=4,yrange=[-0.001,0.001],ytitle='',$
    ticklen=0,panel_size=0.06, charsize=2.,color=254

end
;+
; PROCEDURE:
;         elf_load_sun_shadow_bar
;
; PURPOSE:
;         Loads the survey segment intervals into a bar that can be plotted
;
; KEYWORDS:
;         tplotname:    name of tplot variable (should be ela_pos_sm or ela_pos_sm)
;         no_download:  set this flag to force 
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2017-08-08 09:33:48 -0700 (Tue, 08 Aug 2017) $
;$LastChangedRevision: 23763 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/elf/common/data_status_bar/elf_load_fast_segments.pro $
;-

pro elf_load_sun_shadow_bar, tplotname=tplotname, no_download=no_download

  ; Check that the tplot variable exists
  idx = where(tnames(tplotname) EQ tplotname, ncnt)
  if ncnt LT 1 then begin
    dprint, 'No tplot variable named ' + tplotname + ' exists.'
    dprint, 'Please load data for ' + tplotname
    return 
  endif
  
  ; Retrieve spacecraft position data (in GSE coords) and calculate whether
  ; the spacecraft is in sun or shadow   Note: previously used SM)
  get_data, tplotname, data=elfin_pos
  shadflag = intarr(n_elements(elfin_pos.x))
  yre=elfin_pos.y[*,1]/6378.
  zre=elfin_pos.y[*,2]/6378.
  yz_re=yre^2 + zre^2
  shad_idx = where(elfin_pos.y[*,0] LT 0.0 AND yz_re LE 1.0, n_shadow)
  ;yz_re=sqrt(yre^2 + zre^2)
  ;shad_idx = where(yz_re LT 1.0, n_shadow)
  shadflag[shad_idx] = 1
  ; create start and stop times based on sun and shadow intervals
  find_interval, shad_idx, sidx, eidx
  start_times=elfin_pos.x[sidx]
  end_times=elfin_pos.x[eidx]

  ; create an array of times for the shadow bar display 
  for idx=0,n_elements(sidx)-1 do begin  
    append_array, shadow_bar_x, [start_times[idx], start_times[idx], end_times[idx], end_times[idx]]
    append_array, shadow_bar_y, [!values.f_nan, 0.,0., !values.f_nan]
  endfor
  if undefined(shadow_bar_x) then return
  store_data, 'shadow_bar', data={x:shadow_bar_x, y:shadow_bar_y} 

  ; repeat for the sun bar display
  sun_bar_x=[elfin_pos.x[0],elfin_pos.x[0],elfin_pos.x[n_elements(elfin_pos.x)-1],elfin_pos.x[n_elements(elfin_pos.x)-1]]
  sun_bar_y=[!values.f_nan, 0.,0., !values.f_nan]
  store_data, 'sun_bar', data={x:sun_bar_x, y:sun_bar_y}
  ;options,'sun_bar',thick=5.5,xstyle=4,ystyle=4,yrange=[-0.1,0.1],ytitle='',$
  ;  ticklen=0,panel_size=0.1,colors=5, charsize=2.

end
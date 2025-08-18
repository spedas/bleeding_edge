;+
;Procedure:
;  thm_crib_part_slice2d_multi
;
;Purpose:
;  Demonstrate how to create a time series of distribution  
;  slices using a while loop.
;
;See also:
;  thm_crib_part_slice2d
;  thm_crib_part_slice2d_adv
;  thm_crib_part_slice2d_plot
;  thm_crib_part_slice1d
;
;Notes:
;
;
;$LastChangedBy: nikos $
;$LastChangedDate: 2016-11-30 11:43:37 -0800 (Wed, 30 Nov 2016) $
;$LastChangedRevision: 22421 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/examples/advanced/thm_crib_part_slice2d_multi.pro $
;-



;===========================================================
; Load Data
;===========================================================

; Set time range
day = '2008-02-26/'
start_time = time_double(day + '04:50:00')
end_time = time_double(day + '04:55:00')

; pad time range to ensure enough data is loaded
trange=[start_time - 90, end_time + 90]

; set data types
probe = 'b'
datatype = 'psif'
;datatype = 'peif'


; This example will use basic allignment that doesn't require mag & velocity data
thm_load_fit, probe=probe, datatype = 'fgs', trange=trange, suff='_gsm'
thm_load_esa, probe=probe, datatype = 'peib_velocity_gsm', trange=trange
mag_data = 'thb_fgs_gsm'
vel_data = 'thb_peib_velocity_gsm'


; Create array of SST particle distributions
dist_arr = thm_part_dist_array(probe=probe, datatype=datatype, trange=trange, /get_sun)



;===========================================================
;Set options for slice plots
;===========================================================

timewin = 60.   ; set the time window for each slice
increment = 30. ; time increment for next slice's start

;coord = 'gsm'   ; GSM coordinates
coord = 'gsm'
rotation = 'xy'

erange = [0,5e5]; limit energy range

zrange = [2.2e-27, 2.2e-20] ; plot using fixed range



;===========================================================
; Use loop to create multiple slices and export plots
;===========================================================

;initialize the time variable we will be looping over
slice_time = start_time

;keep producing plots until end_time is reached
while slice_time lt end_time do begin
  
  ;Create slice
  thm_part_slice2d, dist_arr, slice_time=slice_time, timewin=timewin, $
                    coord=coord, rotation=rotation, erange=erange, $
                    part_slice=part_slice,  $
                    /two_d_interp, $ ; can work with /geometric too but for SST use gsm (not dsl) due to hole in SST
                    mag_data=mag_data, $    ; specify mag data for rotation
                    vel_data=vel_data, $    ; specify velocity data for vector projection
                    fail=fail

  ;Check for errors,
  ;the FAIL variable will contain a string message if something goes wrong
  if keyword_set(fail) then begin
    print, 'An error occured while creating the slice at '+time_string(slice_time)+':'
    print, fail
  endif else begin

    ;create filename for image
    file_name = time_string(format=2,slice_time) + '_th'+probe+'_'+datatype
  
    ;Call plotting procedure
    thm_part_slice2d_plot, part_slice, $
;                     zrange=zrange, $    ;use constant zrange, uncomment to use
                     sundir = 1, $     ;plot projection of sun direction
                     plotbfield = 1, $
                     export=file_name   ;create .png with specified name in current directory
    stop
  endelse
 
  ;increment the time
  slice_time += increment
  
endwhile


END


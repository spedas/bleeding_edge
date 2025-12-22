;+
; PROCEDURE:     PLOT_PO_OVERLAY
;
; PURPOSE:       Plots the orbit of the POLAR spacecraft over the
;                existing map display.  The plot timespan is acquired
;                through the keyword TIME_ARRAY.
;
; KEYWORDS:
;
;   TIME_ARRAY   The time array for which to get POLAR orbit data.  If
;                EXPAND is set, only the first and last elements of
;                this array are used.
;   EXPAND       Expands the timespan.  The new timespan will be:
;                new = (2*[expand] + 1)*old
;                If this keyword is NOT set, then POLAR orbit data is
;                calculated for the same times as the preloaded data.
;
;   TAG_COLOR    The color of the time stamps.
;   FLAT         A named variable to receive POLAR footprint latitudes
;   FLNG         A named variable to receive POLAR footprint longitudes
;
; CREATED:       97-8-25
;                By J. Rauchleiba
;
;-
pro plot_po_overlay, $
        TIME_ARRAY=time_pts, $
        EXPAND=expand, $
        TAG_COLOR=tag_color, $
        FLAT=flat, $
        FLNG=flng

; Get the timespan over which to plot POLAR data

npts = n_elements(time_pts)
first = time_pts(0)
last = time_pts(npts-1)
tdur = last - first
if keyword_set(expand) then begin
    t1 = first - double(expand)*tdur
    t2 = last + double(expand)*tdur
    time_array=0
endif else begin
    t1 = time_pts
    t2 = 0
    time_array=1
endelse

; Get POLAR orbit data

get_po_orbit, t1, t2, time_array=time_array, delta_t=600, $
  /no_store, struc=po_orbit, /all, status=st
if st NE 0 then message, 'Error getting POLAR orbit data'

; Plot POLAR footprint over the existing display

;;get_data, 'FLAT', data=flat
;;get_data, 'FLNG', data=flng
flat = po_orbit.FLAT
flng = po_orbit.FLNG
oplot, flng, flat, color=fix(.4*!d.n_colors), thick=3, min_value=40
oplot, flng, flat, color=!d.n_colors-1, thick=1, min_value=40
oplot, flng, flat, color=fix(.4*!d.n_colors), thick=3, max_value=-40
oplot, flng, flat, color=!d.n_colors-1, thick=1, max_value=-40

; Add timeticks to footprint

label_foot_ticks, interval=3600, latlim=45, color=tag_color, $
  time=time_pts, latitude=flat, longitude=flng

end

;+
;thm_crib_rego_ucnew.pro
;usage:
; .run thm_crib_rego_ucnew
;
;Purpose: demonstrate loading and displaying data from the Redline
; Emission Geospace Observatory (REGO) all-sky imager array.
;
; REGO data is loaded from the data archive at data.phys.ucalgary.ca.
;
; Calibration structures are built from the REGO skymaps
; (thm_load_asi_cal,/rego).
;
;Written by: Darren Chaddock, 2026-09-23
;-

;------------------------------------------------------------------------------
; 2026-09-23:
;
; PLEASE NOTE - this crib sheet is temporary and will be modified and moved to
; the thm_crib_rego.pro file in the near future.
;------------------------------------------------------------------------------


; set day for REGO example (REGO operations began late 2014)
timespan,'2014-12-01',1,/day

; load keograms for all available REGO stations
;
; NOTE: the archived REGO keograms have a brightening/scaling adjustment applied
; to them. The same scaling is applied throughout the dataset - for every site
; and every date - so keograms are directly comparable from station to station
; and from night to night.
;
; To apply your own scaling, you'll want to work from the raw images instead,
; using thm_load_rego (further down this crib) instead. This loads the full-resolution
; 512x512 frames in raw counts, which you can stretch however you like.
thm_load_ask,/rego,/verbose,/ucalgary_pgm
print,'Data exist for the following stations: '
tplot_names,'*ask*'
stop

; plot keograms of a few stations for the full day
window,0,xsize=700,ysize=850
loadct,0
ylim,'*ask*',0,511
tplot_options,'title','REGO keogram examples'
tplot,['clg_ask_gill','clg_ask_fsmi','clg_ask_resu']
stop

; zoom into a few hours
timespan,'2014-12-01/00:00:00',4,/hours
tplot,['clg_ask_gill','clg_ask_fsmi','clg_ask_resu'],title='Zoom'
stop

; load an hour of full-resolution red-line images for Gillam
;
; NOTE: the archive stores asf data in 1-minute files, and only the files
; covering the requested time range are downloaded and read. Any loaded
; frames are clipped to the range. This behaviour is a change versus SPEDAS 6.1
; and prior. Set /no_time_clip to keep every frame of the fetched files instead,
; matching the previous behaviour.
timespan,'2014-12-01',1,/day
thm_load_rego,site='gill',trange=['2014-12-01/00:00:00','2014-12-01/01:00:00'],/ucalgary_pgm
tplot_names,'clg_rgf*'

; display a single frame
get_data,'clg_rgf_gill',data=d
window,1,xsize=512,ysize=512
dummy=min(abs(d.x-time_double('2014-12-01/00:50:00')),index)
tvscl,alog10(reform(d.y[index,*,*]) > 100)
xyouts,10,10,'clg_rgf_gill  '+time_string(d.x[index]),/device
stop

; create a mosaic from the full-resolution images
; (calibration comes from the REGO skymaps automatically)
thm_rego_create_mosaic,'2014-12-01/00:50:00',/verbose,/ucalgary_pgm
stop

end

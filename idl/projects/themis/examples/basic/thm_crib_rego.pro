;+
;thm_crib_rego.pro
;usage:
; .run thm_crib_rego
;
;Purpose: demonstrate loading and displaying data from the Redline
; Emission Geospace Observatory (REGO) all-sky imager array.
;
; REGO keograms and images are read from the Berkeley clg_l1 CDFs and the
; calibration from the Berkeley rego_l2_asc cal CDFs, in the same way as the
; THEMIS ASI data in thm_crib_asi.
;
;Written by: Darren Chaddock, 2026-08-11
;-

; set day for REGO example (REGO operations began late 2014)
timespan,'2014-12-01',1,/day

; load keograms for all available REGO stations
thm_load_ask,/rego,/verbose
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
; (the hourly CDF covering the range is loaded in full)
timespan,'2014-12-01',1,/day
thm_load_rego,site='gill',trange=['2014-12-01/00:00:00','2014-12-01/01:00:00']
tplot_names,'clg_rgf*'

; display a single frame
get_data,'clg_rgf_gill',data=d
window,1,xsize=512,ysize=512
dummy=min(abs(d.x-time_double('2014-12-01/00:50:00')),index)
tvscl,alog10(reform(d.y[index,*,*]) > 100)
xyouts,10,10,'clg_rgf_gill  '+time_string(d.x[index]),/device
stop

; create a mosaic from the full-resolution images
; (images and calibration come from the Berkeley CDFs)
thm_rego_create_mosaic,'2014-12-01/00:50:00',/verbose
stop

end

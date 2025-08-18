;+
;thm_crib_asi.pro
;usage:
; .run thm_crib_asi
;
; updated with data past 2006-01-01, Oct. 20, 2010
;
;Written by Harald Frey
; $LastChangedBy: kenb-win2000 $
; $LastChangedDate: 2007-02-11 21:26:08 -0500 (Sun, 11 Feb 2007) $
; $LastChangedRevision: 379 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/thmsoc/trunk/idl/themis/examples/thm_crib_asi.pro $
;
;-

; Before starting IDL run the setup(SSL users only)
; source /usr/local/setup/setup_themis
; (same as the idl/themis/setup_themis file in the thmsw distribution.)

;------------------------------------------------------------------------------
; Load keograms for 2008-02-10
;------------------------------------------------------------------------------

thm_init
timespan,'2008-02-10',1,/day
thm_load_ask,/verbose
print,' '
print,'Data exist for the following stations: '
tplot_names,'*ask*'
stop

; set up some options for tplot and plot full day
window,0
loadct,0
YLIM,'*ask*',0,255
ZLIM,'thg_ask_fykn',0,1.e4
ZLIM,'thg_ask_inuv',0,8.e3
ZLIM,'thg_ask_fsim',0,6.e3
ZLIM,'thg_ask_fsmi',0,1.e4
tplot_options, 'title', 'THEMIS ASI Examples'
TPLOT,['thg_ask_fykn','thg_ask_inuv','thg_ask_fsim','thg_ask_fsmi']
stop

; zoom into just four hour2 of data
timespan,'2008-02-10/04:00:00',4,/hours
TPLOT,['thg_ask_fykn','thg_ask_inuv','thg_ask_fsim','thg_ask_fsmi'],title='Zoom'
stop


;------------------------------------------------------------------------------
; load full resolution images for one station
;------------------------------------------------------------------------------
timespan,'2008-02-10/07:00:00',1,/hours
thm_load_asi,site='fykn',datatype='asf'
tplot,'thg_ask_fykn thg_asf_fykn',title='One station example'
window,1,xsize=256,ysize=256
options,'thg_asf_fykn',irange=[3000,10000.]
ctime,/cut
stop

	; create line plot of intensity
wset,0
get_data,'thg_asf_fykn',data=d
totals=total(total(d.y,2),2)
store_data,'fykn_tot',data={x:d.x,y:totals-min(totals)}
tplot,'fykn_tot',title='FYKN total counts'
stop

	; create mosaic from full resolution data
thm_asi_create_mosaic,'2008-02-10/07:13:30',/verbose,exclude='kian'
stop

	; create mosaic from thumbnail data with many options
show_time='2008-02-10/05:50:00'
thm_asi_create_mosaic,show_time,/verbose,$
    /thumb,$						; thumbnails
    exclude=['kuuj','kian'],$				; do not show these stations
    central_lon=-100,central_lat=60.,scale=2.9e7,$	; set area
    projection='AzimuthalEquidistant'			; map projection
stop

;------------------------------------------------------------------------------
; field line traces
;------------------------------------------------------------------------------

	; get position of one spacecraft
thm_load_state,probe='c',coord='gsm',suffix='_gsm'
thm_load_state,probe='a',coord='gsm',suffix='_gsm'

	; trace to the ionosphere
ttrace2iono,'thc_state_pos_gsm',newname='thc_ifoot_geo',external_model='t89',par=2.0D,/km,$
    in_coord='gsm',out_coord='geo'
get_data,'thc_ifoot_geo',data=d
ttrace2iono,'tha_state_pos_gsm',newname='tha_ifoot_geo',external_model='t89',par=2.0D,/km,$
    in_coord='gsm',out_coord='geo'
get_data,'tha_ifoot_geo',data=a

	; transform to Lat/Lon
lon = !radeg * atan(d.y[*,1],d.y[*,0])
lat = !radeg * atan(d.y[*,2],sqrt(d.y[*,0]^2+d.y[*,1]^2))
plots,lon,lat
lon2 = !radeg * atan(a.y[*,1],a.y[*,0])
lat2 = !radeg * atan(a.y[*,2],sqrt(a.y[*,0]^2+a.y[*,1]^2))
plots,lon2,lat2

	; label a specific time
min_diff=min(abs(d.x-time_double(show_time)),index)
	; show footprint
xyouts,lon[index]+0.5,lat[index]+0.1,'THEMIS-P2',/data,charsize=2
plots,lon[index],lat[index],psym=2,symsize=2
plots,lon[index],lat[index],psym=4,symsize=2
min_diff=min(abs(a.x-time_double(show_time)),index)
	; show footprint of TH-A
xyouts,lon2[index]+0.5,lat2[index]+0.1,'THEMIS-P5',/data,charsize=2
plots,lon2[index],lat2[index],psym=2,symsize=2
plots,lon2[index],lat2[index],psym=4,symsize=2
stop

	; reverse colortable in case people want to stop here
tvlct,rr,gg,bb,/get
loadct2,34
print,'The next calculation takes a long time'
print,'Depending on the speed of your computer it may take up to 5 Minutes'
print,'Close application if you do not want to wait that long'
stop

	; run new thm_asi_merge_mosaic
	; create mosaic from full resolution data
tvlct,rr,gg,bb
show_time='2008-02-10/07:13:30'
thm_asi_merge_mosaic,show_time,/verbose,$
    exclude=['kian','pgeo'],/gif_out	
stop

	; set color table back
loadct2,34

end


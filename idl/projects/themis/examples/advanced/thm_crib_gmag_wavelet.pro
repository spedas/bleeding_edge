;+
;Procedure:
;  thm_crib_gmag_wavelet
;
;Purpose:
;  Demonstrate wavelet analysis of ground magnetometer data.
;
;See also:
;  thm_crib_gmag
;  thm_crib_greenland_gmag
;  thm_crib_maccs_gmag
;
;More info:
;  http://themis.ssl.berkeley.edu/instrument_gmags.shtml
;
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2015-02-27 16:08:10 -0800 (Fri, 27 Feb 2015) $
;$LastChangedRevision: 17056 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/examples/advanced/thm_crib_gmag_wavelet.pro $
;-

thm_init

;------------------------------------------------------------------------------
; Load data
;------------------------------------------------------------------------------

;time range
trange = ['2006-10-02', '2006-10-04' ]

;load data
thm_load_gmag, site='ccnv', trange=trange, /subtract_average

;split components into separate tplot variables 
split_vec, 'thg_mag_ccnv'

;?
options,  'thg_mag_ccnv_?' ,/ynozero

;plot
tplot, 'thg_mag_ccnv_?'

stop

;------------------------------------------------------------------------------
; Zoom in on time segment
;------------------------------------------------------------------------------

;time range for segment
tr = ['2006-10-02/16:00','2006-10-03/05:00'] 

;zoom in & plot
tlimit, tr

stop

;------------------------------------------------------------------------------
; Compute the wavelet transform of x component
;------------------------------------------------------------------------------

;compute wavelet
wav_data,'thg_mag_ccnv_x', /kolom, trange=tr, maxpoints=24l*3600*2

;set z axis range and log scaling flag
zlim,'*pow', .0001,.01, 1

;plot
tplot,'*ccnv_x*'

stop

;------------------------------------------------------------------------------
; Display region with Pi2 waves
;------------------------------------------------------------------------------

tr_pi2 = ['2006-10-03/02:13:30', '2006-10-03/03:46:00']

;zoom in & plot
tlimit, tr_pi2

stop

;------------------------------------------------------------------------------
; Display region with PC1(?) waves
;------------------------------------------------------------------------------

tr_pc1   =  ['2006-10-02/18:23:00', '2006-10-02/18:49:30']

;zoom in & plot
tlimit, tr_pc1

stop

;------------------------------------------------------------------------------
; Select custom time range 
;------------------------------------------------------------------------------

;zoom out
tlimit,tr

print, '  Select your own time range of interest:  '
print, '  (left click to select time, right click to end)'

;bring window to front
wshow,0,icon=0

;query for a time range
ctime,my_tr,/silent
if n_elements(my_tr) eq 2 then begin
  tlimit,my_tr
endif else begin
  print, '  Invalid selection, must select two times to specify a time range.
  print, '  Proceeding to next example.'
endelse

stop

; End of crib sheet.

end

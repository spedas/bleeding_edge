;+
;  MICA crib sheet for loading data
;
; NOTE: Spectrograms are loaded in units of log(power)
; 
; do you have suggestions for this crib sheet?
;   please send them to clrussell@igpp.ucla.edu
;-

;;    ===================================
;; 1) Select site and time 
;;    ===================================
site = 'NAL'     
trange=['2019-02-01','2019-02-02']
mica_load_induction, site, trange=trange
;Change the scale for default spectrogram. Note that these spectra
;display log(power)
zlim, 'spectra_x_1Hz_NAL',-4,-2,0
tplot, 'spectra_x_1Hz_NAL'
stop

;;    =======================================
;; 2) Use tplot_names to see what was loaded
;;    =======================================
tplot_names
stop

;;    ============================================================
;; 2) Pass both site and trange parameters directly into routine
;;    ============================================================
mica_load_induction, 'NAL', trange=['2019-03-05','2019-03-06']
;Change the scale for default spectrogram. Note that these spectra
;display log(power)
zlim, 'spectra_y_5Hz_NAL',-4,-2,0
tplot, 'spectra_y_5Hz_NAL'
stop

;;    ===========================================================
;; 4) If timespan is used to set the time you don't need to pass 
;     trange when calling the load routine
;;    ===========================================================
date = '2019-01-31/00:00:00'
timespan,date,1,/day
site = 'NAL'
mica_load_induction, site  
tplot, ['dbdt_x_NAL','dbdt_y_NAL'] ; you can plot two tplot variables in one call
stop

;;    ===================================
;; 5) Request a shorter time frame
;;    ===================================
mica_load_induction, 'NAL', trange=['2019-01-31/04:00:00','2019-01-31/06:00:00']
tplot, ['spectra_y_1Hz_NAL']
; To verify time is shorter
get_data, 'spectra_y_1Hz_NAL', data=d
print, 'To verify start and stop times are correct'
help, d
print, time_string(minmax(d.x))
stop

;;    ===================================
;; 6) Request 2 days
;;    ===================================
mica_load_induction, 'NAL', trange=['2019-01-31','2019-02-02']
tplot, ['spectra_y_1Hz_NAL']
; To verify time includes 2 days
get_data, 'spectra_y_1Hz_NAL', data=d
help, d
print, time_string(minmax(d.x))
stop

;;    ===================================
;; 7) Clip the time frame
;;    ===================================
tr=time_double(['2019-02-01/01:00:00','2019-02-01/02:00:00'])
time_clip, 'spectra_y_5Hz_NAL', tr[0], tr[1], replace=1, error=error
; To verify time includes 2 days
get_data, 'spectra_y_5Hz_NAL', data=d
help, d
print, time_string(minmax(d.x))
stop

;;    ===================================
;; 8) Request Multiple sites
;;    ===================================
mica_load_induction, ['NAL','PG3','PG4'], trange=['2019-01-31','2019-02-02']
tplot, ['spectra_y_1Hz_NAL','spectra_y_1Hz_PG3','spectra_y_1Hz_PG4']
; To verify time includes 2 days
get_data, 'spectra_y_1Hz_NAL', data=d
help, d
print, time_string(minmax(d.x))
stop

; remove tplot variables created so far
del_data, '*NAL*'

end
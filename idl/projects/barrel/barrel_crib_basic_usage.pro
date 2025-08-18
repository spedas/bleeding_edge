PRO barrel_crib_basic_usage

; specify a time range to load
timespan, '2013-01-17', 2, /days        ; 2 days, starting Jan 17th, 2013

; select data (payload, data product, data level, etc)
barrel_load_data, PROBE=['1D','1K'], DATATYPE=['fspc'], LEVEL='L2'
;   e.g., Requests fast spectra (lightcurves), for 
;     payloads '1D' and '1K', at the L2 level

; list available (loaded) data
tplot_names

; plot given TPLOT variable(s) 
;   e.g., FSPC3 for payload '1D'
tplot, 'brl1D_FSPC3'
STOP

; plot multiple TPLOT variables
tplot, ['brl1D_FSPC3','brl1K_FSPC3']
STOP

; load magnetometer data for these payloads 
barrel_load_data, PROBE=['1D','1K'], DATATYPE=['magn'], LEVEL='L2'

; list available (loaded) data
tplot_names
STOP

; search for specific variables with a wildcard
tplot_names, 'brl1D_MAG_?', NAMES=wildcard_matches
; NOTE: single character wildcarded with a '?', yields the 
;   MAG_X, MAG_Y, and MAG_Z components

; group magnetic components together in a pseudovariable
store_data, 'brl1D_MAG_XYZ', DATA=wildcard_matches

; plot FSPC3 and the MAG_XYZ variable for payload 1D
tplot, ['brl1D_FSPC3','brl1D_MAG_XYZ']
STOP

; adjust the plot..
; make all FSPC variables default to a log-scale plot (y-axis)
options, '*_FSPC?', 'ylog', 1

; evenly space the pseudovariable's labels, so they're legible
options, '*_XYZ', 'labflag', 1

; add a title
tplot_options, 'title', 'FSPC3 and MAG components for Payload 1D'

; zoom to 6 hours +/- midnight (Jan 17th to Jan 18th)
tlimit, '2013-01-17/18:00', '2013-01-18/06:00'



END

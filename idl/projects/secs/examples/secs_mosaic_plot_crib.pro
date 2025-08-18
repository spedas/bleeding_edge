;+
; SECS ASI mosaic overlay plot crib sheet
;
; ASI (All Sky Imager) from THEMIS mission
; SECS (Spherical Elementary Currents) data has two data types
; EICS (Equivalent Ionospheric Currents) are the horizontal currents and
; SECA (SEC Amplitudes) are the current amplitudes
;
; Data resolution is 1 minute. Note: Datasets are large. It's recommended smaller time
; ranges be used
;
; The ground based magnetometer stations used to derive the data are available for some dates.
;
; The SECS archive is created and maintained by James Weygand
;
; All data are available at  http://vmo.igpp.ucla.edu
;
; do you have suggestions for this crib sheet?
;   please send them to clrussell@igpp.ucla.edu
;
;-

timespan, '2015-03-23'
tr=timerange()

; plot the EICs data on top of the ASI mosaic plot
eics_overlay_plots, trange=tr
stop

; plot the SECa data on top of the ASI mosaic plot (note if timespan is used
; to set the timerange you do not need to use the trange keyword)
seca_overlay_plots, trange=tr
stop

; create png file (the /createpng keyword is available for both eics and seca plots)
; PNG file format: C:\data\secs\Mosaic/yyyy/mm/dd/ThemisMosaicEICSyyyymmdd_hhmmss
eics_overlay_plots, trange=tr, /createpng
stop

; you can turn off either geo or the mag grid lines by using showgeo and showmag keywords
seca_overlay_plots, trange=tr, /showgeo, /showmag
stop

; for days that have ground based station information the stations will automatically be 
; plotted as well. Station locations are displayed as green stars.
timespan, '2008-03-09'
eics_overlay_plots, /showgeo

print, 'done'

end
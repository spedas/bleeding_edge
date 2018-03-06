;+
; SECS load data crib sheet
; 
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

; load the data

; load 3 minutes worth of 'eics' data
secs_load_data, trange=['2015-10-15/00:00:00', '2015-10-15/00:03:00'], datatype='eics'
; check the tplot variables that were created, geographic latitude and longitude and jx (m/A,
; which points to geographic north) and jy (m/A, which points to geographic east)
tplot_names
stop

secs_load_data, trange=['2015-10-15/00:00:00', '2015-10-15/00:03:00'], datatype='seca'
; check the tplot variables that were create
tplot_names
stop

; if no datatype is specified both types will be downloaded
del_data, '*'
secs_load_data, trange=['2015-10-15/00:00:00', '2015-10-15/00:03:00']
tplot_names
stop

; to extract the data from the tplot variable
get_data, 'secs_eics_latlong', data=dll
help, dll
get_data, 'secs_eics_jxy', data=dxy
help, dxy
get_data, 'secs_seca_amp', data=da
help, da

; plot some data
thm_init
xsize=600
ysize=850
window, 0, xsize=xsize, ysize=ysize
!p.multi=[0,1,3,0,0]
plot, dll.x, dll.y[*,1], psym=2
plot, dxy.x, dxy.y[*,0], psym=4
plot, da.x, da.y, psym=6
stop

; for days that have a list of stations you can use the get_stations keyword
timespan, '2008-03-09'
tr=timerange()
secs_load_data, trange=tr, datatype='eics', /get_stations
tplot_names   ; there should be a new tplot variable 'secs_stations'
get_data, 'secs_stations', data=d
help, d   ; d.x is the date, d.y is the station name, and d.v is the station location
stop

print, 'done'

end
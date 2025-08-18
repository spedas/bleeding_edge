;+
;Procedure:
; thm_crib_make_ae
;
;Purpose:
; This is an example crib sheet that will calculate and plot "pseudo" geomagnetic
; indices (thmAE, thmAU, thmAL) as derived from THEMIS ground magnetometer data.
; In future, it is planned to include ground magnetometer data from other magnetometer
; networks. Note that currently the calculation of these "pseudo" indices does not
; subtract quiet day variation but simply the median.
;
; Open this file in a text editor and then use copy and paste to copy
; selected lines into an idl window.
;
;Notes:
; Written by Andreas Keiling, 15 May 2008
;
; Modifications:
;   Changed name from thm_crib_AE to thm_crib_make_AE, added print info/stops,
;     remove DEL_DATA,'*' command, W.M.Feuerstein, 6/2/2008.
;
; $LastChangedBy: aaflores $
; $LastChangedDate: 2015-05-13 18:00:26 -0700 (Wed, 13 May 2015) $
; $LastChangedRevision: 17598 $
; $URL $
;-




; Example of generating THEMIS indices using all default values:
;
; - ground magnetometer data will be loaded into the active TDAS even if the
;   data already exist as tplot variables in the active TDAS. Hence, the
;   corresponding tplot variables will be overwritten
; - the time resolution is 60 sec (default value)
; - by default, the names of all stations used for calculation are
;   printed on the screen

print,'Enter ".c" to set timespan to "2008-02-14/10:00:00 to 2008-02-14/15:00:00",
print,'call "thm_make_AE", and plot data.
stop
timespan, '2008-02-14/10:00:00', 5,/hour

thm_make_AE

tplot, ['thmAE','thmAU','thmAL']


print,'Enter ".c" to set timespan to "2008-02-14/10:00:00 to 2008-02-14/15:00:00",
print,'call "thm_make_AE" with RES = 5 and /NO_LOAD, and plot data.
stop




; Example of generating THEMIS indices using keywords:
;
; - Ground magnetometer data will not be loaded into the active TDAS environment.
;   This option requires that tplot variables of ground magnetometer data are
;   already in the active TDAS.
; - the time resolution is set to 5 sec
; - By default, the names of all stations used for calculation are
;   printed on the screen.


timespan, '2008-02-14/10:00:00', 5,/hour

thm_make_AE, res=5, /no_load

tplot, ['thmAE','thmAU','thmAL']


end

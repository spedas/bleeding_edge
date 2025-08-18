;+
; PROGRAM: erg_crib_gmag_magdas
;   This is an example crib sheet that will load MAGDAS magnetometer data.
;   Open this file in a text editor and then use copy and paste to copy
;   selected lines into an idl window.
;   Or alternatively compile and run using the command:
;     .run erg_crib_gmag_magdas
;
; NOTE: See the rules of the road.
;       For more information, see http://magdas.serc.kyushu-u.ac.jp/
;
; Written by: T. Segawa, Feb 12, 2013
;             ERG-Science Center, STEL, Nagoya Univ.
;             erg-sc-core at st4a.stelab.nagoya-u.ac.jp
;
;   $LastChangedDate: 2019-03-17 21:51:57 -0700 (Sun, 17 Mar 2019) $
;   $LastChangedRevision: 26838 $
;-

; initialize
erg_init

; set the date and duration (in days)
timespan, '2008-04-03'

; load 1 sec resolution data
erg_load_gmag_magdas_1sec, site='onw daw'

; view the loaded data names
tplot_names

; reset viewport
tplot_options, 'region', [0.05, 0.0, 1.0, 1.0]
options, 'magdas_mag_onw_1sec_hdz','ytitle','MAGDAS!CONW'
options, 'magdas_mag_daw_1sec_hdz','ytitle','MAGDAS!CDAW'

; plot the H, D, and Z components
tplot, ['magdas_mag_*_1sec_hdz']

END

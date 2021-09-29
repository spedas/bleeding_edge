;+
; erg_crib_mepe.pro 
;
; :Description:
; A crib sheet containing basic examples to demonstrate the loading
; and plotting of Medium-energy Particle Experiments - electron
; analyzer (MEP-e) data obtained by
; the ERG (Arase) satellite.  
;
;:Author:
; Tomo Hori, ERG Science Center ( E-mail: tomo.hori _at_ nagoya-u.jp )
;
; Written by: T. Hori
;   $LastChangedDate: 2019-03-17 21:51:57 -0700 (Sun, 17 Mar 2019) $
;   $LastChangedRevision: 26838 $
;-

;; Initialize
erg_init

;; Set a time range
timespan, '2017-03-27'

;; Load the omni-flux data and display the loaded tplot variables
erg_load_mepe, datatype='omniflux'
tplot_names

stop

;; Plot as a spectrogram 
tplot, [ 'erg_mepe_l2_omniflux_FEDO' ]

stop

;; Load the 3-D flux data
erg_load_mepe, datatype='3dflux'
tplot_names

stop

;; Plot
tplot, [ 'erg_mepe_l2_3dflux_FEDU' ]

stop 

;; Load the 3-D flux data and split them into data of each APD
erg_load_mepe, datatype='3dflux', /split_apd 
tplot_names

stop

;; Plot data for APD#07 and #11, for example
tplot, 'erg_mepe_l2_3dflux_FEDU_apd' + ['07', '11']



end

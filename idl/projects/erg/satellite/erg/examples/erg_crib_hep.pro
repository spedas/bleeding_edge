;+
; erg_crib_hep.pro 
;
; :Description:
; A crib sheet containing basic examples to demonstrate the loading
; and plotting of High-energy Particle Experiments (HEP) data obtained by
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
erg_load_hep, datatype='omniflux'
tplot_names

stop

;; Plot as spectrograms 
tplot, [ 'erg_hep_l2_FEDO_H', 'erg_hep_l2_FEDO_L' ]

stop

;; Create tplot variables for line-plots
erg_load_hep, datatype='omniflux', /lineplot
tplot_names

stop

;; Plot as line-plots
tplot, [ 'erg_hep_l2_FEDO_H_line', 'erg_hep_l2_FEDO_L_line' ]




end

;+
;Startup procedure for Space Physics Research Group idl routines.
;Calling procedure:
;@startup
;PURPOSE:  Initializes various settings.
;
;CREATED BY:	Davin Larson, generalized by J. M. Loran
;LAST MODIFICATION:	@(#)startup.pro	1.4 10/03/97
;-
;on_error,1          ;  returns to main program whenever errors occur
;print,'ON_ERROR set to 1...'
;device,pseudo_color=8  ;fixes color table problem for machines with 24-bit color
;loadct2,39              ; rainbow color map
;print,!d.n_colors,' colors available.'

!p.charsize = 1.0


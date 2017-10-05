;+
;PROCEDURE: IUG_CRIB_IPRT
;    A crib sheet to demonstrate how to deal with data from Iitate 
;    planetary radio observatory using udas. You can run this crib 
;    sheet by copying&pasting each command below into the IDL command line. 
;    Or alternatively compile and run using the command:
;        .run iug_crib_iprt
;
; Written by: M. Yoneda, Nov 11, 2011 
; Last Update: M. Yoneda, Jan 30, 2012
;   
;;;;;;;;;;;;;CAUTION;;;;;;;;;;;;;;
;
; To plot data from Iitate planetary radio observatory, libraries for fits 
; files must be installed into your computer (fits_read, sxpar, fits_open, 
; fits_close, gettok, sxdelpar, sxaddpar, and valid_num) in addition to  the 
; udas and tdas.  They are available at http://idlastro.gsfc.nasa.gov/fitsio.html.
; You can download these procedures by running get_fitslib.
;
;
;-


;Initialize
 
thm_init 
;-----------------
;    Program
;-----------------


;Specify the time span.
timespan, '2010-11-01',10,/min

;Load the data to plot.
iug_load_iprt
zlim,'iprt_sun_L',20,100
zlim,'iprt_sun_R',20,100
tplot,['iprt_sun_L','iprt_sun_R']

; Title
; tplot_options, 'title', 'Sample plot of IPRT solar radio data' 

; Plot
tplot

end

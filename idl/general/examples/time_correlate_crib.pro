;+
; NAME:
;       time_correlate_crib.pro 
;
; PURPOSE:
;       crib sheet demonstrating the use of:
;       ssl_general/misc/ssl_correlate_tplot
;      
;
;
; CATEGORY:
;       THEMIS-SOC
;
; CALLING SEQUENCE:
;       .run time_correlate_crib.pro
;
; OUTPUTS:
;       
; KEYWORDS:
;
; COMMENTS: 
;
;
; PROCEDURE:
;
; EXAMPLE:
;
; MODIFICATION HISTORY:
;       Written by: Patrick Cruce(pcruce@gmail.com) 2007-05-24 V1.0
;
; KNOWN BUGS:
;-

print, "--- Start of crib sheet ---"
timespan, '2007-04-08'

thm_load_state, /get_support_data

thm_load_fgm,probe=['a'],lev=1,type = 'raw', /get_support_data

;this is the simplest possible call
;look at the thm_correlate_tplot.pro file header to see all the neat
;arguments 
ssl_correlate_tplot, 'tha_fge', 0, 'tha_fgl', 0, 'fgm_x_shift', BIN_SIZE = 60

ssl_correlate_tplot, 'tha_fge', 1, 'tha_fgl', 1, 'fgm_y_shift', BIN_SIZE = 60

ssl_correlate_tplot, 'tha_fge', 2, 'tha_fgl', 2, 'fgm_z_shift', BIN_SIZE = 60

tplot, ['fgm_x_shift', 'fgm_y_shift', 'fgm_z_shift']

tlimit, '2007-04-08 07:20:00','2007-04-08 07:40:00'

print, 'This plot is the time v shift for fge and fgl'
print, 'Blank areas are where there was too little overlap or too poor corrletation to correlate functions'
print, 'Values at the edges of the curves are erroneous. I assume this is a byproduct of the mysterious math performed by the idl correlation function.'

stop
 
;dummy data example
 
store_data,'dummy_1',data={x:time_double('2007-04-08')+dindgen(3600*4)/4,y:sin(!DPI/32*dindgen(3600*4))}
store_data,'dummy_2',data={x:(time_double('2007-04-08')+dindgen(3600*4)/4)+((dindgen(3600*4))mod 32)*(1./32.),y:sin(!DPI/32*dindgen(3600*4))}
 
ssl_correlate_tplot, 'dummy_1',0, 'dummy_2', 0, 'dummy_shift', BIN_SIZE = 60
 
tplot,'dummy_shift'
tlimit,'2007-04-08','2007-04-08/01:00:00'

print,'This plot shows the amount of shift in seconds at each time required to maximally correlate, each 60 second bin in the dummy data.'
 
print, "--- End of crib sheet ---"

end

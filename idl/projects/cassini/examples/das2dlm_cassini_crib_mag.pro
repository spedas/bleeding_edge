;+
; PRO:  das2dlm_cassini_crib_mag
;
; Description:
;   A crib sheet demonstrates how to load and plot Cassini data
;   Note, it requres das2dlm library
;
; CREATED BY:
;   Alexander Drozdov (adrozdov@ucla.edu)
;
; $LastChangedBy: adrozdov $
; $Date: 2020-10-09 18:16:50 -0700 (Fri, 09 Oct 2020) $
; $Revision: 29237 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/cassini/examples/das2dlm_cassini_crib_mag.pro $
;-

; Load the mag data and display the loaded tplot variable
das2dlm_load_cassini_mag_mag, trange=['2013-01-01', '2013-01-02']

; Display tplot variables 
tplot_names

; Plot mag data 
tplot, 'cassini_mag_B_mag_01'

end
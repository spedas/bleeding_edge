;+
;
; Name: crib_calculate_lshell
; 
; Purpose: Demonstrates usage of basic L-shell code 
;          using THEMIS data (calculate_lshell.pro) 
; 
; Note: The l-shell code requires the IDL geopack routines 
; 
; 
; $LastChangedBy: jwl $
; $LastChangedDate: 2021-07-28 18:16:15 -0700 (Wed, 28 Jul 2021) $
; $LastChangedRevision: 30156 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/external/IDL_GEOPACK/examples/crib_calculate_lshell.pro $
;
;-


;Set day
timespan, '2007-03-23'

;This example will use all THEMIS probes on the given day
probes = ['a','b','c','d','e']

for i=0, n_elements(probes)-1 do begin
  probe = probes[i]
  
  ;Get position in GSM coords
  thm_load_state, probe=probe, datatype='pos' , coord='gsm'
  
  ;Convert units to RE
  tkm2re, 'th'+probe+'_state_pos'
  
  ;Get data and put into required form ([time, x, y, z])
  get_data, 'th'+probe+'_state_pos_re', data = d, dlimits=dl
  data = transpose( [[d.x],[d.y]] )
  
  ;Get l-shell value
  shells = calculate_lshell(data)
  
  ;Store data
  store_data, 'lshell_value_th'+probe, data = {x:d.x ,y:shells }
  
endfor

;Plot 
tplot, 'lshell_value_th'+probes

end

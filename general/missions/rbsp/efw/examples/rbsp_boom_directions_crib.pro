;+
; NAME: rbsp_boom_directions_crib
; SYNTAX:
; PURPOSE: find the pointing direction of the EFW booms in GSE coord
; INPUT: times -> array of times to find boom directions for
;		 probe -> 'a' or 'b'
; OUTPUT: tplot variables of each antenna direction in GSE ['vecu_gse','vecv_gse','vecw_gse']
; KEYWORDS:
; HISTORY: Written by Aaron W Breneman 05/12/2014
; VERSION:
;   $LastChangedBy: nikos $
;   $LastChangedDate: 2020-05-21 20:36:46 -0700 (Thu, 21 May 2020) $
;   $LastChangedRevision: 28720 $
;   $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/rbsp/efw/examples/rbsp_boom_directions_crib.pro $
;-


pro rbsp_boom_directions_crib,times,probe,no_spice_load=no_spice_load


;Test times
t0 = time_double('2013-07-17/00:00')
t1 = time_double('2013-07-17/00:05')
ntimes = 15.*60.
times = dindgen(ntimes) + t0
probe = 'a'
timespan,'2013-07-17'


;Load the rotation matrix from UVW to DSC
if ~keyword_set(no_spice_load) then $
  rbsp_efw_position_velocity_crib,/noplot,/notrace else $
  rbsp_efw_position_velocity_crib,/noplot,/notrace,/no_spice_load

rbsp_load_state,probe=probe,/no_spice_load,$
  datatype=['spinper','spinphase','mat_dsc','Lvec']


;Create boom direction unit vectors in uvw
data = replicate(1,n_elements(times))
zeros = replicate(0,n_elements(times))
datau = [[data],[zeros],[zeros]]
datav = [[zeros],[data],[zeros]]
dataw = [[zeros],[zeros],[data]]


;Create tplot variables
da = {coord_sys:'uvw'} & dl = {data_att:da}
store_data,'uvw_vecu',data={x:times,y:datau},dlimits=dl
store_data,'uvw_vecv',data={x:times,y:datav},dlimits=dl
store_data,'uvw_vecw',data={x:times,y:dataw},dlimits=dl


;Rotate each unit vector to DSC
rbsp_uvw_to_dsc,probe,'uvw_vecu',/no_spice_load
rbsp_uvw_to_dsc,probe,'uvw_vecv',/no_spice_load
rbsp_uvw_to_dsc,probe,'uvw_vecw',/no_spice_load


;Rotate to GSE
rbsp_cotrans,'uvw_vecu_dsc','vecu_gse',mat_dsc='rbsp'+probe+'_mat_dsc',/dsc2gse
rbsp_cotrans,'uvw_vecv_dsc','vecv_gse',mat_dsc='rbsp'+probe+'_mat_dsc',/dsc2gse
rbsp_cotrans,'uvw_vecw_dsc','vecw_gse',mat_dsc='rbsp'+probe+'_mat_dsc',/dsc2gse


ylim,['uvw_vecu','uvw_vecv','uvw_vecw'],-2,2
tplot,['uvw_vecu','uvw_vecv','uvw_vecw']
stop

ylim,['uvw_vecu_dsc','uvw_vecv_dsc','uvw_vecw_dsc'],-1,1
tplot,['uvw_vecu_dsc','uvw_vecv_dsc','uvw_vecw_dsc']
stop

ylim,['vecu_gse','vecv_gse','vecw_gse','rbsp'+probe+'_spinaxis_direction_gse'],-1,1
tplot,['vecu_gse','vecv_gse','vecw_gse','rbsp'+probe+'_spinaxis_direction_gse']
stop

end

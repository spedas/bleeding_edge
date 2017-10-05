; Created by Jianbao Tao, SSL/UCB.

; Set up
date = '2015-08-07'
sc = 'a'
rbx = 'rbsp' + sc + '_'

timespan, date

; Load spacecraft state information. This step is crucial.
rbsp_load_state, probe = sc

; Check if spin periods have gap.
tlist = rbx + ['spinper']
tplot, tlist

; Load esvy in UVW, which will be fed into rbsp_spinfit.
rbsp_load_efw_waveform, probe = sc, datatype = 'esvy', coord = 'uvw'
; renaming
get_data, rbx + 'efw_esvy', data = d, dlim = dl, lim = lim
store_data, rbx + 'esvy_uvw', data = d, dlim = dl, lim = lim

; Load esvy in DSC, which will be compared with spin-fit results.
rbsp_load_efw_waveform, probe = sc, datatype = 'esvy'
; renaming
get_data, rbx + 'esvy_clean', data = d, dlim = dl, lim = lim
store_data, rbx + 'esvy_dsc', data = d, dlim = dl, lim = lim

; Check
tlist = rbx + ['esvy_dsc', 'esvy_uvw']
tplot, tlist

tvar = rbx + 'esvy_uvw'
; E12
rbsp_spinfit, tvar, plane_dim = 0  ; takes about 30 seconds
get_data, rbx + 'esvy_uvw_spinfit', data = d, dlim = dl, lim = lim
store_data, rbx + 'esvy_uvw_spinfit_e12', data = d, dlim = dl, lim = lim
; E34
rbsp_spinfit, tvar, plane_dim = 1  ; takes about 30 seconds
get_data, rbx + 'esvy_uvw_spinfit', data = d, dlim = dl, lim = lim
store_data, rbx + 'esvy_uvw_spinfit_e34', data = d, dlim = dl, lim = lim

; Separate components
split_vec, rbx + 'esvy_uvw_spinfit_e12'
options, rbx + 'esvy_uvw_spinfit_e12_x', colors = [2], labels = ['sfit e12']
options, rbx + 'esvy_uvw_spinfit_e12_y', colors = [2], labels = ['sfit e12']
options, rbx + 'esvy_uvw_spinfit_e12_z', colors = [2], labels = ['sfit e12']

split_vec, rbx + 'esvy_uvw_spinfit_e34'
options, rbx + 'esvy_uvw_spinfit_e34_x', colors = [6], labels = ['sfit e34']
options, rbx + 'esvy_uvw_spinfit_e34_y', colors = [6], labels = ['sfit e34']
options, rbx + 'esvy_uvw_spinfit_e34_z', colors = [6], labels = ['sfit e34']

split_vec, rbx + 'esvy_dsc'
options, rbx + 'esvy_dsc_x', colors = [0], labels = ['DSC']
options, rbx + 'esvy_dsc_y', colors = [0], labels = ['DSC']
options, rbx + 'esvy_dsc_z', colors = [0], labels = ['DSC']

store_data, rbx + 'edsc_x', data = rbx + ['esvy_dsc_x', $
  'esvy_uvw_spinfit_e12_x', 'esvy_uvw_spinfit_e34_x']
options, rbx + 'edsc_x', labflag = 1

store_data, rbx + 'edsc_y', data = rbx + ['esvy_dsc_y', $
  'esvy_uvw_spinfit_e12_y', 'esvy_uvw_spinfit_e34_y']
options, rbx + 'edsc_y', labflag = 1

store_data, rbx + 'edsc_z', data = rbx + ['esvy_dsc_z', $
  'esvy_uvw_spinfit_e12_z', 'esvy_uvw_spinfit_e34_z']
options, rbx + 'edsc_z', labflag = 1



; Final results
tplot, rbx + ['edsc_x', 'edsc_y', 'edsc_z']


; Load and overplot eclipse times 
rbsp_load_eclipse_predict,sc,date
get_data,'rbsp'+sc+'_umbra',data=eu
get_data,'rbsp'+sc+'_penumbra',data=ep

if is_struct(eu) then timebar,eu.x,color=50
if is_struct(eu) then timebar,eu.x + eu.y,color=50
if is_struct(ep) then timebar,ep.x,color=80
if is_struct(ep) then timebar,ep.x + ep.y,color=80



;This will take the E_ALONG_V and E_NEAR_B variables and create a
;Spin-plane variable in GSE coordinates
;A model B variable is needed, this can be obtasined from the HR_DCB
;files from Bob Strangeway, but can be added to the version 2 of ESV
;output, once SDT is working for me

;E_NEAR_B is along the direction of ((SxB)xS) where S is the spin
;axis, and B is a unit vector in the direction of a model B.
;E_ALONG_V is in the direction of SxB, 90 degrees off, but still in
;the spin plane.

;For a day in 1996
timespan, '1996-12-11'
;Load B model
fa_load_mag_hr_dcb              ;use variable 'fa_hr_dcb_B_model_gei'

;Load EFI data, can be loaded by orbit too
fa_despun_e_load                ;use variable 'fa_spin_axis_gse'

;It's important to get the interpolation out of the way for unit
;vectors, so interpolate the b_model field to the time array for
;the spin axis variable in the EFI file, use tinterpol_mxn
tinterpol_mxn, 'fa_hr_dcb_B_model_gei', 'fa_spin_axis_gse', newname = 'B_model_gei'

;Next coordinate transform B to GSE
cotrans, 'B_model_gei', 'B_model_gse', /gei2gse

;get a unit vector for B_GSE
get_data, 'B_model_gse', data = bmod
btot = sqrt(total(bmod.y^2, 2))
For j = 0, 2 Do bmod.y[*, j] = bmod.y[*,j]/btot
store_data, 'B_unit_gse', data = bmod

;get a unit vector for the spin axis
get_data,'fa_spin_axis_gse',data = s
store_data, 'S_unit_gse', data = {x:s.x, y:s.y}

;The direction of E_ALONG_V is SxB
tcrossp, 'S_unit_gse', 'B_unit_gse', newname = 'SxB_gse'

;The direction of E_NEAR_B is (SxB)xS
tcrossp, 'SxB_gse', 'S_unit_gse', newname = 'SxBxS_gse'

;Use tinterpol_mxn to get the two vectors to the same time array as the field variables
tinterpol_mxn, 'SxB_gse', 'fa_e_along_v', newname = 'SxB_unit_gse'
tinterpol_mxn, 'SxBxS_gse', 'fa_e_near_b', newname = 'SxBxS_unit_gse'

;Normalize for unit vectors:
get_data, 'SxB_unit_gse', data = sxb
sxbtot = sqrt(total(sxb.y^2, 2))
For j = 0, 2 Do sxb.y[*, j] = sxb.y[*,j]/sxbtot
store_data, 'SxB_unit_gse', data = sxb

get_data, 'SxBxS_unit_gse', data = sxbxs
sxbxstot = sqrt(total(sxbxs.y^2, 2))
For j = 0, 2 Do sxbxs.y[*, j] = sxbxs.y[*,j]/sxbxstot
store_data, 'SxBxS_unit_gse', data = sxbxs

;Now get the E field in GSE
get_data, 'fa_e_along_v', data = eav
get_data, 'fa_e_near_b', data = enb

;multiply the components of the directional vectors by the magnitudes of E_ALONG_V and E_NEAR_B
;Need an ntimes, 3 array:
e_gse = sxb.y & e_gse[*] = 0
For j = 0, 2 Do e_gse[*, j] = eav.y*sxb.y[*, j] + enb.y*sxbxs.y[*, j]

;And a tplot variable
store_data, 'fa_e_nearb_and_alongv_gse', data = {x:eav.x, y:e_gse}

;Did this work? 
test_0 = sqrt(total(e_gse^2, 2))
test_1 = sqrt(eav.y^2+enb.y^2)

print, 'Comparison of data from E_ALONG_V, E_NEAR_B and new variable in GSE:'
print, 'This should look like round-off error'
print, minmax(test_1-test_0)
;  -7.0594979e-08   5.6159479e-08
 
End




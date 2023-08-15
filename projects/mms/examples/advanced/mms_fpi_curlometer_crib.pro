;+
; PROCEDURE:
;         mms_fpi_curlometer_crib
;
; PURPOSE:
;         Crib sheet showing how to combine curlometer calculations with FPI data; the output figure includes:
;         
;         1) DIS energy spectra
;         2) DES energy spectra
;         3) B-field in GSE coordinates
;         4) div/curl
;         5) J (Jx, Jy, Jz and J magnitude)
;         6) DES velocity (Vx, Vy, Vz and V magnitude)
;         7) DIS and DES densities
;         8) DES temperatures
;         9) DIS temperatures
;
;
; Suggestions for this crib sheet:
;     https://github.com/spedas/bleeding_edge/issues
;
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2023-08-14 12:51:35 -0700 (Mon, 14 Aug 2023) $
; $LastChangedRevision: 31999 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/examples/advanced/mms_fpi_curlometer_crib.pro $
;-

trange = ['2017-01-31/10:27:34', '2017-01-31/10:27:56']
probe = '1' ; must be a string

mms_load_fpi, probe=probe, datatype=['des-moms', 'dis-moms'], /center, trange=trange, data_rate='brst', /time_clip
mms_load_fgm, probes=[1, 2, 3, 4], trange=trange, data_rate='brst', /time_clip, /get_fgm_ephem

; do the curlometer calculations; note: the input data must be in GSE coordinates
mms_lingradest, fields=['mms1_fgm_b_gse_brst_l2_bvec', $
                        'mms2_fgm_b_gse_brst_l2_bvec', $
                        'mms3_fgm_b_gse_brst_l2_bvec', $
                        'mms4_fgm_b_gse_brst_l2_bvec'], $
                positions=['mms1_fgm_r_gse_brst_l2', $
                           'mms2_fgm_r_gse_brst_l2', $
                           'mms3_fgm_r_gse_brst_l2', $
                           'mms4_fgm_r_gse_brst_l2']

calc, '"div/curl"="divB_nT/1000km"/"absCB"'

; calculate the magnitude of J
calc, '"Jmag"=sqrt("jx"^2+"jy"^2+"jz"^2)'
store_data, 'j_data', data='Jmag jx jy jz'

; combine various variables so that they're plotted in the same panels
store_data, 'dis_temp', data='mms'+probe+'_dis_temppara_brst mms'+probe+'_dis_tempperp_brst'
store_data, 'des_temp', data='mms'+probe+'_des_temppara_brst mms'+probe+'_des_tempperp_brst'
store_data, 'fpi_density', data='mms'+probe+'_dis_numberdensity_brst mms'+probe+'_des_numberdensity_brst'

; add electron velocity magnitude to the velocity variable
get_data, 'mms'+probe+'_des_bulkv_gse_brst', data=vel_data, dlimits=vel_metadata
vmag=sqrt(vel_data.Y[*, 0]^2+vel_data.Y[*, 1]^2+vel_data.Y[*, 2]^2)
store_data, 'des_vel', data={x: vel_data.x, y: [[vel_data.Y[*, 0]], [vel_data.Y[*, 1]], [vel_data.Y[*, 2]], [vmag]]}, dlimits=vel_metadata

; set ytitle/subtitles
options, 'mms'+probe+'_dis_energyspectr_omni_brst', ytitle='DIS'
options, 'mms'+probe+'_dis_energyspectr_omni_brst', ysubtitle='energy (eV)'
options, 'mms'+probe+'_des_energyspectr_omni_brst', ytitle='DES'
options, 'mms'+probe+'_des_energyspectr_omni_brst', ysubtitle='energy (eV)'
options, 'mms'+probe+'_fgm_b_gse_brst_l2', ytitle='B GSE'
options, 'mms'+probe+'_fgm_b_gse_brst_l2', ysubtitle='(nT)'
options, 'j_data', ytitle='j'
options, 'j_data', ysubtitle='(nA/m^2)'
options, 'fpi_density', ytitle='N'
options, 'fpi_density', ysubtitle='(cm^-3)'
options, 'des_temp', ytitle='T'
options, 'des_temp', ysubtitle='(eV)'
options, 'dis_temp', ytitle='T'
options, 'dis_temp', ysubtitle='(eV)'
options, 'des_vel', ytitle='Ve'
options, 'des_vel', ysubtitle='(km/s)'

; set labels
options, 'mms'+probe+'_dis_temppara_brst', labels='Ti_para', colors=6
options, 'mms'+probe+'_dis_tempperp_brst', labels='Ti_perp', colors=0
options, 'dis_temp', labflag=-1
options, 'mms'+probe+'_des_temppara_brst', labels='Te_para', colors=6
options, 'mms'+probe+'_des_tempperp_brst', labels='Te_perp', colors=0
options, 'des_temp', labflag=-1
options, 'mms'+probe+'_dis_numberdensity_brst', linestyle=2 ; dashed ions
options, 'mms'+probe+'_dis_numberdensity_brst', labels='--Ni', colors=0
options, 'mms'+probe+'_des_numberdensity_brst', labels='Ne', colors=0
options, 'mms'+probe+'_fgm_b_gse_brst_l2', labels=['B GSE_x', 'B GSE_y', 'B GSE_z', '|B GSE|']
options, 'fpi_density', labflag=-1
options, 'des_vel', labels=['Ve_GSE_x', 'Ve_GSE_y', 'Ve_GSE_z', '|Ve_GSE|']
options, 'des_vel', colors=[2, 4, 6, 0]
options, 'des_vel', labflag=1
options, 'div/curl', labels='divB/curlB'
options, 'div/curl', labflag=-1
options, 'Jmag', labels='|j_curl|', colors=0
options, 'j_data', labflag=-1

; set ranges
ylim, 'div/curl', 1e-2, 1e1, 1

; create the figure
time_stamp, /off

tplot, ['mms'+probe+'_dis_energyspectr_omni_brst', $
        'mms'+probe+'_des_energyspectr_omni_brst', $
        'mms'+probe+'_fgm_b_gse_brst_l2', $
        'div/curl', $
        'j_data', $
        'des_vel', $
        'fpi_density', $
        'des_temp', $
        'dis_temp']
        
stop
end
;
; NAME:
;    thm_scpot_density
;
; PURPOSE:
;    A crib showing how to convert the spacecraft potential to the electron density
;
; MODIFICATIONS:
;    Written by: Toshi Nishimura@UCLA, 05/02/2009, modified 12/11/2012,12/27/2017 (toshi at atmos.ucla.edu)
;
;    Collaborators: Vassilis Angelopoulos and John Bonnell
;    See the header of thm_scpot_density.pro for more detailed instructions
;    It is recommended to contact them before presentations or publications using the data created by this code. Contact Toshi if you have technical questions or want him to check data quality.
;

;set timespan
timespan,'2013-1-1'

;set probe
probe='d'

;Make sure that the coefficient files (th?_scpot_density_coefficients.sav) exist.
;The file path can be changed in thm_scpot_density.pro
;print,file_search('th'+probe+'_scpot_density_coefficients.sav')

;Get density from the spacecraft potential: Slow survey
thm_scpot_density,probe=probe
tplot,'th'+probe+'_pxxm_density'
stop

;Get density from the spacecraft potential: Slow survey
thm_scpot_density,probe=probe,datatype_esa='peer'
tplot,'th'+probe+'_pxxm_density'
stop

;Get density from the spacecraft potential: Fast survey
thm_scpot_density,probe=probe,datatype_efi='vaf'
tplot,'th'+probe+'_vaf_density'
stop

;Get density from the spacecraft potential: Merge fast and slow survey data
thm_scpot_density,probe=probe,datatype_efi='vaf',/merge
tplot,'th'+probe+'_vaf_density'
stop

;Get density from the spacecraft potential: Particle burst
thm_scpot_density,probe=probe,datatype_efi='vap',datatype_esa='peeb'
tplot,'th'+probe+'_vap_density'
stop

;Get density from the spacecraft potential: Wave burst
thm_scpot_density,probe=probe,datatype_efi='vaw',datatype_esa='peeb'
tplot,'th'+probe+'_vaw_density'
stop


;Get density from the spacecraft potential: Slow survey, use
;/scpot_esa
thm_scpot_density,probe=probe,/scpot_esa,suffix='_scpot_esa'
tplot,'th'+probe+'_pxxm_density_scpot_esa'
stop

;Density at constant scpot, shows how to use the scpot_in keyword
copy_data, 'th'+probe+'_pxxm_scpot', 'th'+probe+'_pxxm_scpot_3'
get_data, 'th'+probe+'_pxxm_scpot_3', data=scp3
scp3.y[*] = 3.0
store_data, 'th'+probe+'_pxxm_scpot_3', data=scp3
thm_scpot_density,probe=probe,scpot_in='th'+probe+'_pxxm_scpot_3',suffix='_scpot_3'
tplot,'th'+probe+'_pxxm_density_scpot_3'
stop

;Density at 2*vthermal, uses 2*thd_peef_vthermal as input velocity
copy_data, 'th'+probe+'_peef_vthermal', 'th'+probe+'_peef_2xvthermal'
get_data, 'th'+probe+'_peef_2xvthermal', data=dv2
dv2.y = 2.0*dv2.y
store_data, 'th'+probe+'_peef_2xvthermal', data=dv2
thm_scpot_density,probe=probe,vthermal_in='th'+probe+'_peef_2xvthermal',suffix='_2xvthermal'
tplot,'th'+probe+'_pxxm_density_2xvthermal'

;tplot, 'th'+probe+'_'+['pxxm', 'vaf', 'vap', 'vaw']+'_density'

End

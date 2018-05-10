;+
;     This crib sheet shows how to calculate plasma beta 
;     using n, T from FPI and B from FGM
;
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2018-05-09 14:44:46 -0700 (Wed, 09 May 2018) $
; $LastChangedRevision: 25190 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/examples/basic/mms_plasma_beta_crib.pro $
;-

timespan, '2016-01-19', 1, /day
probe='1'
mu0=1256.0 ; nT-m/A
Kb=1.3807*10^(-16.) ;cm^2-g-1/s^2-1/K
mu0_str = strcompress(string(mu0), /rem)
Kb_str = strcompress(string(Kb), /rem)

mms_load_fpi, datatype=['dis-moms', 'des-moms'], data_rate='fast', level='l2', probe=probe
mms_load_fgm, level='l2', probe=probe

temp_para_i = 'mms'+probe+'_dis_temppara_fast'
temp_perp_i = 'mms'+probe+'_dis_tempperp_fast'
temp_para_e = 'mms'+probe+'_des_temppara_fast'
temp_perp_e = 'mms'+probe+'_des_tempperp_fast'
number_density_i = 'mms'+probe+'_dis_numberdensity_fast'
number_density_e = 'mms'+probe+'_des_numberdensity_fast'
b_magnitude = 'mms'+probe+'_fgm_b_gsm_srvy_l2_btot'

tinterpol, b_magnitude, number_density_i, newname='b_mag_interpolated'

; note: 1.0e-8 comes from A-nT/m -> g/(s^2-cm)
calc, '"Pmag"=1.0e-8*"b_mag_interpolated"^2/(2.0*'+mu0_str+')'

calc, '"Te_total"=("'+temp_para_e+'"+2*"'+temp_perp_e+'")/3.0'
calc, '"Ti_total"=("'+temp_para_i+'"+2*"'+temp_perp_i+'")/3.0'

; note: eV -> K conversion: 11604.505 K/eV
calc, '"Pplasma"=("'+number_density_i+'"*11604.505*"Ti_total"+"'+number_density_e+'"*11604.505*"Te_total")*'+Kb_str

; beta is just plasma pressure over magnetic pressure
calc, '"Beta"="Pplasma"/"Pmag"'

options, ['Beta', 'Pplasma', 'Pmag'], labels=''
options, 'Beta', colors=2
options, 'Pplasma', ysubtitle='[g/(s!U2!N-cm)]', ytitle='Plasma pressure'
options, 'Pmag', ysubtitle='[g/(s!U2!N-cm)]', ytitle='Magnetic pressure'

tplot, ['Beta', 'Pplasma', 'Pmag']
tlimit, '2016-01-19/4', '2016-01-19/5'

end
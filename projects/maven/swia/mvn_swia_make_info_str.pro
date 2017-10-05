;+
;PROCEDURE: 
;	MVN_SWIA_MAKE_INFO_STR
;PURPOSE: 
;	Construct an array of structures with basic information for interpreting SWIA data products
;AUTHOR: 
;	Jasper Halekas
;CALLING SEQUENCE: 
;	MVN_SWIA_MAKE_INFO_STR, Info_str
;OUTPUTS: 
;	Info_str: An array of structures defining basic info for given time ranges
;
; $LastChangedBy: jhalekas $
; $LastChangedDate: 2014-11-24 13:15:31 -0800 (Mon, 24 Nov 2014) $
; $LastChangedRevision: 16288 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swia/mvn_swia_make_info_str.pro $
;
;-

pro mvn_swia_make_info_str, info_str

compile_opt idl2

e0 = 5.0			; start energy of sweep
deovere = 0.094			; deltaE/E
k_ideal = 7.6			; ideal analyzer constant
k_over_k_ideal = 7.8/7.6	; correction for calibrated analyzer constant
maxdefv = 6.4			; deflector/inner hemisphere ratio for 45 degree deflection
dt_int = 0.0017			; integration time
geom = 0.0056			; geometric factor for 360 sensor w/ all efficiencies (cm^2 s sr eV/eV)
af = 15.0			; maximum attenuation factor (changed from 11.1)
			      ; need to change in coarse moments coefficients as well


energy_ideal = e0 * (1+deovere)^(95-findgen(96))
energy_real = k_over_k_ideal * energy_ideal

vsweep = energy_ideal/k_ideal
defl_ratio_top = maxdefv < 4000/vsweep
defl_ratio_ideal = maxdefv * [findgen(24)-11.5]/11.5
defl_ratio_actual = defl_ratio_top # [findgen(24)-11.5]/11.5

;simplified to ideal thetas since it gives better results

theta_zero = -43.125 + findgen(24)*3.75
theta_zero_atten = theta_zero

g_th_zero = [0.120, 0.154, 0.168, 0.177, 0.181, 0.183, 0.183, 0.183, 0.183, 0.183, 0.183, 0.184, $
	0.184, 0.183, 0.183, 0.183, 0.183, 0.183, 0.181, 0.177, 0.168, 0.152, 0.124, 0.062] 

g_th_zero = g_th_zero/max(g_th_zero)

g_th_zero_atten = [1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0.775] 


theta_all = findgen(96,24)
g_th_all = findgen(96,24)
theta_all_atten = findgen(96,24)
g_th_all_atten = findgen(96,24)
for i= 0,95 do begin
	theta_all[i,*] = interpol(theta_zero,defl_ratio_ideal,defl_ratio_actual[i,*])
	g_th_all[i,*] = interpol(g_th_zero,defl_ratio_ideal,defl_ratio_actual[i,*])
	theta_all_atten[i,*] = interpol(theta_zero_atten,defl_ratio_ideal,defl_ratio_actual[i,*])
	g_th_all_atten[i,*] = interpol(g_th_zero_atten,defl_ratio_ideal,defl_ratio_actual[i,*])

endfor

info_str = {valid_time_range: dblarr(2), $
energy_coarse: fltarr(48), $
theta_coarse: fltarr(48,4), $
theta_coarse_atten: fltarr(48,4), $
g_th_coarse: fltarr(48,4), $
g_th_coarse_atten: fltarr(48,4), $
phi_coarse: fltarr(16), $
geom_coarse: fltarr(16), $
geom_coarse_atten: fltarr(16), $
mf_coarse: fltarr(4), $
sf_coarse: 0., $
sf_coarse_atten: 0., $
deovere_coarse: 0., $
energy_fine: fltarr(96), $
theta_fine: fltarr(96,24), $
theta_fine_atten: fltarr(96,24), $
g_th_fine: fltarr(96,24), $
g_th_fine_atten: fltarr(96,24), $
phi_fine: fltarr(10), $
geom_fine: fltarr(10), $
geom_fine_atten: fltarr(10), $
mf_fine: fltarr(4), $
sf_fine: 0., $
deovere_fine: 0., $
dt_int: 0., $
geom: 0.}

info_str.valid_time_range = time_double(['2010-01-01','2014-11-20'])

info_str.energy_coarse = rebin(energy_real,48)
info_str.theta_coarse = rebin(theta_all,48,4)
info_str.theta_coarse_atten = rebin(theta_all_atten,48,4)
info_str.g_th_coarse = rebin(g_th_all,48,4)
info_str.g_th_coarse_atten = rebin(g_th_all_atten,48,4)
info_str.phi_coarse = [213.75,236.75,258.75,281.25,303.75,326.25,348.75, $
	11.25,33.75,56.25,78.75,101.25,123.75,146.25,168.75,191.25]
;Still tweaking these factors
info_str.geom_coarse = [1, 1, 1, 1, 1, 1, 0.8, 0.5, 1, 1, 1, 1, 1, 1, 1.162, 1.162] * 1/16.
;Still tweaking these factors
info_str.geom_coarse_atten = [0.10, 0.45, 0.7, 1, 1, 1, 0.8, 0.5, 1, 1, 1, 0.7, 0.45, 0.10, 1.162/af, 1.162/af] * 1/16.
info_str.mf_coarse = [9.4746e7, 1.1062e7, 4.1171e5, 6.9944e3] ; [1.0698e8, 1.1185e7, 2.9962e5, 3.6264e3]
info_str.sf_coarse = 1899.59
info_str.sf_coarse_atten = 518.33
info_str.deovere_coarse = deovere * 2

info_str.energy_fine = energy_real
info_str.theta_fine = theta_all
info_str.theta_fine_atten = theta_all_atten
info_str.g_th_fine = g_th_all
info_str.g_th_fine_atten = g_th_all_atten
info_str.phi_fine = [159.75,164.25,168.75,173.25,177.75,182.25,186.76,191.25,195.75,200.25]
;Still tweaking these factors
info_str.geom_fine = [1.09,1.18,1.18,1.18,1.18,1.18,1.18,1.18,1.18,1.09] * 4.5/360
info_str.geom_fine_atten = info_str.geom_fine/af
info_str.mf_fine = [2.9676e7, 3.486e6, 1.3179e5, 2.2752e3] ; [5.3837e9, 4.4739e7, 3.0099e5, 2.2071e3]
info_str.sf_fine = 3276.80
info_str.deovere_fine = deovere

info_str.dt_int = dt_int
info_str.geom = geom



end
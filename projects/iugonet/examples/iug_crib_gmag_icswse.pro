;+
; PROGRAM: iug_crib_gmag_icswse
;   This is an example crib sheet that will load the MAGDAS magnetometer data
;   released by International Center for Space Weather Science and Education(ICSWSE)
;   , Kyushu University, Japan. 
;   Open this file in a text editor and then use copy and paste to copy
;   selected lines into an idl window. Or alternatively compile and run
;   using the command:
;     .RUN IUG_CRIB_GMAG_ICSWSE
;
; NOTE: For more information about MAGDAS and its rules of the road, see:
;       http://data.icswse.kyushu-u.ac.jp/
; Written by: Shuji Abe,  Feb. 03, 2018
;             International Center for Space Weather Science and Education, Kyushu University, Japan 
;             abeshu _at_ icswse.kyushu-u.ac.jp
;
;-

; initialize
thm_init

; set the date and duration (in days)
timespan, '2013-01-03'

; load MAGDAS data, 1-second, IAGA format
iug_load_gmag_icswse_iaga, site='ASB', resolution='1sec'

; view the loaded data names
tplot_names
stop

; change view region
tplot_options, 'region', [0.05, 0, 0.95, 1]

; plot the loaded data
tplot,'kyumag_mag_asb_1sec_hdzf'
stop

; split data to each component and replot data
split_vec, 'kyumag_mag_asb_1sec_hdzf'
tplot, 'kyumag_mag_asb_1sec_hdzf_*'
stop

; calculate power spectrum and replot data
tdpwrspc,'kyumag_mag_asb_1sec_hdzf'
tplot, 'kyumag_mag_asb_1sec_hdzf_*_dpwrspc'
stop

end

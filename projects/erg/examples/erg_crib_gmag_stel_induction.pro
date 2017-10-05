;+
; PROGRAM: erg_crib_gmag_stel_induction
;   This is an example crib sheet that will load STEL induction magnetometer data.
;   Open this file in a text editor and then use copy and paste to copy
;   selected lines into an idl window.
;   Or alternatively compile and run using the command:
;     .run erg_crib_gmag_stel_induction
;     .c
;
; NOTE: See the rules of the road.
;       For more information, see http://stdb2.stelab.nagoya-u.ac.jp/magne/
;
; Written by: Y. Miyashita, Jan 24, 2011
;             ERG-Science Center, STEL, Nagoya Univ.
;             erg-sc-core at st4a.stelab.nagoya-u.ac.jp
;
;   $LastChangedBy: egrimes $
;   $LastChangedDate: 2016-12-13 10:48:28 -0800 (Tue, 13 Dec 2016) $
;   $LastChangedRevision: 22455 $
;   $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/erg/examples/erg_crib_gmag_stel_induction.pro $
;-

;-----
; initialize
thm_init

; set the date and duration (in hours)
timespan, '2009-01-03/09:40:00', 30, /minute

; load the data
erg_load_gmag_stel_induction, site='ath msr'

; view the loaded data names
tplot_names

; plot dH/dt, dD/dt, and dZ/dt
tplot, ['stel_induction_db_dt_*']
stop

; zoom in using the cursor
tlimit
stop

; set full limits
tlimit, /full

;-----
; get spectra
split_vec, 'stel_induction_db_dt_ath'
tdpwrspc, 'stel_induction_db_dt_ath_x', nboxpoints=256, nshiftpoints=128

split_vec, 'stel_induction_db_dt_msr'
tdpwrspc, 'stel_induction_db_dt_msr_x', nboxpoints=256, nshiftpoints=128

tplot,['stel_induction_db_dt_ath_x', 'stel_induction_db_dt_ath_x_dpwrspc', $
       'stel_induction_db_dt_msr_x', 'stel_induction_db_dt_msr_x_dpwrspc']
stop

;-----
; get the information on the quick sensitivity, sensitivity peak frequency, and polarity
get_data, 'stel_induction_db_dt_msr', dlimits=dl
help, dl.cdf.gatt, /struc
stop

;-----
; to get frequecy-dependent sensitivity and phase difference,
; use the frequency_dependent keyword
;erg_load_gmag_stel_induction, site='ath msr', frequency_dependent=fd
erg_load_gmag_stel_induction, site='all', frequency_dependent=fd
help, fd, /struc

; print (If the value is -1.e+31, asterisks will be printed.)
for i=0,4 do begin
  print, fd[i].site_code, fd[i].nfreq
  for j=0, fd[i].nfreq-1 do $
    print, fd[i].frequency[j], fd[i].sensitivity[j,0:2], fd[i].phase_difference[j,0:2], $
    format='(f4.1,3f10.5,3f8.2)'
endfor

;-----
; export to ASCII
tplot_ascii, 'stel_induction_db_dt_msr'

end

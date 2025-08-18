;+
; PROGRAM: iug_crib_gmag_serc
;   This is an example crib sheet that will load the MAGDAS magnetometer data
;   released by Space Environment Research Center(SERC), Kyushu University, Japan. 
;   Open this file in a text editor and then use copy and paste to copy
;   selected lines into an idl window. Or alternatively compile and run
;   using the command:
;     .RUN IUG_CRIB_GMAG_SERC
;
; NOTE: For more information about MAGDAS and its rules of the road, see:
;       http://magdas.serc.kyushu-u.ac.jp/
; Written by: Shuji Abe,  May 01, 2011
;             Space Environment Research Center, Kyushu University, Japan 
;             abeshu _at_ serc.kyushu-u.ac.jp
;
;-

; initialize
thm_init

; set the date and duration (in days)
timespan, '2008-03-28'

; load MAGDAS data
iug_load_gmag_serc,site=['ONW','CMD','ANC']

; view the loaded data names
tplot_names
stop

; change view region
tplot_options, 'region', [0.05, 0, 1, 1]

; plot the loaded data
tplot,'magdas_mag_*'
stop

; subtract mean value and replot data
; following example show tplot variables operations using low level commands
get_data, 'magdas_mag_onw', data=d
for i=0,3 do d.y(*,i)=d.y(*,i)-mean(d.y(*,i),/NaN)
store_data, "magdas_mag_onw_new", data=d
options, "magdas_mag_onw_new", labels=['H','D','Z','F'] , colors=[2,4,6,0],$
                               ytitle = 'MAGDAS ONW', $
                               ysubtitle = '[nT]'

get_data, 'magdas_mag_cmd', data=d
for i=0,3 do d.y(*,i)=d.y(*,i)-mean(d.y(*,i),/NaN)
store_data, "magdas_mag_cmd_new", data=d
store_data, "magdas_mag_cmd_new", data=d
options, "magdas_mag_cmd_new", labels=['H','D','Z','F'] , colors=[2,4,6,0],$
                               ytitle = 'MAGDAS CMD', $
                               ysubtitle = '[nT]'

get_data, 'magdas_mag_anc', data=d
for i=0,3 do d.y(*,i)=d.y(*,i)-mean(d.y(*,i),/NaN)
store_data, "magdas_mag_anc_new", data=d
store_data, "magdas_mag_anc_new", data=d
options, "magdas_mag_anc_new", labels=['H','D','Z','F'] , colors=[2,4,6,0],$
                               ytitle = 'MAGDAS ANC', $
                               ysubtitle = '[nT]'

tplot, 'magdas_mag_*_new'
stop

; set new timespan
timespan,'2008-03-28/10:00:00',4,/hours

; set y-axis
ylim,'magdas_mag_*_new',-50,50

; replot
tplot

end

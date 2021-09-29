;+
; das2dlm_crib_basic_juno.pro
;
; Description:
;   A crib sheet that shows basic commands to work with das2dlm library
;   Note, that it requres the dlm library (das2dlm) been installed in IDL
;
; Note:
;   If the function experience a problem with DAS2C_READHTTP try to restart IDL 
;   Problem example:
;   DAS2C_READHTTP: 301, Could not get body for URL, reason: Host ёlosed connection before sending any headers
;
; CREATED BY:
;   Alexander Drozdov (adrozdov@ucla.edu)
;
; $LastChangedBy: adrozdov $
; $Date: 2020-08-03 20:45:11 -0700 (Mon, 03 Aug 2020) $
; $Revision: 28983 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/external/das2dlm/examples/das2dlm_crib_basic_juno.pro $
;-

; Specify the URL and the with time_start and time_end

time_start = '2018-10-29T14:00' ;  
time_end = '2018-10-30T04:00' ; 2018-10-29T15:00 
s = 'http://jupiter.physics.uiowa.edu/das/server?server=dataset' + $
   '&dataset=Juno/WAV/Survey&start_time=' + time_start + '&end_time=' + time_end  
print, s

; Request and print data query
query = das2c_readhttp(s)
help, query
stop

; Inspect Datasets (0), ds = das2c_datasets(query) can be used instead
; There are 4 data sets available (0-3).
ds = das2c_datasets(query, 0)
help, ds[0]

; Inspecting Physical Dimensions (i.e. Variable Groups)
pdims = das2c_pdims(ds[0])
print, pdims, /IMPLIED_PRINT
stop

; Get variables
pd_time = das2c_pdims(ds, 'Time')
pd_freq = das2c_pdims(ds, 'frequency')
pd_spec = das2c_pdims(ds, 'spec_dens')

var_time = das2c_vars(pd_time, 'center')
var_freq = das2c_vars(pd_freq, 'center')
var_spec = das2c_vars(pd_spec, 'center')

help, var_time
help, var_freq
help, var_spec
stop


; Getting properties
props_time = das2c_props(var_time)
props_freq = das2c_props(var_freq)
props_spec = das2c_props(var_spec)
print, props_time, /IMPLIED_PRINT
print, props_freq, /IMPLIED_PRINT
print, props_spec, /IMPLIED_PRINT
stop


; Get data and fix the dimentions according to variable's rank
time = das2c_data(var_time)
time = transpose(time[0, *],[1, 0])
freq = das2c_data(var_freq)
freq = freq[*, 0] 
spec = das2c_data(var_spec)
spec = transpose(spec, [1, 0])

;Convert time from us2000
time = time / 1d6 + time_double('2000-01-01')-time_double('1970-01-01')

store_data, 'juno_wav_survey_0', data={x:time, y:spec, v:freq}, $ ; _0 - is "0" dataset out of 4 
  dlimits={spec:1, ylog:1, zlog:1, ytitle:props_freq[0].value, ztitle:props_spec[0].value}

; Plot the data
spd_graphics_config
tplot_options,title=props_spec[3].value ; summary
tplot, 'juno_wav_survey_0'


; Cleaning up
res = das2c_free(query)

end
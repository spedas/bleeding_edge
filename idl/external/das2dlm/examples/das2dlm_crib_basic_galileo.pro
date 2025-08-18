;+
; das2dlm_crib_basic_galileo.pro
;
; Description:
;   A crib sheet that shows basic commands to work with das2dlm library
;   Note, that it requres the dlm library (das2dlm) been installed in IDL
;
; Note:
;   If the function experience a problem with DAS2C_READHTTP try to restart IDL 
;   Problem example:
;   DAS2C_READHTTP: 400, Could not get body for URL, reason: Error in query parameters ... 
;
; CREATED BY:
;   Alexander Drozdov (adrozdov@ucla.edu)
;
; $LastChangedBy: adrozdov $
; $Date: 2020-06-11 17:39:13 -0700 (Thu, 11 Jun 2020) $
; $Revision: 28775 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/external/das2dlm/examples/das2dlm_crib_basic_galileo.pro $
;-

; Specify the URL and the with time_start and time_end

time_start = '2001-01-01' ; Can be specifyed as 2001-001 
time_end = '2001-01-02' ; Can be specifyed as 2001-002

; s = 'http://jupiter.physics.uiowa.edu/das/server?server=dataset' + $; Also does not work 
s = 'http://planet.physics.uiowa.edu/das/das2Server?server=dataset' + $
   '&dataset=Galileo/PWS/Survey_Electric&start_time=' + time_start + '&end_time=' + time_end
print, s

; Request and print data query
query = das2c_readhttp(s)
help, query
stop

; Inspect Datasets (0), ds = das2c_datasets(query) can be used instead
ds = das2c_datasets(query, 0)
help, ds

; Inspecting Physical Dimensions (i.e. Variable Groups)
pdims = das2c_pdims(ds)
print, pdims, /IMPLIED_PRINT

; Listing Variables
pd_time = das2c_pdims(ds, 'time')
pd_freq = das2c_pdims(ds, 'frequency')
pd_elec = das2c_pdims(ds, 'electric')

var_time = das2c_vars(pd_time)
var_freq = das2c_vars(pd_freq)
var_elec = das2c_vars(pd_elec)
help, var_time
help, var_freq
help, var_elec

; Getting properties
props_time = das2c_props(var_time)
props_freq = das2c_props(var_freq)
props_elec = das2c_props(var_elec)
print, props_time, /IMPLIED_PRINT
print, props_freq, /IMPLIED_PRINT
print, props_elec, /IMPLIED_PRINT
stop


; Get data and fix the dimentions according to variable's rank
time = das2c_data(var_time)
time = transpose(time[0, *],[1, 0])
freq = das2c_data(var_freq)
freq = freq[*, 0] 
elec = das2c_data(var_elec)
elec = transpose(elec, [1, 0])

;Convert time from us2000
time = time / 1d6 + time_double('2000-01-01')-time_double('1970-01-01')

store_data, 'galileo_pws_survey_electric', data={x:time, y:elec, v:freq}, $
  dlimits={spec:1, ylog:1, zlog:1, yrange:[1e0, 1e8], ytitle:props_freq[0].value, ztitle:props_elec[0].value}

; Plot the data
spd_graphics_config
tplot_options,title=query.source + ' ' + ds.name
tplot, 'galileo_pws_survey_electric'

; Cleaning up
res = das2c_free(query)

end
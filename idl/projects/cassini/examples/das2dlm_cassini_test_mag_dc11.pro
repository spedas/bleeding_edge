; Test of the Cassini/MAG/Differential_C11 data set

url = 'http://planet.physics.uiowa.edu/das/das2Server?server=dataset'
dataset = 'dataset=Cassini/MAG/Differential_C11'
time1 = 'start_time=2013-01-01'
time2 = 'end_time=2013-01-02'
requestUrl = url + '&' + dataset + '&' + time1 + '&' + time2
print, requestUrl

; Qeury
query = das2c_readhttp(requestUrl)

; Get dataset
ds = das2c_datasets(query, 0)

; inspect
print, ds, /IMPLIED_PRINT

; Pdims
pdims = das2c_pdims(ds);

; inspect
print, pdims, /IMPLIED_PRINT

;stop

p = das2c_pdims(ds, 'time') ; physical dimension
v = das2c_vars(p, 'center') ; variable
d = das2c_data(v) ; data

res = das2c_free(query) 
end
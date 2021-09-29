;+
; PRO:  das2dlm_crib_basic_cassini
;
; Description:
;   Similar crib to das2dlm_crib_basic but works with Cassini data
;
; CREATED BY:
;   Alexander Drozdov (adrozdov@ucla.edu)
;
; $LastChangedBy: adrozdov $
; $Date: 2020-06-01 17:27:59 -0700 (Mon, 01 Jun 2020) $
; $Revision: 28753 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/external/das2dlm/examples/das2dlm_crib_basic_cassini.pro $
;-

; Specify the URL and the with time_start and time_end
url = 'http://planet.physics.uiowa.edu/das/das2Server?server=dataset'
dataset = 'dataset=Cassini/MAG/Magnitude'
time1 = 'start_time=' + '2013-01-01'
time2 = 'end_time=' + '2013-01-02'

s = url + '&' + dataset + '&' + time1 + '&' + time2
print, s

; Request data query
query = das2c_readhttp(s)

; Show the query
help, query
stop

; Inspect Datasets
ds = das2c_datasets(query) ; use ds = das2c_datasets(query, 0) if there is more that one dataset 
help, ds

; Inspecting Physical Dimensions (i.e. Variable Groups)
pdims = das2c_pdims(ds)
help, pdims
help, pdims[0]
help, pdims[1]

stop

; Listing Variables
px = das2c_pdims(ds, 'time')
vx = das2c_vars(px)
help, vx

py = das2c_pdims(ds, 'B_mag')
vy = das2c_vars(py)
help, vy

stop

; Getting properties
metax = das2c_props(px)
help, metax
help, metax[0]
help, metax[1]

metay = das2c_props(py)
help, metay

stop

;Geting Data Arrays
x = das2c_data(vx) 
y = das2c_data(vy) 

help, x
help, y

; Cleaning up
res = das2c_free(query)
help, res ; status of query free

end
;+
; NAME: crib_hapi
;
; PURPOSE:  
;       Demonstrates how to query Heliophysics API (HAPI) servers and download, load and plot data from them
;
; NOTES:
;       hapi_load_data requires IDL 8.3 or later due to usage of IDL's json_parse + orderedhash
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2018-11-19 09:13:20 -0800 (Mon, 19 Nov 2018) $
; $LastChangedRevision: 26148 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/examples/crib_hapi.pro $
;-

server='https://cdaweb.gsfc.nasa.gov/hapi' 

; List the server capabilities:
hapi_load_data, /capabilities, server=server
stop

; List the datasets available on this server:
hapi_load_data, /catalog, server=server
stop

; Get info on a dataset:
; note: if dataset keyword is not provided, hapi_load_data will list the catalog and prompt the user for a dataset
hapi_load_data, /info, dataset='VOYAGER1_PLS_HIRES_PLASMA_DATA', server=server
stop

; Load and plot some Voyager 1 plasma data:
hapi_load_data, trange=['77-09-27', '78-01-20'], dataset='VOYAGER1_PLS_HIRES_PLASMA_DATA', server=server
tplot, 'dens'
stop

; Load and plot some Cassini mag data:
hapi_load_data, trange=['02-01-27', '02-02-27'], dataset='CASSINI_MAG_1MIN_MAGNETIC_FIELD', server=server
tplot, ['b_mag', 'b_comp']
stop

; Load and plot some TWINS2 Lyman-alpha data:
hapi_load_data, trange=['12-01-27', '12-01-28'], dataset='TWINS2_L1_LAD', server=server
tplot, ['lad1_data', 'lad2_data']
stop

; you can use the 'parameters' keyword to limit the parameters returned by the server
hapi_load_data, parameters='lad1_data', trange=['12-01-27', '12-01-28'], dataset='TWINS2_L1_LAD', server=server
tplot, 'lad1_data'
stop

end


;+
; NAME: crib_hapi
;
; PURPOSE:  
;       Demonstrates how to query Heliophysics API (HAPI) servers and download, load and plot data from them
;
; NOTES:
;       hapi_load_data requires IDL 8.3 or later due to usage of IDL's json_parse + orderedhash
;
; $LastChangedBy: nikos $
; $LastChangedDate: 2018-01-19 12:01:38 -0800 (Fri, 19 Jan 2018) $
; $LastChangedRevision: 24544 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/examples/crib_hapi.pro $
;-

server='http://datashop.elasticbeanstalk.com/hapi' 

; List the server capabilities:
hapi_load_data, /capabilities, server=server
stop

; List the datasets available on this server:
hapi_load_data, /catalog, server=server
stop

; Get info on a dataset:
; note: if dataset keyword is not provided, hapi_load_data will list the catalog and prompt the user for a dataset
hapi_load_data, /info, dataset='spase://VEPO/NumericalData/Voyager1/LECP/Flux.Proton.PT1H', server=server
stop

; Load and plot some Voyager 1 proton flux data:
hapi_load_data, trange=['77-09-27', '78-01-20'], dataset='spase://VEPO/NumericalData/Voyager1/LECP/Flux.Proton.PT1H', server=server
tplot, 'flux'
stop

; Load and plot some Cassini mag data:
hapi_load_data, trange=['02-01-27', '02-02-27'], dataset='spase://VSPO/NumericalData/Cassini/MAG/PT60S', server=server
tplot, ['br', 'bt', 'bn']
stop

; Load and plot some Geotail mag/position data:
hapi_load_data, trange=['12-01-27', '12-02-27'], dataset='WEYGAND_GEOTAIL_MAG_GSM', server=server
tplot, ['b_gsm', 'position_gsm']
stop

end


;+
; NAME: crib_hapi
;
; PURPOSE:  
;       Demonstrates how to query Heliophysics API (HAPI) servers and download, load and plot data from them
;
; NOTES:
;       hapi_load_data requires IDL 8.2 or later due to usage of IDL's JSON parser
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2017-06-07 11:50:27 -0700 (Wed, 07 Jun 2017) $
; $LastChangedRevision: 23438 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/examples/crib_hapi.pro $
;-

; List the server capabilities:
hapi_load_data, /capabilities
stop

; List the datasets available on this server:
hapi_load_data, /catalog
stop

; Get info on a dataset:
; note: if dataset keyword is not provided, hapi_load_data will list the catalog and prompt the user for a dataset
hapi_load_data, /info, dataset='spase://VEPO/NumericalData/Voyager1/LECP/Flux.Proton.PT1H'
stop

; Load and plot some Voyager 1 proton flux data:
hapi_load_data, trange=['77-09-27', '78-01-20'], dataset='spase://VEPO/NumericalData/Voyager1/LECP/Flux.Proton.PT1H'
tplot, 'flux'
stop

; Load and plot some Cassini mag data:
hapi_load_data, trange=['02-01-27', '02-02-27'], dataset='spase://VSPO/NumericalData/Cassini/MAG/PT60S'
tplot, ['br', 'bt', 'bn']
stop

; Load and plot some Geotail mag/position data:
hapi_load_data, trange=['12-01-27', '12-02-27'], dataset='WEYGAND_GEOTAIL_MAG_GSM'
tplot, ['b_gsm', 'position_gsm']
stop

end


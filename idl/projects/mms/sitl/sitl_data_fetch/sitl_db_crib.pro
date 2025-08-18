; Crib to test deltaB
; 

mms_init

timespan, '2015-10-16/10:00:00', 3.5, /hour

mms_sitl_curl_b, curlflag

mms_sitl_diffb, dbflag

options, 'mms_sitl_jtot_curl_b', 'ytitle', 'Curl QL'

options, 'mms_srvy_jtot_curl_b', 'ytitle', 'Curl L2'

tplot, ['mms4_dfg_srvy_dmpa','mms_sitl_jtot_curl_b','mms_sitl_diffB']

end
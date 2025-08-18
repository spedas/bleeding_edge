;+
; This is to easily switch among servers to download requested CDF.
; Adopted from rbsp_load_wake_effect_cdf_file.
; This program is supposed to be updated frequently during the phasef tests.
;-

function rbsp_efw_phasef_get_server

    server = 'http://rbsp.space.umn.edu/rbsp_efw'
    return, server

end

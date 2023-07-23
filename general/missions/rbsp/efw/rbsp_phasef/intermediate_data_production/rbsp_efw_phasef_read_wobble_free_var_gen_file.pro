;+
; Save the following data to CDF:
;   q_uvw2gse. Fixed for artificial wobble at the spin period, Saved at 1 sec cadence.
;   r_mgse. In Re, 10 sec.
;   v_mgse. In km/s, 10 sec.
;   e_mgse. In mV/m, 10 sec, include Ex.
;   b_mgse. In nT, 10 sec.
;-

pro rbsp_efw_phasef_read_wobble_free_var_gen_file, time, probe=probe, filename=file, errmsg=errmsg, version=version

    routine = 'rbsp_efw_phasef_read_wobble_free_var_gen_file_'+version
    call_procedure, routine, time, probe=probe, filename=file, errmsg=errmsg

end

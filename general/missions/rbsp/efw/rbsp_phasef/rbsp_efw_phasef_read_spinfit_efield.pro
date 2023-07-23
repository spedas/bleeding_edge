;+
; Read spinfit E field in MGSE for all boom pairs.
;-

pro rbsp_efw_phasef_read_spinfit_efield, time_range, probe=probe

;    if n_elements(local_root) eq 0 then local_root = join_path([homedir(),'data','rbsp'])

    rbsp_efw_phasef_read_e_spinfit, time_range, probe=probe, local_root=local_root
    rbsp_efw_phasef_read_e_diagonal_spinfit, time_range, probe=probe, local_root=local_root

end

time_range = time_double(['2018-01-01','2019-11-01'])
probes = ['a']

;time_range = time_double(['2018-07-22/21:00','2018-07-23/00:00'])
;probes = ['a','b']

foreach probe, probes do rbsp_efw_phasef_read_spinfit_efield, time_range, probe=probe
end

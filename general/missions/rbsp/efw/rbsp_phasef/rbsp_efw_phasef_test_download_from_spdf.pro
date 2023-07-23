
;---Settings.
    probes = ['a','b']
    time_range = time_double('2013-01-01')+[0,2]*constant('secofday')
    burst_time_range = time_double('2013-06-07')+[0,1]*constant('secofday')


;---All Level 2 survey data.
;    data_types = ['e-hires-uvw','e-spinfit-mgse','esvy_despun','fbk','spec','vsvy-hires']
;    foreach probe, probes do begin
;        foreach data_type, data_types do begin
;            rbsp_efw_read_l2, time_range, probe=probe, datatype=data_type
;        endforeach
;    endforeach

;---All level 1 burst data.
;    data_types = ['vb1-split','mscb1-split', $
;        'eb1','eb2','mscb1','mscb2','vb1','vb2']
;    foreach probe, probes do begin   
;        foreach data_type, data_types do begin
;            rbsp_efw_read_l1, burst_time_range, probe=probe, datatype=data_type
;        endforeach
;    endforeach


;---Level 3 data.
;    foreach probe, probes do begin
;        rbsp_efw_read_l3, time_range, probe=probe
;    endforeach


;---All Level 1 survey data.
;    data_types = ['esvy','vsvy']
;    foreach probe, probes do begin
;        foreach data_type, data_types do begin
;            rbsp_efw_read_l1, time_range, probe=probe, datatype=data_type
;        endforeach
;    endforeach
    

end
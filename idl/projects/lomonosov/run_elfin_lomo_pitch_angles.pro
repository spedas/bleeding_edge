pro run_elfin_lomo_pitch_angles

timespan, '2016-08-31',1d
trange=timerange()

for i=0,0 do begin
    this_trange=trange + i*86400.
;    calculate_elfin_lomo_pitch_angle, trange=this_trange, angle=0.
;    calculate_elfin_lomo_pitch_angle, trange=this_trange, angle=30.
    calculate_elfin_lomo_pitch_angle, trange=this_trange, angle=60.
;    calculate_elfin_lomo_pitch_angle, trange=this_trange, angle=90.
    
endfor

end
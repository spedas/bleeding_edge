
start_date = time_double('2014-10-18')
end_date = time_double ('2014-11-15')
ndays = round(end_date - start_date)/86400

for J = 0, ndays-1 do mvn_sep_make_ancillary_data, start_date+86400L*J




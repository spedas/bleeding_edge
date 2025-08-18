;   mvn_sep_ql_crib
dprint,print_trace=4,print_dtime=1

dprint,'Set time span'
timespan

trange=timerange()
dprint,'Time Range is: ' ,time_string(trange)

dprint,'retrieve files... '
files = mvn_pfp_file_retrieve(trange=trange)
mvn_sep_load,files=files


dprint,'All TPLOT quantities should have been produced at this point.

dprint,'Generate plots'
mvn_sep_gen_ql  ; generates the plots

dprint,'SEP gets single panel in the overall summary plot page. it will called: ',  'mvn_SEPS_QL'

end
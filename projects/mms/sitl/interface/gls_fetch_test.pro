; Test GLS fetch
; 

start_date = '2018-01-29/00:00:00'
end_date = '2018-01-30/00:00:00'

gls_name = 'gls_selections_mp-dl-unh'

trange = [start_date, end_date]

mms_get_gls_selections, gls_name, gls_files, pw_flag, pw_message, trange=trange

glsstr = mms_read_gls_file(gls_files[0])

end

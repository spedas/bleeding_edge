;+
; Small files can be handled directly on xwaves.
;-

; Settings on xwaves7.
probes = ['a','b']
years = string(make_bins([2012,2019],1),format='(I04)')
in_local_root = '/Volumes/DataA/RBSP/data/rbsp'
out_local_root = '/Volumes/UserA/user_volumes/kersten/data_external/rbsp'

large_file_limit = 1.8e9
large_file_log = join_path([out_local_root,'vb1_split_large_file_log.txt'])
if file_test(large_file_log) eq 0 then ftouch, large_file_log

; This program only needs to be run once !!!
stop
foreach probe, probes do begin
    rbspx = 'rbsp'+probe
	; The program often breaks, so use this to skip dates are done.
	if probe eq 'a' then start_date = '2014-04-12' else start_date = '2012-01-01'
	start_date = time_double(start_date)

    foreach year, years do begin
        path = in_local_root+'/'+rbspx+'/l1/vb1/'+year
        files = file_search(path+'/*_v02.cdf')
        foreach file, files do begin
			; Check file date.
			base = file_basename(file)
			file_time = time_double(strmid(base,13,8),tformat='YYYYMMDD')
			if file_time lt start_date then continue

			; Check file size.
			finfo = file_info(file)
			if finfo.size gt large_file_limit then begin
				lprmsg, 'File size too large, skip '+file+' ...'
				lprmsg, file, large_file_log
				continue
			endif

			rbsp_efw_phasef_gen_l1_vb1_split, file, $
				in_local_root=in_local_root, out_local_root=out_local_root
		endforeach
    endforeach
endforeach

stop

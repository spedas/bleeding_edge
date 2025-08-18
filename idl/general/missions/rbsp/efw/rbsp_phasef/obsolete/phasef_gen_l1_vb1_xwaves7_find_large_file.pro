;+
; Files larger than 1.8 GB cannot be handled on xwaves.
; This program finds such files on xwaves.
;-


; Settings on xwaves7.
probes = ['a','b']
years = string(make_bins([2012,2019],1),format='(I04)')
in_local_root = '/Volumes/DataA/RBSP/data/rbsp'
out_local_root = '/Volumes/UserA/user_volumes/kersten/data_external/rbsp'
large_file_limit = 1.8e9
large_file_log = join_path([out_local_root,'vb1_split_large_file.txt'])
if file_test(large_file_log) eq 0 then ftouch, large_file_log

foreach probe, probes do begin
    rbspx = 'rbsp'+probe
    foreach year, years do begin
        path = in_local_root+'/'+rbspx+'/l1/vb1/'+year
        files = file_search(path+'/*_v02.cdf')
        foreach file, files do begin
			; Check file size.
			finfo = file_info(file)
			if finfo.size gt large_file_limit then begin
				lprmsg, file, large_file_log
			endif
		endforeach
    endforeach
endforeach

end

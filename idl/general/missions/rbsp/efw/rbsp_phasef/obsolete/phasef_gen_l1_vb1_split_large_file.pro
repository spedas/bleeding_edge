;+
; Handle large files on m472e, which has enough memory.
;-

url = 'http://rbsp.space.umn.edu/rbsp_efw/vb1_split_large_file.txt'
large_file_log = join_path([homedir(),'vb1_split_large_file.txt'])
if file_test(large_file_log) eq 0 then download_file, large_file_log, url

in_local_root = '/Volumes/data/rbsp'
out_local_root = '/Volumes/data/rbsp'

secofday = 86400d
rbsp_efw_init
; Berkeley site contains most up to date data.
!rbsp_efw.remote_data_dir = 'http://themis.ssl.berkeley.edu/data/rbsp/'
!rbsp_efw.local_data_dir = '/Volumes/data/rbsp/'

large_files = read_all_lines(large_file_log)
foreach large_file, large_files do begin
    base = file_basename(large_file)
    probe = strmid(base,4,1)
    rbspx = 'rbsp'+probe

    ; Determine where the large file should be saved.
    file_time = strmid(base,13,10)
    file_time = time_double(file_time,tformat='YYYYMMDD')
    start_date = (probe eq 'a')? '2013-10-09': '2012-01-01'
    start_date = time_double(start_date)
    if file_time lt start_date then continue

    path = join_path([in_local_root,rbspx,'l1','vb1','%Y'])
    path = apply_time_to_pattern(path, file_time)
    file = join_path([path,base])

    ; Download the file and split it.
    time_range = file_time+[0,secofday]
    timespan, time_range[0], total(time_range*[-1,1]), /seconds
    rbsp_load_efw_waveform, probe=probe, type='calibrated', $
        datatype='vb1', downloadonly=1
    if file_test(file) eq 0 then message, 'Something is wrong ...'
	rbsp_efw_phasef_gen_l1_vb1_split, file
endforeach
end

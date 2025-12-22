;+
;This program kills SDT (assuming there is only one running, which
;should always be the case) and can be called from a shell script,
;removes the lock file, so that the process can restart cleanly next time
;-

files = file_search('sdt_clear_proc.*')
If(~is_string(files)) Then print, 'No KILL files found'
If(~is_string(files)) Then exit
print, files
n = n_elements(files)
For j = 0, n-1 Do kill_rkl, files[j]
;run_cmd_file, 'sdt_clear_shm.0'

spawn, '/bin/rm process_orbit.lock'

exit


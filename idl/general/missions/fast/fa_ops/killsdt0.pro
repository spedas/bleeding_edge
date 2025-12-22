;+
;This program kills SDT (assuming there is only one running, which
;should always be the case) and can be called from a shell script,
;removes the lock file, so that the process can restart cleanly next time
;-

kill_rkl, 'sdt_clear_proc.0'
;run_cmd_file, 'sdt_clear_shm.0'

spawn, '/bin/rm process_orbit.lock'

exit


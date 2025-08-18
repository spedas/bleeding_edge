;+
;
; PURPOSE:
;   This crib sheet shows how to export THEMIS particle (velocity distribution) data to ASCII files
;
; NOTES: 
;   The underlying routine - spd_pgs_export - will create 5 ASCII files:
;     [filename]_data.txt: the velocity distribution data
;     [filename]_energy.txt: the energy values at each bin
;     [filename]_theta.txt: the theta values at each bin
;     [filename]_phi.txt: the phi values at each bin
;     [filename]_bins.txt: 1 or 0 depending on if this bin is active
;
;   If no filename is specified, dist.project, dist.spacecraft and dist.data_name are used to form the filename
;   
;$LastChangedBy: egrimes $
;$LastChangedDate: 2019-04-10 15:38:44 -0700 (Wed, 10 Apr 2019) $
;$LastChangedRevision: 26999 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/examples/advanced/thm_crib_part_export.pro $
;-

probe = 'b'
datatype = 'peib'
trange = '2008-02-26/' + ['04:54','04:55'] + ':00'
trange = '2008-02-26/' + ['04:54','04:58'] + ':00'

;load data into standard structures
dist = thm_part_dist_array(probe=probe, datatype=datatype, trange=trange)

;apply standard processing
thm_part_process, dist, dist_counts, units='counts'
thm_part_process, dist, dist_df, units='df'

; export the data in DF units
spd_pgs_export, dist_df
stop

; export the data in counts
spd_pgs_export, dist_counts

stop
end
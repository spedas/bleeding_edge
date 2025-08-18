;+
;Purpose:
;  Crib demonstrating usage of isee_3d tool with themis particle data
;
;
;Notes:
;  -Currently only compatible with modified tool at:
;    /spedas_gui/stel_3d/stel_3d_pro_20150811/pro
;
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2016-05-24 13:12:04 -0700 (Tue, 24 May 2016) $
;$LastChangedRevision: 21185 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/examples/advanced/thm_crib_isee_3d.pro $
;-


;IMPORTANT NOTES =======================================================
;
;  -Data must have at least 3 distributions within the time range.
;
;======================================================================



;-------------------------------------------------------------------------
; ESA or SST data
;-------------------------------------------------------------------------

probe = 'b'
datatype = 'peib'
trange = '2008-02-26/' + ['04:54','04:55'] + ':00'


;load data into standard structures
dist = thm_part_dist_array(probe=probe, datatype=datatype, trange=trange)


;apply standard processing
thm_part_process, dist, dist_counts, units='counts'
thm_part_process, dist, dist_df, units='df'


;convert to isee_3d data model
data = spd_dist_to_hash(dist_df, counts=dist_counts)


;load bfield and velocity support data
thm_load_fit, probe=probe, datatype='fgs', level=2, trange=trange
thm_load_esa, probe=probe, datatype=datatype+'_velocity_dsl', trange=trange 

bfield = 'th'+probe+'_fgs_dsl'
velocity = 'th'+probe+'_'+datatype+'_velocity_dsl'


isee_3d, data=data, trange=trange, bfield=bfield, velocity=velocity


stop


;-------------------------------------------------------------------------
; Combined ESA & SST data 
;   -also see thm_crib_part_combine
;-------------------------------------------------------------------------


probe = 'd'
trange = '2011-07-29/' + ['13:00','13:02']

;specify which datatype to use from each instrument
;only full and burst data are valid for sst_datatype
esa_datatype = 'peif'
sst_datatype = 'psif'


;This will automatically load the required particle data and interpolate 
;between the two instruments to produce the combined product.
combined = thm_part_combine(probe=probe, trange=trange, units='df', $
                            esa_datatype=esa_datatype, sst_datatype=sst_datatype) 


;Ignore leading and trailing elements as they will only have one instrument's data 
data = spd_dist_to_hash(combined[1:-2])


;load bfield and velocity support data
thm_load_fit, probe=probe, datatype='fgs', level=2, trange=trange
thm_load_mom, probe=probe, datatype='ptim_velocity', trange=trange 

bfield = 'th'+probe+'_fgs_dsl'
velocity = 'th'+probe+'_ptim_velocity'


;once GUI is open select PSD from Units menu
isee_3d, data=data, trange=trange, bfield=bfield, velocity=velocity



end
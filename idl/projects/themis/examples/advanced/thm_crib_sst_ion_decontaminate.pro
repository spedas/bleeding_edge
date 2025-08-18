;+
;Procedure: thm_crib_sst_ion_decontaminate
;
;Purpose:  A crib on showing how to subtract the SST-FT channels from the SST-O data to remove electron contamination from ion moments.
;
;
;Notes:
;
; $LastChangedBy: pcruce $
; $LastChangedDate: 2017-01-09 09:37:04 -0800 (Mon, 09 Jan 2017) $
; $LastChangedRevision: 22534 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/examples/advanced/thm_crib_sst_ion_decontaminate.pro $
;-


trange = ['2010-06-05','2010-06-06']

;set the date and duration (in days)
timespan,trange

;set the spacecraft
probe = 'c'

;loads particle data for data psif
thm_part_load,probe=probe,datatype='psif'
;and psef
thm_part_load,probe=probe,datatype='psef'

sun_bins = dblarr(64)+1 ;allocate variable for bins, with all bins selected
; sun_bins[[0,8,16,24,30,32,33,34,40,48,58,55,56]] = 0

sun_bins[[0,8,16,24,32,33,40,47,48,55,56,57]] = 0

;In modeling the SST open(ion) side, the magnetic deflector should
;deflect electrons below 350 keV away from the deflector. In theory,
;electrons above 400 keV should be eliminated by anti-coincidence logic.
;In practice, the ion channels still get some contamination.  To
;eliminate the contaminated particles.  You can try subtracting
;electrons from the FT channel from the upper bins of the O channel.

dist_psif = thm_part_dist_array(probe=probe,type='psif',trange=trange,/sst_cal,method_clean='manual',sun_bins=sun_bins)
dist_psef = thm_part_dist_array(probe=probe,type='psef',trange=trange,/sst_cal,method_clean='manual',sun_bins=sun_bins)
thm_part_conv_units,dist_psif,units='eflux',/fractional_counts
thm_part_conv_units,dist_psef,units='eflux',/fractional_counts

;for comparison
thm_part_products,probe=probe,datatype='psif',trange=trange,outputs='moments energy',dist_array=dist_psif,suffix='_before'

;this code assumes that psif/psef are matched in angle
;If they aren't, the code may throw and error.  Call this to match angle:
;thm_part_sphere_interpolate ;matches angle

;get the number of elements for the loop
thm_part_time_iterator,dist_psif,nelements=n


for i = 0l,n-1 do begin
  thm_part_time_iterator,dist_psif,psif_data,index=i
  thm_part_time_iterator,dist_psef,psef_data,index=i

  dim = dimen(psif_data.energy)
  for j = 0l, dim[1]-1l do begin
    data8 = interpol(psef_data.data[*,j],psef_data.energy[*,j],psif_data.energy[8,j]) ;interpolate electron data to 8th sst ion bin
    psif_data.data[8,j]=(psif_data.data[8,j]-data8) > 0 ; subtract data(store max(result,0)
    data9 = interpol(psef_data.data[*,j],psef_data.energy[*,j],psif_data.energy[9,j]) ;interpolate electron data to 9th sst ion bin
    psif_data.data[9,j]=(psif_data.data[9,j]-data9) > 0 ; subtract data(store max(result,0)
  endfor

  thm_part_time_iterator,dist_psif,psif_data,index=i,/set

endfor


thm_part_products,probe=probe,datatype='psif',trange=trange,outputs='moments energy',dist_array=dist_psif,suffix='_after'

stop

end
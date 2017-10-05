;-
;Name: thm_crib_sst_set_calibrations
;
;Purpose: Demonstrates how to set calibration parameters using the new particle management code.
;
;Usage:
; To run this crib, compile and type .go
; Or alternatively, copy & paste
;
;See Also:
;  thm_crib_sst_calibration.pro
;  thm_part_dist_array.pro
;  thm_part_conv_units.pro
;  thm_part_energy_extrapolate.pro
;  thm_part_moments.pro
;  thm_part_getspec.pro
;  thm_part_copy.pro
;
; $LastChangedBy: pcruce $
; $LastChangedDate: 2013-09-19 10:56:58 -0700 (Thu, 19 Sep 2013) $
; $LastChangedRevision: 13080 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/examples/advanced/thm_crib_sst_set_calibrations.pro $
;-

  del_data,'*'
  heap_gc ;New system uses pointers.  This call clears any dangling pointers from earlier sessions

;The new system for particle load/manipulation is as close to vectorized as is feasible for our current particle instruments.
;To load particle data in the new format use thm_part_dist_array.  Here are some examples:

;load EESA
dist_data_eesa = thm_part_dist_array(probe='a',type='peef',trange=['2012-02-08/09','2012-02-08/12'])
;load ESST
dist_data_esst = thm_part_dist_array(probe='a',type='psef',trange=['2012-02-08/09','2012-02-08/12'],/sst_cal)
 
;Note that data is returned in a variable.  It can be passed around and copied just the same as a normal variable.
;With one note.  This data structure uses pointers at the top level.  A deep copy must be used to ensure that you're
;not manipulating an old variable of the same type.

;If you want to deep copy particle data, use thm_part_copy
;eg
thm_part_copy,dist_data_esst,dist_data_esst_copy

;How is the particle data organized?
;At the top level, the values returned by thm_part_dist_array are an array of pointers.
;For each mode in the particle data for the time interval, there will be one pointer.
;  Or put another way, there will be n_mode_changes+1 pointers.
;Inside each pointer, there will be an array of particle data structures that look just
; like the data structures returned by thm_part_dist.
;For example:

;The array of structures in the first mode:
dist_esst_mode0 = *dist_data_esst[0]

;The first sample of the first mode:
dist_eesa_mode0_sample0 = dist_esst_mode0[0]

;The sample of the first mode(another method)
dist_esst_mode0_sample0 = (*dist_data_esst[0])[0]

;Data is loaded in raw format, but for SST, calibrations are stored in the dist structs.
;This means that you can change the calibration parameters using relatively simple vector notations.
;For example

(*dist_data_esst[0]).geom_factor = 1.0 ;change the SST geometric factor for all time samples during mode 0 to 1.0 cm2/sr

;You can then use the modified parameters to calibrate:

thm_part_conv_units,dist_data_esst  ;calibrate, but with mode0 gf changed to 1.0

;Note that, after you call conv_units, the dist_data_esst will be modified irreversibly.
;If you  want to recalibrate with different parameters, you'll need to reload the data,
;or use a copy.

;Here is the structure listing for mode0 SST
 help,*dist_data_esst[0],/str

;The relevant parameters are:
;sc_pot,energy,theta,phi,denergy,dtheta,dphi,bins,gf,integ_t,deadtime,geom_factor,att,eff

;As an example for a more complicated calibration parameter modification, note that you can read out the whole time series of parameters
;For example, the efficiencies are stored in an energy x angle array (16 x 64)
;If you want, you can read them out as an energy  x angle x time array, modify, then store back
eff_energy_angle_time = (*dist_data_esst_copy[0]).eff
eff_energy_angle_time[*,0,*] = 0.0 ;change the efficiency for angle zero to zero at all times and energies
;now write it back to the sst dist array
 (*dist_data_esst_copy[0]).eff = eff_energy_angle_time
 
 ;now calibrate the copy using the new efficiency
thm_part_conv_units,dist_data_esst_copy 
 
 stop
 


end
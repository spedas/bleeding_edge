
;+
;Name:
;  thm_crib_part_combine
; 
;Purpose:
;  Crib demonstrating basic usage of combined ESA/SST particle code.
;
;See also:
;  thm_crib_part_products
;  thm_crib_part_slice2d
;  thm_crib_part_combine_ncount
;  thm_crib_sst_load_calibrate
;  thm_crib_sst.pro
;  thm_crib_esa.pro
;
;Notes:
;  If you see any useful examples missing from these cribs, please let us know.
;  A lot of instrument specific options (e.g. decontamination) are found in the other cribs.
;
;Notes on method:
;  Internally, combined distributions are created in three steps:
;    a) Linear time interpolation
;         -time samples are matched by linearly interpolating the  
;          data set with lower time resolution to match the other
;    b) Linear spherical interpolation
;         -both data sets are interpolated onto the same angular grid
;    c) Energy gap interpolation
;         -once all times/angles match the gap between the 
;          ESA and SST energy ranges is filled in with a logarithmic 
;          linear interpolation (log(flux) vs log(energy))
;
;$LastChangedBy: jimmpc1 $
;$LastChangedDate: 2017-10-05 10:40:29 -0700 (Thu, 05 Oct 2017) $
;$LastChangedRevision: 24118 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/examples/advanced/thm_crib_part_combine.pro $
;-

compile_opt idl2



print, ' ', ' Load times may be as long as 60+ seconds when producing combined data sets. ', ' '

stop


;expand left margin to better accomodate labels
tplot_options, 'xmargin', [15,9]


;--------------------------------------------------------------------------------------
;Load Combined Data
;--------------------------------------------------------------------------------------

;set probe and day
;time intervals longer than 1-2 hours may be memory and times intensive
probe = 'd'
trange = '2011-07-29/' + ['13:00','14:00']

;specify which datatype to use from each instrument
;only full and burst data are valid for sst_datatype
esa_datatype = 'peir'
sst_datatype = 'psif'

;This will automatically load the required particle data and interpolate 
;between the two instruments to produce the combined product.
;The original ESA and SST data will be passed out via the last two keywords. 
combined = thm_part_combine(probe=probe, trange=trange, $
                            esa_datatype=esa_datatype, sst_datatype=sst_datatype, $
                            orig_esa=esa, orig_sst=sst) 
                            
;Default midpoint energies for interpolation above ESA energies are(in eV):
;Ions: [25000,26000.,28000.,30000.0,34000.0,41000.0,53000.0,67400.0,95400.0,142600.,207400.,297000.,421800.,654600.,1.13460e+06,2.32980e+06,4.00500e+06]
;Electrons: [27000,28000.,29000.,30000.0, 31000.0,41000.0,52000.0,65500.0,93000.0,139000.,203500.,293000.,408000.,561500.,719500.]


print, ' ','The "combined" variable now contains pointers to the combined particle distribution.'
print, 'This can be passed to other routines to produce combined data products.', ' '

stop

;--------------------------------------------------------------------------------------
;Produce energy spectrogram
;--------------------------------------------------------------------------------------

;Pass the combined data into processing routines the same way you
;would use output from thm_part_dist_array.
thm_part_products, dist_array=combined, outputs='energy'

window, ysize=800

;naming is slightly different than normal particles variables.
; p=particles
; t=total
; i=ions
; r=reduced distribution esa
; f=full distribution sst
tplot, 'thd_ptirf_eflux_energy'

print, ' ','Pass the combined data to thm_part_products to produce spectrograms.'
print, 'This is an example of a combined energy spectrogram.'
print, 'Continue to the next example to see a before & after comparison.',' '

stop

;--------------------------------------------------------------------------------------
;Compare with original data
;--------------------------------------------------------------------------------------

;Generate spectrograms from original ESA/SST data
thm_part_products, dist_array=esa, outputs='energy'
thm_part_products, dist_array=sst, outputs='energy'

window, 0, ysize=800
window, 1, ysize=800

;set all plots to the same scale
store_data,'thd_ptirf_eflux_energy_pseudo',data='thd_peir_eflux_energy thd_psif_eflux_energy'
zlim, ['thd_ptirf_eflux_energy','thd_ptirf_eflux_energy_pseudo','thd_psif_eflux_energy','thd_peir_eflux_energy'],1e3,1e7,1
ylim, 'thd_ptirf_eflux_energy_pseudo thd_ptirf_eflux_energy',5.,1.e6,1
tplot, ['thd_ptirf_eflux_energy_pseudo'], window=1
tplot, 'thd_ptirf_eflux_energy', window=0

print, ' ','This compares the combined energy spectrogram to plots made from the original data.', ' '

stop

;--------------------------------------------------------------------------------------
;Produce moments
;--------------------------------------------------------------------------------------

;moments will be produced for this run
;see thm_crib_part_products for more usage options
thm_part_products, dist_array=combined, outputs='moments'

;moments to plot
mom_names = 'thd_ptirf_'+['density','velocity','eflux']

tplot, mom_names

print, ' ','Pass the combined data to thm_part_products (or thm_part_moments) to produce combined moments.'
print, 'Continue to the next example to see a comparison with on board moments.',' '

stop

;--------------------------------------------------------------------------------------
;Compare with on board moments
;--------------------------------------------------------------------------------------

;get combined on board moments
thm_load_mom, probe=probe, trange=trange, datatype='ptim'

;density
mom_names = 'thd_'+['ptim','ptirf']+'_density'

options, mom_names, yrange=[1e-2,1e2], ylog=1

tplot, mom_names

print, ' ','Density comparison (on board vs. ground).', ' '

stop

;velocity
mom_names = 'thd_'+['ptim','ptirf']+'_velocity'

options, mom_names, yrange=[-200,200] 

tplot, mom_names

print, ' ','Velocity comparison (on board vs. ground).', ' '

stop

;eflux
mom_names = 'thd_'+['ptim','ptirf']+'_eflux'

options, mom_names, yrange=[-1e11,1e11]

tplot, mom_names

print, ' ','Flux comparison (on board vs. ground).', ' '

stop

;pressure tensor
mom_names = 'thd_'+['ptim','ptirf']+'_ptens'

options, mom_names, yrange=[-1e3,8e3]

tplot, mom_names

print, ' ','Pressure tensor comparison (on board vs. ground).', ' '

stop

;--------------------------------------------------------------------------------------
;Produce velocity slice
;--------------------------------------------------------------------------------------

;load support data for field aligned slice
;  -bulk velocity vector must be specified for combined distributions
;   when using BV, BE, xvel, and perp rotations (no automatic calculation)
thm_load_mom, probe=probe, trange=trange, datatype='ptim'
thm_load_fgm, probe=probe, trange=trange, datatype='fgl', level=2, coord='dsl'

;get velocity slice
thm_part_slice2d, combined, slice_time=trange[0], timewin=30, part_slice=comb_slice, $
  rotation='BV', mag_data='thd_fgl_dsl', vel_data='thd_ptirf_velocity', /three_d_interp

;thm_part_slice2d, combined, slice_time=trange[0], timewin=30, part_slice=comb_slice, $
;   rotation='BV', mag_data='thd_fgl_dsl', vel_data='thd_ptim_velocity', /three_d_interp

thm_part_slice2d_plot, comb_slice

print, ' ','Pass the combined data to thm_part_slice2d to produce combined velocity slices.'
print, 'Continue to the next example to see a comparison with esa-only and sst-only slices.',' '

stop

;--------------------------------------------------------------------------------------
;Compare with plot produced from separate distributions
;--------------------------------------------------------------------------------------

;-use default method to show bin boundaries
;-use gsm coordinates for sst
;-limit energy range to exclude top SST energies
; (tenuous data at high energies/makes it easier to see instrument energy gap)



thm_part_slice2d, combined, slice_time=trange[0], timewin=30, part_slice=comb_slice, $
                  erange=[0,8e5], coord='gsm'
thm_part_slice2d, esa, sst, slice_time=trange[0], timewin=30, part_slice=sep_slice, $
                  erange=[0,8e5], coord='gsm'

zrange = sep_slice.zrange ;range of pre-interpolated data

thm_part_slice2d_plot, comb_slice, zrange=zrange, window=0
thm_part_slice2d_plot, sep_slice, zrange=zrange, window=1


print, ' ','This comparison shows a slice of the combined data compared to an '
print, 'un-interpolated esa + sst slice.',' '

stop

;----------------------------------------------------------------------------------------
;Generate data with SST & interpolated bins only.  
;(This Backwards compatibility mode, generates the output from thm_sst_load_calibrate.)
;----------------------------------------------------------------------------------------
combined = thm_part_combine(probe=probe, trange=trange, $
  esa_datatype=esa_datatype, sst_datatype=sst_datatype, $
  orig_esa=esa, orig_sst=sst,/only_sst)
  

;Pass the combined data into processing routines the same way you
;would use output from thm_part_dist_array.
thm_part_products, dist_array=combined, outputs='energy'

window, 0, ysize=800

tplot,'thd_psif_eflux_energy'

print,'SST data & interpolated bins used to generate particle products.'

stop

;----------------------------------------------------------------------------------------
;Generate data with SST energy bins below the limit removed before filling the ESA/SST gap
;For later mission dates those bins may be unreliable due to instrument degration
;----------------------------------------------------------------------------------------
combined = thm_part_combine(probe=probe, trange=trange, $
  esa_datatype=esa_datatype, sst_datatype=sst_datatype, $
  orig_esa=esa, orig_sst=sst,sst_min_energy=60000.,esa_max_energy=10000.)


;Pass the combined data into processing routines the same way you
;would use output from thm_part_dist_array.
thm_part_products, dist_array=combined, outputs='energy'

tplot,'thd_psif_eflux_energy'

print,'SST data & interpolated bins used to generate particle products.'

stop

;--------------------------------------------------------------------------------------
;Use manually loaded data
;This can be useful if the data needs to be processed before interpolation.
;--------------------------------------------------------------------------------------

;set probe and time range
probe = 'd'
trange = '2011-07-29/' + ['13:00','14:00']

;load data manually
;IMPORTANT: always use the same time range and probe!
esa_dist = thm_part_dist_array(probe=probe, trange=trange, datatype = 'peif')
sst_dist = thm_part_dist_array(probe=probe, trange=trange, datatype = 'psif')

;Pass the pre-loaded data through the ESA_DIST and SST_DIST keywords
combined = thm_part_combine(probe=probe, trange=trange, $
  esa_dist=esa_dist, sst_dist=sst_dist)


thm_part_products, dist_array=combined, outputs='energy'

options, 'thd_pt??f_eflux_energy', zrange=[1e3,1e7]
tplot,'thd_pt??f_eflux_energy'


print, ' ','Load original data manually', ' '

stop

;--------------------------------------------------------------------------------------
;Mask SST data at particular times
;--------------------------------------------------------------------------------------
;Generate the mask variable
calc,'"thd_psif_count_rate_mask"="thd_psif_count_rate" lt 800' ;include data only when rate is less than 800

;Generate combined data
combined = thm_part_combine(probe=probe, trange=trange, esa_datatype=esa_datatype,$
                            sst_datatype=sst_datatype, orig_esa=esa, orig_sst=sst,$
                            sst_data_mask="thd_psif_count_rate_mask")
                            ;set /esa_extrapolate if you want to extrapolate esa data instead of removing sst data
            
;Generate products
thm_part_products, dist_array=combined, outputs='energy'

tplot,'thd_ptirf_eflux_energy'

print,'Mask SST data for particular time intervals'

stop

;--------------------------------------------------------------------------------------
;Propogate Error calculation through to thm_part_products, using
;GET_ERROR. The example is for manual data load, but the /get_error
;option will work in any case. The /get_error option must be used in
;thm_part_combine if it is used subsequently.
;--------------------------------------------------------------------------------------

;set probe and time range
probe = 'd'
trange = '2011-07-29/' + ['13:00','14:00']

;load data manually
;IMPORTANT: always use the same time range and probe!
esa_dist = thm_part_dist_array(probe=probe, trange=trange, datatype = 'peif')
sst_dist = thm_part_dist_array(probe=probe, trange=trange, datatype = 'psif')

;Pass the pre-loaded data through the ESA_DIST and SST_DIST keywords,
;set /get_error
combined = thm_part_combine(probe=probe, trange=trange, $
  esa_dist=esa_dist, sst_dist=sst_dist, /get_error)


thm_part_products, dist_array=combined, outputs=['energy','moments'], /get_error

tplot,'thd_pt??f_*sigma'


print, ' ','Load original data manually, set /get_error and plot', ' '

stop

;--------------------------------------------------------------------------------------
;End
;--------------------------------------------------------------------------------------

print, 'End of crib.'

end

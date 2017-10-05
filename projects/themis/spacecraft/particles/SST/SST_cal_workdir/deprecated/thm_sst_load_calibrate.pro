;+
;NAME:
; thm_sst_load_calibrate
;PURPOSE:
;  Wrapper which loads SST data and performs various calibration tasks; providing a high level interface to sst data.
;  As of 2013-03-11 this provides the most advanced SST calibrations.
;  #1 GEANT4 modeled theoretical channel efficiencies.(provided by Drew Turner)
;  #2 GEANT4 modeled theoretical energy boundaries.(provided by Drew Turner)
;  #3 Empirical dead layers calculated through intercalibration with ESA.(provided by Drew Turner)
;  #4 Empirical detector performance calculated through intercalibration with ESA. (provided by Drew Turner)
;  #5 Interpolates energy channels to single energy grid.  (So that moments & pitch angle distributions can be generated)
;  #6 Interpolates energy channels with ESA to fill energy gap between instruments.
;
;Inputs:
;  probe=probe: Default is "a"
;  datatype=datatype: Default is "psif"
;  esa_datatype=esa_datatype: Default is same datatype as sst (e.g. if datatype is psif esa_datatype is peif)
;                        Use this keyword is you want to use different data types for esa & sst( e.g. full sst & burst esa)
;  trange=trange: Default is current(loading more than 2 hours could be very slow)
;  energies=energies:  The target energy interpolates for SST data in eV
;    default: [26000.,28000., 31000.000,       42000.000,       55500.000,       68000.000,       95500.000,       145000.00,       206500.00,       295500.00,       420000.00,       652500.00,$
;       1133500.0,       3976500.0]
;  sun_bins=sun_bins:  The SST look directions to remove due to sun contamination.
;    default: [0,8,16,24,32,33,40,47,48,55,56,57]
;    Set to -1 for no sun removal
;  dist_esa: use this keyword to return a copy of the esa distribution after time interpolation. (Since it is already interpolated, it makes generating a combined product easier)
;Outputs:
;   dist_data=dist_data:
;    dist_data pointer array(like the type returned by thm_part_dist_array.pro)  
;    dist_data can be used with standard particle routines like thm_part_moments.pro & thm_part_getspec.pro
;    
;  error=error:  After completion, will be set 1 if error occured, zero otherwise   
;NOTES:
;  #1 As of now, this thing is extremely inefficient in processor & memory.  This limits loads to only a few hours on machines with 2-4 Gb of RAM.
;  Future iterations will window loading to reduce memory utilization at the expense of higher processing time.
;
;  #2 Only intended for psif/psef, for now.  Any other usages will produce unreliable results or errors.
;
;  #3 Loads ESA data to perform intercalibration between instruments on the fly.
;  
;  #4 More detailed SST electrons calibration parameters are pending new ESA decontamination.
;
;Examples:
; #1
;  thm_sst_load_calibrate,probe='d',datatype='psif',trange=['2011-07-29/13:00:00','2011-07-29/14:00:00'],dist_data=dist_psif
;  thm_part_moments,inst='psif',probe='d',dist_array=dist_psif
;  thm_part_getspec,data_type='psif',probe='d',dist_array=dist_psif,angle='phi'
;  
;See Also:
;  thm_sst_interpolate_tests.pro
;  thm_part_dist_array.pro
;
;$LastChangedBy: pcruce $
;$LastChangedDate: 2014-03-05 17:20:40 -0800 (Wed, 05 Mar 2014) $
;$LastChangedRevision: 14508 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/particles/SST/SST_cal_workdir/deprecated/thm_sst_load_calibrate.pro $
;-

pro thm_sst_load_calibrate,probe=probe,datatype=datatype,esa_datatype=esa_datatype,trange=trange,energies=energies,sun_bins=sun_bins,dist_data=dist_data,error=error,dist_esa=dist_esa_copy,_extra=ex

  compile_opt idl2

  error=1

  dprint,'WARNING: This routine is deprecated.  Use thm_part_combine with the /only_sst keyword instead',dlevel=1

  heap_gc
  thm_init ;color table & stuffs

  if ~undefined(probe) then begin
    probe=probe ;placeholder for validation code
  endif else begin
    probe='a'
  endelse
  
  if ~undefined(datatype) then begin
    datatype=datatype
  endif else begin
    datatype='psif'
  endelse
  
  if ~undefined(esa_datatype) then begin
    esa_datatype=esa_datatype
  endif else begin
    esa_datatype='pe'+strmid(datatype,2,2)
  endelse
  
  if ~undefined(trange) then begin
    trange=trange
  endif else begin
    trange=timerange()
  endelse
  
  if ~undefined(energies) then begin
    energies=energies
  endif else begin
    ;picked fairly arbitrarily
    if strlowcase(strmid(datatype,2,1)) eq 'i' then begin
      energies = [25300,26000.,28000.,30000.0,34000.0,41000.0,53000.0,67400.0,95400.0,142600.,207400.,297000.,421800.,654600.,1.13460e+06,2.32980e+06,4.00500e+06]
    endif else begin
      energies = [27000,28000.,29000.,30000.0, 31000.0,41000.0,52000.0,65500.0,93000.0,139000.,203500.,293000.,408000.,561500.,719500.]
    endelse
  endelse
  
  sun_mask = dblarr(64)+1 ;allocate variable for bins, with all bins selected
  if ~undefined(sun_bins) then begin
    if sun_bins[0] ne -1 then begin
      sun_mask[sun_bins]=0
    endif
  endif else begin
    sun_mask[[0,8,16,24,32,33,34,40,47,48,49,50,55,56,57]] = 0 
    ;sun_mask[[0,8,16,24,32,33,40,47,48,55,56,57]] = 0
  endelse
  
  start_time=systime(/sec)

  dprint,"Loading Raw Data",dlevel=2
  dprint,"DATATYPE = " + datatype,dlevel=2
  dprint,"PROBE = " + probe,dlevel=2
  dprint,"TIMERANGE = " + time_string(trange),dlevel=2
  dprint,"ENERGIES = " + strjoin(strtrim(energies,2),', '),dlevel=2
  dprint,"SUN BINS = " + strjoin(strtrim(where(~sun_mask),2),', '),dlevel=2
  
  ;Load raw data 
  dist_sst = thm_part_dist_array(probe=probe,type=datatype,trange=trange,/sst_cal,method_clean='manual',sun_bins=sun_mask,_extra=ex)
  dist_esa = thm_part_dist_array(probe=probe,type=esa_datatype,trange=trange,/bgnd_remove)
  
  dprint,"Converting to flux",dlevel=2
  
  ;
  ;change into flux units so that data can be interpolated
  ;don't use eflux because energy variances in SST can make match between SST thetas more troublesome
  thm_part_conv_units,dist_sst,units='flux'
  thm_part_conv_units,dist_esa,units='flux'
  
  ;Interpolate ESA & SST data onto the same time grid
  
  dprint,"Interpolating ESA data to SST times",dlevel=2
  
  thm_part_time_interpolate,dist_esa,dist_sst,error=time_interp_error

  if time_interp_error then begin
    dprint,'ERROR: performing ESA->SST time interpolation',dlevel=0
    return
  endif
  
  if arg_present(dist_esa_copy) then begin
    thm_part_copy,dist_esa,dist_esa_copy
  endif
  
  ;spherical interpolation of ESA look directions to SST

  dprint,"Interpolating ESA data to SST look directions (This may take a while...)",dlevel=2
  
  thm_part_sphere_interpolate,dist_esa,dist_sst,error=sphere_interp_error
        
  if sphere_interp_error then begin
    dprint,'ERROR: performing ESA->SST spherical interpolation',dlevel=0
    return
  endif
  
  ;energy interpolation SST->ESA(fills gap) and SST->SST, so that all look directions share same energy grid
  dprint,"Interpolating SST energies to regular grid",dlevel=2

 
  thm_part_energy_interpolate,dist_sst,dist_esa,energies,error=energy_interp_error
 
  if energy_interp_error then begin
    dprint,'ERROR: performing SST->ESA energy interpolation',dlevel=0
    return
  endif
 
  end_time=systime(/sec)
  dprint,"SST Processing complete.  Total runtime: " + strtrim(end_time-start_time) + ' secs',dlevel=2

 ;cleanup
 
  dist_data=temporary(dist_sst)
 
  undefine,dist_esa
 
 ;set no error occurred state
  error=0

end
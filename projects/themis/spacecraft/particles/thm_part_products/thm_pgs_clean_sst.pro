;+
;PROCEDURE: thm_pgs_clean_sst
;PURPOSE:
;  Helper routine for thm_part_products
;  Maps SST data into simplified format for high-level processing. Converts into physical untis
;  Creates consistency for downstream routines and throws out extra fields to save memory 
;  
;Inputs(required):
;
;  data:  An SST particle data structure, produced by thm_part_dist or thm_sst_ps?? etc...
;  units:  The requested units for the data.
;
;Outputs:
;  output:  A sanitized SST data structure.  Any instrument specific corrections should be applied.
;           Extraneous fields are discarded.  All dimensions should be in ascending order.
;           Structure definition:
;               ** Structure <afc6c05c>, 10 tags, length=30736, data length=30736, refs=1:
;               DATA            FLOAT     Array[16, 64]
;               TIME            DOUBLE       1.1746086e+09
;               END_TIME        DOUBLE       1.1746086e+09
;               PHI             FLOAT     Array[16, 64]
;               DPHI            FLOAT     Array[16, 64]
;               THETA           FLOAT     Array[16, 64]
;               DTHETA          FLOAT     Array[16, 64]
;               ENERGY          FLOAT     Array[16, 64]
;               DENERGY         FLOAT     Array[16, 64]
;               BINS            INT       Array[16, 64]
;               CHARGE          FLOAT          0.000000
;               MASS            FLOAT         0.0104390
;               MAGF            FLOAT     Array[3]
;               SC_POT          FLOAT          0.000000
;           
;           
;Keywords:
;  sst_sun_bins:  The bin numbers that should be flagged as contaminated by sun and interpolated
;  sst_method_clean: how to decontaminate the sst data.  Right now the only option is 'manual', but selects a good set of default sst_sun_bins, if not user specified.
;  sst_min_energy: Set to minimum energy to toss bins that are having problems from instrument degradation. 
;$LastChangedBy: aaflores $
;$LastChangedDate: 2016-08-24 18:29:05 -0700 (Wed, 24 Aug 2016) $
;$LastChangedRevision: 21724 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/particles/thm_part_products/thm_pgs_clean_sst.pro $
;-


;Note: Keep options for vectorizing open
pro thm_pgs_clean_sst,data,units,output=output,sst_sun_bins=sst_sun_bins,sst_method_clean=sst_method_clean,sst_min_energy=sst_min_energy,remove_counts=remove_counts,_extra=ex

  compile_opt idl2,hidden
  
  ;set default bins 
  ;if keyword_set(sst_method_clean) && undefined(sst_sun_bins) then begin
  if undefined(sst_sun_bins) then begin ;now enabled by default
    
    ;no good default for reduced angle mode
    if strlowcase(tag_names(data,/str)) eq 'thm_sst_dist3d_16x1' || strlowcase(tag_names(data,/str)) eq 'thm_sst_dist3d_16x6' then begin
      sst_sun_bins = -1
    endif else begin ;good default for full & burst
      sst_sun_bins = [0,8,16,24,32,33,34,40,47,48,49,50,55,56,57]
      dprint,'Sun decontamination being enabled by default(disable with sst_sun_bins=-1)',dlevel=1
      ;bin list determined empirically through analysis Jim McTiernan @ UC Berkeley SSL. (jimm@ssl.berkeley.edu)
      ;after testing, determined that a few additional bins needed to cover earlier dates,pat
      ;Additional bins: 2,34,49,50
    endelse 

  endif

  ;allow user to set threshold of N counts
  if keyword_set(remove_counts) then begin
    thm_part_remove, data, threshold=remove_counts, /zero
  endif

  ;convert to requested units
  ;get scaling coefficient used to convert from counts->units
  udata = conv_units(data,units,scale=scale,_extra=ex)
  scale = float(scale)
  if n_elements(scale) eq 1 then begin
    scale = replicate(scale,size(data.data,/dim))
  endif
  
  if strlowcase(tag_names(udata,/str)) eq '' then begin ;anonymous struct, indicates output from user processing routine
    
    output = {data:udata.data[*,*], $ ;particle data 2-d array, energy by angle. (Float or double)
      scaling:scale[*,*], $ ;scaling coefficient corresponding to 1 count/bin, used for error calculation (float or double)
      time:udata.time, $ ;sample start time(1-element double precision scalar)
      end_time:udata.end_time, $ ;sample end time(1-element double precision scalar)
      phi:udata.phi[*,*], $ ;Measurment angle in plane parallel to spacecraft spin.(2-d array matching data array.) (Float or double)
      dphi:udata.dphi[*,*], $ ;Width of measurement angle in plane parallel to spacecraft spin.(2-d array matching data array.) (Float or double)
      theta:udata.theta[*,*], $ ;Measurment angle in plane perpendicular to spacecraft spin.(2-d array matching data array.) (Float or double)
      dtheta:udata.dtheta[*,*], $ ;Width of measurement angle in plane perpendicular to spacecraft spin. (2-d array matching data array.) (Float or double)
      energy:udata.energy[*,*], $ ;Contains measurment energy for each component of data array. (2-d array matching data array.) (Float or double)
      denergy:udata.denergy[*,*], $ ;Width of measurment energy for each component of data array. (2-d array matching data array.)
      bins:udata.bins[*,*], $ ; 0-1 array, indicating which bins are enabled for subsequent calculations. (2-d array matching data array.)  (Integer type.)
      charge:udata.charge, $ ;expected particle charge (1-element float scalar)
      mass:udata.mass, $ ;expected particle mass (1-element float scalar)
      magf:udata.magf, $ ;placeholder for magnetic field vector(3-element float array)
      sc_pot:udata.sc_pot $ ;placeholder for spacecraft potential (1-element float scalar)
    }
  endif else if strlowcase(tag_names(udata,/str)) eq 'thm_sst_dist3d_16x64_2' then begin
    ;NOTE: this code is coupled with code in thm_part_dist2, if you change this, you'll probably have to change that
    if data.channel eq 'f' || data.channel eq 'o' then begin
      energy_idx = [0,1,2,3,4,5,6,7,8,9,10,11]  
    endif else if data.channel eq 'ft' then begin
      energy_idx = [12,13,14]
    endif else if data.channel eq 'ot' then begin
      energy_idx = [12,13]
    endif else if data.channel eq 'fto' then begin
      energy_idx = [15]
    endif else if data.channel eq 'f_ft' then begin
      energy_idx = [0,1,2,3,4,5,6,7,8,9,10]
    endif else begin
      message,'ERROR: unexpected channel label: "' + data.channel + '"' 
    endelse
    
    output = {data:udata.data[energy_idx,*], $ ;particle data 2-d array, energy by angle. (Float or double)
      scaling:scale[energy_idx,*], $ ;scaling coefficient corresponding to 1 count/bin, used for error calculation (float or double)
      time:udata.time, $ ;sample start time(1-element double precision scalar)
      end_time:udata.end_time, $ ;sample end time(1-element double precision scalar)
      phi:udata.phi[energy_idx,*], $ ;Measurment angle in plane parallel to spacecraft spin.(2-d array matching data array.) (Float or double)
      dphi:udata.dphi[energy_idx,*], $ ;Width of measurement angle in plane parallel to spacecraft spin.(2-d array matching data array.) (Float or double)
      theta:udata.theta[energy_idx,*], $ ;Measurment angle in plane perpendicular to spacecraft spin.(2-d array matching data array.) (Float or double)
      dtheta:udata.dtheta[energy_idx,*], $ ;Width of measurement angle in plane perpendicular to spacecraft spin. (2-d array matching data array.) (Float or double)
      energy:udata.energy[energy_idx,*], $ ;Contains measurment energy for each component of data array. (2-d array matching data array.) (Float or double)
      denergy:udata.denergy[energy_idx,*], $ ;Width of measurment energy for each component of data array. (2-d array matching data array.)
      bins:udata.bins[energy_idx,*], $ ; 0-1 array, indicating which bins are enabled for subsequent calculations. (2-d array matching data array.)  (Integer type.)
      charge:udata.charge, $ ;expected particle charge (1-element float scalar)
      mass:udata.mass, $ ;expected particle mass (1-element float scalar)
      magf:udata.magf, $ ;placeholder for magnetic field vector(3-element float array)
      sc_pot:udata.sc_pot $ ;placeholder for spacecraft potential (1-element float scalar)
    }      
  endif else begin
  
    ;[0:11] includes only f/o channels by default
    output = {data:udata.data[0:11,*], $ ;particle data 2-d array, energy by angle. (Float or double)
      scaling:scale[0:11,*], $ ;scaling coefficient corresponding to 1 count/bin, used for error calculation (float or double)
      time:udata.time, $ ;sample start time(1-element double precision scalar)
      end_time:udata.end_time, $ ;sample end time(1-element double precision scalar)
      phi:udata.phi[0:11,*], $ ;Measurment angle in plane parallel to spacecraft spin.(2-d array matching data array.) (Float or double)
      dphi:udata.dphi[0:11,*], $ ;Width of measurement angle in plane parallel to spacecraft spin.(2-d array matching data array.) (Float or double)
      theta:udata.theta[0:11,*], $ ;Measurment angle in plane perpendicular to spacecraft spin.(2-d array matching data array.) (Float or double)
      dtheta:udata.dtheta[0:11,*], $ ;Width of measurement angle in plane perpendicular to spacecraft spin. (2-d array matching data array.) (Float or double)
      energy:udata.energy[0:11,*], $ ;Contains measurment energy for each component of data array. (2-d array matching data array.) (Float or double)
      denergy:udata.denergy[0:11,*], $ ;Width of measurment energy for each component of data array. (2-d array matching data array.)
      bins:udata.bins[0:11,*], $ ; 0-1 array, indicating which bins are enabled for subsequent calculations. (2-d array matching data array.)  (Integer type.)
      charge:udata.charge, $ ;expected particle charge (1-element float scalar)
      mass:udata.mass, $ ;expected particle mass (1-element float scalar)
      magf:udata.magf, $ ;placeholder for magnetic field vector(3-element float array)
      sc_pot:udata.sc_pot $ ;placeholder for spacecraft potential (1-element float scalar)
    }
  endelse

  if ~undefined(sst_min_energy) then begin

    idx = where(max(output.energy,dimension=2) ge sst_min_energy,c)
    
    if c eq 0 then begin
      message,'ERROR: sst_min_energy identifies zero valid bins' 
    endif
    
    output = {data:output.data[idx,*], $ ;particle data 2-d array, energy by angle. (Float or double)
      scaling:output.scaling[idx,*], $ ;scaling coefficient corresponding to 1 count/bin, used for error calculation (float or double)
      time:output.time, $ ;sample start time(1-element double precision scalar)
      end_time:output.end_time, $ ;sample end time(1-element double precision scalar)
      phi:output.phi[idx,*], $ ;Measurment angle in plane parallel to spacecraft spin.(2-d array matching data array.) (Float or double)
      dphi:output.dphi[idx,*], $ ;Width of measurement angle in plane parallel to spacecraft spin.(2-d array matching data array.) (Float or double)
      theta:output.theta[idx,*], $ ;Measurment angle in plane perpendicular to spacecraft spin.(2-d array matching data array.) (Float or double)
      dtheta:output.dtheta[idx,*], $ ;Width of measurement angle in plane perpendicular to spacecraft spin. (2-d array matching data array.) (Float or double)
      energy:output.energy[idx,*], $ ;Contains measurment energy for each component of data array. (2-d array matching data array.) (Float or double)
      denergy:output.denergy[idx,*], $ ;Width of measurment energy for each component of data array. (2-d array matching data array.)
      bins:output.bins[idx,*], $ ; 0-1 array, indicating which bins are enabled for subsequent calculations. (2-d array matching data array.)  (Integer type.)
      charge:output.charge, $ ;expected particle charge (1-element float scalar)
      mass:output.mass, $ ;expected particle mass (1-element float scalar)
      magf:output.magf, $ ;placeholder for magnetic field vector(3-element float array)
      sc_pot:output.sc_pot $ ;placeholder for spacecraft potential (1-element float scalar)
    }

  endif

  ;perform sst sun contamination
  ;
  ;Error for removed data will later be calculated as the statistical error 
  ;corresponding the actual measurements (in counts) which would precipitate 
  ;the interpolated values.  This assumes that non-contaminated bins will not
  ;have their values changed by the interpolation below (true for method=linear).
  if ~undefined(sst_sun_bins) then begin
          
    dim = dimen(output.data)

    ;doesn't work in single angle mode
    if n_elements(dim) gt 1 then begin
      
      method="Linear"
      ;remove sun bins
      sst_includes = ssl_set_complement(sst_sun_bins,dindgen(dim[1]))
   
      qhull,udata.phi[0,sst_includes],udata.theta[0,sst_includes],triangles,sphere=dummy
   
      for i = 0,dim[0]-1 do begin
        ;spherically interpolate across sun bins
        output.data[i,*] = griddata(output.phi[i,sst_includes],output.theta[i,sst_includes],output.data[i,sst_includes],$
          /sphere,/degrees,xout=reform(output.phi[i,*]),yout=reform(output.theta[i,*]),method=method,triangles=triangles) 
      endfor
      
    endif
    
  endif
            
end
;+
;PROCEDURE:
;  thm_part_energy_interpolate
;
;PURPOSE:
;  Interpolate particle data by energy between sst & esa distributions using 
;  a weighted curve fitting routine.
;
;INPUTS:
;  dist_sst: SST particle distribution structure in flux 
;  dist_esa: ESA particle distribution structure in flux
;  energies: The set of target energies to interpolated the SST to.
;    
;OUTPUTS:
;   Replaces dist_sst with the interpolated data set
;
;KEYWORDS: 
;  error: Set to 1 on error, zero otherwise
;  get_error:  if set, interpolates scaling factor needed for error propagation
;  
;NOTES:
;   #1 The number of time samples and the times of those samples must 
;      be the same for dist_sst & dist_esa (use thm_part_time_interpolate.pro)
;   #2 The number of angles and the angles of each sample must be 
;      the same for dist_sst & dist_esa (use thm_part_sphere_interp.pro)
;
;SEE ALSO:
;   thm_part_dist_array
;   thm_part_smooth
;   thm_part_subtract,
;   thm_part_omni_convert
;   thm_part_time_interpolate.pro
;   thm_part_sphere_interp.pro
;
;  $LastChangedBy: pcruce $
;  $LastChangedDate: 2013-09-26 16:32:05 -0700 (Thu, 26 Sep 2013) $
;  $LastChangedRevision: 13156 $
;  $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/thmsoc/trunk/idl/themis/spacecraft/particles/thm_part_energy_interpolate.pro $
;-

pro thm_part_energy_interp,dist_sst,dist_esa,energies,error=error,extrapolate_esa=extrapolate_esa,get_error=get_error;,dist_sst_counts=dist_sst_counts,dist_esa_counts=dist_esa_counts,emin=emin

   compile_opt idl2
   
   error=1
   
   dist_esa_i = 0
   dist_esa_j = 0
    
   min_flux = 1e-4 ; order of magnitude of min 1 count flux for esa/sst.  Used so that we can to log/log interpolation on data with a lot of zeros
    
   ;TBD units must be FLUX
    
   ;TBD input validation
   ;TBD verification that number of samples in dist_sst matches the number in dist_esa...
   ;TBD verification that the number of angles in dist_sst match the number in dist_esa 
   ;TBD verification of units on input distributions
   
   blankarr = (fltarr(n_elements(energies))+1)
  
   for i = 0,n_elements(dist_sst)-1 do begin
     extrap_num = 0 ;keep track of how many angles were extrapolated
   
     ;Note that most of the calculations below assume that variables
     ;are not changing along one dimension or another.  If that assumption
     ;fails, these calculations will need to be made more complex.
     sst_dim = dimen((*dist_sst[i])[0].data)
     sst_template_out = (*dist_sst[i])[0]
     sst_energy_out = energies # (fltarr(sst_dim[1])+1)
     sst_denergy_out = blankarr # (fltarr(sst_dim[1]))
     sst_data_out = blankarr # (fltarr(sst_dim[1]))
     sst_scaling_out = blankarr # (fltarr(sst_dim[1]))
     sst_bins_out =  blankarr # (*dist_sst[i])[0].bins[0,*]
     sst_phi_out = blankarr # sst_template_out.phi[0,*]
     sst_theta_out = blankarr # sst_template_out.theta[0,*]
     sst_dphi_out = blankarr # sst_template_out.dphi[0,*]
     sst_dtheta_out = blankarr # sst_template_out.dtheta[0,*]
     
     ;update all the supplemental variables that are required by the moment routines
     str_element,sst_template_out,'energy',sst_energy_out,/add_replace
     str_element,sst_template_out,'denergy',sst_denergy_out,/add_replace
     str_element,sst_template_out,'data',sst_data_out,/add_replace
     str_element,sst_template_out,'scaling',sst_scaling_out,/add_replace ;jmm, 2017-09-28
     str_element,sst_template_out,'bins',sst_bins_out,/add_replace
     str_element,sst_template_out,'phi',sst_phi_out,/add_replace
     str_element,sst_template_out,'theta',sst_theta_out,/add_replace
     str_element,sst_template_out,'dphi',sst_dphi_out,/add_replace 
     str_element,sst_template_out,'dtheta',sst_dtheta_out,/add_replace
     
     ;expand to match number of samples
     sst_mode_out = replicate(sst_template_out,n_elements(*dist_sst[i]))
     
     ;look over samples for this combined mode
     for j = 0,n_elements(*dist_sst[i])-1 do begin
     
       sample_sst = (*dist_sst[i])[j]
       sample_esa = (*dist_esa[dist_esa_i])[dist_esa_j]

       ;combined, pre-interpolated data
       combined_energy = [sample_esa.energy,sample_sst.energy]
       combined_data = [sample_esa.data,sample_sst.data]
       combined_scaling = [sample_esa.scaling,sample_sst.scaling]
       combined_bins = [sample_esa.bins,sample_sst.bins]
       combined_dim = dimen(combined_energy)
       
       ;Calculate energy bin widths for target energies a la moments_3d
       ;  -uses 1/2 the separation of each 2 energy bin values
       ;  -endpoints use the de/e from adjacent bin scaled by their energy
       combined_tmp = [sample_esa.energy[*,0],energies]
       esa_dim = dimen(sample_esa.data)
       tmp_dim = dimen(combined_tmp)
       combined_denergy = (shift(combined_tmp,-1)-shift(combined_tmp,1))/2. / combined_tmp
       combined_denergy[0] = combined_denergy[1]
       combined_denergy[tmp_dim[0]-1] = combined_denergy[tmp_dim[0]-2]
       combined_denergy *= combined_tmp
       ;combined_denergy = deriv([sample_esa.energy[*,0],energies])
       sst_mode_out[j].denergy = (combined_denergy[esa_dim[0]:tmp_dim[0]-1]) # replicate(1.,sst_dim[1]) 
       
       if max(sample_esa.energy,/nan) gt min(energies,/nan) then begin
         dprint,dlevel=1,'ERROR: ESA maximum energy(' + strtrim(max(sample_esa.energy,/nan),2) + ' eV) greater than minimum energy target(' + strtrim(min(energies,/nan),2) + ' eV)' 
         return
       endif
       
       sst_mode_out[j].time=sample_sst.time ;copy time over
       sst_mode_out[j].end_time=sample_sst.end_time ;copy time over
       
       ;loop over look directions and interpolate 
       for l=0,sst_dim[1]-1 do begin
       
         ;generate bins data for new bins(not needed...I think?)
         ;sst_mode_out[j].bins[*,l] = round(interpol(sample_sst.bins[*,l],sample_sst.energy[*,l],energies)) > 0 < 1

         sst_idx = where(sample_sst.bins[*,l],c)
         if c eq 0 then begin
           ;extrapolate from ESA data if requested and no valid SST data exists
           ;set highest SST energy bin to zero to ensure interpolation doesn't go wild
           if keyword_set(extrapolate_esa) then begin
             extrap_num++
             combined_bins[combined_dim[0]-1l,l] = 1 ;enable highest energy
             combined_data[combined_dim[0]-1l,l] = 0 ;set to zero
;             combined_energy[-1,l] = energies[-1]
             sst_mode_out[j].bins[*,l] = 1
           endif else begin
             combined_bins[combined_dim[0]-n_elements(energies):combined_dim[0]-1l,l] = 1 ;enable bins
             combined_data[combined_dim[0]-n_elements(energies):combined_dim[0]-1l,l] = !VALUES.D_NAN ;set to zero
           
             ;dprint,dlevel=1,'ERROR: No SST bins enabled for angle:'+strtrim(l,2)
             ;return
           endelse
         endif
         
         ;need to use proper bins so that disabled bins aren't included in interpolation calculations
         combined_idx = where(combined_bins[*,l],c)
         if c eq 0 then begin
           dprint,dlevel=1,'ERROR: No bins enabled for angle:'+strtrim(l,2)
           return
         endif

         ;The +min_flux -min_flux, turns alog(0) to alog(min_flux) preventing lots of -infinities in our interpolation, should work for scaling too 
         sst_mode_out[j].data[*,l] = exp(interpol(alog(combined_data[combined_idx,l]+min_flux),alog(combined_energy[combined_idx,l]),alog(energies)))-min_flux 
         if keyword_set(get_error) then sst_mode_out[j].scaling[*,l] = exp(interpol(alog(combined_scaling[combined_idx,l]+min_flux),alog(combined_energy[combined_idx,l]),alog(energies)))-min_flux 
;         sst_mode_out[j].data[*,l] = interpol(combined_data[combined_idx,l],combined_energy[combined_idx,l],energies) 
       
       endfor
   
       ;dist_two should have matching time samples, but not necessarily 
       ;matching mode transitions, the index logic below synchronizes 
       ;iterations over the two data structures 
       dist_esa_j++
       if n_elements(*dist_esa[dist_esa_i]) eq dist_esa_j then begin
         dist_esa_i++
         dist_esa_j=0
       endif 
       
     endfor
     
     ;notify user of how many angles were extrapolated
     if keyword_set(extrapolate_esa) then begin
       dprint, dlevel=2, 'Extrapolated '+strtrim(extrap_num,2)+' angles over '+strtrim(j,2)+' samples in mode'
     endif

     ;temporary routine bombs on some machines if out_dist is undefined, but not others
     if ~undefined(dist_out) then begin
       dist_out=array_concat(ptr_new(sst_mode_out,/no_copy),temporary(dist_out))
     endif else begin
       dist_out=array_concat(ptr_new(sst_mode_out,/no_copy),dist_out)
     endelse
   endfor
   
   dist_sst=temporary(dist_out)
   heap_gc   
   error=0

end

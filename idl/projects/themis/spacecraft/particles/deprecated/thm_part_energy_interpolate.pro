;+
;PROCEDURE: thm_part_energy_interpolate
;PURPOSE:  Interpolate particle data by energy between sst & esa distributions using a weighted curve fitting routine
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
;  
; NOTES:
;   #1 The number of time samples and the times of those samples must be the same for dist_sst & dist_esa (use thm_part_time_interpolate.pro)
;   #2 The number of angles and the angles of each sample must be the same for dist_sst & dist_esa (use thm_part_sphere_interpolate.pro)
; SEE ALSO:
;   thm_part_dist_array, thm_part_smooth, thm_part_subtract,thm_part_omni_convert,thm_part_time_interpolate.pro,thm_part_sphere_interpolate.pro
;
;  $LastChangedBy: jimm $
;  $LastChangedDate: 2017-10-02 11:19:09 -0700 (Mon, 02 Oct 2017) $
;  $LastChangedRevision: 24078 $
;  $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/particles/deprecated/thm_part_energy_interpolate.pro $
;-

pro thm_part_energy_interpolate,dist_sst,dist_esa,energies,error=error;,dist_sst_counts=dist_sst_counts,dist_esa_counts=dist_esa_counts,emin=emin

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
   
  
   for i = 0,n_elements(dist_sst)-1 do begin
   
     ;note that most of these calculations below assume that variables are not changing along one dimension or another
     ;If they change on both, these calculations will need to be made more complex
     sst_dim = dimen((*dist_sst[i])[0].data)
     sst_template_out = (*dist_sst[i])[0]
     sst_energy_out = energies#(fltarr(sst_dim[1])+1)
     sst_denergy_out = abs(deriv(energies))#(fltarr(sst_dim[1])+1)
     sst_data_out = (fltarr(n_elements(energies))+1)#(fltarr(sst_dim[1]))
     sst_bins_out = (fltarr(n_elements(energies))+1)#(*dist_sst[i])[0].bins[0,*]
     ;sst_bins_out = (fltarr(n_elements(energies))+1)#(fltarr(sst_dim[1])+1) 
     sst_gf_out = (fltarr(n_elements(energies))+1)#sst_template_out.gf[0,*]
     sst_integ_t_out = (fltarr(n_elements(energies))+1)#(*dist_sst[i])[0].integ_t[0,*]
 ;    sst_eff_out = interpol(reform(sst_template_out.eff[*,0]),reform(sst_template_out.energy[*,0]),energies)#(fltarr(sst_dim[1])+1)
     sst_eff_out = (fltarr(n_elements(energies))+1)#(fltarr(sst_dim[1]))
     
     sst_phi_out = (fltarr(n_elements(energies))+1)#sst_template_out.phi[0,*]
     sst_theta_out =(fltarr(n_elements(energies))+1)#sst_template_out.theta[0,*]
     sst_dphi_out = (fltarr(n_elements(energies))+1)#sst_template_out.dphi[0,*]
     sst_dtheta_out = (fltarr(n_elements(energies))+1)#sst_template_out.dtheta[0,*]
     
     ;update all the supplemental variables that are required by the moment routines
     str_element,sst_template_out,'energy',sst_energy_out,/add_replace
     str_element,sst_template_out,'denergy',sst_denergy_out,/add_replace
     str_element,sst_template_out,'data',sst_data_out,/add_replace
     str_element,sst_template_out,'att',/delete ;remove attenuator calibration factors
     str_element,sst_template_out,'bins',sst_bins_out,/add_replace
     str_element,sst_template_out,'gf',sst_gf_out,/add_replace
     str_element,sst_template_out,'eff',sst_eff_out,/add_replace
     str_element,sst_template_out,'integ_t',sst_integ_t_out,/add_replace
     str_element,sst_template_out,'phi',sst_phi_out,/add_replace
     str_element,sst_template_out,'theta',sst_theta_out,/add_replace
     str_element,sst_template_out,'dphi',sst_dphi_out,/add_replace 
     str_element,sst_template_out,'dtheta',sst_dtheta_out,/add_replace

     sst_template_out.nenergy = n_elements(energies)
   
     ;eff, denergy, gf
   
     sst_mode_out = replicate(sst_template_out,n_elements(*dist_sst[i]))
   
     for j = 0,n_elements(*dist_sst[i])-1 do begin
     
       sample_sst = (*dist_sst[i])[j]
       sample_esa = (*dist_esa[dist_esa_i])[dist_esa_j]
      
       combined_energy = [reverse(sample_esa.energy,1),sample_sst.energy]
       combined_data = [reverse(sample_esa.data,1),sample_sst.data]
       combined_bins = [reverse(sample_esa.bins,1),sample_sst.bins]
       
       if max(sample_esa.energy,/nan) gt min(energies,/nan) then begin
        dprint,dlevel=1,'ERROR: ESA maximum energy(' + strtrim(max(sample_esa.energy,/nan),2) + ' eV) greater than minimum energy target(' + strtrim(min(energies,/nan),2) + ' eV)' 
        return
       endif
       
       sst_mode_out[j].atten=sample_sst.atten ;copy atten flags over
       sst_mode_out[j].time=sample_sst.time ;copy time over
       sst_mode_out[j].end_time=sample_sst.end_time ;copy time over
       for l=0,sst_dim[1]-1 do begin
         ;generate bins data for new bins(not needed...I think?)
         ;sst_mode_out[j].bins[*,l] = round(interpol(sample_sst.bins[*,l],sample_sst.energy[*,l],energies)) > 0 < 1
         
         ;need to use proper bins so that disabled bins aren't included in interpolation calculations
         combined_idx = where(combined_bins[*,l],c)
         if c eq 0 then begin
           dprint,dlevel=1,'ERROR: No bins enabled for angle:'+strtrim(l,2)
           return
         endif

         sst_idx = where(sample_sst.bins[*,l],c)
         if c eq 0 then begin
           dprint,dlevel=1,'ERROR: No SST bins enabled for angle:'+strtrim(l,2)
           return
         endif 
         
         ;The +min_flux -min_flux, turns alog(0) to alog(min_flux) preventing lots of -infinities in our interpolation 
         sst_mode_out[j].data[*,l] = exp(interpol(alog(combined_data[combined_idx,l]+min_flux),alog(combined_energy[combined_idx,l]),alog(energies)))-min_flux 
      ;   sst_mode_out[j].data[*,l] = interpol(combined_data[combined_idx,l],combined_energy[combined_idx,l],energies) 
       
         ;don't use ESA data to interpolate efficiencies since they're not really comparable to SST efficiencies.
         ;sst_mode_out[j].eff[*,l] = interpol(sample_sst.eff[sst_idx,l],sample_sst.energy[sst_idx,l],energies)
          sst_mode_out[j].eff[*,l] = interpol(sample_sst.eff[sst_idx,l],alog(sample_sst.energy[sst_idx,l]),alog(energies)) ;since energy distribution is log, but efficiency is, roughly, linear use log energy linear efficiency
       endfor
   
       
   
       ;if sample_sst.time - time_double('2011-07-29/12:35:00') gt 0 then stop
       
;       sst_data_out = (dblarr(n_elements(energies))+1)#(dblarr(sst_dim[1])+1)
;       sst_energy_out = energies#(dblarr(sst_dim[1])+1)
;       
;     
;          
;          sst_data_out[*,l] = interpol_data
;       endfor
       
       
; test code, easier to check out the plots "in situ"
; compares an interpolation of omni data with an angle by angle interpolation followed by a conversion to omni
;       plot,total(sample_esa.energy,2,/nan)/64.,total(sample_esa.data,2,/nan)/64.,/xlog,/ylog,xrange=minmax(total(combined_energy,2,/nan))/64.,yrange=minmax(total(combined_data,2,/nan))/64.,color=0
;
;       interpol_data = interpol(total(combined_data,2,/nan)/64.,total(combined_energy,2,/nan)/64.,energies)
;       oplot,energies,interpol_data,color=4
;       oplot,total(sample_sst.energy,2,/nan)/64.,total(sample_sst.data,2,/nan)/64.,color=2
;
;       kluge=0
;       stop
;       for l=0,sst_dim[1]-1 do begin
;         plot,sample_esa.energy[*,l],sample_esa.data[*,l],/xlog,/ylog,xrange=minmax(combined_energy),yrange=minmax(combined_data)
;  
;         interpol_data = interpol(combined_data[*,l],combined_energy[*,l],energies)
;         sst_data_out[*,l] = interpol_data
;         oplot,energies,interpol_data,color=4
;         oplot,sample_sst.energy[*,l],sample_sst.data[*,l],color=2
;
;         if kluge then stop
;       endfor
;       
;       plot,total(sample_esa.energy,2,/nan)/64.,total(sample_esa.data,2,/nan)/64.,/xlog,/ylog,xrange=minmax(total(combined_energy,2,/nan))/64.,yrange=minmax(total(combined_data,2,/nan))/64.,color=0
;
;       oplot,energies,total(sst_data_out,2,/nan)/64.,color=4
;       oplot,total(sample_sst.energy,2,/nan)/64.,total(sample_sst.data,2,/nan)/64.,color=2
;       stop
       
;       plot,sample_esa.energy[*,l],sample_esa.data[*,l],/xlog,/ylog,xrange=minmax(combined_energy),yrange=minmax(combined_data)
;       oplot,sample_sst.energy[*,l],sample_sst.data[*,l],color=2
;       stop
       
       
       ;dist_two should have matching time samples, but not necessarily matching mode transitions, the index logic below synchronizes iterations over the two data structures 
       dist_esa_j++
       if n_elements(*dist_esa[dist_esa_i]) eq dist_esa_j then begin
         dist_esa_i++
         dist_esa_j=0
       endif 
     endfor
     
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
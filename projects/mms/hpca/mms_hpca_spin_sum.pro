;+
; PROCEDURE:
;         mms_hpca_spin_sum
;
; PURPOSE:
;         Calculates spin-summed fluxes and counts for the HPCA instrument
;
; KEYWORDS:
;         probe: observatory # to spin sum the spectra for (e.g., probe='1')
;         datatype: type of data to spin sum; potential options include:
;             flux, count_rate, RF_corrected, bkgd_corrected, norm_counts
;         fov: field of view of the spectra created with mms_hpca_calc_anodes; 
;             default is [0, 360]
;         tplotnames: list of tplot variable names already loaded; should
;             include the HPCA spectra variables you would like to spin-sum;
;             if not provided, uses tnames() by default. 
;         avg: average instead of sum
;         suffix: suffix that was used when the data were loaded; if you provide a suffix
;         to mms_load_hpca and mms_hpca_calc_anodes, you'll need to apply a suffix
;         here as well
;         
; OUTPUT:
;         Creates tplot variables containing the spin summed fluxes and counts; 
;         the new variables have the suffix "_spin" appended to their names
;
; NOTES:
;         Must have HPCA data loaded and summed/averaged over the FoV (or anodes); i.e., 
;         you must have already called mms_load_hpca and mms_hpca_calc_anodes prior to 
;         calling this routine. 
;     
;     
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2021-03-02 09:40:53 -0800 (Tue, 02 Mar 2021) $
;$LastChangedRevision: 29721 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/hpca/mms_hpca_spin_sum.pro $
;-

pro mms_hpca_spin_sum, probe = probe, datatype=datatype, species=species, fov=fov, tplotnames=tplotnames, avg=avg, names_out=names_out, suffix=suffix
    if undefined(probe) then begin
        dprint, dlevel = 0, 'Error, must provide probe # to spin-sum the HPCA data'
        return
    endif else begin
        probe = strcompress(string(probe), /rem)
    endelse
    
    if undefined(suffix) then suffix = ''
    
    if undefined(datatype) then datatype =['*_count_rate', '*_RF_corrected', '*_bkgd_corrected', '*_norm_counts', '*_flux'] else datatype = '*_'+datatype
    if undefined(species) then species = ['hplus', 'oplus', 'oplusplus', 'heplus', 'heplusplus']
    if undefined(fov) then fov = ['0', '360'] else fov = strcompress(string(fov),/rem)
    if undefined(tplotnames) then tplotnames = tnames()
    
    get_data, 'mms'+probe+'_hpca_start_azimuth'+suffix, data=start_az
    
    if ~is_struct(start_az) then begin
        dprint, dlevel = 0, 'Error, couldn''t find the variable containing the start azimuth'
        return
    endif
    spin_starts = where(start_az.Y eq 0, count_starts)
    
    if count_starts eq 0 then begin
        dprint, dlevel = 0, 'Error, couldn''t identify spin starts from start_azimuth tplot variable'
        return
    endif

    for sum_idx = 0, n_elements(datatype)-1 do begin
        vars_to_sum = strmatch(tplotnames, datatype[sum_idx]+suffix+'_elev_'+fov[0]+'-'+fov[1])

        for vars_idx = 0, n_elements(vars_to_sum)-1 do begin
            if vars_to_sum[vars_idx] eq 1 then begin
                for species_idx = 0, n_elements(species)-1 do begin
                  
                  ;varname = 'mms'+probe+'_hpca_'+species[species_idx]+'_'+datatype+'_elev_'+fov[0]+'-'+fov[1]
                  varname = tplotnames[vars_idx]
                  
                  get_data, varname, data=hpca_data, dlimits=hpca_dl, limits=hpca_l
        
                  if ~is_struct(hpca_data) then begin
                    dprint, dlevel = 0, 'Error, couldn''t load data from the variable: ' + varname
                    return
                  endif
        
                  spin_summed = dblarr(n_elements(spin_starts), n_elements(hpca_data.Y[0, *]))
        
                  for spin_idx = 0, n_elements(spin_starts)-2 do begin
                    if ~keyword_set(avg) then spin_summed[spin_idx, *] = total(hpca_data.Y[spin_starts[spin_idx]:spin_starts[spin_idx+1]-1,*], 1, /nan, /double) $
                    else spin_summed[spin_idx, *] = average(hpca_data.Y[spin_starts[spin_idx]:spin_starts[spin_idx+1]-1,*], 1, /nan, /double)
                  endfor
        
                  new_varname = varname+'_spin'
        
                  store_data, new_varname, data={x: start_az.X[spin_starts], y: spin_summed, v: hpca_data.V}, dlimits=hpca_dl, limits=hpca_l
                  options, new_varname, spec=1
                  ylim, new_varname, 0, 0, 1
                  zlim, new_varname, 0, 0, 1
                  append_array, names_out, new_varname
                endfor
            endif
        endfor
    endfor
end

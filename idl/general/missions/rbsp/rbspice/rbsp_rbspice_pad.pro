;+
; PROCEDURE:
;         rbsp_rbspice_pad
;
; PURPOSE:
;         Calculate pitch angle distributions using data from the
;           RBSP Radiation Belt Storm Probes Ion Composition Experiment (RBSPICE)
;
; KEYWORDS:
;
;         probe:      RBSP spacecraft indicator [Options: 'a' (default), 'b']
;         trange:     Time range of interest  (2 element array); if not set, the default is to prompt the user
;         datatype:   desired data type [Options: 'TOFxEH' (default), 'TOFxEnonH']
;         level:      data level ['l1','l2','l3' (default),'l3pap']
;         energy:     user-defined energy range to include in the calculation in keV [default = [0,1000]]
;         bin_size:   desired size of the pitch angle bins in degrees [default = 15]
;         scopes:       string array of telescopes to be included in PAD [0-5, default is all]
;
; EXAMPLES:
;
;
; OUTPUT:
;
;
; NOTES:
;     This was written by Brian Walsh; minor modifications by egrimes@igpp and Ian Cohen (APL)
;
; REVISION HISTORY:
;       + 2017-02-22, I. Cohen      : created based on mms_eis_pad.pro, edited to handle omni-directional or single telescope
;    
;$LastChangedBy: egrimes $
;$LastChangedDate: 2017-03-03 08:08:58 -0800 (Fri, 03 Mar 2017) $
;$LastChangedRevision: 22902 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/rbsp/rbspice/rbsp_rbspice_pad.pro $   
;-
pro rbsp_rbspice_pad,probe = probe, trange = trange, datatype = datatype, level = level, $
                energy = energy, bin_size = bin_size, scopes = scopes
                
    if not KEYWORD_SET(probe) then probe = 'a'
    if not KEYWORD_SET(datatype) then datatype = 'TOFxEH'
    case datatype of
      'TOFxEH':       species = 'proton'
      'TOFxEnonH':    species = ['helium','oxygen']
      'TOFxPHHHELT':  species = ['proton','oxygen']
    endcase
    if not KEYWORD_SET(level) then level = 'l3'
    if (level ne 'l1') then units_label = '1/(cm!U2!N-sr-s-keV)' else units_label = 'counts/s'
    if not KEYWORD_SET(energy) then energy = [0,1000]
    if not KEYWORD_SET(bin_size) then bin_size = 15.
    if not KEYWORD_SET(scopes) then scopes = [0,1,2,3,4,5]
   
    prefix = 'rbsp'+probe+'_rbspice_'+level+'_'+datatype+'_'

    if energy[0] gt energy[1] then begin
        print, 'Low energy must be given first, then high energy in "energy" keyword'
        return
    endif

    ; set up the number of pa bins to create
    bin_size = float(bin_size)
    n_pabins = 180./bin_size
    pa_bins = 180.*indgen(n_pabins+1)/n_pabins
    pa_label = 180.*indgen(n_pabins)/n_pabins+bin_size/2.

    dprint, dlevel=0, 'Num PA bins: ', string(n_pabins)
    dprint, dlevel=0, 'PA bins: ', string(pa_bins)
 
    status = 1
 
    ; check to make sure the data exist
    get_data, prefix + 'Alpha', data=d, index = index
    if index eq 0 then begin
      print, 'No '+datatype+' data is currently loaded for probe rbsp-'+probe+' for the selected time period'
      status = 0
      return
    endif
    
    var_data = tnames(prefix+species)

    ; if data exists continue
    if status ne 0 then begin

      for ion_type_idx = 0, n_elements(species)-1 do begin
  
        ; get pitch angle data (all telescopes in single variable)
        get_data, prefix + 'Alpha', data = d_pa
        pa_file = fltarr(n_elements(d_pa.x),n_elements(scopes)) ; time steps, look direction
        for aa=0,n_elements(scopes)-1 do pa_file[*,scopes[aa]] = d_pa.y[*,scopes[aa]]
        
        pa_flux = fltarr(n_elements(d_pa.x),n_pabins,n_elements(scopes))
        pa_flux[where(pa_flux eq 0)] = !values.f_nan
        pa_num_in_bin = fltarr(n_elements(d_pa.x), n_pabins, n_elements(scopes))
        
        for qq=0,n_elements(species)-1 do begin
          
          ; get flux data (all telescopes in single variable)
          get_data, prefix + species[qq], data = d_flux
          dprint, dlevel=1, prefix + species[qq]
          flux_file = fltarr(n_elements(d_flux.x),n_elements(scopes)) ; time steps, look direction
          flux_file[where(flux_file eq 0)] = !values.f_nan
          new_pa_flux = fltarr(n_elements(d_flux.x),n_pabins,n_elements(scopes))          ; the average for each bin
          
          ; get energy range of interest
          e = d_flux.v
          indx = where((e lt energy[1]) and (e gt energy[0]), energy_count)
  
          if energy_count eq 0 then begin
            print, 'Energy range selected is not covered by the detector for ' + datatype + ' ' + species[ion_type_idx]
            continue
          endif
          
          for t=0,n_elements(scopes)-1 do begin
            
            ; Loop through each time step and get:
            ; 1.  the total flux for the energy range of interest for each detector
            ; 2.  flux in each pa bin
            for i=0, n_elements(d_flux.x)-1 do begin ; loop through time
              flux_file[i,t] = total(reform(d_flux.y[i,indx,scopes[t]]), /nan)  ; start with lowest energy
              for j=0, n_pabins-1 do begin ; loop through pa bins
                if (pa_file[i,t] gt pa_bins[j]) and (pa_file[i,t] lt pa_bins[j+1]) then begin
                  if ~finite(pa_flux[i,j,t]) then begin
                    pa_flux[i,j,t] = flux_file[i,t]
                  endif else begin
                    pa_flux[i,j,t] = pa_flux[i,j,t] + flux_file[i,t]
                  endelse
                  pa_num_in_bin[i,j,t] += 1.0
                endif
              endfor
            endfor
  ;        endfor
          
            ; loop over time
            for i=0, n_elements(pa_flux[*,0,0])-1 do begin
              ; loop over bins
              for bin_idx = 0, n_elements(pa_flux[i,*,0])-1 do begin
                if pa_num_in_bin[i,bin_idx,t] ne 0.0  then begin
                  new_pa_flux[i,bin_idx,t] = pa_flux[i,bin_idx,t]/pa_num_in_bin[i,bin_idx,t]
                endif else begin
                  new_pa_flux[i,bin_idx,t] = !values.f_nan
                endelse
              endfor
            endfor
          endfor
            
          en_range_string = strcompress(string(energy[0]), /rem) + '-' + strcompress(string(energy[1]), /remove_all) + 'keV'
          if (n_elements(scopes) eq 6) then begin
            new_name = prefix+species(qq)+'_omni_'+en_range_string+'_pad' 
            new_omni_pa_flux = reform(new_pa_flux[*,*,0])
            for ii=0,n_elements(new_pa_flux[*,0,0])-1 do for jj=0,n_elements(new_pa_flux[0,*,0])-1 do new_omni_pa_flux(ii,jj)= mean(new_pa_flux(ii,jj,*),/NAN)
            store_data, new_name, data={x:d_flux.x, y:new_omni_pa_flux, v:pa_label}
            options, new_name, yrange = [0,180], ystyle=1, spec = 1, no_interp=1 , $
              ytitle = 'rbsp-'+probe+'!Crbspice!C'+species[ion_type_idx]+'!Comni', ysubtitle=en_range_string+'!CPA [Deg]', ztitle=units_label, minzlog=.01
            zlim, new_name, 0, 0, 1
          endif else begin
            new_name = strarr(n_elements(scopes))
            for ii=0,n_elements(scopes)-1 do begin
              new_name = prefix+species(qq)+'_T'+strcompress(string(scopes[ii]),/remove_all)+'_'+en_range_string+'_pad'
              store_data, new_name, data={x:d_flux.x, y:reform(new_pa_flux[*,*,ii]), v:pa_label}
              options, new_name, yrange = [0,180], ystyle=1, spec = 1, no_interp=1 , $
                ytitle = 'rbsp-'+probe+'!Crbspice!C' +species[ion_type_idx]+'!CT'+strcompress(scopes[t],/remove_all), ysubtitle=en_range_string+'!CPA [Deg]', ztitle=units_label, minzlog=.01
              zlim, new_name, 0, 0, 1
            endfor   
          endelse
         
          ; now do the spin average
          rbsp_rbspice_pad_spinavg, probe=probe, datatype=datatype, species=species[ion_type_idx], energy=energy, bin_size=bin_size, scopes=scopes
        endfor
      endfor
    endif
end
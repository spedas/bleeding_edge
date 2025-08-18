;+
; PROCEDURE:
;         mms_eis_pad
;
; PURPOSE:
;         Calculate pitch angle distributions using data from the MMS Energetic Ion Spectrometer (EIS)
;           
;
; KEYWORDS:
;         trange:               time range of interest
;         probes:               value for MMS SC #
;         species:              proton (default), helium (formerly alpha), oxygen, electron
;         energy:               energy range to include in the calculation
;         size_pabin:           size of the pitch angle bins
;         data_units:           flux or cps
;         datatype:             extof, phxtof, electronenergy
;         level:                data level ['l1a','l1b','l2pre','l2' (default)]
;         scopes:               string array of telescopes to be included in PAD ('0'-'5')
;         suffix:               suffix used when loading the data
;         num_smooth:           should contain number of seconds to use when smoothing
;                                 only creates a smoothed product (_pad_smth) if this keyword is specified
;         combine_proton_data:  set equal to 1 to combine extof and phxtof data
;         mmsx_vars:            set equal to 1 to combine SC into mms-x variables if more than 1 SC is present
;                                 (default = 0)
;         range_pad_only:       set equal to 1 to create only an integral PAD over the user-defined energy range,
;                                 no PADs for individual energy channels (default = 0)
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
;$LastChangedBy: egrimes $
;$LastChangedDate: 2021-08-03 09:08:16 -0700 (Tue, 03 Aug 2021) $
;$LastChangedRevision: 30167 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/eis/mms_eis_pad.pro $
;-
; REVISION HISTORY:
;       + 2015-10-26, I. Cohen      : added "scopes" keyword to mms_eis_pad call-line to allow omittance of t3 (ions) & t2 (electrons)
;       + 2015-11-12, I. Cohen      : changed sizing of second dimension of flux_file and pa_file to reflect number of elements in "scopes"
;       + 2015-12-14, I. Cohen      : introduced data_rate keyword and conditional definition of prefix to handle burst data
;       + 2016-1-8, egrimes         : moved eis_pabin_info, mms_eis_pad_spinavg into separate routines; changed stops to returns
;       + 2016-01-26, I. Cohen      : added scope_suffix definition to allow for distinction between single telescope PADs
;                                   : added to call to mms_eis_pad_spinavg.pro
;       + 2016-02-26, I. Cohen      : changed 'cps' units_label from 'Counts/s' to '1/s' for compliance with mission standards
;       + 2016-04-29, egrimes       : implemented suffix keyword, now allowing probes to be passed as an integer
;       + 2016-09-19, E. Grimes     : updated to support v3 L1b files
;       + 2017-06-06, I. Cohen      : added num_smooth keyword 
;       + 2017-10-18, I. Cohen      : updated to incorporate finite angular width of telescopes (after mms_feeps_pad.pro); changed "size_pabin"
;                                     keyword to "size_pabin"
;       + 2017-11-17, I. Cohen      : altered program to calculate PAD for each individual EIS channel within defined energy range, as well as
;                                     integral over all defined energies; changed default energy range; added capability to combine PHxTOF and
;                                     ExTOF proton data if user-defined energy range calls for it; changed PAD tplot variable names to use integers
;                                     instead of double-precision numbers; added ability to handle multiple s/c at once and introduced call to 
;                                     mms_eis_pad_combine_sc.pro when doing so; replaced species keyword definition with species and removed species
;       + 2017-11-20, I. Cohen      : changed names of IDL variables resulting from get_data from all using 'd' to help with troubleshooting; added
;                                     degapping
;       + 2017-12-04, I. Cohen      : changed bin_size keyword to size_pabin in calls to mms_eis_pad_spinavg.pro
;       + 2018-02-19, I. Cohen      : added combine_proton_data keyword to enable override of automatic combination of PHxTOF and ExTOF data
;       + 2018-06-14, I. Cohen      : fixed zlim range for PAD variables with zero counts to differentiate from non-accessed pitch angles
;       + 2018-08-09, I. Cohen      : fixed energy range for integrated PAD variable to match actual range, not user-defined range
;       + 2020-03-23, I. Cohen      : create integral PAD tplot variable only if user-defined energy range covers more than 1 EIS energy channel
;       + 2020-03-30, I. Cohen      : added/mirrored datatype to call of mms_eis_pad_combine_sc.pro
;       + 2020-04-24, I. Cohen      : added mmsx_vars and range_pad_only keywords; changed so that MMS-X vars are only generated if requested by user
;       + 2020-04-27, I. Cohen      : updated to correctly calculate and name PAD variables based on actual energy range of each channel
;       + 2020-06-23, E. Grimes     : fixed minor issues with the suffix keyword, and removed probe keyword in call to mms_eis_pad_combine_sc
;       + 2020-10-26, I. Cohen      : added ability to create energy range from energy limit variables without having to load support data; 
;                                     changed "undefined" to "KEYWORD_SET" in initialization of some keywords
;       + 2020-12-10, I. Cohen      : undid change of "undefined" to "KEYWORD_SET" in initialization of some keywords from 2020-10-26, set all back to "undefined"
;       + 2021-02-09, I. Cohen      : added helium to species in header under KEYWORD section
;       + 2021-04-08, I. Cohen      : updated prefix definition to handle new L2 variable names; added level to mms_eis_pad_spinavg, mms_eis_combine_proton_pad, & mms_eis_pad_combine_sc calls
;       + 2021-06-16, I. Cohen      : fixed definition of pvalue
;                             
;-

pro mms_eis_pad, probes = probes, trange = trange, species = species, data_rate = data_rate, energy = energy, $
                size_pabin = size_pabin, data_units = data_units, datatype = datatype, scopes = scopes, level = level, $
                suffix = suffix, num_smooth = num_smooth, combine_proton_data=combine_proton_data, mmsx_vars = mmsx_vars, $
                range_pad_only = range_pad_only
  ;
  compile_opt idl2
  if undefined(probes) then probes = '1' else probes = strcompress(string(probes), /rem)
  if undefined(datatype) then datatype = 'extof'
  if undefined(species) then species = 'proton'
  if n_elements(datatype) eq 1 && (datatype eq 'electronenergy') then species = 'electron'
  if undefined(energy) then energy = [55,800]
  if undefined(size_pabin) then size_pabin = 15
  if undefined(data_units) then data_units = 'flux'
  if undefined(data_rate) then data_rate = 'srvy' else data_rate = strlowcase(data_rate)
  if undefined(scopes) then scopes = ['0','1','2','3','4','5']
  if undefined(level) then level = 'l2'
  if undefined(suffix) then suffix = ''
  if undefined(mmsx_vars) then mmsx_vars = 0
  if undefined(range_pad_only) then range_pad_only = 0
  if undefined(combine_proton_data) then begin
    if (species eq 'proton') then begin
      energy_test1 = where(energy gt 50)
      energy_test2 = where(energy lt 50)
      if (energy_test1[0] eq -1) or (energy_test2[0] eq -1) then begin
        combine_proton_data = 0
      endif else begin
        combine_proton_data = 1
        datatype = ['phxtof','extof']
      endelse
    endif else combine_proton_data = 0
  endif
  ;
  ; would be good to get this from the metadata eventually
  units_label = data_units eq 'cps' ? '1/s': '1/(cm!U2!N-sr-s-keV)'
  ;
  if (n_elements(scopes) eq 1) then scope_suffix = '_t'+scopes+suffix else if (n_elements(scopes) eq 6) then scope_suffix = '_omni'+suffix
  ;
  if energy[0] gt energy[1] then begin
    print, 'Low energy must be given first, then high energy in "energy" keyword'
    return
  endif
  ;
  ; set up the number of pa bins to create
  size_pabin = double(size_pabin)
  n_pabins = 180./size_pabin
  pa_bins = 180.*indgen(n_pabins+1)/n_pabins
  pa_label = 180.*indgen(n_pabins)/n_pabins+size_pabin/2.
  ;
  ; Account for angular response (finite field of view) of instruments
  pa_halfang_width = 10.0         ; [deg]
  delta_pa = size_pabin/2d
  ;
  dprint, dlevel=0, 'Num PA bins: ', string(n_pabins)
  dprint, dlevel=0, 'PA bins: ', string(pa_bins)
  ;
  status = 1
  ;
  for pp=0,n_elements(probes)-1 do begin
    prefix = 'mms'+probes[pp]+'_epd_eis_'+data_rate+'_'+level+'_'
    ;
    for dd=0,n_elements(datatype)-1 do begin
      ;
      ; check to make sure the data exist
      get_data, prefix + datatype[dd] + '_pitch_angle_t0'+suffix, data=d, index = index
      if (index eq 0) then begin
        print, 'No '+data_rate+' '+datatype[dd]+' data is currently loaded for MMS'+probes[pp]+' for the selected time period'
        status = 0
        return
      endif
      ;
      ; if data exists continue  
      if (status ne 0) then begin
        for species_idx = 0, n_elements(species)-1 do begin
          ;
          ; get pa from each detector
          get_data, prefix + datatype[dd] + '_pitch_angle_t0'+suffix, data = temp_pad
          pa_file = dblarr(n_elements(temp_pad.x),n_elements(scopes))                                                ; time x telescopes (look directions)
          pa_file[*,0] = temp_pad.y
          ;
          ;
          get_data,prefix+datatype[dd]+'_'+species+'_'+data_units+'_omni'+suffix,data=omni_data
          get_data,prefix+datatype[dd]+'_'+species+'_energy_range'+suffix,data=erange
          if (is_struct(erange) eq 0) then begin
            get_data,prefix+datatype[dd]+'_'+species+'_t0_energy'+suffix, data=ecenter
            IF (is_struct(ecenter) eq 1) THEN BEGIN
              get_data,prefix+datatype[dd]+'_'+species+'_t0_energy_dminus'+suffix, data=eupper
              get_data,prefix+datatype[dd]+'_'+species+'_t0_energy_dplus'+suffix, data=elower
              erange = DBLARR(N_ELEMENTS(ecenter.y), 2)
              FOR ee = 0,N_ELEMENTS(ecenter.y)-1 DO erange[ee, *] = [ecenter.y[ee]-elower.y[ee], ecenter.y[ee]+eupper.y[ee]]
            ENDIF ELSE BEGIN
              print, 'Energy range variable is missing from loaded EIS data'
              return
            ENDELSE
          endif
          inchan_check_low = dblarr(n_elements(omni_data.v))
          inchan_check_hi = dblarr(n_elements(omni_data.v))
          inchan_check_low[where((erange.y[*, 0] ge energy[0]) and (erange.y[*, 0] le energy[1]), energies_count_low)] = 1d
          inchan_check_hi[where((erange.y[*, 1] ge energy[0]) and (erange.y[*, 1] le energy[1]), energies_count_hi)] = 1d
          these_energies = where((inchan_check_low gt 0) or (inchan_check_hi gt 0))
          if (energies_count_low eq 0) or (energies_count_hi eq 0) then begin
            print, 'Energy range selected is not covered by the detector for ' + datatype[dd] + ' ' + species[species_idx] + ' ' + data_units
            return
          endif
          flux_file = dblarr(n_elements(temp_pad.x),n_elements(scopes),n_elements(these_energies)) + !Values.d_NAN    ; time x telescopes (look directions) x energy
          pa_flux = dblarr(n_elements(temp_pad.x),n_pabins,n_elements(these_energies)) + !Values.d_NAN                ; time x bins x energy
          pa_num_in_bin = dblarr(n_elements(temp_pad.x),n_pabins,n_elements(these_energies))                          ; time x bins x energy
          ;
          for t=0, n_elements(scopes)-1 do begin
            get_data, prefix + datatype[dd] + '_pitch_angle_t'+scopes[t]+suffix, data = data_pa
            pa_file[*,t] = reform(data_pa.y)
            ;
            ; use wild cards to figure out what this variable name should be for telescope 0
            this_variable = tnames(prefix + datatype[dd] + '_' + species[species_idx] + '*_' + data_units + '_t0'+suffix)
            ;
            if level eq 'l2' || level eq 'l1b' then begin
              ; get the P# value from the name of telescope 0:
              pvalue = (strsplit(this_variable, '_', /extract))[7]
              if (pvalue ne data_units) then pvalue = pvalue + '_' else pvalue = ''
            endif else begin
              pvalue = ''
            endelse
            ;
            ; get flux from each detector
            get_data, prefix + datatype[dd] + '_' + species[species_idx] + '_' + pvalue + data_units + '_t'+scopes[t]+suffix, data = data_flux
            dprint, dlevel=1, prefix + datatype[dd] + '_' + species[species_idx] + '_' + pvalue + data_units + '_t'+scopes[t]+suffix
;            data_flux.y[where(data_flux.y eq 0.0)] = !Values.d_NAN
            ;
            ; get energy range of interest
            e = data_flux.v[these_energies]
            ;
            flux_file[*,t,*] = data_flux.y[*,these_energies]
          endfor
          ;
          ; CREATE PAD VARIABLES FOR EACH ENERGY CHANNEL IN USER-DEFINED ENERGY RANGE
          ;
          if (range_pad_only ne 1) then begin
            for i=0, n_elements(data_flux.x)-1 do for j=0, n_pabins-1 do for ee=0,n_elements(these_energies)-1 do begin
              ind = where((pa_file[i,*] + pa_halfang_width ge pa_label[j]-delta_pa) and (pa_file[i,*] - pa_halfang_width lt pa_label[j]+delta_pa))
              if (ind[0] ne -1) then pa_flux[i,j,ee] = average(flux_file[i,ind,ee], 2, /NAN)
            endfor
  ;          pa_flux[where(pa_flux eq 0.0)] = !Values.d_NAN                                                      ; fill any missed bins with NAN
            ;
            for ee=0,n_elements(these_energies)-1 do begin
              energy_string = strcompress(string(fix(erange.y[these_energies[ee], 0])), /rem)+'-'+strcompress(string(fix(erange.y[these_energies[ee], 1])), /rem) + 'keV'
              new_name = prefix + datatype[dd] + '_' + energy_string + '_' + species[species_idx] + '_' + data_units + scope_suffix + '_pad'
              ;
              ; the following is because prefix becomes a single-element array in some cases
              if is_array(new_name) then new_name = new_name[0]
              ;
              store_data, new_name, data={x:data_flux.x, y:reform(pa_flux[*,*,ee]), v:pa_label}
              options, new_name, yrange = [0,180], ystyle=1, spec = 1, no_interp=1, ytitle = 'MMS'+probes[pp]+' EIS ' + species[species_idx], ysubtitle=energy_string+'!CPA [Deg]', ztitle=units_label, minzlog=.01, /extend_y_edges
              if (max(pa_flux[*,*,ee],/NAN) eq 0) then zlim, new_name, 0, 10, 0 else zlim, new_name, 0, 0, 1
              tdegap, new_name, /overwrite
              ;
            endfor
            ;
            store_data, prefix + datatype[dd] + '_' + species[species_idx] + '_' + data_units + scope_suffix + '_pads', data={x:data_flux.x, y:pa_flux, v1:pa_label, v2:omni_data.v[these_energies]}
            tdegap, prefix + datatype[dd] + '_' + species[species_idx] + '_' + data_units + scope_suffix + '_pads', /overwrite
          endif
          ;
          ; CREATE PAD VARIABLE INTEGRATED OVER USER-DEFINED ENERGY RANGE
          ;
          if (n_elements(these_energies) gt 1) then begin
            energy_range_string = strcompress(string(fix(erange.y[these_energies[0], 0])), /rem)+'-'+strcompress(string(fix(erange.y[these_energies[-1], 1])), /rem) + 'keV'
            new_name = prefix + datatype[dd] + '_' + energy_range_string + '_' + species[species_idx] + '_' + data_units + scope_suffix + '_pad'
            ;
            ; the following is because of prefix becoming a single element array in some cases
            if is_array(new_name) then new_name = new_name[0]
            avg_pa_flux = dblarr(n_elements(data_flux.x),n_pabins) + !Values.d_NAN                                    ; time x bins
            for tt=0,n_elements(data_flux.x)-1 do for bb=0,n_pabins-1 do avg_pa_flux[tt,bb] = average(pa_flux[tt,bb,*],/NAN)
            ;
;            avg_pa_flux[where(avg_pa_flux eq 0.0)] = !Values.d_NAN
            store_data, new_name, data={x:data_flux.x, y:avg_pa_flux, v:pa_label}
            options, new_name, yrange = [0,180], ystyle=1, spec = 1, no_interp=1, ytitle = 'MMS'+probes[pp]+' EIS ' + species[species_idx], ysubtitle=energy_range_string+'!CPA [Deg]', ztitle=units_label, minzlog=.01, /extend_y_edges
            zlim, new_name, 5e2, 1e4, 1
            tdegap, new_name, /overwrite
            ;
            ; now do the spin average
            mms_eis_pad_spinavg, probes=probes[pp], species=species[species_idx], datatype=datatype[dd], energy=energy, data_units=data_units, size_pabin=size_pabin, $
              data_rate = data_rate, level = level, scopes=scopes, suffix = suffix
            ;
            if ~undefined(num_smooth) then spd_smooth_time, new_name, newname=new_name+'_smth', num_smooth, /nan
          endif
        endfor
      endif
    endfor
    ;
    if (combine_proton_data eq 1) then begin
      mms_eis_combine_proton_pad, probes=probes[pp], data_rate = data_rate, data_units = data_units, size_pabin = size_pabin, energy = energy, level = level, suffix = suffix
      ;
      combined_var_name = tnames(prefix+'combined*proton*pad')
      ;
      ; now do the spin average
      mms_eis_pad_spinavg, probes=probes[pp], species='proton', datatype='combined', energy=energy, data_units=data_units, size_pabin=size_pabin, data_rate = data_rate, level = level, scopes=scopes, suffix = suffix
      ;
      if KEYWORD_SET(num_smooth) then spd_smooth_time, combined_var_name[0], newname=combined_var_name[0]+'_smth', num_smooth, /nan
    endif
    ;
  endfor
  ;
  ; NOTE: PLEASE SPECIFY IN ANY PRESENTATIONS OR PUBLICATIONS WHICH SPACECRAFT ARE INCLUDED IF YOU GENERATE AND USE MMS-X VARIABLES
  if (n_elements(probes) gt 1) and (mmsx_vars eq 1) then $
    mms_eis_pad_combine_sc, trange = trange, species = species, data_rate = data_rate, energy = energy, data_units = data_units, level = level, suffix = suffix, datatype = datatype
  ;
end
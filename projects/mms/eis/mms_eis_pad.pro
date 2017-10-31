;+
; PROCEDURE:
;         mms_eis_pad
;
; PURPOSE:
;         Calculate pitch angle distributions using data from the
;           MMS Energetic Ion Spectrometer (EIS)
;
; KEYWORDS:
;         trange: time range of interest
;         probe: value for MMS SC #
;         species: 'ion', 'electron', or 'all'
;         energy: energy range to include in the calculation
;         size_pabin: size of the pitch angle bins
;         data_units: flux or cps
;         data_name: extof, phxtof
;         ion_type: array containing types of particles to include.
;               for PHxTOF data, valid options are 'proton', 'oxygen'
;               for ExTOF data, valid options are 'proton', 'oxygen', and/or 'alpha'
;         scopes: string array of telescopes to be included in PAD ('0'-'5')
;         suffix: suffix used when loading the data
;         num_smooth: should contain number of seconds to use when smoothing
;             only creates a smoothed product (_pad_smth) if this keyword is specified
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
;$LastChangedDate: 2017-10-30 07:49:05 -0700 (Mon, 30 Oct 2017) $
;$LastChangedRevision: 24232 $
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
;       + 2016-04-29, egrimes       : implemented suffix keyword, now allowing probe to be passed as an integer
;       + 2016-09-19, E. Grimes     : updated to support v3 L1b files
;       + 2017-06-06, I. Cohen      : added num_smooth keyword 
;       + 2017-10-18, I. Cohen      : updated to incorporate finite angular width of telescopes (after mms_feeps_pad.pro); changed "size_pabin"
;                                     keyword to "size_pabin"
;-

pro mms_eis_pad,probe = probe, trange = trange, species = species, data_rate = data_rate, $
                energy = energy, size_pabin = size_pabin, data_units = data_units, $
                datatype = datatype, ion_type = ion_type, scopes = scopes, level = level, $
                suffix = suffix, num_smooth = num_smooth
                
    compile_opt idl2
    ;if not KEYWORD_SET(trange) then trange = ['2015-06-28', '2015-06-29']
    if not KEYWORD_SET(probe) then probe = '1' else probe = strcompress(string(probe), /rem)
    if not KEYWORD_SET(species) then species = 'all'
    if not KEYWORD_SET(ion_type) then ion_type = ['oxygen', 'proton']
    ;if not KEYWORD_SET(energy) then energy = [35,45] ; set default energy as lowest energy channel in keV
    if not KEYWORD_SET(energy) then energy = [0,1000] ; set default energy as lowest energy channel in keV
    if not KEYWORD_SET(size_pabin) then size_pabin = 15 ; set default energy as lowest energy channel in keV
    if not KEYWORD_SET(data_units) then data_units = 'flux'
    if undefined(data_rate) then data_rate = 'srvy' else data_rate = strlowcase(data_rate)
    if not KEYWORD_SET(scopes) then scopes = ['0','1','2','3','4','5']
    if not KEYWORD_SET(datatype) then datatype = 'extof'
    if undefined(level) then level = 'l2'
    if datatype eq 'electronenergy' then ion_type = 'electron'
    if undefined(suffix) then suffix = ''
   
    ; would be good to get this from the metadata eventually
    units_label = data_units eq 'cps' ? '1/s': '1/(cm!U2!N-sr-s-keV)'
    if (data_rate eq 'brst') then prefix = 'mms'+probe+'_epd_eis_brst_' else prefix = 'mms'+probe+'_epd_eis_'

    if (n_elements(scopes) eq 1) then scope_suffix = '_t'+scopes+suffix else if (n_elements(scopes) eq 6) then scope_suffix = '_omni'+suffix

    if energy[0] gt energy[1] then begin
        print, 'Low energy must be given first, then high energy in "energy" keyword'
        return
    endif

    ; set up the number of pa bins to create
    size_pabin = float(size_pabin)
    n_pabins = 180./size_pabin
    pa_bins = 180.*indgen(n_pabins+1)/n_pabins
    pa_label = 180.*indgen(n_pabins)/n_pabins+size_pabin/2.
    
    ; Account for angular response (finite field of view) of instruments
    pa_halfang_width = 10.0         ; [deg]
    delta_pa = size_pabin/2d
    
    dprint, dlevel=0, 'Num PA bins: ', string(n_pabins)
    dprint, dlevel=0, 'PA bins: ', string(pa_bins)
 
    status = 1
 
    ; check to make sure the data exist
    get_data, prefix + datatype + '_pitch_angle_t0'+suffix, data=d, index = index
    if index eq 0 then begin
      print, 'No data is currently loaded for probe '+probe+' for the selected time period'
      status = 0
      return
    endif

    ; if data exists continue
    if status ne 0 then begin
      for ion_type_idx = 0, n_elements(ion_type)-1 do begin
        ; get pa from each detector
        get_data, prefix + datatype + '_pitch_angle_t0'+suffix, data = d
   
        flux_file = fltarr(n_elements(d.x),n_elements(scopes)) ; time steps, look direction
        pa_file = fltarr(n_elements(d.x),n_elements(scopes)) ; time steps, look direction
        pa_file[*,0] = d.y
        pa_flux = fltarr(n_elements(d.x),n_pabins)
        pa_flux[where(pa_flux eq 0)] = !values.f_nan
         
        pa_num_in_bin = fltarr(n_elements(d.X), n_pabins)
        
        for t=0, n_elements(scopes)-1 do begin
          get_data, prefix + datatype + '_pitch_angle_t'+scopes[t]+suffix, data = d
          pa_file[*,t] = reform(d.y)

          ; use wild cards to figure out what this variable name should be for telescope 0
          this_variable = tnames(prefix + datatype + '_' + ion_type[ion_type_idx] + '*_' + data_units + '_t0'+suffix)
           
          if level eq 'l2' || level eq 'l1b' then begin
            ; get the P# value from the name of telescope 0:
            pval_num_in_name = data_rate eq 'brst' ? 6 : 5
            pvalue = (strsplit(this_variable, '_', /extract))[pval_num_in_name]
            if pvalue ne data_units then pvalue = pvalue + '_' else pvalue = ''
          endif else begin
            pvalue = ''
          endelse

          ; get flux from each detector
          get_data, prefix + datatype + '_' + ion_type[ion_type_idx] + '_' + pvalue + data_units + '_t'+scopes[t]+suffix, data = d
          dprint, dlevel=1, prefix + datatype + '_' + ion_type[ion_type_idx] + '_' + pvalue + data_units + '_t'+scopes[t]+suffix
          d.y[where(d.y eq 0.0)] = !values.d_nan
            
          ; get energy range of interest
          e = d.v
          indx = where((e lt energy[1]) and (e gt energy[0]), energy_count)
                   
          if energy_count eq 0 then begin
            print, 'Energy range selected is not covered by the detector for ' + datatype + ' ' + ion_type[ion_type_idx] + ' ' + data_units
            continue
          endif

          flux_file[*,t] = reform(average(d.y[*,indx],2,/NAN))
        endfor   
          
        for i=0, n_elements(d.x)-1 do for j=0, n_pabins-1 do begin
          ind = where((pa_file[i,*] + pa_halfang_width ge pa_label[j]-delta_pa) and (pa_file[i,*] - pa_halfang_width lt pa_label[j]+delta_pa))
          if (ind[0] ne -1) then pa_flux[i,j] = reform(average(flux_file[i,ind], 2, /NAN))
        endfor
        pa_flux[where(pa_flux eq 0.0)] = !values.d_nan ; fill any missed bins with NAN
        
        en_range_string = strcompress(string(energy[0]), /rem) + '-' + strcompress(string(energy[1]), /rem) + 'keV
        new_name = prefix + datatype + '_' + en_range_string + '_' + ion_type[ion_type_idx] + '_' + data_units + scope_suffix + '_pad'
          
        ; the following is because of prefix becoming a single element array in some cases
        if is_array(new_name) then new_name = new_name[0] 

        store_data, new_name, data={x:d.x, y:pa_flux, v:pa_label}
        ;store_data, new_name, data={x:d.x, y:new_pa_flux, v:pa_label}
        options, new_name, yrange = [0,180], ystyle=1, spec = 1, no_interp=1 , $
          ytitle = 'MMS'+probe+' EIS ' + ion_type[ion_type_idx], ysubtitle=en_range_string+'!CPA [Deg]', ztitle=units_label, minzlog=.01
        zlim, new_name, 0, 0, 1
               
        options, new_name, 'extend_y_edges', 1
        ; now do the spin average
        mms_eis_pad_spinavg, probe=probe, species=ion_type[ion_type_idx], datatype=datatype, energy=energy, data_units=data_units, $
          size_pabin=size_pabin, data_rate = data_rate, scopes=scopes, suffix = suffix
      
        if ~undefined(num_smooth) then spd_smooth_time, new_name, newname=new_name+'_smth', num_smooth, /nan
      endfor
    endif
end
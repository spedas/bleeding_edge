;+
;
; PROCEDURE:
;         rbsp_rbspice_spin_avg
;
; PURPOSE:
;         Calculates spin-averaged fluxes for the RBSPICE instrument
;
; KEYWORDS:
;         probe:        RBSP spacecraft indicator [Options: 'a' (default), 'b']
;         datatype:     RBSPICE data type ['TOFxEH' (default),'TOFxEnonH'],
;         tplotnames:   This does not need to be defined, will load all previously loaded tplot variables
;         level:        data level ['l1','l2','l3' (default),'l3pap']
;                     
;
; REVISION HISTORY:
;       + 2016-12-09, I. Cohen      : created based on mms_eis_spin_avg.pro
;       + 2017-02-21, I. Cohen      : removed species keyword; defined species variable for y-axis labeling
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2017-03-03 08:08:58 -0800 (Fri, 03 Mar 2017) $
;$LastChangedRevision: 22902 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/rbsp/rbspice/rbsp_rbspice_spin_avg.pro $
;-

pro rbsp_rbspice_spin_avg, probe=probe, datatype = datatype, tplotnames = tplotnames, level=level
  if undefined(probe) then probe = 'a'
  if undefined(datatype) then datatype = 'TOFxEH'
  if undefined(level) then level = 'l3'
  if (level ne 'l1') then units_label = '1/(cm!U2!N-sr-s-keV)' else units_label = 'counts/s'
  
  probe = strcompress(string(probe), /rem)
  prefix = 'rbsp'+probe+'_rbspice_'+level+'_'+datatype+'_'
  
  get_data, prefix + 'Spin', data=spin_nums
  
  if ~is_struct(spin_nums) then return ; gracefully handle the case of no spin # variable found

  ; find where the spins start
  spin_starts = uniq(spin_nums.Y)
  
  if (datatype eq 'TOFxEH') then species = 'proton' $
    else if (datatype eq 'TOFxEnonH') then species = ['helium','oxygen'] $
    else if (datatype eq 'TOFxPHHHELT') then species = ['proton','oxygen']

  ; find the flux/cps data name(s)
  var_data = tnames(prefix + species + '_T?')
  var_omni =  tnames(prefix + species + '_omni')
  append_array,var_data,var_omni

  for n=0,n_elements(var_data)-1 do begin
    if var_data[n] eq '' then begin
      dprint, dlevel = 0, 'Error, problem finding the tplot variables to calculate the spin averages'
      return
    endif else begin
      get_data, var_data[n], data=flux_data, dlimits=flux_dl

      str_element, flux_data, 'v', success=s
      if s ne 1 then begin
        dprint, dlevel = 0, 'Error, couldn''t find energy table for the flux/cps data variable'
        continue
      endif
      
      if (strmid(var_data[n],1,1,/reverse) eq 'T') then species = strmid(var_data[n],8,6,/reverse) $
        else if (strmid(var_data[n],3,4,/reverse) eq 'omni') then species = strmid(var_data[n],10,6,/reverse)
      case species of
        'proton': if (datatype ne 'TOFxPHHHELT') then zrange = [5.,1.e5] else zrange = [2.e2,1.e6]
        'helium': zrange = [1.,5.e2]
        'oxygen': if (datatype ne 'TOFxPHHHELT') then zrange = [1.,1.e2] else zrange = [1e1,1.e4]
      endcase

      spin_sum_flux = dblarr(n_elements(spin_starts), n_elements(flux_data.v))

      current_start = 0
      ; loop through the spins for this telescope
      for spin_idx = 0, n_elements(spin_starts)-1 do begin
        ; loop over energies
        spin_sum_flux[spin_idx, *] = average(flux_data.Y[current_start:spin_starts[spin_idx], *], 1, /NAN)
        current_start = spin_starts[spin_idx]+1
      endfor
      sp = '_spin'
      store_data, var_data[n]+sp, data={x:spin_nums.X[spin_starts], y:spin_sum_flux, v:flux_data.V}, dlimits=flux_dl

      if (strmid(var_data[n],3,4,/reverse_offset) eq 'omni') then suffix = '!Comni' $
        else if (strmid(var_data[n],1,2,/reverse_offset) eq 'T'+strtrim(string(n),2)) then suffix= '!CT'+strtrim(string(n),2) $
        else suffix=''
      options, var_data[n]+sp, ylog = 1, zlog=1, spec = 1, yrange = minmax(flux_data.v), ystyle=1,  /default, zrange=zrange, zstyle=1, minzlog = .01, $
        ytitle = 'rbsp'+probe+'!Crbspice!C'+species+'!C'+suffix, ysubtitle='[keV]', ztitle=units_label
    endelse
  endfor
end

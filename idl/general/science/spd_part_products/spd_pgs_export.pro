;+
;
; PROCEDURE:
;   spd_pgs_export
;   
; PURPOSE:
;   Exports SPEDAS particle data to ASCII files
;
; INPUT:
;   data_in: standard SPEDAS particle data structure
; 
; KEYWORDS:
;  filename: output filename
;  precise: increases precision to the maximum (microseconds)
;
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2019-04-10 07:20:38 -0700 (Wed, 10 Apr 2019) $
;$LastChangedRevision: 26982 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/science/spd_part_products/spd_pgs_export.pro $
;-


pro spd_pgs_export, data_in, filename=filename, output_dir=output_dir, precise=precise

  if ~ptr_valid(data_in[0]) and ~is_struct(data_in[0]) then begin
    fail = 'Invalid data.  Input must be pointer or structure array.'
    dprint, dlevel=1, fail
    return
  endif
  
  if ptr_valid(data_in[0]) then data = *data_in[0] else data = data_in
  
  if undefined(precise) then precise=3 else precise=6
  if undefined(output_dir) then output_dir = '' else output_dir = spd_addslash(output_dir)
  if undefined(filename) then filename = output_dir + strlowcase(data[0].project_name)+strlowcase(data[0].spacecraft)+'_'+strlowcase(strjoin(strsplit(data[0].data_name, ' ', /extract), '_'))
  
  ; the following assumes the number of angular and energy bins do not change over time
  dims = size(data[0].data, /dimensions)

  if n_elements(dims) eq 3 then begin
    ncol = dims[0]*dims[1]*dims[2]
  endif else if n_elements(dims) eq 2 then begin
    ncol = dims[0]*dims[1]
  endif

  data_out = dblarr(n_elements(data), ncol)
  energy_out = dblarr(n_elements(data), ncol)
  theta_out = dblarr(n_elements(data), ncol)
  phi_out = dblarr(n_elements(data), ncol)
  bins_out = dblarr(n_elements(data), ncol)

  for time_idx=0l, n_elements(data)-1 do begin
    data_out[time_idx, *] = reform(data[time_idx].data, ncol)
    energy_out[time_idx, *] = reform(data[time_idx].energy, ncol)
    theta_out[time_idx, *] = reform(data[time_idx].theta, ncol)
    phi_out[time_idx, *] = reform(data[time_idx].phi, ncol)
    bins_out[time_idx, *] = reform(data[time_idx].bins, ncol)
  endfor

  time_precision_str = 'A' + strtrim(21 + precise,2)
  data_format_string = '(' + time_precision_str + ', ' + strtrim(ncol, 2) + '(2X,e30.17))'
  misc_format_string = '(' + time_precision_str + ', ' + strtrim(ncol, 2) + '(2X,e20.7))'
  bins_format_string = '(' + time_precision_str + ', ' + strtrim(ncol, 2) + '(2X,I12))'

  openw, /get_lun, data_lun, filename+'_data.txt', width=2500
  openw, /get_lun, energy_lun, filename+'_energy.txt', width=2500
  openw, /get_lun, theta_lun, filename+'_theta.txt', width=2500
  openw, /get_lun, phi_lun, filename+'_phi.txt', width=2500
  openw, /get_lun, bins_lun, filename+'_bins.txt', width=2500

  ; save the data
  for i=0l, n_elements(data)-1 do begin
    printf, data_lun, time_string(data[i].time, precision=precise), reform(data_out[i,*]), format=data_format_string
    printf, energy_lun, time_string(data[i].time, precision=precise), reform(energy_out[i,*]), format=misc_format_string
    printf, theta_lun, time_string(data[i].time, precision=precise), reform(theta_out[i,*]), format=misc_format_string
    printf, phi_lun, time_string(data[i].time, precision=precise), reform(phi_out[i,*]), format=misc_format_string
    printf, bins_lun, time_string(data[i].time, precision=precise), reform(bins_out[i,*]), format=bins_format_string
  endfor

  close, data_lun
  free_lun, data_lun
  close, energy_lun
  free_lun, energy_lun
  close, theta_lun
  free_lun, theta_lun
  close, phi_lun
  free_lun, phi_lun
  close, bins_lun
  free_lun, bins_lun
end
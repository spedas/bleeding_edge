;+
; PROCEDURE:
;         eis_pabin_info
;
; PURPOSE:
;         Prints EIS PA bin information - for debugging
;
; KEYWORDS:
;
; OUTPUT:
;
;
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2016-01-08 08:53:21 -0800 (Fri, 08 Jan 2016) $
;$LastChangedRevision: 19695 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/eis/eis_pabin_info.pro $
;-

pro eis_pabin_info, pa_bins, pa_flux, pa_num_in_bin, pa_file, flux_file, start
  print, '---------------------------------'
  for i=0, n_elements(pa_file[start, *])-1 do print, strcompress(string(pa_file[start, i]), /rem)+': '+string(flux_file[start,i])
  print, '---------------------------------'
  for num=0, n_elements(pa_bins)-2 do print, strcompress('['+string(pa_bins[num])+'-'+string(pa_bins[num+1]), /rem)+']:'+string(pa_num_in_bin[start, num])+', ' +string(pa_flux[start,num])
end
;
;  $LastChangedBy: pulupalap $
;  $LastChangedDate: 2019-01-30 21:11:34 -0800 (Wed, 30 Jan 2019) $
;  $LastChangedRevision: 26522 $
;  $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/fields/l1/l1_aeb1_hk/spp_fld_aeb1_hk_load_l1.pro $
;

pro spp_fld_aeb1_hk_load_l1, file, prefix = prefix

  if not keyword_set(prefix) then prefix = 'spp_fld_aeb1_hk_'

  cdf2tplot, /get_support_data, file, prefix = prefix

  aeb_hk_names = tnames(prefix + '*')

  if aeb_hk_names[0] NE '' then begin

    foreach name, aeb_hk_names do begin

      name_no_prefix = name.Remove(0, prefix.Strlen()-1)

      options, name, 'ynozero', 1
      options, name, 'horizontal_ytitle', 1
      
      if strpos(name_no_prefix, 'AEB') NE -1 then begin
        colors = [0]
        labels = ''   
      endif else if strpos(name_no_prefix, '1') NE -1 then begin
        colors = [6]
        labels = '1'
      endif else if strpos(name_no_prefix, '2') NE -1 then begin
        colors = [4]
        labels = '  2'
      endif else if strpos(name_no_prefix, '5') NE -1 then begin
        colors = [3]
        labels = '        5'
      endif else begin
        colors = [0]
        labels = ''
      endelse
      
      options, name, 'colors', colors
      options, name, 'labels', labels
      options, name, 'ytitle', name_no_prefix

      options, name, 'psym_lim', 100
      options, name, 'datagap', 3600d
      options, name, 'symsize', 0.75

    endforeach

  endif

end
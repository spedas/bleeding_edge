;+
; PROCEDURE:
;         mms_load_hpca_fix_dist
;
; PURPOSE:
;         Replace supplementary fields in 3D distribution variables with actual
;         values from supplementary tplot variables (theta).
;
; NOTE:
;         Expect this routine to be made obsolete after the CDFs are updated
;
;
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2016-04-01 18:22:39 -0700 (Fri, 01 Apr 2016) $
;$LastChangedRevision: 20714 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/hpca/mms_load_hpca_fix_dist.pro $
;-
pro mms_load_hpca_fix_dist, tplotnames, suffix = suffix

    compile_opt idl2, hidden


  if undefined(suffix) then suffix = ''

  ;find applicable variables
  regex = '^mms([1-4])_hpca_[^_]+plus(_(phase_space_density|count_rate|flux)| ?)' + suffix + '$'
  
  idx = where( stregex(tplotnames,regex,/bool), n)
  if n eq 0 then return

  ;get list of probes
  probes = (stregex(tplotnames,regex,/subex,/extract))[1,*]

  for i=0, n-1 do begin

    ;avoid unnecessary copies
    get_data, tplotnames[idx[i]], ptr=data

    if ~is_struct(data) then continue

    get_data, 'mms'+probes[idx[i]]+'_hpca_centroid_elevation_angle', ptr=theta

    ;replacing one variable pointer's target appears to change the dependent
    ;var for all other variables from that CDF, we'll do it for each variable
    ;anyway just in case that dependency can be broken
    if ~is_struct(theta) then begin
      info = mms_get_hpca_info()
      *data.v1 = info.elevation
    endif else begin
      *data.v1 = *theta.y
    endelse

  endfor

end
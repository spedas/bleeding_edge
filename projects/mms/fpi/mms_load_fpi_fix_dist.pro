;+
; PROCEDURE:
;         mms_load_fpi_fix_dist
;
; PURPOSE:
;         Replace supplementary fields in 3D distribution variables with actual
;         values from supplementary tplot variables (E,phi,theta).
;
; NOTE:
;         Expect this routine to be made obsolete after the CDFs are updated
;
;
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2016-08-26 11:45:19 -0700 (Fri, 26 Aug 2016) $
;$LastChangedRevision: 21737 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/fpi/mms_load_fpi_fix_dist.pro $
;-
pro mms_load_fpi_fix_dist, tplotnames, probe = probe, level = level, data_rate = data_rate, $
                           datatype = datatype, suffix = suffix

  if undefined(suffix) then suffix = ''
  if undefined(datatype) then begin
      dprint, dlevel = 0, 'Error, must provide a datatype to mms_load_fpi_fix_dist'
      return
  endif
  if undefined(level) then begin
      dprint, dlevel = 0, 'Error, must provide a level to mms_load_fpi_fix_dist'
      return
  endif
  if undefined(level) then begin
      dprint, dlevel = 0, 'Error, must provide a level to mms_load_fpi_fix_dist'
      return
  endif

  prefix = 'mms' + strcompress(string(probe), /rem)
  
  regex = level eq 'l2' ? prefix+'_d([ei])s_dist_'+data_rate+suffix : $
                          prefix+'_d([ei])s_.*SkyMap_dist'+suffix
  
  idx = where( stregex(tplotnames,regex,/bool), n)
  if n eq 0 then return

  species = (stregex(tplotnames,regex,/subex,/extract))[1,*]

  for i=0, n-1 do begin

    ;avoid unnecessary copies
    get_data, tplotnames[idx[i]], ptr=data

    if ~is_struct(data) then continue

    ;load before loop if this needs to be done more than once or twice (it shouldn't)
    if data_rate eq 'brst' then begin
      energies = mms_fpi_burst_energies(species[idx[i]], probe, level=level, suffix=suffix)
    endif else begin
      energies = mms_fpi_energies(species[idx[i]], probe=probe, level=level, suffix=suffix)
    endelse
    
    mms_fpi_dist_angles, probe=probe, level=level, data_rate=data_rate, species=species[idx[i]], suffix=suffix, $
                         phi=phi, theta=theta
    
    ;replace energies
    if n_elements(energies) gt 1 then begin
      ;*data.v1 = energies ; egrimes flipped v1 and v3, 8/26/2016
      *data.v3 = energies
    endif

    ;replace azimuths
    if ~undefined(phi) then begin
     ; *data.v3 = phi
      *data.v1 = phi ; egrimes flipped v1 and v3, 8/26/2016
    endif

    ;replace elevations (colat)
    if ~undefined(theta) then begin
      *data.v2 = theta
    endif

  endfor  

end
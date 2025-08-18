;+
;
; FUNCTION:
;     flatten_spectra_convert_units
;     
; PURPOSE:
;     Helper roputine for flatten_spectra and flatten_spectra_multi
;
; 
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2021-08-13 11:48:37 -0700 (Fri, 13 Aug 2021) $
; $LastChangedRevision: 30205 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/util/flatten_spectra_convert_units.pro $
;-

function flatten_spectra_convert_units, var, data_x, data_y, metadata, to_kev=to_kev, to_flux=to_flux
  
  ; first check that unit conversion was requested
  if undefined(to_kev) && undefined(to_flux) then return, hash('data_x', data_x, 'data_y', data_y)
  
  cdf_yunits = ''
  cdf_zunits = ''
  cdf_units = spd_get_spectra_units(var)
  m = spd_extract_tvar_metadata(var)

  if is_struct(cdf_units) then begin
    cdf_zunits = cdf_units.zunits
    cdf_yunits = cdf_units.yunits
  endif
  
  yunits = cdf_yunits
  
  if keyword_set(to_kev) && ((tag_exist(metadata, 'ysubtitle') && metadata.ysubtitle ne '') || (tag_exist(metadata, 'yunits') && metadata.yunits ne '') || (cdf_yunits ne '')) then begin
    if cdf_yunits ne '' && (cdf_yunits eq 'eV' || cdf_yunits eq '[eV]' || cdf_yunits eq '(eV)') then begin
      data_x = data_x/1000d
      yunits = 'keV'
    endif else if tag_exist(metadata, 'ysubtitle') && (metadata.ysubtitle eq 'eV' || metadata.ysubtitle eq '[eV]' || metadata.ysubtitle eq '(eV)') then begin
      data_x = data_x/1000d
      yunits = 'keV'
    endif else if tag_exist(metadata, 'yunits') && (metadata.yunits eq 'eV' || metadata.yunits eq '[eV]' || metadata.yunits eq '(eV)') then begin
      data_x = data_x/1000d
      yunits = 'keV'
    endif
  endif
  
  if keyword_set(to_kev) and yunits ne 'keV' then begin
    dprint, dlevel=0, 'Error, could not find y-axis units for: ' + var + '; could not convert to keV'
  endif
  
  if yunits ne 'keV' && yunits ne 'eV' then begin
    if cdf_yunits ne '' && (cdf_yunits eq 'eV' || cdf_yunits eq '[eV]' || cdf_yunits eq '(eV)') then begin
      yunits = 'eV'
    endif else if tag_exist(metadata, 'ysubtitle') && (metadata.ysubtitle eq 'eV' || metadata.ysubtitle eq '[eV]' || metadata.ysubtitle eq '(eV)') then begin
      yunits = 'eV'
    endif else if tag_exist(metadata, 'yunits') && (metadata.yunits eq 'eV' || metadata.yunits eq '[eV]' || metadata.yunits eq '(eV)') then begin
      yunits = 'eV'
    endif else if cdf_yunits ne '' && (cdf_yunits eq 'keV' || cdf_yunits eq '[keV]' || cdf_yunits eq '(keV)') then begin
      yunits = 'keV'
    endif else if tag_exist(metadata, 'ysubtitle') && (metadata.ysubtitle eq 'keV' || metadata.ysubtitle eq '[keV]' || metadata.ysubtitle eq '(keV)') then begin
      yunits = 'keV'
    endif else if tag_exist(metadata, 'yunits') && (metadata.yunits eq 'keV' || metadata.yunits eq '[keV]' || metadata.yunits eq '(keV)') then begin
      yunits = 'keV'
    endif
  endif

  if keyword_set(to_flux) && (m.units ne '' || cdf_zunits ne '') then begin
    if yunits eq  '' then begin
      dprint, dlevel=0, 'Error, could not find y-axis units for: ' + var + '; could not convert to flux'
      return, hash('data_x', data_x, 'data_y', data_y)
    endif

    if cdf_zunits ne '' then ztitle = cdf_zunits else ztitle = string(m.units)
    ztitle_stripped = strjoin(strsplit(ztitle, '!U', /extract), '')
    ztitle_stripped = strjoin(strsplit(ztitle_stripped, '!N', /extract), '')
    ztitle_stripped = strjoin(strsplit(ztitle_stripped, '^', /extract), '')
    ztitle_stripped = strjoin(strsplit(ztitle_stripped, '-', /extract), '')
    ztitle = ztitle_stripped
    if ztitle eq 'keV/(cm2 sr s keV)' || ztitle eq '[keV/(cm2 sr s keV)]' || ztitle eq 'keV/(cm2 s sr keV)' || ztitle eq '[keV/(cm2 s sr keV)]' then begin
      if yunits eq 'eV' then data_y = data_y*1000d/data_x else data_y = data_y/data_x
    endif else if ztitle eq 'eV/(cm2 sr s eV)' || ztitle eq '[eV/(cm2 sr s eV)]' || ztitle eq 'eV/(cm2 s sr eV)' || ztitle eq '[eV/(cm2 s sr eV)]' then begin
      if yunits eq 'keV' then data_y = data_y*1000d/data_x else data_y = data_y/data_x
    endif else if ztitle eq '1/(cm2 sr s eV)' || ztitle eq '[1/(cm2 sr s eV)]' || ztitle eq '1/(cm2 s sr eV)' || ztitle eq '[1/(cm2 s sr eV)]' then begin
      ; convert to 1/(cm2 sr s keV)
      data_y = data_y*1000d
    endif
  endif
  return, hash('data_x', data_x, 'data_y', data_y)
end
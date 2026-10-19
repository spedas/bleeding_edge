;+
;FUNCTION:
;  thm_asi_cal_adapter_rego
;
;PURPOSE:
;  Build a REGO calibration structure from a REGO skymap that is
;  drop-in compatible with what thm_load_asi_cal,/rego returns from the
;  legacy Berkeley rego_l2_asc v01 calibration CDFs: a cdf_load_vars-style
;  structure with .vars[i].name / .vars[i].dataptr containing the 40
;  variables in the exact legacy order (positions verified against the
;  real rego_l2_asc_gill_19700101_v01.cdf; site-center scalars sit at
;  vars[20]/vars[21] like the THEMIS files).
;
;  Differences from the THEMIS adapter, per the legacy REGO cal layout:
;    - 512x512 full-resolution arrays; corner grids are [3,513,513] with
;      ALL THREE altitude planes (110/150/230 km), not a single plane
;    - variable prefixes clg_rgf_ (full), clg_rgt_ (1024-bin thumb),
;      clg_rgk_ (keogram), clg_asc_ (site scalars)
;    - extra full-frame variables flat / c512 / c513
;
;  Magnetic coordinates (_mlat/_mlon) and clg_asc_<site>_midn are filled
;  with NaN/'' (the legacy files populate them, but no SPEDAS consumer
;  reads them, and skymaps do not carry AACGM coordinates).
;
;  Verified against rego_l2_asc_gill_19700101_v01.cdf: all 40 names and
;  positions match, and azim/elev/glon/glat (all 3 altitude planes),
;  mask/offset/flat/multiply/alti/c512/c513, the full rgt bin set, and the
;  asc site scalars are numerically EXACT. Two documented deviations, both
;  consumer-free (verified no SPEDAS code reads them):
;    - clg_rgf_<site>_bin: legacy per-pixel bin-ID map differs slightly
;      (mean ~11 of 1024; the bin geometry itself -- rgt binc/binr/corner
;      maps -- is exact), likely an older generation pass in the legacy file
;    - clg_rgk_<site>_*: the legacy keogram-cal arrays are only partially
;      filled (202 of 512 entries, elevations near horizon only) and match
;      no rgf slice; the adapter instead provides a clean center-meridian
;      convention (CCD column 256 reversed / corner columns 256/255),
;      analogous to the THEMIS ask cal
;
;INPUT:
;  skymap:   restored REGO skymap structure (thm_asi_skymap,/rego)
;  site:     4-letter site code (string)
;  filename: skymap file path (recorded in the .filename tag)
;
;OUTPUT:
;  cal structure {filename, inq, compression, gzip_level, g_attributes,
;                 g_att_names, nv, vars[40]}
;-
function thm_asi_cal_adapter_rego, skymap, site, filename

  compile_opt idl2

  st = strlowcase(site)

  ; ---- derived values
  vs = strtrim(string(skymap.generation_info.valid_interval_start), 2)
  if strlen(vs) ge 8 then begin
    tstr = strmid(vs,0,4) + '-' + strmid(vs,4,2) + '-' + strmid(vs,6,2)
    if strlen(vs) ge 10 then tstr += '/' + strmid(vs,8,2) + ':00:00'
    t_valid = time_double(tstr)
  endif else t_valid = time_double('2000-01-01')
  epoch1970 = 62167219200000d0                 ; CDF epoch (ms) of 1970-01-01
  epoch_valid = epoch1970 + t_valid * 1000d0

  nalt = n_elements(skymap.full_map_altitude)  ; 3 (110/150/230 km)
  nan_full = fltarr(nalt,513,513) * !values.f_nan
  nan_bin = fltarr(4,1024) * !values.f_nan
  nan_keo = fltarr(nalt,512) * !values.f_nan

  ; CDF-orientation rgf arrays (REGO ORIENT pinned = rotate(img,2), same
  ; as THEMIS; verified bit-identical vs legacy clg_rgf CDF frames)
  rgf_azim = thm_asi_orient(float(skymap.full_azimuth))
  rgf_elev = thm_asi_orient(float(skymap.full_elevation))
  rgf_mask = thm_asi_orient(byte(skymap.full_ignore))
  rgf_offset = thm_asi_orient(uint(skymap.full_subtract))
  rgf_multiply = thm_asi_orient(float(skymap.full_multiply))
  rgf_bin = thm_asi_orient(uint(skymap.full_bin))

  ; corner grids: all altitude planes, [3,513,513] with altitude first
  rgf_glon = fltarr(nalt,513,513)
  rgf_glat = fltarr(nalt,513,513)
  for k = 0, nalt-1 do begin
    rgf_glon[k,*,*] = thm_asi_orient(float(reform(skymap.full_map_longitude[*,*,k])))
    rgf_glat[k,*,*] = thm_asi_orient(float(reform(skymap.full_map_latitude[*,*,k])))
  endfor

  ; flat field: derive as 1/multiply (divide-by-zero protected), matching
  ; the legacy flat/multiply relationship
  rgf_flat = rgf_multiply
  wnz = where(rgf_multiply ne 0., nnz, complement=wz, ncomplement=nz)
  if nnz gt 0 then rgf_flat[wnz] = 1.0 / rgf_multiply[wnz]
  if nz gt 0 then rgf_flat[wz] = 1.0

  ; rgt bins: transpose [1024,4] -> [4,1024]; longitudes to +-180
  rgt_glon = float(transpose(skymap.bin_map_longitude))
  wlon = where(rgt_glon gt 180., nlon)
  if nlon gt 0 then rgt_glon[wlon] -= 360.
  rgt_glat = float(transpose(skymap.bin_map_latitude))

  ; rgk keogram cal: center-column convention analogous to the THEMIS ask
  ; cal (elev/azim from CCD column 256 reversed; glat from corner column
  ; 256, glon from corner column 255), for all altitude planes
  rgk_elev = reverse(reform(rgf_elev[256, 0:511]))
  rgk_azim = reverse(reform(rgf_azim[256, 0:511]))
  rgk_glat = fltarr(nalt,512)
  rgk_glon = fltarr(nalt,512)
  for k = 0, nalt-1 do begin
    rgk_glat[k,*] = reform(rgf_glat[k, 0:511, 256])
    rgk_glon[k,*] = reform(rgf_glon[k, 0:511, 255])
  endfor

  ; ---- assemble the 40 variables in exact legacy order
  ventry = {name:'', num:0, is_zvar:1, datatype:'', type:0, numattr:-1, $
    numelem:1, recvary:0b, numrec:-1l, comp:0, gzip:0, block:0, $
    ndimen:0, d:lonarr(6), dataptr:ptr_new(), attrptr:ptr_new()}
  vars = replicate(ventry, 40)

  names = 'clg_' + $
    ['rgf_'+st+'_time','rgf_'+st+'_epoch','rgf_'+st+'_epoch0','','rgf_'+st+'_azim', $
     'rgf_'+st+'_elev','rgf_'+st+'_glon','rgf_'+st+'_glat','rgf_'+st+'_mlon', $
     'rgf_'+st+'_mlat','rgf_'+st+'_alti','rgf_'+st+'_mask','rgf_'+st+'_offset', $
     'rgf_'+st+'_flat','rgf_'+st+'_multiply','rgf_'+st+'_bin','rgf_'+st+'_c512', $
     'rgf_'+st+'_c513','rgt_'+st+'_column','rgt_'+st+'_row','asc_'+st+'_glon', $
     'asc_'+st+'_glat','asc_'+st+'_mlon','asc_'+st+'_mlat','asc_'+st+'_alti', $
     'asc_'+st+'_midn','rgt_'+st+'_azim','rgt_'+st+'_elev','rgt_'+st+'_binc', $
     'rgt_'+st+'_binr','rgt_'+st+'_glon','rgt_'+st+'_glat','rgt_'+st+'_mlon', $
     'rgt_'+st+'_mlat','rgk_'+st+'_elev','rgk_'+st+'_azim','rgk_'+st+'_glat', $
     'rgk_'+st+'_glon','rgk_'+st+'_mlat','rgk_'+st+'_mlon']
  names[3] = 'range_epoch'

  dtypes = ['CDF_REAL8','CDF_EPOCH','CDF_EPOCH','CDF_EPOCH','CDF_REAL4', $
    'CDF_REAL4','CDF_REAL4','CDF_REAL4','CDF_REAL4','CDF_REAL4','CDF_REAL4', $
    'CDF_BYTE','CDF_UINT2','CDF_REAL4','CDF_REAL4','CDF_UINT2','CDF_UINT2', $
    'CDF_UINT2','CDF_UINT2','CDF_UINT2','CDF_REAL4','CDF_REAL4','CDF_REAL4', $
    'CDF_REAL4','CDF_REAL4','CDF_CHAR','CDF_REAL4','CDF_REAL4','CDF_UINT2', $
    'CDF_UINT2','CDF_REAL4','CDF_REAL4','CDF_REAL4','CDF_REAL4','CDF_REAL4', $
    'CDF_REAL4','CDF_REAL4','CDF_REAL4','CDF_REAL4','CDF_REAL4']

  values = list( $
    [t_valid], $                                ;  0 rgf_time
    [epoch_valid], $                            ;  1 rgf_epoch
    epoch1970, $                                ;  2 rgf_epoch0
    [epoch_valid], $                            ;  3 range_epoch
    rgf_azim, $                                 ;  4
    rgf_elev, $                                 ;  5
    rgf_glon, $                                 ;  6 [3,513,513]
    rgf_glat, $                                 ;  7
    nan_full, $                                 ;  8 rgf_mlon (NaN, see header)
    nan_full, $                                 ;  9 rgf_mlat
    float(skymap.full_map_altitude), $          ; 10 rgf_alti [3], metres
    rgf_mask, $                                 ; 11
    rgf_offset, $                               ; 12
    rgf_flat, $                                 ; 13
    rgf_multiply, $                             ; 14
    rgf_bin, $                                  ; 15
    uindgen(512), $                             ; 16 rgf_c512
    uindgen(513), $                             ; 17 rgf_c513
    uindgen(1024), $                            ; 18 rgt_column
    uindgen(4), $                               ; 19 rgt_row
    float(skymap.site_map_longitude), $         ; 20 asc_glon  (autocenter lon)
    float(skymap.site_map_latitude), $          ; 21 asc_glat  (autocenter lat)
    !values.f_nan, $                            ; 22 asc_mlon
    !values.f_nan, $                            ; 23 asc_mlat
    float(skymap.site_map_altitude), $          ; 24 asc_alti
    '', $                                       ; 25 asc_midn (not derivable)
    float(skymap.bin_azimuth), $                ; 26 rgt_azim
    float(skymap.bin_elevation), $              ; 27 rgt_elev
    uint(skymap.bin_column), $                  ; 28 rgt_binc
    uint(skymap.bin_row), $                     ; 29 rgt_binr
    rgt_glon, $                                 ; 30
    rgt_glat, $                                 ; 31
    nan_bin, $                                  ; 32 rgt_mlon
    nan_bin, $                                  ; 33 rgt_mlat
    rgk_elev, $                                 ; 34
    rgk_azim, $                                 ; 35
    rgk_glat, $                                 ; 36 [3,512]
    rgk_glon, $                                 ; 37
    nan_keo, $                                  ; 38 rgk_mlat
    nan_keo)                                    ; 39 rgk_mlon

  for i = 0, 39 do begin
    vars[i].name = names[i]
    vars[i].num = i
    vars[i].datatype = dtypes[i]
    val = values[i]
    vars[i].type = size(val, /type)
    sz = size(val)
    vars[i].ndimen = sz[0]
    if sz[0] gt 0 then vars[i].d[0:sz[0]-1] = sz[1:sz[0]]
    vars[i].numelem = (size(val, /type) eq 7) ? strlen(val) > 1 : 1
    vars[i].dataptr = ptr_new(val)
  endfor

  inq = {ndims: 0l, decoding: 'HOST_DECODING', encoding: 'NETWORK_ENCODING', $
    majority: 'ROW_MAJOR', maxrec: 0l, nvars: 0l, nzvars: 40l, natts: 0l, $
    dim: lonarr(1)}
  g_attributes = { $
    project: 'REGO', $
    source_name: 'CLG>Redline Emission Geospace Observatory', $
    data_type: 'ASC>All Sky Imager, Calibration data (skymap adapter)', $
    descriptor: strupcase(st), $
    generated_by: 'SPEDAS thm_asi_cal_adapter_rego, skymap: ' + file_basename(filename), $
    rules_of_use: 'Open Data for Scientific Use' $
    }

  return, create_struct('filename', filename, 'inq', inq, 'compression', 0l, $
    'gzip_level', 0l, 'g_attributes', g_attributes, $
    'g_att_names', tag_names(g_attributes), 'nv', 40l, 'vars', vars)
end

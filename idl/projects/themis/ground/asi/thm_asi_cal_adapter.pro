;+
;FUNCTION:
;  thm_asi_cal_adapter
;
;PURPOSE:
;  Build a calibration structure from a skymap that is drop-in
;  compatible with what thm_load_asi_cal returns from the legacy Berkeley
;  thg_l2_asc v02 calibration CDFs: a cdf_load_vars-style structure with
;  .vars[i].name / .vars[i].dataptr, containing the 40 variables of the
;  v02 cal files in the exact same order (some consumers index vars by
;  position, e.g. the /autocenter code in thm_asi_create_mosaic).
;
;  Variable sources (skymap tag -> cal variable):
;    full_azimuth/full_elevation (ORIENTed)      -> thg_asf_<site>_azim/_elev [256,256]
;    full_map_longitude/latitude[*,*,i] (ORIENT) -> thg_asf_<site>_glon/_glat [257,257]
;                                                   (all 3 altitude planes kept? no --
;                                                    the 110 km plane, like v02 cal)
;    full_map_altitude                           -> thg_asf_<site>_alti [3]
;    full_ignore/full_subtract/full_multiply/full_bin (ORIENTed)
;                                                -> _mask/_offset/_multiply/_bin
;    bin_azimuth/bin_elevation                   -> thg_ast_<site>_azim/_elev [1024]
;    bin_column/bin_row                          -> thg_ast_<site>_binc/_binr [1024]
;    transpose(bin_map_longitude/latitude)       -> thg_ast_<site>_glon/_glat [4,1024]
;                                                   (longitude converted to +-180,
;                                                    matching the v02 cal convention)
;    site_map_longitude/latitude/altitude        -> thg_asc_<site>_glon/_glat/_alti
;    asf arrays at CCD column 127                -> thg_ask_<site>_* [256]
;                                                   (same convention as the v02
;                                                    mlat/mlon patch in thm_load_asi_cal)
;
;  Magnetic coordinates (_mlat/_mlon) are filled with NaN: no SPEDAS ASI
;  consumer uses them (verified), and the skymaps do not carry AACGM
;  coordinates. thg_asc_<site>_midn (MLT midnight string) is likewise not
;  derivable from the skymap and is set to ''.
;
;INPUT:
;  skymap:   restored skymap structure (from thm_asi_skymap)
;  site:     4-letter site code (string)
;  filename: skymap file path (recorded in the .filename tag)
;
;OUTPUT:
;  cal structure {filename, inq, compression, gzip_level, g_attributes,
;                 g_att_names, nv, vars[40]}
;-
function thm_asi_cal_adapter, skymap, site, filename

  compile_opt idl2

  st = strlowcase(site)

  ; ---- derived values
  ; validity start (generation_info.valid_interval_start is 'YYYYMMDDHH')
  vs = strtrim(string(skymap.generation_info.valid_interval_start), 2)
  if strlen(vs) ge 8 then begin
    tstr = strmid(vs,0,4) + '-' + strmid(vs,4,2) + '-' + strmid(vs,6,2)
    if strlen(vs) ge 10 then tstr += '/' + strmid(vs,8,2) + ':00:00'
    t_valid = time_double(tstr)
  endif else t_valid = time_double('2000-01-01')
  epoch1970 = 62167219200000d0                 ; CDF epoch (ms) of 1970-01-01
  epoch_valid = epoch1970 + t_valid * 1000d0

  ; altitude plane: 110 km, same emission height as the v02 cal arrays
  !null = min(abs(skymap.full_map_altitude - 110000.), i110)

  nan257 = fltarr(257,257) * !values.f_nan
  nan1024 = fltarr(4,1024) * !values.f_nan
  nan256 = fltarr(256) * !values.f_nan

  ; CDF-orientation asf arrays
  asf_azim = thm_asi_orient(float(skymap.full_azimuth))
  asf_elev = thm_asi_orient(float(skymap.full_elevation))
  asf_glon = thm_asi_orient(float(reform(skymap.full_map_longitude[*,*,i110])))
  asf_glat = thm_asi_orient(float(reform(skymap.full_map_latitude[*,*,i110])))
  asf_mask = thm_asi_orient(byte(skymap.full_ignore))
  asf_offset = thm_asi_orient(uint(skymap.full_subtract))
  asf_multiply = thm_asi_orient(float(skymap.full_multiply))
  asf_bin = thm_asi_orient(uint(skymap.full_bin))
  ; flat field: legacy cal 'flat' is unity where multiply is unity; derive
  ; as 1/multiply with divide-by-zero protection
  asf_flat = asf_multiply
  wnz = where(asf_multiply ne 0., nnz, complement=wz, ncomplement=nz)
  if nnz gt 0 then asf_flat[wnz] = 1.0 / asf_multiply[wnz]
  if nz gt 0 then asf_flat[wz] = 1.0

  ; ast bins: transpose [1024,4] -> [4,1024]; longitudes to +-180 (v02 convention)
  ast_glon = float(transpose(skymap.bin_map_longitude))
  wlon = where(ast_glon gt 180., nlon)
  if nlon gt 0 then ast_glon[wlon] -= 360.
  ast_glat = float(transpose(skymap.bin_map_latitude))

  ; ask arrays: replicate the (internally inconsistent, but long-standing)
  ; legacy v02 cal conventions exactly, determined empirically against the
  ; real Berkeley cal CDFs:
  ;   ask_elev/azim = reverse(asf[128, 0:255])   (exact match, 0.0000 deg)
  ;   ask_glat      = asf_glat[0:255, 128]       (match to < 0.09 deg)
  ;   ask_glon      = asf_glon[0:255, 127]       (match to < 0.03 deg)
  ask_elev = reverse(reform(asf_elev[128, 0:255]))
  ask_azim = reverse(reform(asf_azim[128, 0:255]))
  ask_glat = reform(asf_glat[0:255, 128])
  ask_glon = reform(asf_glon[0:255, 127])

  ; ---- assemble the 40 variables in exact v02 order
  ; helper template mirroring cdf_info's varinfo structure
  ventry = {name:'', num:0, is_zvar:1, datatype:'', type:0, numattr:-1, $
    numelem:1, recvary:0b, numrec:-1l, comp:0, gzip:0, block:0, $
    ndimen:0, d:lonarr(6), dataptr:ptr_new(), attrptr:ptr_new()}
  vars = replicate(ventry, 40)

  ; (name, datatype, type, value) table; dims derived from the value
  names = 'thg_' + $
    ['asf_'+st+'_time','asf_'+st+'_epoch','asf_'+st+'_epoch0','','asf_'+st+'_azim', $
     'asf_'+st+'_elev','asf_'+st+'_glon','asf_'+st+'_glat','asf_'+st+'_mlon', $
     'asf_'+st+'_mlat','asf_'+st+'_alti','asf_'+st+'_mask','asf_'+st+'_offset', $
     'asf_'+st+'_flat','asf_'+st+'_multiply','asf_'+st+'_bin','asf_'+st+'_c256', $
     'asf_'+st+'_c257','ast_'+st+'_column','ast_'+st+'_row','asc_'+st+'_glon', $
     'asc_'+st+'_glat','asc_'+st+'_mlon','asc_'+st+'_mlat','asc_'+st+'_alti', $
     'asc_'+st+'_midn','ast_'+st+'_azim','ast_'+st+'_elev','ast_'+st+'_binc', $
     'ast_'+st+'_binr','ast_'+st+'_glon','ast_'+st+'_glat','ast_'+st+'_mlon', $
     'ast_'+st+'_mlat','ask_'+st+'_elev','ask_'+st+'_azim','ask_'+st+'_glat', $
     'ask_'+st+'_glon','ask_'+st+'_mlat','ask_'+st+'_mlon']
  names[3] = 'range_epoch'

  dtypes = ['CDF_REAL8','CDF_EPOCH','CDF_EPOCH','CDF_EPOCH','CDF_REAL4', $
    'CDF_REAL4','CDF_REAL4','CDF_REAL4','CDF_REAL4','CDF_REAL4','CDF_REAL4', $
    'CDF_BYTE','CDF_UINT2','CDF_REAL4','CDF_REAL4','CDF_UINT2','CDF_UINT2', $
    'CDF_UINT2','CDF_UINT2','CDF_UINT2','CDF_REAL4','CDF_REAL4','CDF_REAL4', $
    'CDF_REAL4','CDF_REAL4','CDF_CHAR','CDF_REAL4','CDF_REAL4','CDF_UINT2', $
    'CDF_UINT2','CDF_REAL4','CDF_REAL4','CDF_REAL4','CDF_REAL4','CDF_REAL4', $
    'CDF_REAL4','CDF_REAL4','CDF_REAL4','CDF_REAL4','CDF_REAL4']

  values = list( $
    [t_valid], $                                ;  0 asf_time (unix, 'unleaped seconds')
    [epoch_valid], $                            ;  1 asf_epoch
    epoch1970, $                                ;  2 asf_epoch0 (non-record-varying scalar)
    [epoch_valid], $                            ;  3 range_epoch
    asf_azim, $                                 ;  4
    asf_elev, $                                 ;  5
    asf_glon, $                                 ;  6
    asf_glat, $                                 ;  7
    nan257, $                                   ;  8 asf_mlon (NaN, see header)
    nan257, $                                   ;  9 asf_mlat
    float(skymap.full_map_altitude), $          ; 10 asf_alti [3], metres
    asf_mask, $                                 ; 11
    asf_offset, $                               ; 12
    asf_flat, $                                 ; 13
    asf_multiply, $                             ; 14
    asf_bin, $                                  ; 15
    uindgen(256), $                             ; 16 asf_c256
    uindgen(257), $                             ; 17 asf_c257
    uindgen(1024), $                            ; 18 ast_column
    uindgen(4), $                               ; 19 ast_row
    float(skymap.site_map_longitude), $         ; 20 asc_glon  (autocenter lon)
    float(skymap.site_map_latitude), $          ; 21 asc_glat  (autocenter lat)
    !values.f_nan, $                            ; 22 asc_mlon
    !values.f_nan, $                            ; 23 asc_mlat
    float(skymap.site_map_altitude), $          ; 24 asc_alti
    '', $                                       ; 25 asc_midn (MLT midnight, not available)
    float(skymap.bin_azimuth), $                ; 26 ast_azim
    float(skymap.bin_elevation), $              ; 27 ast_elev
    uint(skymap.bin_column), $                  ; 28 ast_binc
    uint(skymap.bin_row), $                     ; 29 ast_binr
    ast_glon, $                                 ; 30
    ast_glat, $                                 ; 31
    nan1024, $                                  ; 32 ast_mlon
    nan1024, $                                  ; 33 ast_mlat
    ask_elev, $                                 ; 34
    ask_azim, $                                 ; 35
    ask_glat, $                                 ; 36
    ask_glon, $                                 ; 37
    nan256, $                                   ; 38 ask_mlat
    nan256)                                     ; 39 ask_mlon

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

  ; minimal top-level shell mirroring cdf_info's output layout
  inq = {ndims: 0l, decoding: 'HOST_DECODING', encoding: 'NETWORK_ENCODING', $
    majority: 'ROW_MAJOR', maxrec: 0l, nvars: 0l, nzvars: 40l, natts: 0l, $
    dim: lonarr(1)}
  g_attributes = { $
    project: 'THEMIS', $
    source_name: 'THG>THEMIS Ground Based Observatory', $
    data_type: 'ASC>All Sky Imager, Calibration data (skymap adapter)', $
    descriptor: strupcase(st), $
    generated_by: 'SPEDAS thm_asi_cal_adapter, skymap: ' + file_basename(filename), $
    rules_of_use: 'Open Data for Scientific Use' $
    }

  return, create_struct('filename', filename, 'inq', inq, 'compression', 0l, $
    'gzip_level', 0l, 'g_attributes', g_attributes, $
    'g_att_names', tag_names(g_attributes), 'nv', 40l, 'vars', vars)
end

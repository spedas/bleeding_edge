;+
;PROCEDURE:
;  srscan_asi_keogram
;
;PURPOSE:
;  Build a custom keogram from a loaded raw all-sky image variable: a
;  vertical (south-north) slice through each frame, stacked in time.
;
;  Unlike the archived keogram products (lossy JPEG quicklooks for TREx
;  RGB), a keogram built here from raw data is photometric -- this is the
;  quantitative alternative the loaders point at.
;
;  Works on truecolor cubes {x[n], y[n,3,ncol,nrow]} (TREx RGB); creates
;    <varname>_keo: {x[n], y[n,nrow,3] byte, v[nrow]}
;  which renders in TRUECOLOR in tplot (srscan_trexrgb_keoplot plotting
;  routine; the zrange option sets the linear stretch). With channel= set,
;  a single-channel classic spectrogram companion <varname>_keo_<channel>
;  is created as well. Row 0 = south, matching the archived keogram
;  convention, so the two can be compared directly.
;
;INPUT:
;  varname: raw image tplot variable, e.g. 'srscan_trexrgb_gill'
;
;KEYWORDS:
;  column:  CCD column to slice (default: center column)
;  channel: if set to 'luma', 'r', 'g', or 'b', also create the
;           single-channel spectrogram companion
;  newname: output variable base name (default <varname>_keo)
;  verbose: dprint verbosity
;
;EXAMPLE:
;  srscan_load_trex_rgb, site='gill', trange=['2023-03-24/06:00','2023-03-24/07:00']
;  srscan_asi_keogram, 'srscan_trexrgb_gill'
;  tplot, 'srscan_trexrgb_gill_keo'
;-
pro srscan_asi_keogram, varname, column = column, channel = channel, $
  newname = newname, verbose = verbose

  compile_opt idl2

  get_data, varname, data = d, dlimits = dl_in
  if size(d, /type) ne 8 then begin
    dprint, dlevel=0, 'srscan_asi_keogram: variable not found: ' + varname
    return
  endif
  dims = size(d.y, /dimensions)
  if n_elements(dims) ne 4 then begin
    dprint, dlevel=0, 'srscan_asi_keogram: ' + varname + ' is not a [n,nchan,ncol,nrow] ' + $
      'image cube (single-frame time= loads cannot make a keogram)'
    return
  endif
  n = dims[0] & nchan = dims[1] & ncol = dims[2] & nrow = dims[3]

  col = n_elements(column) gt 0 ? long(column) : ncol / 2
  col = col > 0 < (ncol - 1)
  if ~keyword_set(newname) then newname = varname + '_keo'

  ; slice: [n, nchan, nrow] at the chosen column -> [n, nrow, nchan]
  ; (explicit dimensions: a bare reform would also drop a leading n=1
  ; frame dimension and break the transpose)
  slc = reform(d.y[*, *, col, *], n, nchan, nrow)
  ytrue = transpose(slc, [0, 2, 1])              ; [n, nrow, nchan]

  units = 'counts'
  if size(dl_in, /type) eq 8 then str_element, dl_in, 'data_att.units', units

  ; main variable: full RGB, rendered truecolor by srscan_trexrgb_keoplot
  dl = { $
    tplot_routine: 'srscan_trexrgb_keoplot', $
    spec: 0b, log: 0b, $
    data_att: {coord_sys: '', units: units, source: varname, column: col}, $
    yrange: [0, nrow - 1], ystyle: 1, $
    ysubtitle: '[' + units + ', col ' + strtrim(col, 2) + ']' $
    }
  store_data, newname, data = {x: d.x, y: ytrue, v: indgen(nrow)}, dlimits = dl

  ; optional single-channel classic spectrogram companion
  if keyword_set(channel) then begin
    chname = strlowcase(channel[0])
    case chname of
      'r': yspec = reform(ytrue[*, *, 0])
      'g': yspec = reform(ytrue[*, *, 1])
      'b': yspec = reform(ytrue[*, *, 2])
      else: begin
        chname = 'luma'
        yspec = (nchan ge 3) ? $
          byte(round(0.299d * ytrue[*, *, 0] + 0.587d * ytrue[*, *, 1] + $
            0.114d * ytrue[*, *, 2]) < 255) : reform(ytrue[*, *, 0])
      end
    endcase
    dl_ch = { $
      spec: 1b, log: 0b, $
      data_att: {coord_sys: '', units: units, source: varname, column: col}, $
      ysubtitle: '', $
      ztitle: '[' + units + ', col ' + strtrim(col, 2) + ']' $
      }
    store_data, newname + '_' + chname, data = {x: d.x, y: yspec, v: indgen(nrow)}, $
      dlimits = dl_ch
  endif

  dprint, dlevel=2, verbose=verbose, 'srscan_asi_keogram: created ' + newname + $
    ' from column ' + strtrim(col, 2)
end

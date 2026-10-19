;+
;PROCEDURE:
;  srscan_trexrgb_keoplot
;
;PURPOSE:
;  Custom tplot plotting routine that renders a TRUECOLOR (RGB) keogram
;  panel. Registered on a tplot variable through
;    dlimits = {tplot_routine: 'srscan_trexrgb_keoplot', ...}
;  and invoked by tplot itself; not normally called by users.
;
;  Expects data {x[n], y[n,nrow,3], v[nrow]} -- time, pixel row
;  (south->north), RGB channel. The panel is painted with tv,/true in
;  24-bit color, so keograms look like the archive colour quicklooks
;  instead of a greyscale spectrogram.
;
;  Honored limits/dlimits options (beyond the standard axis options that
;  box/plot understand: yrange, ytitle, position, ...):
;    zrange:  [lo,hi] linear DN stretch window applied to all three
;             channels (default [0,255]; one window preserves colour
;             balance)
;    datagap: seconds; gaps longer than this render black
;             (default 2x the median sample spacing)
;
;  Requires a 24-bit graphics target. WIN/X are fine as-is; for headless
;  Z-buffer rendering use
;    device, set_resolution=[xs,ys], set_pixel_depth=24, decomposed=0
;  (tv,/true paints real RGB on any 24-bit target regardless of the
;  decomposed setting, and decomposed=0 keeps tplot's axis/label colors
;  going through the color table as usual -- with decomposed=1 the axis
;  color index 255 would be read as the 24-bit value '0000FF'x = red).
;  If truecolor display fails (8-bit device), the routine falls back to a
;  greyscale luma rendering through the current color table and says so.
;-
pro srscan_trexrgb_keoplot, data = data, limits = limits

  compile_opt idl2

  if size(data, /type) ne 8 then return
  dims = size(data.y, /dimensions)
  if n_elements(dims) ne 3 then begin
    dprint, dlevel=0, 'srscan_trexrgb_keoplot: expected [n,nrow,3] truecolor keogram data'
    return
  endif
  n = dims[0] & nrow = dims[1] & nchan = dims[2]

  ; default y range = full pixel-row extent
  lim = keyword_set(limits) ? limits : {yrange: [0, nrow - 1]}
  yr = [0., nrow - 1.]
  str_element, lim, 'yrange', yr
  if yr[0] eq yr[1] then yr = [0., nrow - 1.]

  ; ---- set up the panel coordinate frame (draws the axes)
  box, lim, data.x, yr

  ; ---- device-pixel extent of the plot window
  pixpos = round(convert_coord(!x.window, !y.window, /norm, /to_device))
  npx = pixpos[0, 1] - pixpos[0, 0] - 1
  npy = pixpos[1, 1] - pixpos[1, 0] - 1
  xposition = pixpos[0, 0] + 1
  yposition = pixpos[1, 0] + 1
  if npx le 0 || npy le 0 then return

  ; data ranges actually displayed
  xcr = !x.crange
  ycr = !y.crange

  ; ---- nearest-neighbor resample onto the device grid
  ; column times at device-pixel centers
  tg = xcr[0] + (dindgen(npx) + 0.5d) / npx * (xcr[1] - xcr[0])
  ix = value_locate(data.x, tg) > 0 < (n - 1)
  ; snap to the nearer of the two bracketing samples
  ix2 = (ix + 1) < (n - 1)
  wnear = where(abs(data.x[ix2] - tg) lt abs(data.x[ix] - tg), nnear)
  if nnear gt 0 then ix[wnear] = ix2[wnear]
  ; gap mask
  if n gt 1 then dt_med = median(data.x[1:*] - data.x) else dt_med = 3d
  maxgap = 2d * dt_med
  str_element, lim, 'datagap', maxgap
  wgap = where(abs(data.x[ix] - tg) gt maxgap, ngap)

  ; row values at device-pixel centers
  rv = ycr[0] + (dindgen(npy) + 0.5d) / npy * (ycr[1] - ycr[0])
  iy = round(rv)
  wyoff = where(iy lt 0 or iy gt nrow - 1, nyoff)
  iy = iy > 0 < (nrow - 1)

  ; ---- stretch (one window for all channels preserves colour balance)
  zr = [0., 255.]
  str_element, lim, 'zrange', zr

  ; full [npx,npy] index matrices (vector subscripts of different sizes
  ; are an error in IDL; element-wise pairing needs same-size arrays)
  ixm = rebin(long(ix), npx, npy)
  iym = rebin(reform(long(iy), 1, npy), npx, npy)

  image = bytarr(3, npx, npy)
  for c = 0, (nchan - 1) < 2 do begin
    ch = float(reform(data.y[*, *, c]))
    sub = ch[ixm, iym]
    scl = (sub - zr[0]) / ((zr[1] - zr[0]) > 1.) < 1. > 0.
    image[c, *, *] = byte(round(scl * 255.))
  endfor
  if ngap gt 0 then image[*, wgap, *] = 0b
  if nyoff gt 0 then image[*, *, wyoff] = 0b

  ; ---- paint; fall back to greyscale luma if the device can't do truecolor
  catch, tverr
  if tverr ne 0 then begin
    catch, /cancel
    dprint, dlevel=1, 'srscan_trexrgb_keoplot: truecolor display failed on device ' + $
      !d.name + ' (' + !error_state.msg + '); falling back to greyscale luma. ' + $
      'For the Z buffer use device, set_pixel_depth=24, decomposed=0.'
    luma = byte(round(0.299 * image[0, *, *] + 0.587 * image[1, *, *] + $
      0.114 * image[2, *, *]) < 255)
    tv, reform(luma), xposition, yposition, xsize = npx, ysize = npy
    return
  endif
  tv, image, xposition, yposition, xsize = npx, ysize = npy, true = 1
  catch, /cancel
end

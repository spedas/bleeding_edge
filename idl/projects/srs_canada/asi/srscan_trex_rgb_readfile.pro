;+
;PROCEDURE:
;  srscan_trex_rgb_readfile
;
;PURPOSE:
;  Read TREx RGB stream0 (nominal cadence) HDF5 files into a frame cube
;  and a matching unix-time array.
;
;  Each 1-minute file holds up to 20 truecolor frames (nominal 3-s
;  cadence) in /data/images as byte [nf,3,553,480] -- frame index first,
;  then [channel, x, y] -- plus /data/timestamp, an array of strings of
;  the form 'YYYY-MM-DD HH:MM:SS.ffffff UTC' giving each frame's exposure
;  start. Short files (fewer than 20 frames) occur and are handled.
;
;  Frames are returned in ARCHIVE orientation (y increases southward);
;  apply srscan_trex_rgb_orient before display or geometry work.
;
;INPUT:
;  filenames: string array of local .h5 file paths
;
;OUTPUT (positional):
;  images:   byte array [n_frames, 3, 553, 480]
;  times:    dblarr [n_frames], unix time of each frame
;
;KEYWORDS:
;  count:    (out) number of frames read
;  verbose:  dprint verbosity passthrough
;
;NOTES:
;  File layout verified against the archive with h5_parse (2023-03-24
;  gill). Files that fail to open or lack the expected datasets are
;  skipped with a warning rather than aborting the read.
;-
pro srscan_trex_rgb_readfile, filenames, images, times, count = count, verbose = verbose

  compile_opt idl2

  count = 0l
  images = !null
  times = !null

  nfiles = n_elements(filenames)
  if nfiles eq 0 then return

  ; two passes are wasteful for multi-GB reads; instead accumulate into a
  ; list and concatenate once at the end
  img_list = list()
  t_list = list()

  for i = 0l, nfiles - 1 do begin
    fname = filenames[i]

    catch, error_status
    if (error_status ne 0) then begin
      catch, /cancel
      dprint, dlevel=1, verbose=verbose, 'srscan_trex_rgb_readfile: failed to read ' + $
        fname + ' (' + !error_state.msg + '), skipping'
      if isa(fid) && fid gt 0 then h5f_close, fid
      fid = 0
      continue
    endif

    fid = h5f_open(fname)
    did = h5d_open(fid, '/data/images')
    img = h5d_read(did)
    h5d_close, did
    did = h5d_open(fid, '/data/timestamp')
    ts = h5d_read(did)
    h5d_close, did
    h5f_close, fid
    fid = 0
    catch, /cancel

    ; expect [nf,3,553,480]; a single-frame file can come back [3,553,480]
    sz = size(img, /dimensions)
    if n_elements(sz) eq 3 then begin
      img = reform(img, 1, sz[0], sz[1], sz[2])
      sz = size(img, /dimensions)
    endif
    if n_elements(sz) ne 4 || sz[1] ne 3 then begin
      dprint, dlevel=1, verbose=verbose, 'srscan_trex_rgb_readfile: unexpected image ' + $
        'dimensions [' + strjoin(strtrim(sz, 2), ',') + '] in ' + fname + ', skipping'
      continue
    endif

    nf = sz[0] < n_elements(ts)
    if nf le 0 then begin
      ; guards the img[0:nf-1,...] below: with nf=0 the subscript 0:-1
      ; would select the ENTIRE cube while count stays unincremented
      dprint, dlevel=1, verbose=verbose, 'srscan_trex_rgb_readfile: no timestamps ' + $
        'in ' + fname + ', skipping'
      continue
    endif

    ; 'YYYY-MM-DD HH:MM:SS.ffffff UTC' -> unix time
    tt = dblarr(nf)
    for k = 0l, nf - 1 do begin
      s = ts[k]
      pos = strpos(s, ' UTC')
      if pos ge 0 then s = strmid(s, 0, pos)
      tt[k] = time_double(s)
    endfor

    img_list.add, img[0:nf-1, *, *, *]
    t_list.add, tt
    count += nf
  endfor

  if count eq 0 then return

  ; concatenate along the frame dimension
  nchunks = n_elements(img_list)
  if nchunks eq 1 then begin
    images = img_list[0]
    times = t_list[0]
  endif else begin
    d = size(img_list[0], /dimensions)
    images = bytarr(count, d[1], d[2], d[3], /nozero)
    times = dblarr(count)
    ofs = 0l
    for i = 0l, nchunks - 1 do begin
      chunk = img_list[i]
      nf = (size(chunk, /dimensions))[0]
      images[ofs:ofs+nf-1, *, *, *] = chunk
      times[ofs:ofs+nf-1] = t_list[i]
      ofs += nf
    endfor
  endelse

  ; guarantee time order across files
  srt = sort(times)
  if ~array_equal(srt, lindgen(count)) then begin
    times = times[srt]
    images = images[srt, *, *, *]
  endif

  dprint, dlevel=3, verbose=verbose, 'srscan_trex_rgb_readfile: read ' + $
    strtrim(count, 2) + ' frame(s) from ' + strtrim(nfiles, 2) + ' file(s)'
end

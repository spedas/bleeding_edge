;+
; Structure definition for PGM frame metadata (one per frame).
;-
pro thm_asi_pgm_metadata__define
  compile_opt idl2, hidden

  !null = { $
    thm_asi_Pgm_Metadata, $
    site_uid: '', $
    imager_uid: '', $
    site_latitude: 0.0, $
    site_longitude: 0.0, $
    exposure_start_string: '', $
    exposure_start_cdf: 0.0d0, $
    exposure_duration_request: 0.0, $
    exposure_duration_actual: 0.0, $
    ccd_size: [0, 0], $
    ccd_center: [0, 0], $
    ccd_offset: [0, 0], $
    ccd_binning: [0, 0], $
    frame_size: [0, 0], $
    comments: '' $
    }
end

;+
; Parse the comment block of one PGM frame into a metadata structure.
; Returns 0 on success, 1 on failure.
;-
function thm_asi_parse_pgm_comments, comments, metadata, $
  minimal_metadata = minimal_metadata, no_metadata = no_metadata
  compile_opt idl2, hidden

  ; init errors
  on_ioerror, ioerror

  ; init metadata variable
  metadata = {thm_asi_Pgm_Metadata}

  ; set comments field
  metadata.comments = comments[0]
  for i = 1, n_elements(comments) - 1 do begin
    metadata.comments = metadata.comments + string(13b) + comments[i]
  endfor

  ; set temp variable for processing comments
  tmp = strlowcase(metadata.comments)
  if (strlen(tmp) eq 0) then return, 1

  ; extract the exposure start timestamp; try the full-resolution raw header
  ; style first, then older/terser summary-product styles
  timestring = (stregex(tmp, '"image request start" *([^#]+) utc', /subexpr, /extract))[1]
  if (timestring eq '') then timestring = (stregex(tmp, '"exposure start time" *([^#]+) utc', /subexpr, /extract))[1]
  if (timestring eq '') then timestring = (stregex(tmp, 'time *([0-9][^#]+)', /subexpr, /extract))[1]
  if (timestring eq '') then begin
    dprint, dlevel=0, 'thm_asi_readfile: could not find time information in PGM comments'
    return, 1
  endif

  ; clean the capture: split off any quoted trailer, strip CR/LF, trim
  timestring = (strsplit(timestring, '"', /extract))[0]
  timestring = strjoin(strsplit(timestring, string(13b) + string(10b), /extract))
  timestring = strtrim(timestring, 2)

  ; parse timestring (fractional seconds optional)
  year = 0
  month = 0
  day = 0
  hour = 0
  minute = 0
  second = 0.0
  reads, timestring, year, month, day, hour, minute, second, format = '(I4,X,I2,X,I2,X,I2,X,I2,X,F9.7)'
  milli = round(1000 * (second - fix(second)))
  second = fix(second)

  ; set exposure start string value
  metadata.exposure_start_string = timestring

  ; set exposure start CDF value
  cdf_epoch, epoch, year, month, day, hour, minute, second, milli, /compute
  metadata.exposure_start_cdf = epoch

  ; if MINIMAL_METADATA keyword is set, then skip the remaining fields
  if not keyword_set(minimal_metadata) then begin
    metadata.site_uid = (stregex(tmp, '"site unique *id" ([a-z0-9-]+)', /subexpr, /extract))[1]
    metadata.imager_uid = (stregex(tmp, '"imager unique *id" ([a-z0-9-]+)', /subexpr, /extract))[1]
    metadata.site_latitude = (stregex(tmp, '"*latitude" ([a-z0-9-]+.[a-z0-9-]+)', /subexpr, /extract))[1]
    metadata.site_longitude = (stregex(tmp, '"*longitude" ([a-z0-9-]+.[a-z0-9-]+)', /subexpr, /extract))[1]
    metadata.ccd_size[0] = (stregex(tmp, '"CCD xsize" ([0-9]+) pixels', /subexpr, /extract, /fold_case))[1]
    metadata.ccd_size[1] = (stregex(tmp, '"CCD ysize" ([0-9]+) pixels', /subexpr, /extract, /fold_case))[1]
    exposure = stregex(tmp, '"exposure options"[^#]*', /extract)
    metadata.frame_size = (stregex(exposure, 'width=([0-9]+).*height=([0-9]+)', /subexpr, /extract))[1 : 2]
    metadata.ccd_offset = (stregex(exposure, 'xoffset=([0-9]+).*yoffset=([0-9]+)', /subexpr, /extract))[1 : 2]
    metadata.ccd_binning = (stregex(exposure, 'xbin=([0-9]+).*ybin=([0-9]+)', /subexpr, /extract))[1 : 2]
    metadata.exposure_duration_request = (stregex(exposure, 'msec=([0-9]+)', /subexpr, /extract))[1]
    metadata.exposure_duration_actual = (stregex(tmp, '"exposure.*plus.*readout" *([0-9\.]+) ms', /subexpr, /extract))[1]

    ; convert exposure milliseconds to seconds
    metadata.exposure_duration_request = metadata.exposure_duration_request / 1d3
    metadata.exposure_duration_actual = metadata.exposure_duration_actual / 1d3
  endif

  ; return success
  return, 0

  ; on ioerror, return failure
  ioerror:
  if not keyword_set(no_metadata) then begin
    dprint, dlevel=0, 'thm_asi_readfile: could not parse metadata, use /no_metadata to read image anyway'
  endif
  metadata = {thm_asi_Pgm_Metadata}
  return, 1
end

;+
; Read a single PGM frame from an open LUN (or a standalone file).
; Returns the image array, or -1L on failure. The comments keyword returns
; the frame's comment lines; maxval returns the PGM maxval.
;-
function thm_asi_pgm_read_frame, filename, $
  lun = lun, verbose = verbose, comments = comments, maxval = maxval
  compile_opt idl2, hidden

  ; set error cases
  if not keyword_set(verbose) then on_error, 2
  on_ioerror, ioerror

  ; open file for reading
  if keyword_set(lun) then begin
    ; re-use already acquired lun
    llun = lun
    filename = string(lun, format = '("LUN=",I)')
    fs = fstat(llun)
    if (not fs.read) then begin
      dprint, dlevel=0, 'thm_asi_readfile: cannot read from lun ' + string(llun)
      return, -1l
    endif
  endif else begin
    ; acquire new lun
    if ~file_test(filename[0], /read) then begin
      dprint, dlevel=0, 'thm_asi_readfile: file not found: ' + filename[0]
      return, -1l
    endif
    compress = stregex(strupcase(filename[0]), '.*\.GZ$', /boolean)
    openr, llun, filename[0], /get_lun, /swap_if_little_endian, compress = compress
  endelse

  ; read magic number
  magicnumber = bytarr(2)
  readu, llun, magicnumber
  case string(magicnumber) of
    'P2': filetype = 2 ; ASCII grayscale PGM
    'P5': filetype = 5 ; binary grayscale PGM
    else: message, 'thm_asi_readfile: invalid magic number: ' + string(magicnumber)
  endcase

  ; init reading variables
  width = 0
  height = 0
  maxval = -1l
  depth = ([1, 1, 3, 1, 1, 3, 0])[filetype - 1]
  line = ''
  comments = ''
  value = lonarr(3)
  nvalues = 0

  ; read header lines (dimensions + maxval), collecting comments
  repeat begin
    readf, llun, line

    ; check if line is a comment
    pos = strpos(line, '#')
    if (pos ge 0) then begin
      comment = strmid(line, pos + 1, 999)
      line = strmid(line, 0, pos)
    endif else comment = ''
    if (strlen(comment) gt 0) then comments = [comments, comment]

    ; strip off whitespace, if empty then continue to next line
    line = strcompress(strtrim(line, 2))
    if (strlen(line) eq 0) then continue

    ; set dimensions
    token = strsplit(line, ' ', /extract)
    ntokens = n_elements(token)
    value[nvalues] = token[0 : (ntokens - 1) < 2]
    nvalues = nvalues + ntokens
  endrep until (nvalues ge 3) or eof(llun)

  ; check if the end of the file was encountered while reading metadata
  if eof(llun) then begin
    if not keyword_set(lun) then free_lun, llun
    dprint, dlevel=0, 'thm_asi_readfile: end of file while reading header: ' + filename
    return, -1l
  endif

  ; set variables for width, height, and max value
  width = value[0]
  height = value[1]
  maxval = value[2]
  if (n_elements(comments) gt 1) then comments = comments[1 : *]
  if (width le 0) or (height le 0) or (depth le 0) then $
    message, 'thm_asi_readfile: invalid dimensions'
  if (maxval le 0) or (maxval gt 65535l) then $
    message, 'thm_asi_readfile: invalid maxval:' + string(maxval)

  ; set image variable
  ; (note: 0us not 0u -- under compile_opt idl2 / DEFINT32, 0u is ULONG)
  if (maxval le 255) then atom = 0b else atom = 0us
  if (depth gt 1) then dimensions = [depth, width, height] else dimensions = [width, height]
  image = replicate(atom, dimensions)

  ; read image data
  if (filetype le 3) then begin
    readf, llun, image
  endif else begin
    readu, llun, image
  endelse

  ; close if we opened the file ourselves
  if not keyword_set(lun) then free_lun, llun

  ; return image
  return, image

  ; on error, free lun
  ioerror:
  free_lun, llun
  dprint, dlevel=0, 'thm_asi_readfile: ' + !error_state.msg
  return, -1l
end

;+
;PROCEDURE:
;  thm_asi_readfile
;
;PURPOSE:
;  Read one or more archive PGM / PGM.GZ files (multi-frame
;  one-minute raw bundles, hourly thumb32 bundles, or daily keogram files)
;  into a frame stack plus per-frame metadata.
;
;INPUT:
;  filename: string or string array of files to read (sorted internally)
;
;OUTPUT:
;  images:   [width, height, n_frames] byte or uint array (per PGM maxval)
;  metadata: n_frames-element array of thm_asi_Pgm_Metadata
;
;KEYWORDS:
;  count:       returns number of frames read
;  no_metadata: skip comment parsing (metadata contains defaults)
;  minimal_metadata: only parse timestamps
;  first_frame: stop after the first frame of each file
;  verbose:     dprint verbosity
;
;NOTES:
;  Frames are returned in raw PGM orientation; callers must apply
;  thm_asi_orient to match the orientation of the legacy
;  Berkeley CDF images.
;-
pro thm_asi_readfile, filename, images, metadata, $
  count = n_frames, verbose = verbose, $
  no_metadata = no_metadata, minimal_metadata = minimal_metadata, $
  first_frame = first_frame
  compile_opt idl2

  ; init
  n_frames = 0
  n_files = 0
  filenames = ''
  if (n_elements(no_metadata) eq 0) then no_metadata = 0
  if (n_elements(first_frame) eq 0) then first_frame = 0
  if (n_elements(verbose) eq 0) then verbose = 0

  ; init error catching
  catch, error
  if error ne 0 then begin
    catch, /cancel
    dprint, dlevel=0, 'thm_asi_readfile: error: ' + !error_state.msg
    return
  endif

  ; check that files exist and are readable
  for i = 0, n_elements(filename) - 1 do begin
    if file_test(filename[i], /read) then filenames = [filenames, filename[i]]
  endfor
  n_files = n_elements(filenames) - 1
  if (n_files eq 0) then begin
    dprint, dlevel=0, 'thm_asi_readfile: no readable files in input list'
    n_frames = 0
    return
  endif
  filenames = filenames[1 : n_files]

  ; sort filenames (archive filenames sort chronologically)
  if (n_elements(filenames) gt 1) then filenames = filenames[sort(filenames)]

  ; set values for pre-allocating memory (significantly increases speed)
  n_chunk = 20
  n_start = (n_chunk * n_files) < 2400

  ; for each file
  for i = 0, n_files - 1 do begin
    dprint, dlevel=3, verbose=verbose, 'thm_asi_readfile: reading ' + filenames[i]
    on_ioerror, fail

    openr, lun, filenames[i], /get_lun, $
      compress = stregex(strupcase(filenames[i]), '.*\.GZ$', /boolean), /swap_if_little_endian
    while not eof(lun) do begin
      image = thm_asi_pgm_read_frame(lun = lun, comments = comments, verbose = verbose)
      if (n_elements(image) le 1) then break   ; frame read failure

      ; parse comments
      if (no_metadata eq 0) then begin
        !null = thm_asi_parse_pgm_comments(comments, mdata, $
          minimal_metadata = minimal_metadata, no_metadata = no_metadata)
      endif else begin
        mdata = {thm_asi_Pgm_Metadata}
      endelse

      ; set returning variables
      if (n_frames eq 0) then begin
        isize = size(image, /struct)
        frame_ndim = isize.n_dimensions   ; 1 for vector products, 2 for images
        dimensions = isize.dimensions[0 : frame_ndim]
        dimensions[frame_ndim] = n_start
        images = make_array(dimensions, type = isize.type, /nozero)
        metadata = replicate({thm_asi_Pgm_Metadata}, n_start)
        dimensions[frame_ndim] = n_chunk
      endif else if (n_frames ge n_start) then begin
        ; need to expand the arrays
        if (frame_ndim eq 1) then begin
          images = [[images], [make_array(dimensions, type = isize.type, /nozero)]]
        endif else begin
          images = [[[images]], [[make_array(dimensions, type = isize.type, /nozero)]]]
        endelse
        metadata = [metadata, replicate({thm_asi_Pgm_Metadata}, n_chunk)]
        n_start = n_start + n_chunk
      endif

      ; copy previous metadata that may not be present in every record
      ; (only the first frame of a minute bundle carries the full header)
      if (no_metadata eq 0 and n_frames gt 0) then begin
        if (mdata.site_uid eq '') then mdata.site_uid = metadata[n_frames - 1].site_uid
        if (mdata.imager_uid eq '') then mdata.imager_uid = metadata[n_frames - 1].imager_uid
        if (mdata.site_latitude eq 0.0) then mdata.site_latitude = metadata[n_frames - 1].site_latitude
        if (mdata.site_longitude eq 0.0) then mdata.site_longitude = metadata[n_frames - 1].site_longitude
      endif

      ; replace site and device uids in the metadata using the filename
      ; (some archived files have metadata mismatching the filename; the
      ; filename is authoritative -- same workaround as idl-aurorax)
      fname_tokens = strsplit(file_basename(filenames[i]), '_', /extract)
      if (n_elements(fname_tokens) ge 4) then begin
        mdata.site_uid = fname_tokens[2]
        mdata.imager_uid = fname_tokens[3]
      endif

      ; finalize return variables
      metadata[n_frames] = mdata
      if (frame_ndim eq 1) then images[0, n_frames] = image $
      else images[0, 0, n_frames] = image
      n_frames = n_frames + 1

      ; if first_frame keyword is used, then break out
      if (first_frame ne 0) then break
    endwhile

    ; failure point, free the lun
    fail:
    if (isa(lun) eq 1) then free_lun, lun
  endfor

  ; remove extra unused memory
  if (n_frames gt 0) then begin
    if (frame_ndim eq 1) then images = images[*, 0 : n_frames - 1] $
    else images = images[*, *, 0 : n_frames - 1]
    metadata = metadata[0 : n_frames - 1]
  endif
end

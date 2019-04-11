;+
; NAME:
;   SPP_FLD_MAG_SURVEY_LOAD_L1
;
; PURPOSE:
;   Loads a L1 FIELDS MAG SURVEY CDF file into TPLOT variables.
;
; CALLING SEQUENCE:
;   spp_fld_mag_survey_load_l1, file, prefix = prefix
;
; INPUTS:
;   FILE: The name of the FIELDS Level 1 CDF file to be loaded.
;   PREFIX: The standard input is 'spp_fld_magi_survey_' or 
;     'spp_fld_mago_survey_' 
;
; OUTPUTS: No outputs returned.  TPLOT variables containing MAG data from
;   the specified CDF file will be created.
;
; EXAMPLE:
;   See call in SPP_FLD_MAGI_SURVEY_LOAD_L1.
;
; CREATED BY:
;   pulupa
;
;  $LastChangedBy: pulupalap $
;  $LastChangedDate: 2019-04-09 23:28:56 -0700 (Tue, 09 Apr 2019) $
;  $LastChangedRevision: 26976 $
;  $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/fields/l1/l1_mag_survey/spp_fld_mag_survey_load_l1.pro $
;

pro spp_fld_mag_survey_load_l1, file, prefix = prefix

  if not keyword_set(file) then begin
    print, 'file must be specified'
    return
  endif

  ; Load the L1 CDF file into IDL.

  cdf2tplot, /get_support_data, file, prefix = prefix

  if not keyword_set(prefix) then prefix = ''

  ; Detect (from the prefix, which is something like 'spp_fld_magi_survey_')
  ; whether we are loading 'magi' or 'mago' data.

  mag_string_index = prefix.IndexOf('mag')

  if mag_string_index GE 0 then begin
    short_prefix = prefix.Substring(mag_string_index, mag_string_index+3)
  endif else begin
    short_prefix = ''
  endelse

  ; Get metadata from the loaded items:
  ;
  ; avg_period_raw describes the number of vectors in the packet and the
  ;   measurement cadence.
  ;
  ; range_bits describes which range the observations are in.
  ;   There are 2 range bits per second, left justified
  ;   in a 32 bit range_bit item.  Depending on the averaging
  ;   period, there can be 2, 4, 8, or 16 seconds worth of data
  ;   in the packet, yielding 4, 8, 16, or 32 range bits.
  ;   The data item is always 32 bits long.  If there are fewer than
  ;   32 range bits required for the length of the packet,
  ;   the first 2 * (# of seconds) bits are used and the
  ;   remainder are zero filled.

  get_data, prefix + 'avg_period_raw', data = d_ppp
  get_data, prefix + 'range_bits', data = d_range_bits

  ; If the data hasn't been loaded then quit.

  if tnames(prefix + 'avg_period_raw') EQ '' then return

  ; Each packet has up to 512 mag vectors.  times_2d is the array of times
  ; that are in the CDF file (1 per packet)

  times_2d = d_ppp.x

  n_times_2d = n_elements(times_2d)

  ; times_1d is an array of times with one time per sample

  times_1d = rebin(times_2d, n_times_2d, 512l)

  ; ppp describes both the cadence and the number of measurements in the
  ; packet

  ppp = fix(d_ppp.y)

  ; 2^ppp gives the cadence (or, the number of samples averaged together,
  ; so ppp = 0 is no averaging at the full cadence of 256 samples / cycle)
  ; This also determines the rate, in vectors / cycle.

  navg = 2l^(fix(ppp))
  rate = 512l / (2l^(ppp+1))

  ; The number of vectors in a packet is 512 at the highest cadences, and
  ; as low as 32 vectors at the lowest cadence.

  nvec = 512l / 2l^(ppp - 3) * (navg GE 16) + 512l * (navg LT 16)

  ; The number of seconds in a packet is 2 for the highest cadence, and up
  ; to 16 for the lowest cadence

  nseconds = 16l * (navg GE 16) + 2l * navg * (navg LT 16)

  ; To summarize:
  ;
  ; PPP   # full cadence samples   Sample rate       Vectors      Cycles
  ;       per sample in packet     vectors / cycle   per packet   per packet
  ;
  ;   0         1                      256              512          2
  ;   1         2                      128              512          4
  ;   2         4                       64              512          8
  ;   3         5                       32              512         16
  ;   4        16                       16              256         16
  ;   5        32                        8              128         16
  ;   6        64                        4               64         16
  ;   7       128                        2               32         16
  ;
  ; Note that all measurements use the FIELDS cycle / "New York Second" instead
  ; of seconds.  1 cycle = 2^25 / 38.4e6 seconds.

  ; From the above metadata, compute 2D arrays where each vector in the array
  ; contains all of the times for the MAG vectors in the corresponding packet.
  ; For elements in the array which have fewer than 512 vectors, set the time
  ; to NaN.

  rate_arr = rebin(rate, n_times_2d, 512l)

  indices = rebin(lindgen(1,512), n_times_2d, 512l)

  max_inds = rebin(nvec, n_times_2d, 512l)

  nys_since_start = double(indices) / rate_arr

  times_1d += nys_since_start * (2.^25/38.4e6)

  times_valid_ind = where(indices LT max_inds, n_times_valid, $
    complement = times_invalid_ind, ncomplement = n_times_invalid)

  if n_times_valid NE n_elements(times_1d) then $
    times_1d[times_invalid_ind] = !VALUES.D_NAN

  ; These few lines take the range bits described above and other metadata
  ; arrays described above and make one dimensional vectors with one element
  ; per measured MAG vector.
  ; The reform, rebin, transpose commands aren't very easy to deciper, but
  ; doing it this way in IDL is much faster than using a for loop.

  range_bits_nys = rebin(d_range_bits.y, n_times_2d, 16l) / $
    transpose(rebin(4l^[reverse(lindgen(16))], 16l, n_times_2d)) MOD 4

  range_bits = range_bits_nys[$
    reform(transpose(rebin(lindgen(n_times_2d), n_times_2d, 512l)), $
    n_elements(nys_since_start)), $
    reform(long(transpose(nys_since_start * (indices LT max_inds))), $
    n_elements(nys_since_start))]

  times_1d = reform(transpose(times_1d), n_elements(times_1d))

  packet_index = reform(transpose(indices), n_elements(times_1d))

  rate_1d = reform(transpose(rate_arr), n_elements(times_1d))

  ; Remove invalid times from the time and metadata vectors.

  valid = where(finite(times_1d), n_valid)

  if n_valid GT 0 then begin

    times_1d = times_1d[valid]

    rate_1d = rate_1d[valid]

    packet_index = packet_index[valid]

    range_bits = range_bits[valid]

  endif

  ; Nominal scale factor (nT / count) for ranges 0-3.  In this Level 1 load
  ; routine, we don't apply detailed calibrations or subtract offsets.

  nt_adu = [0.03125,0.1250,0.5,2.0]
  scale_factor = nt_adu[range_bits]

  ; Store metadata in tplot variables.

  store_data, prefix + 'packet_index', $
    data = {x:times_1d, y:packet_index}

  store_data, prefix + 'range', $
    data = {x:times_1d, y:range_bits}

  store_data, prefix + 'rate', $
    data = {x:times_1d, y:rate_1d}

  ; Store each component of the MAG data in a TPLOT variable.

  mag_comps = ['mag_bx', 'mag_by', 'mag_bz']

  foreach mag_comp, mag_comps do begin

    ; Get the 2D data, with each row of the array consisting of all of the
    ; MAGx/y/z values for a single packet.

    get_data, prefix + mag_comp + '_2d', data = d_b_2d

    d_2d_size = size(d_b_2d.y, /dim)

    if d_2d_size[0] GT 0 and n_elements(d_2d_size) EQ 2 then begin

      if d_2d_size[1] LT 512 then begin

        d_b_2d_pad = make_array(d_2d_size[0], 512l - d_2d_size[1])

        b_2d = [[d_b_2d.y], [d_b_2d_pad]]

      endif else begin

        b_2d = d_b_2d.y

      endelse

    endif else begin

      b_2d = d_b_2d.y

    endelse

    ; Transform the array into a 1D vector.

    b_1d = reform(transpose(b_2d), n_elements(b_2d))

    if n_valid GT 0 then begin

      ; Select valid points and store in a tplot variable.

      b_1d = b_1d[valid]

      store_data, prefix + mag_comp, data = {x:times_1d, y:b_1d}

      ; The 'nT' tplot variable included the rough scale factors defined by
      ; the range bits above.

      store_data, prefix + mag_comp + '_nT', $
        data = {x:times_1d, y:b_1d * scale_factor}

      ; Set tplot plotting options

      options, prefix + mag_comp, 'ytitle', $
        short_prefix + ' b' + mag_comp.Substring(-1,-1)
      options, prefix + mag_comp, 'ysubtitle', '[Counts]'

      options, prefix + mag_comp, 'ynozero', 1
      options, prefix + mag_comp, 'panel_size', 1.5
      options, prefix + mag_comp, 'psym_lim', 200
      options, prefix + mag_comp, 'max_points', 40000l

      options, prefix + mag_comp + '_nT', 'ytitle', $
        short_prefix + ' b' + mag_comp.Substring(-1,-1)
      options, prefix + mag_comp + '_nT', 'ysubtitle', '[nT]'

      options, prefix + mag_comp + '_nT', 'ynozero', 1
      options, prefix + mag_comp + '_nT', 'panel_size', 1.5
      options, prefix + mag_comp + '_nT', 'psym_lim', 200
      options, prefix + mag_comp + '_nT', 'max_points', 40000l

    end

  endforeach

  get_data, prefix + 'mag_bx_nT', data = d_x
  get_data, prefix + 'mag_by_nT', data = d_y
  get_data, prefix + 'mag_bz_nT', data = d_z

  ; Store the data as a vector and a magnitude:

  store_data, prefix + 'nT', data = {x:d_x.x, y:[[d_x.y],[d_y.y],[d_z.y]]}
  store_data, prefix + 'nT_mag', data = {x:d_x.x, y:sqrt(d_x.y^2+d_y.y^2+d_z.y^2)}

  ; Set up plotting options for the tplot items:

  options, prefix + 'range', 'yrange', [-0.5,3.5]
  options, prefix + 'range', 'ytitle', short_prefix + '!Crange'
  options, prefix + 'range', 'yminor', 1
  options, prefix + 'range', 'ystyle', 1
  options, prefix + 'range', 'yticks', 3
  options, prefix + 'range', 'ytickv', [0,1,2,3]
  options, prefix + 'range', 'psym_lim', 200
  options, prefix + 'range', 'max_points', 40000l
  options, prefix + 'range', 'ysubtitle', ''
  options, prefix + 'range', 'panel_size', 0.75

  ;options, prefix + 'rate', 'yrange', [-0.5,7.5]
  options, prefix + 'rate', 'ytitle', short_prefix + '!Crate'
  ;options, prefix + 'rate', 'yminor', 1
  ;options, prefix + 'rate', 'ystyle', 1
  ;options, prefix + 'rate', 'yticks', 7
  ;options, prefix + 'rate', 'ytickv', [0,1,2,3,4,5,6,7]
  options, prefix + 'rate', 'psym_lim', 200
  options, prefix + 'rate', 'max_points', 40000l
  options, prefix + 'rate', 'ysubtitle', ''
  options, prefix + 'rate', 'panel_size', 0.75

  options, prefix + 'avg_period_raw', 'ytitle', short_prefix + '!CAvPR'
  options, prefix + 'avg_period_raw', 'ysubtitle'
  options, prefix + 'avg_period_raw', 'yrange', [-1.0,8.0]
  options, prefix + 'avg_period_raw', 'ystyle', 1
  options, prefix + 'avg_period_raw', 'yminor', 1
  options, prefix + 'avg_period_raw', 'yticks', 7
  options, prefix + 'avg_period_raw', 'ytickv', [0,1,2,3,4,5,6,7]
  options, prefix + 'avg_period_raw', 'psym_lim', 100
  options, prefix + 'avg_period_raw', 'ysubtitle', ''
  options, prefix + 'avg_period_raw', 'panel_size', 0.75

  options, prefix + 'packet_index', 'ytitle', $
    short_prefix + '!Cpkt_ind'
  options, prefix + 'packet_index', 'psym_lim', 200
  options, prefix + 'packet_index', 'max_points', 40000l
  options, prefix + 'packet_index', 'yrange', [0,512]
  options, prefix + 'packet_index', 'ystyle', 1
  options, prefix + 'packet_index', 'yminor', 4
  options, prefix + 'packet_index', 'yticks', 4
  options, prefix + 'packet_index', 'ytickv', [0,128,256,384,512]
  options, prefix + 'packet_index', 'ysubtitle', ''
  options, prefix + 'packet_index', 'panel_size', 0.75

  options, prefix + 'compressed', 'yrange', [-0.25,1.25]
  options, prefix + 'compressed', 'ystyle', 1
  options, prefix + 'compressed', 'yticks', 1
  options, prefix + 'compressed', 'ytickv', [0,1]
  options, prefix + 'compressed', 'yminor', 1
  options, prefix + 'compressed', 'psym', 4
  options, prefix + 'compressed', 'symsize', 0.5
  options, prefix + 'compressed', 'panel_size', 0.5
  options, prefix + 'compressed', 'ytitle', $
    short_prefix + '!Ccomp'
  options, prefix + 'compressed', 'ysubtitle', ''

  options, prefix + 'nT', 'labels', ['Bx','By','Bz']
  options, prefix + 'nT', 'ytitle', strupcase(short_prefix)
  options, prefix + 'nT', 'ysubtitle', '[nT]'
  options, prefix + 'nT', 'max_points', 40000l
  options, prefix + 'nT', 'datagap', 60d

  options, prefix + 'nT_mag', 'labels', ['|B|']
  options, prefix + 'nT_mag', 'ytitle', strupcase(short_prefix)
  options, prefix + 'nT_mag', 'ysubtitle', '[nT]'
  options, prefix + 'nT_mag', 'max_points', 40000l
  options, prefix + 'nT_mag', 'datagap', 60d

  ; Store the mag vector and the magnitude in a single tplot item with
  ; the name 'spp_fld_mago_survey' or 'spp_fld_magi_survey'

  store_data, strmid(prefix,0,strlen(prefix)-1), data = prefix + ['nT', 'nT_mag']

  options, strmid(prefix,0,strlen(prefix)-1), 'panel_size', 2

end
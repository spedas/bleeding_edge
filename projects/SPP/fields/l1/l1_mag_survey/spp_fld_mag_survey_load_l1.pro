;
;  $LastChangedBy: pulupalap $
;  $LastChangedDate: 2018-09-06 09:47:57 -0700 (Thu, 06 Sep 2018) $
;  $LastChangedRevision: 25739 $
;  $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/fields/l1/l1_mag_survey/spp_fld_mag_survey_load_l1.pro $
;

pro spp_fld_mag_survey_load_l1, file, prefix = prefix

  if not keyword_set(file) then begin
    print, 'file must be specified'
    return
  endif

  cdf2tplot, file, prefix = prefix

  if not keyword_set(prefix) then prefix = ''

  mag_string_index = prefix.IndexOf('mag')

  if mag_string_index GE 0 then begin
    short_prefix = prefix.Substring(mag_string_index, mag_string_index+3)
  endif else begin
    short_prefix = ''
  endelse

  ;store_data, prefix + 'mag_bx', newname = prefix + 'mag_bx_2d'
  ;store_data, prefix + 'mag_by', newname = prefix + 'mag_by_2d'
  ;store_data, prefix + 'mag_bz', newname = prefix + 'mag_bz_2d'

  get_data, prefix + 'avg_period_raw', data = d_ppp
  get_data, prefix + 'range_bits', data = d_range_bits


  if tnames(prefix + 'avg_period_raw') EQ '' then return

  times_2d = d_ppp.x

  times_1d = list()
  range_bits_1d = list()
  packet_index = list()

  foreach time, times_2d, ind do begin

    dprint, ind, n_elements(times_2d), dwait = 5

    ppp = d_ppp.y[ind]

    navg = 2l^ppp

    ; If the number of averages is less than 16, then
    ; there are 512 vectors in the packet.  Otherwise, there
    ; are fewer (See FIELDS CTM)

    if navg LT 16 then begin
      nvec = 512l
      nseconds = 2l * navg
    endif else begin
      nvec = 512l / 2l^(ppp-3)
      nseconds = 16l
    endelse

    ; rate = Vectors per NYS

    rate = 512l / (2l^(ppp+1))

    ; (2.^25 / 38.4d6) is the FIELDS NYS
    ; 512 vectors with no averaging yields 256 vectors
    ; per NYS

    timedelta = dindgen(nvec) / rate * (2.^25/38.4e6)

    times_1d.Add, list(time + timedelta, /extract), /extract

    packet_index.Add, dindgen(nvec), /extract

    ; There are 2 range bits per second, left justified
    ; in a 32 bit range_bit item.  Depending on the averaging
    ; period, there can be 2, 4, 8, or 16 seconds worth of data
    ; in the packet, yielding 4, 8, 16, or 32 range bits.
    ; The data item is always 32 bits long.  If there are fewer than
    ; 32 range bits required for the length of the packet,
    ; the first 2 * (# of seconds) bits are used and the
    ; remainder are zero filled.

    range_bits_i = d_range_bits.y[ind]

    range_bits_str = string(range_bits_i, format = '(b032)')

    ;if range_bits_str NE '01010000000000000000000000000000' then stop

    range_bits_list = list()

    for j = 0, nseconds - 1 do begin

      range_bits_int_j = 0

      range_bits_str_j = strmid(range_bits_str, j * 2, 2)

      reads, range_bits_str_j, range_bits_int_j, format = '(B)'

      range_bits_arr_j = lonarr(rate) + range_bits_int_j

      range_bits_list.Add, range_bits_arr_j, /extract

    end

    range_bits_1d.Add, range_bits_list, /extract

  endforeach

  ; Nominal scale factor (nT / count) for ranges 0-3

  nt_adu = [0.03125,0.1250,0.5,2.0]

  store_data, prefix + 'packet_index', $
    data = {x:times_1d.ToArray(), y:packet_index.ToArray()}

  store_data, prefix + 'range', $
    data = {x:times_1d.ToArray(), y:range_bits_1d.ToArray()}

  scale_factor = nt_adu[range_bits_1d.ToArray()]

  mag_comps = ['mag_bx', 'mag_by', 'mag_bz']

  foreach mag_comp, mag_comps do begin

    get_data, prefix + mag_comp + '_2d', data = d_b_2d

    b_1d = reform(transpose(d_b_2d.y), n_elements(d_b_2d.y))

    b_1d_finite = where(finite(b_1d) and (b_1d GT -2147483648), finite_count)

    if finite_count GT 0 then begin

      b_1d = b_1d[b_1d_finite]

      store_data, prefix + mag_comp, data = {x:times_1d.ToArray(), y:b_1d}

      store_data, prefix + mag_comp + '_nT', data = {x:times_1d.ToArray(), y:b_1d * scale_factor}

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

  store_data, prefix + 'nT', data = {x:d_x.x, y:[[d_x.y],[d_y.y],[d_z.y]]}

  store_data, prefix + 'nT_mag', data = {x:d_x.x, y:sqrt(d_x.y^2+d_y.y^2+d_z.y^2)}


  options, prefix + 'range', 'yrange', [-0.5,3.5]
  options, prefix + 'range', 'ytitle', short_prefix + '!Crange'
  options, prefix + 'range', 'yminor', 1
  options, prefix + 'range', 'ystyle', 1
  options, prefix + 'range', 'yticks', 3
  options, prefix + 'range', 'ytickv', [0,1,2,3]  
  ;options, prefix + 'range', 'psym', 3
  options, prefix + 'range', 'psym_lim', 200
  options, prefix + 'range', 'max_points', 40000l
  options, prefix + 'range', 'ysubtitle', ''
  options, prefix + 'range', 'panel_size', 0.75


  options, prefix + 'avg_period_raw', 'ytitle', short_prefix + '!CAvPR'
  options, prefix + 'avg_period_raw', 'ysubtitle'
  options, prefix + 'avg_period_raw', 'yrange', [-1.0,8.0]
  options, prefix + 'avg_period_raw', 'ystyle', 1
  options, prefix + 'avg_period_raw', 'yminor', 1
  options, prefix + 'avg_period_raw', 'yticks', 7
  options, prefix + 'avg_period_raw', 'ytickv', [0,1,2,3,4,5,6,7]
  options, prefix + 'avg_period_raw', 'psym', 4
  options, prefix + 'avg_period_raw', 'ysubtitle', ''
  options, prefix + 'avg_period_raw', 'panel_size', 0.75


  options, prefix + 'packet_index', 'ytitle', $
    short_prefix + '!Cpkt_ind'
  ;options, prefix + 'packet_index', 'psym', 3
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

  store_data, strmid(prefix,0,strlen(prefix)-1), data = prefix + ['nT', 'nT_mag']

  options, strmid(prefix,0,strlen(prefix)-1), 'panel_size', 2

end
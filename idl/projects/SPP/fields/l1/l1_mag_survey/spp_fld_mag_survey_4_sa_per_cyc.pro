;+
;
; spp_fld_mag_survey_4_sa_per_cyc downsamples high cadence FIELDS MAG
; Level 1 data to a rate of 4 Sa/cycle (aka 4 Sa/NYS).
;
; The downsampling is performed using a simplified triangle filter, similar
; to the filter used for onboard downsampling.
;
; Level 1 data which is already at 2 Sa/cycle or 4 Sa/cycle is left
; unchanged.
;
; $LastChangedBy: pulupalap $
; $LastChangedDate: 2025-04-22 14:32:54 -0700 (Tue, 22 Apr 2025) $
; $LastChangedRevision: 33271 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/fields/l1/l1_mag_survey/spp_fld_mag_survey_4_sa_per_cyc.pro $
;-

pro spp_fld_mag_survey_4_sa_per_cyc, ppp, vectors, pkt_t, $
  rate_arr, indices, range_bits, $
  times_1d = times_1d, b_1d = b_1d, $
  packet_index = packet_index, $
  rate_1d = rate_1d, range_1d = range_1d
  compile_opt idl2

  ;
  ; The parameter stored in metadata as 'ppp' defines the rate of MAG data
  ; in a given MAG packet, ranging from 0: full cadence to 7: 2 Sa/cycle.
  ;
  ; Packets at high sampling rates contain 512 vectors. At lower sampling
  ; rates, a packet is produced every 16 cycles, so those packets can contain
  ; fewer than 512 samples.
  ;
  ; ppp   # full cadence samples   Sample rate       Vectors      Cycles
  ; .     per sample in packet     vectors / cycle   per packet   per packet
  ;
  ; 0         1                      256              512          2
  ; 1         2                      128              512          4
  ; 2         4                       64              512          8
  ; 3         8                       32              512         16
  ; 4        16                       16              256         16
  ; 5        32                        8              128         16
  ; 6        64                        4               64         16
  ; 7       128                        2               32         16

  ; To get to 4 samples per NYS, most sampling rates must be downsampled.
  ; The number of downsampled vectors varies with different values of 'ppp'.
  ;
  ; ppp       downsampled        full cadence vectors (rbits)   t0**      dt***
  ; .         vectors in packet  per downsampled vector
  ; 0          8                     64                        31.5      64
  ; 1         16                     32                        15.5      64
  ; 2         32                     16                         7.5      64
  ; 3         64                      8                         3.5      64
  ; 4         64                      4                         1.5      64
  ; 5         64                      2                         0.5      64
  ; 6*        64                      N/A                       N/A      64
  ; 7*        32                      N/A                       N/A     128
  ;
  ; *: no downsampling for ppp = 6 or 7, which are already at low cadence
  ;
  ; **: 't0' is the time from the start of the triangle filtered data to
  ; the midpoint of the triangle filter. However, the time shift is not
  ; applied in this routine. In FIELDS Level 2 MAG production, this
  ; shift is applied via a convolution kernel.
  ;
  ; ***: 'dt' is delta time for the downsampled data, in units of the maximum
  ; MAG cadence of 256 Sa/cycle (so dt = 64 is 4 Sa/cycle)
  ;

  ; Maximum cadence of FIELDS fluxgate MAG data

  dt_full = 2d ^ 17 / 38.4d6

  if n_elements(vectors) eq 0 then vectors = dindgen(512)

  ; See above table

  ds_vec_all = [8, 16, 32, 64, 64, 64, 64, 32]
  n_tri_all = [64, 32, 16, 8, 4, 2, 0, 0]
  t0_all = [31.5d, 15.5d, 07.5d, 03.5d, 01.5d, 00.5d, 00.0d, 00.0d]
  dt_all = [64, 64, 64, 64, 64, 64, 64, 128]
  sec_all = [2, 4, 8, 16, 16, 16, 16, 16]

  ; List of times

  t_all = list()

  ; List of data

  d_all = list()

  ; List of packet index

  pi_all = list()

  ; List of rates

  rt_all = list()

  ; List of ranges

  rb_all = list()

  ; Apply triangle filter on a packet-by-packet basis

  for pkt = 0, n_elements(ppp) - 1 do begin
    DPRINT, pkt, dwait = 5d

    p = fix(ppp[pkt])

    sec = sec_all[p]

    t0 = t0_all[p] ; * 0d ; zeroed out here because we apply correction later

    ; number of vectors in downsampled packet

    ds_vec = ds_vec_all[p]

    ; number of points in triangle filter

    n_tri = n_tri_all[p]

    ; delta time for downsampled data (in units of full cadence dt)

    dt = dt_all[p]

    ; time in seconds for downsampled vectors

    t = (t0 + dt * dindgen(ds_vec)) * dt_full + pkt_t[pkt]

    ; Apply triangle filter if needed

    if n_tri gt 0 then begin
      ; triangle filter coeffs

      tri0 = [dindgen(n_tri / 2) + 1, reverse(dindgen(n_tri / 2) + 1)]

      ; normalize triangle filter

      tri = tri0 / total(tri0)

      ; apply the triangle filter ds_vec times to data in the packet

      ds = fltarr(ds_vec)

      for i = 0, ds_vec - 1 do begin
        ind = [i * n_tri, (i + 1) * n_tri - 1]

        vec_i = vectors[pkt, ind[0] : ind[1]]

        ; saturated data

        if max(vec_i) ge 32767 then begin
          ds[i] = !values.f_nan
        endif else if (min(vec_i) le -32767) then begin
          ds[i] = !values.f_nan
          ; stop
        endif else begin
          ds[i] = total(vec_i * tri)
        endelse
      endfor
    endif else begin
      ; case with no downsampling

      ds = vectors[pkt, 0 : (ds_vec - 1)]
    endelse

    ;
    ; Check the range bits for range information
    ; if range_bits = 0, then the packet contains only data from range = 0
    ; (always the case for on orbit PSP data as of 2020 March)
    ;
    ; If range is mixed, then don't include the data (code currently can't
    ; average data from different ranges together).
    ;

    rb = range_bits[pkt]

    rb_sec = rb / reverse(2l ^ (lindgen(16) * 2)) mod 4

    rb_sec = rb_sec[0 : sec - 1]

    ; if n_tri gt 0 then rb_vec = rebin(rb_sec, n_elements(ds), /sample) else $
    ; rb_vec = rb_sec ; [0]

    rb_vec = rebin(rb_sec, n_elements(ds), /sample)

    ; special case, where we have a 2 second packet and ranges are all
    ; ones or all zero

    if (min(rb_vec) eq max(rb_vec)) then begin
      ;
      ; Add triangle filtered data to lists
      ;

      t_all.add, t, /extract
      d_all.add, ds, /extract
      pi_all.add, lindgen(n_elements(ds)), /extract
      rt_all.add, lonarr(n_elements(ds)) + min([4, 2 ^ (8 - p)]), /extract
      rb_all.add, lonarr(n_elements(ds)) + rb_sec[0], /extract
    endif else begin
      ; stop

      t_all.add, t, /extract
      d_all.add, ds, /extract
      ; d_all.Add, fltarr(n_elements(ds)) + 32768, /extract
      pi_all.add, lindgen(n_elements(ds)), /extract
      rt_all.add, lonarr(n_elements(ds)) + min([4, 2 ^ (8 - p)]), /extract
      ; rb_all.Add, lonarr(n_elements(ds)), /extract
      rb_all.add, rb_vec, /extract

      if n_elements(ds) ne n_elements(rb_vec) then stop
    endelse

    ; if max(rb_vec) - min(rb_vec) gt 1 then stop

    ; if t[-1] gt 1743230824.9796770 then stop

    ; if n_elements(rb_all) NE n_elements(d_all) then stop
  end

  ;
  ; Return triangle filtered data in array form
  ;

  times_1d = t_all.toArray()
  b_1d = d_all.toArray()
  packet_index = pi_all.toArray()
  rate_1d = rt_all.toArray()
  range_1d = rb_all.toArray()
end

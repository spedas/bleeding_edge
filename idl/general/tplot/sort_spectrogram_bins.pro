;+
; NAME:
;   sort_spectrogram_bins
;
; PURPOSE:
;   Sort spectrogram bin centers into monotonically increasing order and
;   apply the same permutation to the spectrogram values.
;
; CALLING SEQUENCE:
;   sort_spectrogram_bins, y_in, z_in, y_out, z_out
;
; INPUTS:
;   y_in:
;     Either an M-element vector of time-independent bin centers or an
;     N-by-M array of time-dependent bin centers.
;
;   z_in:
;     N-by-M array of spectrogram values. The second dimension must
;     correspond to the bins in y_in.
;
; OUTPUTS:
;   y_out:
;     Copy of y_in with each bin-center vector sorted in increasing order.
;
;   z_out:
;     Copy of z_in with the bin dimension permuted to match y_out.
;
; NOTES:
;   - The input arrays are not modified.
;   - For a one-dimensional y_in, one permutation is applied at all times.
;   - For a two-dimensional y_in, each time row is sorted independently.
;   - IDL's SORT places NaN values after finite values. The associated
;     z_in entries are moved with those NaNs.
;   - Equal finite bin centers are permitted. SORT does not guarantee the
;     relative order of equal values, but every y/z pair remains together.
;   - The caller must validate the input ranks and dimensions. Behavior is
;     undefined for incompatible inputs or higher-rank arrays.
;
; EXAMPLE:
;   y = [30., 10., 20.]
;   z = REFORM([300., 30., 100., 10., 200., 20.], 2, 3)
;   sort_spectrogram_bins, y, z, ys, zs
;-
PRO sort_spectrogram_bins, y_in, z_in, y_out, z_out

  COMPILE_OPT idl2

  y_ndim = SIZE(y_in, /N_DIMENSIONS)

  IF y_ndim EQ 1 THEN BEGIN
    order = SORT(y_in)
    y_out = y_in[order]
    z_out = z_in[*, order]
  ENDIF ELSE BEGIN
    y_dims = SIZE(y_in, /DIMENSIONS)

    y_out = y_in
    z_out = z_in

    FOR time_index = 0L, y_dims[0] - 1L DO BEGIN
      order = SORT(REFORM(y_in[time_index, *]))
      y_out[time_index, *] = y_in[time_index, order]
      z_out[time_index, *] = z_in[time_index, order]
    ENDFOR
  ENDELSE

END
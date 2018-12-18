;
; NAME:
;
;   SPP_FLD_RFS_FLOAT
;
; DESCRIPTION:
;
;   The 64 bit values of onboard RFS spectra are compressed to
;   16 bit floating point values for telemetry.  The specifications
;   of the bits for exponent, mantissa, and sign (cross spectra only)
;   as well as example calculations are in the documents
;
;   SPF_FSW_908_RFS_Calcs.xlsx
;   SPF_FSW_912_RFS_HFR_Verification.xlsx
;
;   This program is an IDL version of the calculation which decompresses
;   those values.
;
;   Input can be integers (long or long longs also OK), a string
;   with an integer value, a four character hex string (e.g. '2D73x'),
;   or a sixteen bit binary string (e.g. '0010110101110011b').
;
;   Input can be an array, but the input array has to all be the
;   same type (e.g., all integers or all hex strings).
;
;   Input must be within the range of 0 to 2^16 - 1.  Out of range
;   inputs will return a value of -1.0D30.
;
;   Output is an array of the same dimensions as the input,
;   containing the double precision uncompressed RFS quantities.
;   
;   Typical compression errors are less than 0.1%.
;
; KEYWORDS:
;
;   CROSS: Use the signed cross spectra calculation instead of the
;     unsigned auto spectra calculation.
;
;   VERBOSE: Show detailed output of the input in various formats,
;     the sign, exponent, and mantissa.
;
;   BIGINTS: If this keyword is set to a variable, then a list of
;     IDL BigInteger values is returned.  The calculated values for the
;     RFS floating point calculation can overflow a 64 bit integer, so if
;     the exact (non-double-precision) values are necessary, they can
;     be returned with this keyword.
;
;     BigIntegers don't work with array-based operations, so use of this
;     keyword will make the program run much more slowly.
;
;     This keyword also only currently works with scalar or vector inputs.
;
; EXAMPLES:
;
;   A single value:
;
;   IDL> print, spp_fld_rfs_float(11635, /verbose)
;   IDL> print, spp_fld_rfs_float('0x2D73')
;
;   Both should return an exponent of 11, a mantissa of 371, and
;   a return of 1428480.
;
;   Calculate all valid inputs for auto and cross product compressed values:
;
;   IDL> rfs_comp = lindgen(2l^16)
;   IDL> rfs_auto_decomp = spp_fld_rfs_float(rfs_comp, bigints = rfs_auto_big)
;   IDL> rfs_cros_decomp = spp_fld_rfs_float(rfs_comp, bigints = rfs_cros_big, /cross)
;
;   IDL> rfs_auto_decomp = spp_fld_rfs_float(rfs_comp)
;   IDL> rfs_cros_decomp = spp_fld_rfs_float(rfs_comp, /cross)
;
;   The calculations should produce the same result, but the ones without
;   the bigints will be much faster.
;
;   Plot results:
;
;   IDL> plot, rfs_comp, rfs_auto_decomp, /ylog, yrange = [1.,1.e25], psym = 3
;   IDL> oplot, rfs_comp, rfs_cros_decomp, psym = 3, col = 2
;   IDL> oplot, rfs_comp, -rfs_cros_decomp, psym = 3, col = 6
;
;   The plots should show the floating point variables which correspond
;   to all valid 16 bit inputs.
;
; HISTORY:
;
;   Initial version Spring 2016 by MPP
;   Commented and cleaned up August 2016 by MPP
;

function spp_fld_rfs_float, rfs_input, $
  cross = cross, $
  verbose = verbose, $
  bigints = bigints

  ; Convert all input types to IDL long integers

  n_in = size(rfs_input,/dim)
  if n_in[0] EQ 0 then n_in = n_elements(rfs_input) ; for scalar
  
  rfs_in_long = size(rfs_input,/n_elem) ? 0ll : lonarr(n_in)

  if data_type(rfs_input) EQ 7 then begin

    rfs_input = rfs_input.ToLower( )

    if rfs_input[0].Contains('x') then begin

      in_format = 'Hex'
      reads, rfs_input, rfs_in_long, format = '(z)'

    endif else if rfs_input[0].Contains('b') then begin

      in_format = 'Bin'
      reads, rfs_input, rfs_in_long, format = '(b)'

    endif else begin

      in_format = 'Int'
      reads, rfs_input, rfs_in_long, format = '(i)'

    endelse

  endif else begin

    in_format = 'Int'
    rfs_in_long = long(rfs_input)

  endelse

  ; The calculations for the auto and cross are nearly identical,
  ; the only differences are:
  ;  - the powers of 2 which go into the mod and div functions
  ;  - the cross has a sign calculation (here, we set EXP_MOD as a
  ;    value higher than any possible input value, so the sign
  ;    always ends up as positive
  ;  - the cross product is multiplied by 2 at the end

  if not keyword_set(cross) then begin

    exp_mod = 2ll^17
    exp_div = 2ll^10
    man_mod = 2ll^10
    res_factor = 1ll
    man_add = 2ll^10

  endif else begin

    exp_mod = 2ll^15
    exp_div = 2ll^9
    man_mod = 2ll^9
    res_factor = 2ll
    man_add = 2ll^9

  endelse

  ; Calculate the sign, exponent, and mantissa from the input RFS_FLOAT

  sign_arr = ((rfs_in_long/exp_mod GE 1ll) * (-2)) + 1
  exp_int = (rfs_in_long MOD exp_mod) / exp_div
  man_int = rfs_in_long MOD man_mod

  ; For both auto and cross, there is a special case for exponent = 0.

  ; If bigints keyword is present, then calculate using the IDL
  ; BigInteger class.  If not, use (much faster) array operations.

  if arg_present(bigints) then begin

    bigints = LIST()

    for i = 0, n_in[0] - 1 do begin

      if exp_int[i] EQ 0 then begin

        bigints.Add, sign_arr[i] * res_factor * BigInteger(man_int[i])

      endif else begin

        bigints.Add, sign_arr[i] * res_factor * $
          (BigInteger(man_int[i]) + man_add) * $
          (2ll^(BigInteger(exp_int[i] - 1ll)))

      endelse

    end

    if n_in EQ 1 then result = bigints[0].ToDouble()

    result_list = bigints.Map(Lambda(x:x.ToDouble()))

    result = result_list.ToArray()

  endif else begin

    result = dblarr(n_in)

    exp_zero_ind = where(exp_int EQ 0ll, n_exp_zero, $
      complement = exp_nonz_ind, ncomplement = n_exp_nonz)

    if n_exp_zero GT 0ll then begin

      result[exp_zero_ind] = $
        sign_arr[exp_zero_ind] * res_factor * DOUBLE(man_int[exp_zero_ind])

    end

    if n_exp_nonz GT 0ll then begin

      result[exp_nonz_ind] = $
        sign_arr[exp_nonz_ind] * res_factor * $
        (man_int[exp_nonz_ind] + man_add) * $
        DOUBLE(2ll^(exp_int[exp_nonz_ind] - 1ll))

    end

  end

  ; Eliminate invalid input results and return an array of double precision
  ; values.

  rfs_in_invalid = where(rfs_in_long LT 0 or rfs_in_long GE 2ll^16-2, $
    rfs_in_invalid_count)

  if rfs_in_invalid_count GT 0 then begin

    exp_int[rfs_in_invalid] = -2ll^63
    man_int[rfs_in_invalid] = -2ll^63
    result[rfs_in_invalid] = !values.d_nan ; -1.0d30

    if n_elements(bigints) GT 0 then begin

      for i = 0, rfs_in_invalid_count - 1 do begin

        bigints[i] = -BigInteger(10)^30

      endfor

    endif

  endif

  ; Print results if requested.

  if keyword_set(verbose) then begin

    for i = 0, n_elements(rfs_input)-1 do begin

      print, ''
      print, '  RFS_FLOAT output for element' + $
        strcompress(string(i, format = '(I10)')) + ':'
      print, 'RFS float type:', keyword_set(cross) ? 'Cross' : 'Auto', $
        format = '(A20, A30)'
      print, 'Input format:', in_format, format = '(A20, A30)'
      print, 'as string:', rfs_input[i], $
        format ='(A20, ' + string(n_in) + '(A30))'

      if rfs_in_long[i] GE 0 AND rfs_in_long[i] LT 2l^16 then begin

        print, 'as long:', rfs_in_long[i], format = '(A20, I30)'
        print, 'as binary:', string(rfs_in_long[i], format = '(B016)'), $
          format = '(A20, A30)'
        print, 'as hex:', string(rfs_in_long[i], format = '(Z04)'), $
          format = '(A20, A30)'
        print, ''
        print, 'Sign:', (result[i] GE 0) ? '+' : '-', format = '(A20, A30)'
        print, 'Exponent as long:', exp_int[i], format = '(A20, I30)'
        print, 'Mantissa as long:', man_int[i], format = '(A20, I30)'
        if arg_present(bigints) then $
          print, 'Result as BigInt:', bigints[i].ToString(), $
          format = '(A20, A30)'
        print, 'Result as double:', result[i], format = '(A20, E30.7)'

      endif else begin

        print, '  Invalid input (out of range, valid input range is 0 - 2^16-1)'

      endelse

      print, ''

    end

  end

  return, result

end
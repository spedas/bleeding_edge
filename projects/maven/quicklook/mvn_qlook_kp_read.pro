;+
;NAME:
; mvn_qlook_kp_read
;PURPOSE:
; Reads a MAVEN KP text file,returns an array of values
;CALLING SEQUENCE:
; otp_array = mvn_qlook_kp_read(filename, time_array, column_ids, $
;             tplot = tplot, tvars = tvars)
;INPUT:
; filename = the input filename
;OUTPUT:
; otp_array =  an array of data pointers
; time_array = a time array for the values
; col_quantity = the quantity in the appropriate column
; col_source = the source instrument
; col_units = units
; col_fmt = the format code of the original quantity
; header = a string array of the header lines
;HISTORY:
; 18-sep-2015, jmm, jimm@ssl.berkeley.edu
; 25-sep-2015, jmm, Moved tplot variable stuff to mvn_qlook_load_kp.pro
;$LastChangedBy: jimm $
;$LastChangedDate: 2015-09-25 13:57:25 -0700 (Fri, 25 Sep 2015) $
;$LastChangedRevision: 18937 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/quicklook/mvn_qlook_kp_read.pro $
;-
Function mvn_qlook_kp_read, filename, time_array, col_quantity, col_source, $
                            col_units, col_fmt, col_ids_arr = col_ids_arr, $
                            _extra = _extra

  mvn_qlook_init

;Initialize output
  otp = -1
  time_array = -1
  column_ids = -1

;Get file
  filex = file_search(filename)
  If(~is_string(filex)) Then Begin
     dprint, 'File not found: '+filename
     Return, otp
  Endif

;Read the file
  ll = file_lines(filex)
  all_lines = strarr(ll)
  openr, unit, filex, /get_lun
  readf, unit, all_lines
  ss_h = where(strmid(all_lines, 0, 1) Eq '#', nssh)
  header = all_lines(ss_h)

;Search in the header for the number of columns, rows and the format
  ncol = -1 & nrow = -1 & fmt = -1
  For j = 0L, nssh-1 Do Begin
     pc = strpos(header[j], 'Number of parameter columns')
     If(pc[0] Ne -1) Then Begin
        temp = strsplit(header[j], ' ', /extract)
        ncol = long(temp[1])
     Endif
     pr = strpos(header[j], 'Number of lines (rows)')
     If(pr[0] Ne -1) Then Begin
        temp = strsplit(header[j], ' ', /extract)
        nrow = long(temp[1])
     Endif
     pf =  strpos(header[j], 'Format codes (IDL/Fortran)')
     If(pf[0] Ne -1) Then Begin
        temp = strsplit(header[j+1], ' ', /extract)
        fmt = strjoin(temp[1:*])
     Endif
  Endfor

  If(ncol Eq -1) Then Begin
     dprint, 'Bad column number'
     Return, otp
  Endif
  If(nrow Eq -1) Then Begin
     dprint, 'Bad row number'
     Return, otp
  Endif
  If(~is_string(fmt)) Then Begin
     dprint, 'Bad format'
     Return, otp
  Endif

;temp1 is used to find where the column descriptions start
  temp1 = ['#', strcompress(indgen(ncol)+1, /remove_all)]
  pt = -1
  For j = nssh-1, 0L, -1 Do Begin
     temp = strsplit(header[j], ' ', /extract)
     If(array_equal(temp1, temp)) Then Begin
        pt = j
        break
     Endif
  Endfor

  If(pt Eq -1) Then Begin
     dprint, 'Bad column line'
  Endif

;Extract column ids:
  hdr2col = header[pt:*]
  nrow_col_ids = n_elements(hdr2col)
  col_ids_arr = strarr(ncol, nrow_col_ids)
  For j = 0, nrow_col_ids-1 Do Begin
     temp = hdr2col[j]
     For k = 0, ncol-1 Do col_ids_arr[k, j] = strmid(temp, 3+16*k, 16)
  Endfor
  col_quantity = strarr(ncol)
  For k = 0, ncol-1 Do Begin
     temp = reform(strtrim(col_ids_arr[k, *], 2))
     col_quantity[k] = strjoin(temp[1:3], ' ')
  Endfor
  col_source = reform(strcompress(col_ids_arr[*, 4], /remove_all))
  col_units = reform(strtrim(col_ids_arr[*, 5], 2))
  col_fmt = reform(strtrim(col_ids_arr[*, 6], 2))
;For the time variable
  col_fmt[0] = 'A19'

;Oh, how about the data?
  data = temporary(all_lines)   ;maybe this'll help with memory
  data = data[nssh:*]
  ndata = n_elements(data)
  data_arr = strarr(ncol, ndata)
  For j = 0L, ndata-1 Do Begin
     temp = strsplit(data[j], ' ', /extract)
     data_arr[*, j] = temp
  Endfor

;Output is an array of pointers
  time_array = time_double(reform(data_arr[0, *]))
  otp = ptrarr(ncol)
  For k = 0, ncol-1 Do Begin ;keep string values for strings, use format for others
     x = strupcase(strcompress(col_fmt[k], /remove_all))
     x = strmid(x, 0, 1)
     If(x Eq 'E' Or x Eq 'F') Then Begin
        temp = reform(float(data_arr[k, *]))
        otp[k] = ptr_new(temp)
     Endif Else If(x Eq 'I') Then Begin
        temp = reform(long(data_arr[k, *]))
        otp[k] = ptr_new(temp)
     Endif Else Begin
        temp = reform(data_arr[k, *])
        otp[k] = ptr_new(temp)
     Endelse
  Endfor

;there's a typo
  If(col_quantity[205] Eq 'APP Attitude GEO X') Then Begin
     col_quantity[205] = 'APP Attitude GEO Z'
     col_ids_arr[205, 3] = 'GEO Z'
  Endif

  Return, otp
End

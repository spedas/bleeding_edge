Pro dummy_var, inp
  e = 3.0                       ;any statement will do here
  return
End
;+
;NAME:
;       string_parser
;PURPOSE:
;       Parse strings into components
;CALLING SEQUENCE:
;       string_parser, inpx, parse_by, out, output_count
;INPUT:
;       inpx     strings to parse
;       parse_by        character to parse by
;OUTPUT:
;       out     array of substrings
;       output_count    number of substrings
;HISTORY:
;       Updated 22-April-1993 by Terry Slocum
;       Fixed output_count bug, 28-mar-94, JMM
;       Gave the ability to use a parse_by string of more than one
;       character, jmm 13-jun-2007
;-
pro string_parser,  inpx,  parse_by,  out,  output_count

  npb =  strlen(parse_by)
  IF(N_ELEMENTS(inpx) GE 1) THEN BEGIN
    out =  ''
    input_count =  N_ELEMENTS(inpx)

    FOR yy =  0,  input_count-1 DO BEGIN
      line =  inpx(yy)
      length =  STRLEN(line)
      i =  0
      WHILE (length GT 0) DO BEGIN
        first_p =  STRPOS(line,  parse_by,  i)
        IF (first_p EQ -1) THEN BEGIN
           out =  [out,  line]
          line =  ''
        ENDIF ELSE IF (first_p EQ 0) THEN BEGIN
          i =  0
          line =  STRMID(line,  npb,  length)
        ENDIF ELSE BEGIN
          xx =  STRMID(line,  i,  first_p - i)
          out =  [out,  xx]
          line =  STRMID(line,  first_p + npb,  length)
          i =  0
        ENDELSE
        length =  STRLEN(line)
      ENDWHILE
    ENDFOR

    IF (N_ELEMENTS(out) GT 1) THEN BEGIN
      out =  out(1:*)
      output_count =  n_elements(out)
    ENDIF
  ENDIF
END
;+
;NAME:
; code_fragment
;PURPOSE:
; takes a string, where input variables are defined as array_elements
; 'qq' and creates a set of tplot commands using those data
;CALLING SEQUENCE:
; code_fragment,  inp_string,  otp_string
;HISTORY:
; 13-jun-2007, jmm, jimm@ssl.berkeley.edu
;-
Pro code_fragment,  inp_string,  otp_string

;inp_string has "qq"
  otp_string =  ''
  bqq =  strpos(inp_string,  'qq')
  If(bqq[0] Eq -1) Then Return
  inpx =  strlowcase(strcompress(inp_string,  /remove_all))
  linp =  strlen(inpx)
  t1 =  strmid(inpx,  0,  2)
  If(t1 Eq 'qq') Then qq_at_start =  1b Else qq_at_start =  0b
  t1 = strmid(inpx,  linp-2,  linp)
  If(t1 Eq 'qq') Then qq_at_end =  1b Else qq_at_end =  0b

  string_parser,  inpx,  'qq',  code_fragments
  nqq =  n_elements(code_fragments)
  cfnew =  code_fragments
  For j =  0,  nqq -1 Do Begin
;Is there an array element there?
    testj =  strmid(code_fragments[j],  0,  1)
    If(testj[0] Eq '[') Then Begin ;find the closing ']'
      pj =  strsplit(code_fragments[j],  ']', /extract)
      npj =  n_elements(pj)
      If(npj Eq 2) Then Begin
        cfnew[j] =  pj[0]+'].y'+pj[1]
      Endif Else If(npj Eq 1) Then Begin
        cfnew[j] =  pj[0]+'].y'
      Endif Else message,  'bad values for pj'
      If(j Eq 0) Then Begin
        If(qq_at_start) Then cfnew[j] =  'qq'+cfnew[j]
      Endif Else cfnew[j] =  'qq'+cfnew[j]
    Endif Else Begin
      If(j Eq 0) Then Begin
        If(qq_at_start) Then cfnew[j] =  'qq.y'+cfnew[j]
      Endif Else cfnew[j] =  'qq.y'+cfnew[j]
    Endelse
    otp_string =  otp_string+cfnew[j]
  Endfor
  If(qq_at_end) Then otp_string =  otp_string+'qq.y'

  Return
End

;+
;NAME:
; tuserdef
;PURPOSE:
; Inputs a string expression that operates on a tplot variable, or an
; array of tplot variables, and returns the result. Note that this is
; a very experimental program.
;CALLING SEQUENCE:
; otp_var = tuserdef(inp_var, input_string)
;INPUT:
; inp_var = a tplot variable, or an array of tplot variable
;           names. Note that the time arrays of the variables need not
;           be the same, the program will handle that. But the Y
;           arrays of the variables must be the same, unless one is a
;           1d vector.
; input_string = an input string, where 'qq' represents the tplot
;                variable data to be operated on, 'qq' can look like
;                an array, each element of 'qq' is a separate tplot
;                variable. E.g., '2.0*qq[0]/qq[1]' will divide the
;                data for qq[0] by that for qq[1], and multiply by
;                2.0.
;OUTPUT:
; otp_var = an output tplot variable name, will be the null string if
;           the process fails
;KEYWORDS:
; otp_string = the string used for the 'execute' command
; success = the success value from the execute command, 1 good, 0 not
; out_varname = a name for the output variable, the default is
;               tuserdef_output
;EXAMPLES:
; For the absolute value of a variable:
; newvar = tuserdef(oldvar, 'abs(qq)')
; To divide a variable be the square root of another:
; newvar = tuserdef([oldvar1, oldvar2], 'qq[0]/sqrt(qq[1])'
; To compare THEMIS moment data:
; moment_ratio = tuserdef(['tha_peim_ptens', 'tha_peir_ptens'], 'qq[1]/qq[0]')
;HISTORY:
; 19-feb-2008, jmm, jimm@ssl.berkeley.edu
; 24-feb-2008, jmm, Allow replication of 1d y variables to n
;                   dimensions when multiple dimensions are passed in.
; 3-mar-2014, jmm, testing SVN mail
;+
Function tuserdef, inp_var, input_string, $
                   otp_string = otp_string, success = yyy, $
                   out_varname = out_varname, _extra = _extra

  otp_var = ''                  ;init
;first, get the code needed
  code_fragment, input_string, otp_string
;now get the data, note that the data structures will need to be
;consistent, since there are different time arrays, the time array of
;the first element in the array will be used.
  n = n_elements(inp_var)
  get_data, inp_var[0], data = qq, dlimits = dl
  If(is_struct(qq) Eq 0) Then Begin
    dprint, 'No data for: '+inp_var[0],dlevel=2
    ;message, 'No data for: '+inp_var[0],/info
    Return, otp_var
  Endif
  If(n Gt 1) Then Begin
    t = qq.x
    yp = qq.y & yp[*] = 0.0     ;temporary variable for type issues
    syp = size(yp)
    typ_p = size(yp, /type)
    If(tag_exist(qq, 'v')) Then Begin
      vp = qq.v
      yes_v = 1b
    Endif Else yes_v = 0b
;for each sub_array, use "data_cut" to get a new data structure, if
;necessary -- note that Y arrays aren't checked and incompatible y's
;             will bomb, unless Y is a 1d vector, then we replicate
    For j = 1, n-1 Do Begin
      get_data, inp_var[j], data = d1
      If(is_struct(d1) Eq 0) Then Begin
        dprint, 'No data for: '+inp_var[j],dlevel=2
        ;message,/info,'No data for: '+inp_var[j]
        Return, otp_var
      Endif
      t1 = d1.x
      If(size(d1.y, /n_dim) Gt 1) Then Begin
        If(n_elements(d1.y[0, *, *, *]) Ne $
           n_elements(qq[0].y[0, *, *, *])) Then Begin
          dprint, 'Incompatible Y sizes: '+inp_var[j]+' and '+inp_var[0],dlevel=2
          ;message,/info, 'Incompatible Y sizes: '+inp_var[j]+' and '+inp_var[0]
          Return, otp_var
        Endif
;change type if necessary 
        If(size(d1.y, /type) Ne typ_p) Then Begin
          ytmp = make_array(dimen = size(d1.y, /dimen), type = typ_p)
          ytmp[*] = d1.y
          dummy_var, temporary(d1)
          d1 = {x:t1, y:ytmp}
        Endif
      Endif Else Begin          ;replicate the y variable if necessary
        If(syp[0] Eq 1) Then Begin
          ytmp = d1.y
        Endif Else If(syp[0] Eq 2) Then Begin
          ytmp = rebin(d1.y, syp[1], syp[2])
        Endif Else If(syp[0] Eq 3) Then Begin
          ytmp = rebin(d1.y, syp[1], syp[2], syp[3])
        Endif Else If(syp[0] Eq 4) Then Begin
          ytmp = rebin(d1.y, syp[1], syp[2], syp[3], syp[4])
        Endif Else Begin
          dprint, 'Unsupported Array size',dlevel=2
;          message, 'Unsupported Array size',/info
          Return, otp_var
        Endelse
        If(size(ytmp, /type) Ne typ_p) Then Begin ;change the type
          ytmp1 = make_array(dimen = size(ytmp, /dimen), type = typ_p)
          ytmp1[*] = temporary(ytmp)
          ytmp = temporary(ytmp1)
        Endif
        dummy_var, temporary(d1)
        d1 = {x:t1, y:ytmp}
      Endelse
      If(n_elements(t1) Ne n_elements(t) Or $
         max(abs(t1-t)) Gt 0.0) Then Begin
        d1 = data_cut(temporary(d1), t)
        If(is_struct(d1) Eq 0) Then Begin
          yp[*] = d1[*]
        Endif Else yp[*] = d1.y[*]
        If(yes_v) Then d1 = {x:t, y:yp, v:vp} $
        Else d1 = {x:t, y:yp}
      Endif Else Begin
        If(yes_v) Then str_element, d1, 'v', qq[0].v, /add_replace
      Endelse
      qq = [temporary(qq), temporary(d1)]
    Endfor
  Endif Else t = qq.x

  otp_string = 'y = '+otp_string
  yyy = execute(otp_string)

  If(yyy Gt 0) Then Begin       ;put this into a tplot variable
    If(keyword_set(out_varname)) Then otp_var = out_varname $
    Else otp_var = 'tuserdef_output'
    store_data, otp_var, data = {x:t, y:y}, dlimits = dl
  Endif Else otp_var = ''

  Return, otp_var
End

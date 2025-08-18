;+
;NAME:
; tdeflag
;PURPOSE:
; wapper for xdeflag.pro allowing input of tplot variable names
;CALLING SEQUENCE:
; tdeflag, varnames, method, newname = newname, $
;          overwrite = overwrite, _extra = _extra
;INPUT:
; varnames = an array (or scalar) of tplot variable names
; method = set to "remove_nan", this will remove any NaN (or infinite) values
;             from the data (potentially returning shortened or empty arrays)
;          set to "repeat", this will repeat the last good value.
;          set to "linear", then linear interpolation is used, but for
;          the edges, the closest value is used, there is no
;          extrapolation
;          set to "replace", this will replace the gap values with an
;          input variable, input via the keyword, "fillval"
;KEYWORDS:
; flag = all values greater than 0.98 times this value will be deflagged,
;        the default is 6.8792e28, Nan's, Inf's are also deflagged
; maxgap = the maximum number of rows that can be filled? the default
;           is n_elements(t)
; newname = if set, give these names to the deflagged data, the
;                default is to append '_deflag' to the input names and
;                pass out the names in the newname variables,
;                Unless /overwrite is set
; overwrite = if set, write the new data back to the old tplot
;             variables, do not set this with newname
; display_object = Object reference to be passed to dprint for output.
; fillval = a fill value for the "replace" option. THe default is zero.
;
;HISTORY:
; 2-feb-2007, jmm, jimm.ssl.berkeley.edu
;
;$LastChangedBy: jimm $
;$LastChangedDate: 2020-09-23 15:50:05 -0700 (Wed, 23 Sep 2020) $
;$LastChangedRevision: 29179 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/misc/tdeflag.pro $
;-

; tdeflag_remove_nan removes all NaN and infinite values
; no other operations are performed on the data
; dat is the input and output data structure
pro tdeflag_remove_nan, dat = dat, display_object = display_object
  if (~is_struct(dat)) then begin
    dprint, 'Input is not a structure. Nothing to do.', display_object = display_object
    return
  endif
  y = dat.y
  t0 = dat.x
  nrows = n_elements(t0)
  if (n_elements(y[*, 0]) ne nrows) Then Begin
    dprint, 'Number of rows does not agree between time and y array(s)', display_object = display_object
    Return
  Endif
  ndims = size(y, /dimensions)
  ncols = 0 & nlayers = 0
  if (n_elements(ndims) ge 2) then ncols = ndims[1]
  if (n_elements(ndims) eq 3) then nlayers = ndims[2]
  if (ncols eq 0) then nycols = 1 else nycols = ncols
  if (nlayers eq 0) then nylayers = 1 else nylayers = nlayers
  nycolayers = nycols*nylayers
  y = reform(y, nrows, nycolayers)
  
  ;find which elements are finite for every dimension
  finite_elements = make_array(nrows,  /integer, value = 1)
  for j = 0, nycolayers-1 do begin
    finite_elements[where(finite(y[*, j]) Eq 0)] = 0
  end
  
  t0 = t0[where(finite_elements eq 1)]
  new_nrows = n_elements(t0)
  if new_nrows le 0 then begin ;it is empty
    dat = 0 ;for empty array return 0 so that store_date routine will work correctly
    dprint, 'NaN values were removed. Empty array returned.', display_object = display_object
  endif else begin
    y0 = make_array(new_nrows, nycolayers)
    for j = 0, nycolayers-1 do begin
      y0[*, j] = y[where(finite_elements eq 1), j]
    endfor
    str_element, dat, 'x', t0, /ADD_REPLACE
    str_element, dat, 'y', y0, /ADD_REPLACE
    dprint, 'A total of ' + STRTRIM(string(nrows - new_nrows), 2) + ' NaN values were removed.', display_object = display_object
  endelse
end


Pro tdeflag, varnames, method, newname = newname, display_object = display_object, $
             overwrite = overwrite, fillval = fillval, _extra = _extra
  
  ;First extract the data
  n = n_elements(varnames)
  if (keyword_set(newname)) Then begin
    if (keyword_set(overwrite)) Then begin
      dprint, 'Do not set both the newname and overwrite keywords', display_object = display_object
      return
    Endif
    if (n_elements(newname) Ne n) Then Begin
      dprint, 'Incompatible varnames, newname input', display_object = display_object
      Return
    Endif
    nvn = newname
  Endif Else nvn = varnames+'_deflag'
  ;Now do the deflagging
  For j = 0, n-1 Do Begin
    get_data, varnames[j], data = d, dlim = dlim, lim = lim
    if (is_struct(d)) Then Begin
      if STRCMP(method, 'remove_nan', /FOLD_CASE) then begin
        tdeflag_remove_nan, dat=d, display_object = display_object
      endif else begin
        y = d.y
        xdeflag, method, d.x, y, display_object = display_object, fillval = fillval, _extra = _extra
        d.y = temporary(y)
      endelse
      
      if (keyword_set(overwrite)) Then new_name = varnames[j] $
      Else new_name = nvn[j]
      store_data, new_name, data = d, dlim = dlim, lim = lim
    Endif Else Begin
      dprint,'No Deflagging of: '+varnames[j], display_object = display_object
    Endelse
  Endfor
  newname = nvn
  Return
End


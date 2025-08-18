;+
; Procedure: bas_read_data
;
; Keywords:
;             filename:      full path name of the file
;             site:          name of the magnetometer station 
;             
; OUTPUT:
;   bas_data : a structure in the standard tplot variable format
;              ( data = {x:time, y:[H,D,Z]}
;
; EXAMPLE:
;    bas_data = bas_read_data(filename, site)
;    
; $LastChangedBy: clrussell $
; $LastChangedDate: 2017-02-13 15:32:14 -0800 (Mon, 13 Feb 2017) $
; $LastChangedRevision: 22769 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/bas/bas_load_data.pro $
;-

function bas_read_data, filename, site

  compile_opt idl2

  ; handle possible server errors
  catch, errstats
  if errstats ne 0 then begin
    dprint, dlevel=1, 'Error: ', !ERROR_STATE.MSG
    catch, /cancel
    return, -1
  endif

  ; initialize variables and parameters
  defsysv, '!bas', exists=exists
  if not(exists) then bas_init
  if ~keyword_set(filename) then begin
    print, 'You must enter a valid file name'
    return, -1
  endif
    
  ; get BAS data
  undefine, bas_data
  bas_data = READ_ASCII(filename)

  if ~undefined(bas_data) then begin
    year = transpose(strtrim(string(fix(bas_data.field01[2,*])),1))
    month = transpose(strtrim(string(fix(bas_data.field01[3,*])),1))
    idx = where(strlen(month) eq 1, ncnt)
    if ncnt GT 0 then month[idx]='0'+month[idx]
    day = transpose(strtrim(string(fix(bas_data.field01[4,*])),1))
    idx = where(strlen(day) eq 1, ncnt)
    if ncnt GT 0 then day[idx]='0'+day[idx]
    hr = transpose(strtrim(string(fix(bas_data.field01[5,*])),1))
    idx = where(strlen(hr) eq 1, ncnt)
    if ncnt GT 0 then hr[idx]='0'+hr[idx]
    min = transpose(strtrim(string(fix(bas_data.field01[6,*])),1))
    idx = where(strlen(min) eq 1, ncnt)
    if ncnt GT 0 then min[idx]='0'+min[idx]
    sec = transpose(strtrim(string(fix(bas_data.field01[7,*])),1))
    idx = where(strlen(sec) eq 1, ncnt)
    if ncnt GT 0 then sec[idx]='0'+sec[idx]
    h = transpose(bas_data.field01[10,*])
    d = transpose(bas_data.field01[11,*])
    z = transpose(bas_data.field01[12,*])
    time = time_double(year + '-' + month + '-' + day + '/' + hr + ':' + min + ':' + sec)
    bas_data={x:time, y:[[h],[d],[z]]}
  endif else begin
    bas_data=-1
    print, 'No data was found for file: ' + filename
    return, -1
  endelse
   
  return, bas_data
  
end
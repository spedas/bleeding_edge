; Routine to get diffB index for display in EVA
; flag = 1 for failure if there are less than 2 spacecraft and calculating diffB is impossible.

; The no_load keyword will bypass calling mms_sitl_get_dfg, however, it assumes that the user
; ran the code for all four spacecraft outside of the routine, and all appropriate tplot variables are stored.

;  $LastChangedBy: rickwilder $
;  $LastChangedDate: 2017-07-20 09:15:54 -0700 (Thu, 20 Jul 2017) $
;  $LastChangedRevision: 23676 $
;  $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/sitl/sitl_data_fetch/mms_sitl_diffb.pro $


pro mms_sitl_diffB, flag, no_load=no_load

flag = 0

mu0 = !pi*4e-7

times = timerange(/current)

if times(0) gt time_double('2016-09-15/00:00:00') then begin
  sep = 7d
endif else if times(0) gt time_double('2017-06-15/00:00:00') then begin
  sep = 15d
endif else begin
  sep = 10d
endelse

; Load the data

if ~keyword_set(no_load) then begin
  mms_sitl_get_dfg, sc_id = ['mms1', 'mms2', 'mms3', 'mms4']
endif

; Define variable names
dataname = '_dfg_srvy_dmpa' ; NEED TO CHANGE THIS FOR SITL
dataname_gse = '_dfg_srvy_gse'


names = ['mms1', 'mms2', 'mms3', 'mms4'] + dataname

; Names for conversion to GSE coordinates
DEC = '_ql_RADec_gse'

decnames = ['mms1', 'mms2', 'mms3', 'mms4'] + DEC

namesgse = ['mms1', 'mms2', 'mms3', 'mms4'] + dataname_gse

; Check to see how many s/c have valid data
ivalid = intarr(4)

for i = 0, 3 do begin
  get_data, names[i], data = d
  get_data, decnames[i], data = d2
  
  if ~is_struct(d) or ~is_struct(d2) then begin
    ivalid[i] = 0
  endif else begin
    ivalid[i] = 1
  endelse
endfor

; Check to see if there are at least two spacecraft.
valloc = where(ivalid eq 1, countvalid)

if countvalid lt 2 then begin
  print, 'NEED AT LEAST TWO SPACECRAFT FOR DIFFB. RETURNING!'
  flag = 1
  return
endif

; How to scale the result if there are less than four s/c
scale = 4d/countvalid

new_vals = valloc
lengths = lonarr(n_elements(valloc))

for i = 0, countvalid-1 do begin
  split_vec, decnames[valloc(i)]
  dsl2gse, names[valloc(i)], decnames[valloc(i)] + '_0', decnames[valloc(i)] + '_1', namesgse[valloc(i)], /ignore_dlimits

  get_data, namesgse[valloc(i)], data = blah
  lengths[i] = n_elements(blah.x)
endfor

maxlen = max(lengths, lidx)
best_sc_name = namesgse[valloc[lidx]]
best_sc_idx = valloc[lidx] + 1

; Now we have our reference time for interpolation
get_data, best_sc_name, data = best_b
tref = best_b.x

; Now fill spacecraft that aren't valid
badloc = where(ivalid eq 0, count_invalid)

if count_invalid gt 0 then begin
  for i = 0, count_invalid-1 do begin
    Bx = replicate(!values.f_nan, n_elements(tref))
    By = replicate(!values.f_nan, n_elements(tref))
    Bz = replicate(!values.f_nan, n_elements(tref))
    Bbad = [[Bx], [By], [Bz]]
    store_data, namesgse[badloc[i]], data = {x:tref, y:Bbad}
    
  endfor
endif

; Now interpolate everything.

case best_sc_idx of
  1: begin
    tinterpol, namesgse(1), namesgse(0), /overwrite, /nan_extrapolate
    tinterpol, namesgse(2), namesgse(0), /overwrite, /nan_extrapolate
    tinterpol, namesgse(3), namesgse(0), /overwrite, /nan_extrapolate
  end
  2: begin
    tinterpol, namesgse(0), namesgse(1), /overwrite, /nan_extrapolate
    tinterpol, namesgse(2), namesgse(1), /overwrite, /nan_extrapolate
    tinterpol, namesgse(3), namesgse(1), /overwrite, /nan_extrapolate
  end
  3: begin
    tinterpol, namesgse(0), namesgse(2), /overwrite, /nan_extrapolate
    tinterpol, namesgse(1), namesgse(2), /overwrite, /nan_extrapolate
    tinterpol, namesgse(3), namesgse(2), /overwrite, /nan_extrapolate
  end
  4: begin
    tinterpol, namesgse(0), namesgse(3), /overwrite, /nan_extrapolate
    tinterpol, namesgse(1), namesgse(3), /overwrite, /nan_extrapolate
    tinterpol, namesgse(2), namesgse(3), /overwrite, /nan_extrapolate
  end
  else: return
endcase

get_data, namesgse(0), data = d1
get_data, namesgse(1), data = d2
get_data, namesgse(2), data = d3
get_data, namesgse(3), data = d4

diffB = dblarr(n_elements(d1.x))

; Brute force to avoid a massive headache, even at the expense of the code being really slow
for i = 0, n_elements(d1.x)-1 do begin
  Bxs = [d1.y(i,0), d2.y(i,0), d3.y(i,0), d4.y(i,0)]
  Bys = [d1.y(i,1), d2.y(i,1), d3.y(i,1), d4.y(i,1)]
  Bzs = [d1.y(i,2), d2.y(i,2), d3.y(i,2), d4.y(i,2)]
  jvalid = [0, 0, 0, 0]
  
  goodloc = where(finite(Bxs), countgood)
  
  badloc = where(~finite(Bxs), countbad)
    
  if countbad gt 0 then begin
    Bxs[badloc] = 0
    Bys[badloc] = 0
    Bzs[badloc] = 0
  endif
  
  
  if countgood le 1 then begin
    diffB(i) = 0
  endif else begin
    jvalid[goodloc] = 1
    scale = 4d/countgood

    B1x = Bxs(0)
    B2x = Bxs(1)
    B3x = Bxs(2)
    B4x = Bxs(3)

    B1y = Bys(0)
    B2y = Bys(1)
    B3y = Bys(2)
    B4y = Bys(3)
    
    B1z = Bzs(0)
    B2z = Bzs(1)
    B3z = Bzs(2)
    B4z = Bzs(3)

    dBx12 = jvalid[0]*jvalid[1]*(b1x - b2x)^2
    dBx13 = jvalid[0]*jvalid[2]*(b1x - b3x)^2
    dBx14 = jvalid[0]*jvalid[3]*(b1x - b4x)^2
    dBx23 = jvalid[1]*jvalid[2]*(b2x - b3x)^2
    dBx24 = jvalid[1]*jvalid[3]*(b2x - b4x)^2
    dBx34 = jvalid[2]*jvalid[3]*(b3x - b4x)^2

    dBy12 = jvalid[0]*jvalid[1]*(b1y - b2y)^2
    dBy13 = jvalid[0]*jvalid[2]*(b1y - b3y)^2
    dBy14 = jvalid[0]*jvalid[3]*(b1y - b4y)^2
    dBy23 = jvalid[1]*jvalid[2]*(b2y - b3y)^2
    dBy24 = jvalid[1]*jvalid[3]*(b2y - b4y)^2
    dBy34 = jvalid[2]*jvalid[3]*(b3y - b4y)^2

    dBz12 = jvalid[0]*jvalid[1]*(b1z - b2z)^2
    dBz13 = jvalid[0]*jvalid[2]*(b1z - b3z)^2
    dBz14 = jvalid[0]*jvalid[3]*(b1z - b4z)^2
    dBz23 = jvalid[1]*jvalid[2]*(b2z - b3z)^2
    dBz24 = jvalid[1]*jvalid[3]*(b2z - b4z)^2
    dBz34 = jvalid[2]*jvalid[3]*(b3z - b4z)^2

    diffB(i) = scale*(dbx12 + dbx13 + dbx14 + dbx23 + dbx24 + dbx34 + $
      dby12 + dby13 + dby14 + dby23 + dby24 + dby34 + $
      dbz12 + dbz13 + dbz14 + dbz23 + dbz24 + dbz34)

  endelse
  
endfor


; Now calculate diffB - multiply by zero if spacecraft doesn't exist for one of the values  
diffB = sqrt(diffB)*1e-6/(2*sep*mu0)
  
store_data, 'mms_sitl_diffB', data = {x:tref, y:diffB}

options, 'mms_sitl_diffB', 'ytitle', 'diffB!cuA/m!U2!D'

end
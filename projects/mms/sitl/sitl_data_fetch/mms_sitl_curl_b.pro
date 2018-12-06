; Calculate curl of B for use in EVA/SITL.
; flag = 1 if inadequate spacecraft availability for the curlometer.
; 
;  $LastChangedBy: egrimes $
;  $LastChangedDate: 2018-12-05 10:32:31 -0800 (Wed, 05 Dec 2018) $
;  $LastChangedRevision: 26246 $
;  $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/sitl/sitl_data_fetch/mms_sitl_curl_b.pro $



pro mms_sitl_curl_b, flag, trange = trange, no_load = no_load

flag = 0

RE = 6378.137
mu0 = !pi*4e-7

if keyword_set(trange) then time = time_double(trange)

; Get B-field for all four SC

if ~keyword_set(no_load) then begin
  mms_sitl_get_dfg, sc_id = ['mms1', 'mms2', 'mms3', 'mms4']
endif

; Recombine all B
dataname = '_dfg_srvy_dmpa' ; NEED TO CHANGE THIS FOR SITL
dataname_gse = '_dfg_srvy_gse'
Name1 = 'mms1' + dataname
Name2 = 'mms2' + dataname
Name3 = 'mms3' + dataname
Name4 = 'mms4' + dataname

Name1gse = 'mms1' + dataname_gse
Name2gse = 'mms2' + dataname_gse
Name3gse = 'mms3' + dataname_gse
Name4gse = 'mms4' + dataname_gse

get_data, Name1, data=d1, dlim=blim
get_data, Name2, data=d2
get_data, Name3, data=d3
get_data, Name4, data=d4

; Check for existence of data
if ~is_struct(d1) or ~is_struct(d2) or ~is_struct(d3) or ~is_struct(d4) then begin
  print, 'MISSING BFIELD DATA FROM ONE OR MORE SPACECRAFT. NOT CALCULATING CURL B!'
  flag = 1
  return
endif

; Convert data to gse coordinates
DEC = '_ql_RADec_gse'
DEC1 = 'mms1' + DEC
DEC2 = 'mms2' + DEC
DEC3 = 'mms3' + DEC
DEC4 = 'mms4' + DEC

split_vec, DEC1
dsl2gse, Name1, DEC1 + '_0', DEC1 + '_1', Name1gse, /ignore_dlimits

split_vec, DEC2
dsl2gse, Name2, DEC2 + '_0', DEC2 + '_1', Name2gse, /ignore_dlimits

split_vec, DEC3
dsl2gse, Name3, DEC3 + '_0', DEC3 + '_1', Name3gse, /ignore_dlimits

split_vec, DEC4
dsl2gse, Name4, DEC4 + '_0', DEC4 + '_1', Name4gse, /ignore_dlimits

get_data, Name1gse, data = d1
get_data, Name2gse, data = d2
get_data, Name3gse, data = d3
get_data, Name4gse, data = d4

if ~is_struct(d1) or ~is_struct(d2) or ~is_struct(d3) or ~is_struct(d4) then begin
  print, 'UNABLE TO CONVERT AT LEAST ONE SPACECRAFT FROM DMPA TO GSE. NOT CALCULATING CURL B!'
  return
endif

; Find the mag file with the most data
lengths = [n_elements(d1.x), n_elements(d2.x), n_elements(d3.x), n_elements(d4.x)]
maxlen = max(lengths, lidx)
best_sc = lidx + 1

gse_names = [Name1gse, Name2gse, Name3gse, Name4gse]

case best_sc of
  1: begin
      tinterpol, gse_names(1), gse_names(0), /overwrite, /nan_extrapolate
      tinterpol, gse_names(2), gse_names(0), /overwrite, /nan_extrapolate
      tinterpol, gse_names(3), gse_names(0), /overwrite, /nan_extrapolate
     end
  2: begin
      tinterpol, gse_names(0), gse_names(1), /overwrite, /nan_extrapolate
      tinterpol, gse_names(2), gse_names(1), /overwrite, /nan_extrapolate
      tinterpol, gse_names(3), gse_names(1), /overwrite, /nan_extrapolate
     end
  3: begin
      tinterpol, gse_names(0), gse_names(2), /overwrite, /nan_extrapolate
      tinterpol, gse_names(1), gse_names(2), /overwrite, /nan_extrapolate
      tinterpol, gse_names(3), gse_names(2), /overwrite, /nan_extrapolate
     end
  4: begin
      tinterpol, gse_names(0), gse_names(3), /overwrite, /nan_extrapolate
      tinterpol, gse_names(1), gse_names(3), /overwrite, /nan_extrapolate
      tinterpol, gse_names(2), gse_names(3), /overwrite, /nan_extrapolate
     end
else: return
endcase

get_data, Name1gse, data = d1
get_data, Name2gse, data = d2
get_data, Name3gse, data = d3
get_data, Name4gse, data = d4


Bx1 = d1.y(*,0)
Bx2 = d2.y(*,0)
Bx3 = d3.y(*,0)
Bx4 = d4.y(*,0)

By1 = d1.y(*,1)
By2 = d2.y(*,1)
By3 = d3.y(*,1)
By4 = d4.y(*,1)

Bz1 = d1.y(*,2)
Bz2 = d2.y(*,2)
Bz3 = d3.y(*,2)
Bz4 = d4.y(*,2)


;Bx1 = d1.Y(*,0)
;Bx2 = interpol(d2.Y(*,0), d2.X, d1.X)
;Bx3 = interpol(d3.Y(*,0), d3.X, d1.X)
;Bx4 = interpol(d4.Y(*,0), d4.X, d1.X)
;
;By1 = d1.Y(*,1)
;By2 = interpol(d2.Y(*,1), d2.X, d1.X)
;By3 = interpol(d3.Y(*,1), d3.X, d1.X)
;By4 = interpol(d4.Y(*,1), d4.X, d1.X)
;
;Bz1 = d1.Y(*,2)
;Bz2 = interpol(d2.Y(*,2), d2.X, d1.X)
;Bz3 = interpol(d3.Y(*,2), d3.X, d1.X)
;Bz4 = interpol(d4.Y(*,2), d4.X, d1.X)

npts = n_elements(d1.x)
Y = fltarr(npts,4)

Y(*,0) = Bx1
Y(*,1) = Bx2
Y(*,2) = Bx3
Y(*,3) = Bx4

Bx = {x:d1.x, y:Y}

Y(*,0) = By1
Y(*,1) = By2
Y(*,2) = By3
Y(*,3) = By4

By = {x:d1.x, y:Y}

Y(*,0) = Bz1
Y(*,1) = Bz2
Y(*,2) = Bz3
Y(*,3) = Bz4

Bz = {x:d1.x, y:Y}

;---------------------------------------------------------------------------------------
; Now grab position and deltaB, deltar matrix
;---------------------------------------------------------------------------------------

; Set time range just in case keyword is set
nind = n_elements(Bx.X)

if keyword_set(trange) then $
  ind = where((Bx.X GE time(0)) AND (Bx.X LE time(1)), nind ) else $
  ind = lindgen(nind)


dBX = fltarr(nind, 3)
dBY = fltarr(nind, 3)
dBZ = fltarr(nind, 3)
dBX(*,0) = Bx.Y(ind,1) - Bx.Y(ind,0) ; SC2 - SC1
dBX(*,1) = Bx.Y(ind,2) - Bx.Y(ind,0) ; SC3 - SC1
dBX(*,2) = Bx.Y(ind,3) - Bx.Y(ind,0) ; SC4 - SC1
dBY(*,0) = By.Y(ind,1) - By.Y(ind,0) ; SC2 - SC1
dBY(*,1) = By.Y(ind,2) - By.Y(ind,0) ; SC3 - SC1
dBY(*,2) = By.Y(ind,3) - By.Y(ind,0) ; SC4 - SC1
dBZ(*,0) = Bz.Y(ind,1) - Bz.Y(ind,0) ; SC2 - SC1
dBZ(*,1) = Bz.Y(ind,2) - Bz.Y(ind,0) ; SC3 - SC1
dBZ(*,2) = Bz.Y(ind,3) - Bz.Y(ind,0) ; SC4 - SC1

; MAKE OUTPUT ARRAYS
Jx   = fltarr(nind)
Jy   = fltarr(nind)
Jz   = fltarr(nind)
Jerr = fltarr(nind)

; Now grab delta_r's
;mms_load_mec, probes=[1, 2, 3, 4], varformat='*_r_gse'
;
;store_data, '*eci*', /delete

t = Bx.x(ind)
ntimes = n_elements(t)

dum = dblarr(ntimes)
nprbs = 4
Pos = {t:t, sc:0, X:dum, Y:dum, Z:dum}
Pos = replicate(Pos,nprbs)

;success = 1
; loop over spacecraft
FOR j=0, 3 DO BEGIN

  ; Get position name
    Pname = 'mms' + strcompress(string(j+1), /REMOVE_ALL) + '_ql_pos_gse'

  ; GET DATA
  IF spd_check_tvar(Pname) then BEGIN
    get_data, Pname, data=mms_pos
    ; EXTRACT POSITION DATA
    Pos(j).X  = interpol(mms_pos.y(*,0), mms_pos.X, t, /spline)
    Pos(j).Y  = interpol(mms_pos.y(*,1), mms_pos.X, t, /spline)
    Pos(j).Z  = interpol(mms_pos.y(*,2), mms_pos.X, t, /spline)
    Pos(j).sc = fix(j+1)
    Pos(j).t  = t
  ENDIF ELSE BEGIN
    print, 'MMS_SITL_CURL_B:WARNING! Cannot find tplot name:', Pname
    print, 'returning!'
    flag = 1
    return
  ENDELSE

ENDFOR

; set up relative output - needed for dr part of curl
M = fltarr(ntimes,3,3)
M(*,0,0) = pos(1).X-Pos(0).X
M(*,1,0) = pos(1).Y-Pos(0).Y
M(*,2,0) = pos(1).Z-Pos(0).Z
M(*,0,1) = pos(2).X-Pos(0).X
M(*,1,1) = pos(2).Y-Pos(0).Y
M(*,2,1) = pos(2).Z-Pos(0).Z
M(*,0,2) = pos(3).X-Pos(0).X
M(*,1,2) = pos(3).Y-Pos(0).Y
M(*,2,2) = pos(3).Z-Pos(0).Z

;---------------------------------------------------------------------------------------
; Evaluate curl
;---------------------------------------------------------------------------------------

Jx   = fltarr(nind)
Jy   = fltarr(nind)
Jz   = fltarr(nind)
Jerr = fltarr(nind)


; Evaluate the derivatives
FOR i = 0L, nind-1 do BEGIN
  MI = invert(reform(M(i,*,*),3,3))
  dBxdx = MI(0,0)*dBX(i,0) + MI(1,0)*dBX(i,1)+ MI(2,0)*dBX(i,2)
  dBxdy = MI(0,1)*dBX(i,0) + MI(1,1)*dBX(i,1)+ MI(2,1)*dBX(i,2)
  dBxdz = MI(0,2)*dBX(i,0) + MI(1,2)*dBX(i,1)+ MI(2,2)*dBX(i,2)
  dBydx = MI(0,0)*dBY(i,0) + MI(1,0)*dBY(i,1)+ MI(2,0)*dBY(i,2)
  dBydy = MI(0,1)*dBY(i,0) + MI(1,1)*dBY(i,1)+ MI(2,1)*dBY(i,2)
  dBydz = MI(0,2)*dBY(i,0) + MI(1,2)*dBY(i,1)+ MI(2,2)*dBY(i,2)
  dBzdx = MI(0,0)*dBZ(i,0) + MI(1,0)*dBZ(i,1)+ MI(2,0)*dBZ(i,2)
  dBzdy = MI(0,1)*dBZ(i,0) + MI(1,1)*dBZ(i,1)+ MI(2,1)*dBZ(i,2)
  dBzdz = MI(0,2)*dBZ(i,0) + MI(1,2)*dBZ(i,1)+ MI(2,2)*dBZ(i,2)

  ; Calculate J AND Jerr DIV(B)I
  Jx(i) = (dBzdy - dBydz)*1e-6/mu0
  Jy(i) = (dBxdz - dBzdx)*1e-6/mu0
  Jz(i) = (dBydx - dBxdy)*1e-6/mu0
  Jerr(i) = (dBxdx + dBydy + dBzdz)*1e-6/mu0
ENDFOR

; Store as tplot variables
Y = fltarr(nind,4)
Y(*,0) = JX
Y(*,1) = JY
Y(*,2) = JZ
Y(*,3) = Jerr
NewName = 'mms_sitl_curl_b'
dlim = {SPEC: 0b, LOG: 0b, YSUBTITLE: '', $
  COLORS: [2,4,6,5], $
  LABELS: ['Jx', 'Jy', 'Jz', 'Jerr'], LABFLAG: 1, $
  YTITLE: 'Jvec: Curl(B)!cuA/m!U2!D'}
store_data, NewName, data={X:Bx.X(ind), Y:Y, V: [1,2,3,4]}, dlim=dlim

; Total current
J_tot = sqrt(JX^2 + JY^2 + JZ^2)
TotName = 'mms_sitl_jtot_curl_b'
dlim = {YSUBTITLE: '', $
  COLORS: [6,0], $
  LABELS: ['Jerr', 'Jtot'], LABFLAG: 1, $
  YTITLE: 'Jtot: Curl(B)!cuA/m!U2!D'}

store_data, TotName, data = {X:Bx.X(ind), y:[[abs(Jerr)],[J_tot]]}, dlim=dlim


end
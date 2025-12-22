;+
; FUNCTION:      FDF_ORB_WRITE
;
; PURPOSE:       Writes an orbit file in the style of the FDF for use
;                as an input file to orbgen.  The file will contain
;                only an epoch, position vector, and velocity vector.
;                Orbgen does not need the other orbit parameters
;                (ecc., manomaly, etc.) to propagate an orbit when
;                given this form of input.
;
; KEYWORDS:
;
;   EPOCH        The time for which the position and velocity vectors
;                are given. (String or double float.)
;   POSITION     Three-element position vector in GEI.
;   VELOCITY     Three-element velocity vector in GEI.
;   FILE         The name of the file to be created.
;
; CREATED:       97-8-21
;                By J.Rauchleiba
;-
function fdf_orb_write, EPOCH=intime, POSITION=pos, VELOCITY=vel, FILE=file

retval = 0
catch, errstat
if errstat NE 0 then begin
    retval = -1
    return, retval
endif

if data_type(epoch) EQ 7 then epoch=str_to_time(intime) else epoch=intime

; Construct lines for temporary two-line element file.
; This file has a peculiar format.

zeroes = ['','0','00','000','0000','00000','000000', $
          '0000000','00000000', '000000000']

; HEADER

newline = '^M^M'
headline = 'GEPVGWSGT' + newline

; EPOCH

date_doy_sec, epoch, year, doy_int, sec
time_o_day = (str_sep(time_to_str(sec, /msec), '/'))(1)
hhmmss = str_sep(time_o_day, ':')
sec_msec = str_sep( strtrim(string(hhmmss(2), format='(F7.4)'),2), '.' )
;; Seconds must be ss.ssss exactly
if strlen(sec_msec(0)) EQ 1 then sec_msec(0)='0' + sec_msec(0)
sec_str = strtrim(sec_msec(0),2) + strtrim(sec_msec(1),2)
;; DOY must be length 3
doy_stg = strtrim(doy_int,2)
doy_addz = 3 - strlen(doy_stg)
doy_stg = zeroes(doy_addz) + doy_stg
timeline = '00000000000000' + strtrim(year,2) + doy_stg + $
  strtrim(hhmmss(0),2) + strtrim(hhmmss(1),2) + sec_str + newline

; POSITION

X = pos(0)
Y = pos(1)
Z = pos(2)
if X LT 0 then Xsign='-' else Xsign=' '
if Y LT 0 then Ysign='-' else Ysign=' '
if Z LT 0 then Zsign='-' else Zsign=' '
Xfix = str_sep(strtrim(string(abs(X), format='(D19.7)'), 2), '.')
Yfix = str_sep(strtrim(string(abs(Y), format='(D19.7)'), 2), '.')
Zfix = str_sep(strtrim(string(abs(Z), format='(D19.7)'), 2), '.')
X_addz = 10 - strlen(Xfix(0))
Y_addz = 10 - strlen(Yfix(0))
Z_addz = 10 - strlen(Zfix(0))
Xfix(0) = zeroes(X_addz) + Xfix(0)
Yfix(0) = zeroes(Y_addz) + Yfix(0)
Zfix(0) = zeroes(Z_addz) + Zfix(0)
posline = Xsign + Xfix(0) + Xfix(1) + $
  Ysign + Yfix(0) + Yfix(1) + $
  Zsign + Zfix(0) + Zfix(1) + newline

; VELOCITY

VX = vel(0)
VY = vel(1)
VZ = vel(2)
if VX LT 0 then VXsign='-' else VXsign=' '
if VY LT 0 then VYsign='-' else VYsign=' '
if VZ LT 0 then VZsign='-' else VZsign=' '
VXfix = str_sep(strtrim(string(abs(VX), format='(D15.10)'), 2), '.')
VYfix = str_sep(strtrim(string(abs(VY), format='(D15.10)'), 2), '.')
VZfix = str_sep(strtrim(string(abs(VZ), format='(D15.10)'), 2), '.')
VX_addz = 3 - strlen(VXfix(0))
VY_addz = 3 - strlen(VYfix(0))
VZ_addz = 3 - strlen(VZfix(0))
VXfix(0) = zeroes(VX_addz) + VXfix(0)
VYfix(0) = zeroes(VY_addz) + VYfix(0)
VZfix(0) = zeroes(VZ_addz) + VZfix(0)
velline = VXsign + VXfix(0) + VXfix(1) + $
  VYsign + VYfix(0) + VYfix(1) + $
  VZsign + VZfix(0) + VZfix(1) + newline

; Write the file

print, 'Writing FDF format orbit vector file...'
openw, unit, /get_lun, file
printf, unit, format='(A//A//A//A//A)', newline, headline, timeline, posline, velline
close, unit

return, retval

end

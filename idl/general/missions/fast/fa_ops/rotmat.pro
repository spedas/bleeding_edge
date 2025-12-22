;+
;PROCEDURE:
;    ROTMAT,time,geogei,geigse,geigsm,geism,geigsq,geigsr,dgei,rgei,s
;
;PURPOSE:
;	generates rotation matrices for coordinate transformations for a given time
;
;     ------------------------------------------------------------------
;     ROTMAT generates various rotation matrices for coordinate trans-
;            formations for a given instant of time
;
;     INPUT: TIME: in seconds since 1970
;
;     OUTPUT (cf. Russell, Cosm. Electrodyn. 2, 184,
;                               1971 for names and definitions)
;
;     matrices: GEOGEI ... GEIGSR = rotation matrices transforming from
;               GEO to GEI system etc.; transposed matrix transforms
;               from GEI to GEO etc.
;
;     GEO = geographic                  GEI = geoc. equat. inertial
;     GSE = geoc. solar ecliptic        GSM = geoc. solar magnetospheric
;     SM  = geoc. solar magnetic        GSQ = geoc. solar equatorial
;     GSR = y axis as in gsq, z axis = sun's rot. axis,
;           earth-sun line in x-z plane
;
;     vectors:  dgei = earth's dipole axis in gei
;               rgei = sun's rotation axis in gei
;               s    = position of sun (earth-sun line) in gei
;
;
;-

pro sun, iyr, iday, secs, gst, slong, srasn, sdec, s
;
; Calculates sidereal time and position of the sun. IYR and IDAY must
; be integers, SECS is a double. These define universal time. The
; output is Greenwich mean sidereal time (GST) in radians, longitude
; along ecliptic in radians, and apparent right ascension and
; declination of the sun, all in radians. The unit vector from the
; earth to the sun, in GEI, is returned in S. 
;
rad= 180.d/!dpi

if (where(iyr lt 1901 or iyr gt 2099))[0] ge 0 then begin
    message,'not valid before 1901 or after 2099...',/continue
    return
endif

fday = secs/86400.d
dj = double(365L*(long(iyr)-1900L) +  $
            long(iyr-1901)/4L +  $
            iday + fday) - 0.5d

t = dj/36525.d

vl = (279.696678d + 0.9856473354d*dj) mod 360.d
gst = ((279.690983d + 0.9856473354d*dj + 360.d*fday + 180.d) mod 360.d) / rad
g = ((358.475845d + 0.985600267d*dj) mod 360.d) / rad

slong = (vl + (1.91946d - 0.004789d*t)*sin(g) + 0.020094d*sin(2.d*g))/ rad
slp = slong - 0.005686d/rad

obliq = (23.45229d - 0.0130125d*t) / rad

sind = sin(obliq)*sin(slp)
cosd = sqrt(1.d - sind^2)
sdec = atan(sind/cosd)
srasn = !dpi - atan((sind/cosd)/tan(obliq), -cos(slp)/cosd)

s = reform([[cos(srasn)*cos(sdec)],[sin(srasn)*cos(sdec)],[sin(sdec)]])

return
end
;
;-----------------------------------------------------------------------
;
pro rotmat, time,  $
            geogei, geigse, geigsm, geism, geigsq, geigsr, $
            dgei, rgei, s


dgeo= double([0.06859,-0.18602, 0.98015])
rgei= double([0.122,-0.424,0.897])

geogei= dblarr(3,3)
geigse= dblarr(3,3) 
geigsm= dblarr(3,3) 
geism= dblarr(3,3) 
geigsq= dblarr(3,3) 
geigsr= dblarr(3,3) 

sec_per_year = 86400.d*365.25d
iyr0 = 1970.d + double(long(time/sec_per_year))

yr = lindgen(fix(iyr0 - 1970.d)+10) + 1970l
leap = (((yr MOD 4) EQ 0) AND ((yr MOD 100) NE 0) OR  $
            ((yr MOD 400) EQ 0))
inc = [0.d,(365.d + double(leap))*86400.d]
yr_beg = total(inc, /cumulative)
this_year = max(where(yr_beg le time))

iyr = 1970 + this_year
iday = fix((time - yr_beg[this_year])/86400.d) + 1
secs = time - (yr_beg[this_year] + (iday-1)*86400.d)

sun, iyr, iday, secs, gst, slong, srasn, sdec, s
;
; GEOGEI
;
geogei[0,2] = 0.
geogei[1,2] = 0.
geogei[2,0] = 0.
geogei[2,1] = 0.
geogei[2,2] = 1.
geogei[0,0] = cos(gst)
geogei[0,1] =-sin(gst)
geogei[1,1] =  geogei[0,0]
geogei[1,0] = -geogei[0,1]
;
; DGEI
;
dgei= geogei#dgeo
;
; GEIGSE
;
geigse[2,0] = 0.
geigse[2,1] = -0.398
geigse[2,2] = 0.9174            ; modified 10 jan 1989 -> 1.00003
aux= geigse[2,*]
bux= crossp(aux,s)
geigse[0,*]= s
geigse[1,*]= bux
;
; GEIGSM
;
aux= crossp(dgei,s)
baux= sqrt(total(aux^2))
aux= aux/baux
bux= crossp(s,aux)
geigsm[0,*]= s
geigsm[1,*]= aux
geigsm[2,*]= bux
;
; GEISM
;
bux= crossp(aux,dgei)
geism[0,*]= bux
geism[1,*]= aux
geism[2,*]= dgei
;
; GEIGSQ
;
aux= crossp(rgei,s)
abaux= sqrt(total(aux^2))
aux= aux/abaux
bux= crossp(s,aux)
geigsq[0,*]= s
geigsq[1,*]= aux
geigsq[2,*]= bux
;
; GEIGSR
;
bux= crossp(aux,rgei)
geigsr[0,*]= bux
geigsr[1,*]= aux
geigsr[2,*]= rgei


return
end

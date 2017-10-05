FUNCTION mms_bss_fomrng, time
  compile_opt idl2
  
  if undefined(time) then message,'Please input time (scalar or vector)'
  
  ;------------
  ; FOM RANGE
  ;------------

  imax = n_elements(time)
  fomrng = fltarr(6,2,imax)

  ;  CURRENT SETTING
  fomrng[0,0,*] = 200 & fomrng[0,1,*] = 256
  fomrng[1,0,*] = 150 & fomrng[1,1,*] = 200
  fomrng[2,0,*] = 100 & fomrng[2,1,*] = 150
  fomrng[3,0,*] =  50 & fomrng[3,1,*] = 100
  fomrng[4,0,*] =   0 & fomrng[4,1,*] =  50
  fomrng[5,0,*] =   0 & fomrng[5,1,*] = 256

  ;  BEFORE 2015 Aug 24
  ts = time_double('2015-08-15/00:00')
  te = time_double('2015-08-24/00:00')
  ix = where( (ts le time) and (time lt te), ct)
  if ct gt 0 then begin
    fomrng[0,0,ix] = 200 & fomrng[0,1,ix] = 256
    fomrng[1,0,ix] = 150 & fomrng[1,1,ix] = 200
    fomrng[2,0,ix] =  50 & fomrng[2,1,ix] = 150
    fomrng[3,0,ix] =  25 & fomrng[3,1,ix] =  50
    fomrng[4,0,ix] =   0 & fomrng[4,1,ix] =  25
    fomrng[5,0,ix] =   0 & fomrng[5,1,ix] = 256
  endif

  ;  BEFORE 2015 Aug 15
  ts = time_double('2015-03-12/22:44')
  te = time_double('2015-08-15/00:00')
  ix = where( (ts le time) and (time lt te), ct)
  if ct gt 0 then begin
    fomrng[0,0,ix] = 200 & fomrng[0,1,ix] = 256
    fomrng[1,0,ix] = 100 & fomrng[1,1,ix] = 200
    fomrng[2,0,ix] =  50 & fomrng[2,1,ix] = 100
    fomrng[3,0,ix] =  25 & fomrng[3,1,ix] =  50
    fomrng[4,0,ix] =   0 & fomrng[4,1,ix] =  25
    fomrng[5,0,ix] =   0 & fomrng[5,1,ix] = 256
  endif
  
  return, fomrng
END

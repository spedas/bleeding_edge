
;+
;FUNCTION:	t_4d(dat,ENERGY=en,ERANGE=er,EBINS=ebins,ANGLE=an,ARANGE=ar,BINS=bins,MASS=ms,m_int=mi,q=q,mincnt=mincnt)
;INPUT:	
;	dat:	structure,	4d data structure filled by themis routines mvn_sta_c6.pro, mvn_sta_d0.pro, etc.
;KEYWORDS
;	ENERGY:	fltarr(2),	optional, min,max energy range for integration
;	ERANGE:	fltarr(2),	optional, min,max energy bin numbers for integration
;	EBINS:	bytarr(na),	optional, energy bins array for integration
;					0,1=exclude,include,  
;					na = dat.nenergy
;	ANGLE:	fltarr(2,2),	optional, angle range for integration
;				theta min,max (0,0),(1,0) -45<theta<45 
;				phi   min,max (0,1),(1,1)   -180<phi<180
;				or fltarr(2)
;				phi   min,max -180<phi<180
;	ARANGE:	fltarr(2),	optional, min,max angle bin numbers for integration
;	BINS:	bytarr(nb),	optional, angle bins array for integration
;					0,1=exclude,include,  
;					nb = dat.ntheta
;	BINS:	bytarr(na,nb),	optional, energy/angle bins array for integration
;					0,1=exclude,include
;PURPOSE:
;	Returns the temperature, [Tx,Ty,Tz,Tavg], eV 
;NOTES:	
;	Function normally called by "get_4dt" to
;	generate time series data for "tplot.pro".
;	;;;RESULTS IN A PRESSURE TENSOR THAT IS NOT DIAGONALIZED AROUND THE MAGNETIC FIELD.
;
;CREATED BY:
;	J.McFadden	2014-02-27
;LAST MODIFICATION:
; G. Hanley 2019-09-21
;-
function t_4dg,dat2,ENERGY=en,ERANGE=er,EBINS=ebins,ANGLE=an,ARANGE=ar,BINS=bins,MASS=ms,m_int=mi,q=q,mincnt=mincnt

Tavg = !values.F_NAN
Tx = !values.F_NAN
Ty = !values.F_NAN
Tz = !values.F_NAN

if dat2.valid eq 0 then begin
	print,'Invalid Data'
	return, [Tx,Ty,Tz,Tavg]
endif

if (dat2.quality_flag and 195) gt 0 then return,[Tx,Ty,Tz,Tavg]

dat=dat2

if dat.nbins eq 1 then return,tb_4d(dat,ENERGY=en,ERANGE=er,EBINS=ebins,ANGLE=an,ARANGE=ar,BINS=bins,MASS=ms,m_int=mi,q=q)

if keyword_set(ms) then begin
  ind = where(dat.mass_arr lt ms[0] or dat.mass_arr gt ms[1],count)
  if count ne 0 then dat.data[ind]=0.
  if count ne 0 then dat.bkg[ind]=0.
endif

if keyword_set(mi) then begin
  dat.mass_arr[*]=mi 
endif else begin
  if keyword_set(ms) then dat.mass_arr=(ms[0]+ms[1])/2. else $
  dat.mass_arr[*]=round(dat.mass_arr-.1)>1.       ; the minus 0.1 helps account for straggling at low mass
endelse

dat3 = dat

if keyword_set(an) then begin
  case 1 of
   (size(an, /n_dim) eq 1):  begin
      ind = where(dat.phi lt an[0] or dat.phi gt an[1],count)
      if count ne 0 then dat.data[ind]=0.
      if count ne 0 then dat.bkg[ind]=0.
      
      end
   (size(an, /n_dim) eq 2): begin   
      ind = where(dat.theta lt an[0,0] or dat.theta gt an[1,0],count)
      if count ne 0 then dat.data[ind]=0.
      if count ne 0 then dat.bkg[ind]=0.
      
      ind = where(dat.phi lt an[0,1] or dat.phi gt an[1,1],count)
      if count ne 0 then dat.data[ind]=0.
      if count ne 0 then dat.bkg[ind]=0.
      end
    else: print, 'Invalid angle range, ignoring' 
    endcase
endif

if keyword_set(mincnt) then if total(dat.data-dat.bkg) lt mincnt then return, [Tx,Ty,Tz,Tavg]



press   = p_4dg(dat,ENERGY=en,ERANGE=er,EBINS=ebins,ANGLE=an,ARANGE=ar,BINS=bins,MASS=ms,m_int=mi,q=q,mincnt=mincnt)
density = n_4d(dat,ENERGY=en,ERANGE=er,EBINS=ebins,ANGLE=an,ARANGE=ar,BINS=bins,MASS=ms,m_int=mi,q=q,mincnt=mincnt)

if keyword_set(ms) then begin
	Tavg = reform(press[0]+press[1]+press[2])/((density+1.e-10)*3.)
	Tx = reform(press[0])/(density+1.e-10)
	Ty = reform(press[1])/(density+1.e-10)
	Tz = reform(press[2])/(density+1.e-10)
endif else begin
	Tavg = reform(press[0,*]+press[1,*]+press[2,*])/((density+1.e-10)*3.)
	Tx = reform(press[0,*])/(density+1.e-10)
	Ty = reform(press[1,*])/(density+1.e-10)
	Tz = reform(press[2,*])/(density+1.e-10)
endelse


return, transpose([[Tx],[Ty],[Tz],[Tavg]])

end


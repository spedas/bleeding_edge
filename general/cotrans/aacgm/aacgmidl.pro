; aacgmidl.pro
;
; By R.J.Barnes
; Original version of AACGM by Kile Baker and Simon Wing
; 
; Copyright � 2001 The Johns Hopkins University/Applied Physics Laboratory.
; All rights reserved.
; 
; This material may be used, modified, or reproduced by or for the U.S.
; Government pursuant to the license rights granted under the clauses at DFARS
; 252.227-7013/7014.
; 
; For any other permissions, please contact the Space Department
; Program Office at JHU/APL.
; 
; This Distribution and Disclaimer Statement must be included in all copies of
; RST-ROS (hereinafter "the Program").
; 
; The Program was developed at The Johns Hopkins University/Applied Physics
; Laboratory (JHU/APL) which is the author thereof under the "work made for
; hire" provisions of the copyright law.  
; 
; JHU/APL assumes no obligation to provide support of any kind with regard to
; the Program.  This includes no obligation to provide assistance in using the
; Program or to provide updated versions of the Program.
; 
; THE PROGRAM AND ITS DOCUMENTATION ARE PROVIDED AS IS AND WITHOUT ANY EXPRESS
; OR IMPLIED WARRANTIES WHATSOEVER.  ALL WARRANTIES INCLUDING, BUT NOT LIMITED
; TO, PERFORMANCE, MERCHANTABILITY OR FITNESS FOR A PARTICULAR PURPOSE ARE
; HEREBY DISCLAIMED.  YOU ASSUME THE ENTIRE RISK AND LIABILITY OF USING THE
; PROGRAM TO INCLUDE USE IN COMPLIANCE WITH ANY THIRD PARTY RIGHTS.  YOU ARE
; ADVISED TO TEST THE PROGRAM THOROUGHLY BEFORE RELYING ON IT.  IN NO EVENT
; SHALL JHU/APL BE LIABLE FOR ANY DAMAGES WHATSOEVER, INCLUDING, WITHOUT
; LIMITATION, ANY LOST PROFITS, LOST SAVINGS OR OTHER INCIDENTAL OR
; CONSEQUENTIAL DAMAGES, ARISING OUT OF THE USE OR INABILITY TO USE THE
; PROGRAM."
; 
; NOTE: Minor modifications made by Patrick Cruce at IGPP/UCLA for use with
; THEMIS TDAS Software in July/August 2008
; 
;     5/27/2015:
;         modified by egrimes@igpp, added a note to aacgmidl to load the coefficients
;         before trying to use these routines. also note that this previously 
;         loaded the coefficients for year = 2000 by batch executing default.pro
;         
;ALSO NOTE:
;    Haje Korth's AACGM DLM interface to the C code is significantly faster:
;         http://ampere.jhuapl.edu/code/idl_aacgm.html
;         
; 
; 
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;+
; NAME:
;	AACGMIDL
;
; PURPOSE:
;	This library is a pure IDL version of the AACGM library
;	
;
; ROUTINES:
;
;	EQN_OF_TIME     equation of time
;	SOLAR_LOC 	find location of sun
;	CNV_AACGM	convert coordinates to/from magnetic/geographic
;	CALC_MLT	calculate magnetic local time
;	LOAD_COEF	load a set of AACGM coefficients
;
;----------------------------------------------------------------------------
;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;+
; NAME:
;       EQN_OF_TIME
;
; PURPOSE:
;       equation of time for a given longitude and year
;
; Calling sequence:
;	eqt = eqn_of_time(mean_lon,yr)
;	   
;
;	
;---------------------------------------------------------------------
;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;+
; NAME:
;       SOLAR_LOC
;
; PURPOSE:
;       location of the sun for given year and time
;
; Calling sequence:
;	solar_loc,yr,t1,mean_lon,dec
;	   t1 is the seconds from the start of year.
;          the mean longitude and declination are returned
;          in mean_lon and dec as floats.
;
;	
;---------------------------------------------------------------------
;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;+
; NAME:
;       CNV_AACGM
;
; PURPOSE:
;       convert to and from AACGM and Geographic coordinates
;
; Calling sequence:
;	CNV_AACGM,in_lat,in_lon,height,out_lat,out_lon,r,error
;	   the calculated latitude and longitude for the
;          given height are returned in out_lat,out_lon.
;         
;
;	
;---------------------------------------------------------------------
;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;+
; NAME:
;       CALC_MLT
;
; PURPOSE:
;       calculate magnetic local time for a given longitude
;
; Calling sequence:
;	mlt=CALC_MLT(yr,t0,mlong)
;	    t1 is the seconds from the start of year and 
;           mlong is the magnetic longitude of the observing
;           point.
;	
;---------------------------------------------------------------------
;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;+
; NAME:
;       LOAD_COEF
;
; PURPOSE:
;       load a set of AACGM coefficients
;
; Calling sequence:
;	load_coef,fname
;	    fname is the filename. 
;          
;	
;---------------------------------------------------------------------
;





;
; $Log: aacgmidl.pro,v $
; Revision 1.2  2002/03/29 16:03:43  barnes
; Fixed credits.
;
; Revision 1.1  2002/03/29 15:50:19  barnes
; Initial revision
;
;

; sind and cosd removed to avoid duplicate routines (other versions in ssl_general/misc/math)
;function sind, theta
;  return, sin(theta*!PI/180.0)
;end
;
;function cosd, theta
;  return, cos(theta*!PI/180.0)
;end

function asind, theta
  return, asin(theta)*180.0/!PI
end

function acosd, theta
  return, acos(theta)*180.0/!PI
end


function sgn,a,b
 if (a ge 0) then x=a else x=-a
 if (b ge 0) then return, x
 return, -x
end

function modulus,x,y
  quotient=x/y
  if (quotient ge 0) then quotient=floor(quotient) $
  else quotient=-floor(-quotient)
  return, (x-y*quotient)
end
 
pro rylm,colat,lon,order,ylmval

 
  
  cos_theta = cos(colat)
  sin_theta = sin(colat)

  cos_lon = cos(lon)
  sin_lon = sin(lon)

  d1 = -sin_theta;
  z2=complex(cos_lon,sin_lon)
  z1=d1*z2
  q_fac=z1

  ylmval[0]=1;
  ylmval[2]=cos_theta;

  for l=1,order-1 do begin
    la = (l - 1) * l + 1
    lb = l * (l + 1) + 1
    lc = (l + 1) * (l + 2) + 1;

    ca =float(l * 2. + 1.) / (l + 1.)
    cb= float(l)/(l + 1.)
    ylmval[lc-1] = ca * cos_theta * ylmval[lb-1] - cb * ylmval[la-1]
  end

  q_val=q_fac;
  ylmval[3]=float(q_val)
  ylmval[1]=-imaginary(q_val)
  for l=2,order do begin
    d1 = l*2 - 1.
    z2=d1*q_fac
    z1=z2*q_val
    q_val=z1
    
    la = l*l + (2*l) + 1
    lb = l*l + 1;

    ylmval[la-1] = float(q_val)
    ylmval[lb-1] = -imaginary(q_val)

  end

  for l=2,order do begin
     la = l*l
     lb = l*l - 2*(l - 1)
     lc = l*l + (2*l);
     ld = l*l + 2

     fac = l*2 - 1
     ylmval[lc-1] = fac * cos_theta * ylmval[la-1]
     ylmval[ld-1] = fac * cos_theta * ylmval[lb-1]
   end

   for m=1,order-2 do begin
      la = (m+1)*(m+1)
      lb = (m+2)*(m+2)-1
      lc = (m+3)*(m+3)-2
	
      ld = la - (2*m)
      ldd = lb - (2*m)
      lf = lc - (2*m)

      for l=m+2,order do begin
        ca=float(2.*l-1)/(l-m)
        cb=float(l+m-1.)/(l-m)

        ylmval[lc-1] = ca * cos_theta *ylmval[lb-1] - cb *ylmval[la-1]
        ylmval[lf-1] = ca * cos_theta *ylmval[ldd-1] - cb *ylmval[ld-1]

	la = lb
        lb = lc
        lc = lb + (2*l) + 2

        ld = la - (2*m)
	ldd = lb - (2*m)
	lf = lc - (2*m)
      end
   end 
   return
end


pro altitude_to_cgm, r_height_in, r_lat_alt, r_lat_adj
   eradius=6371.2
   eps=1e-9
   unim=0.9999999;

  r1 = cosd(r_lat_alt)
  ra = r1 * r1
  if (ra lt eps) then ra = eps
  r0 = (r_height_in/eradius+1) / ra
  if (r0 lt unim) then r0 = unim
  
  r1 = acos(sqrt(1/r0));
  r_lat_adj= sgn(r1, r_lat_alt)*180./!pi;
  return
end

pro cgm_to_altitude, r_height_in,r_lat_in,  r_lat_adj, error
  eradius=6371.2
  unim=1
  error=0
  r1 = cosd(r_lat_in);
  ra = (r_height_in/ eradius+1)*(r1*r1);
  if (ra gt unim) then begin
    ra = unim;
    error=1;
  end

  r1 = acos(sqrt(ra));
  r_lat_adj = sgn(r1,r_lat_in)*180./!pi;
  return
end





function eqn_of_time,mean_lon,yr
  eqcoef=[  [-105.8,596.2,4.4,-12.7,-429.0,-2.1,19.3], $
          [-105.9,596.2,4.4,-12.7,-429.0,-2.1,19.3], $
          [-106.1,596.2,4.4,-12.7,-428.9,-2.1,19.3], $
          [-106.2,596.2,4.4,-12.7,-428.9,-2.1,19.3], $
          [-106.4,596.1,4.4,-12.7,-428.9,-2.1,19.3], $
          [-106.5,596.1,4.4,-12.7,-428.8,-2.1,19.3], $
          [-106.6,596.1,4.4,-12.7,-428.8,-2.1,19.3], $
          [-106.7,596.1,4.4,-12.7,-428.7,-2.1,19.3], $
          [-106.8,596.1,4.4,-12.7,-428.7,-2.1,19.3], $
          [-107.0,596.1,4.4,-12.7,-428.7,-2.1,19.3], $
          [-107.2,596.1,4.4,-12.7,-428.6,-2.1,19.3], $
          [-107.3,596.1,4.4,-12.7,-428.6,-2.1,19.3]  $
       ]
  index=1
  if (yr lt 88) then index=yr+2000-1988
  if ((yr ge 88) and (yr lt 100)) then index=yr-88 $
  else if ((yr ge 100) and (yr lt 1900)) then index=yr-88 $
  else index=yr-1988 
  if (index lt 1) then index=1
  if (index gt 12) then index=12;
 

  return,  eqcoef[0,index-1]*sind(mean_lon)+ $
           eqcoef[1,index-1]*sind(2.0*mean_lon)+ $
           eqcoef[2,index-1]*sind(3.0*mean_lon)+ $ 
           eqcoef[3,index-1]*sind(4.0*mean_lon)+ $
           eqcoef[4,index-1]*cosd(mean_lon)+ $
           eqcoef[5,index-1]*cosd(2.0*mean_lon)+ $
           eqcoef[6,index-1]*cosd(3.0*mean_lon)
          
end

pro solar_loc,yr, t1, mean_lon, dec

  L0=[279.642,279.403,279.165,278.926,279.673,279.434, $
      279.196,278.957,279.704,279.465,279.226,278.982]
  DL=0.985647

  G0=[356.892984,356.637087,356.381191,356.125295, $
      356.854999,356.599102,356.343206,356.087308, $
      356.817011,356.561113,356.31,356.05]
  DG=0.98560028
  EPS0=[23.440722,23.440592,23.440462,23.440332, $
        23.440202,23.440072,23.439942,23.439811, $
        23.439682,23.439552,23.439422,23.439292] 
  DE=-0.00000036;


  d = 0;
  if (yr lt 1900) then index = yr - 88 $
  else index = yr - 1988

  if (index le 0) then delta_yr = index - 1 $
  else if (index gt 10) then delta_yr = index - 10 $
  else delta_yr = 0;
     
  if (index lt 1) then index = 1
  if (index gt 12) then index = 12
  

  yr_step = sgn(1,delta_yr)
  delta_yr = abs(delta_yr)

  for i=1,delta_yr do  begin 
      if (yr_step gt 0) then yrs=98+i-1 $
      else yrs=89-i

      if (modulus(yrs,4) eq 0) then d = d + 366*yr_step $
      else d = d + 365*yr_step
    end

     
  d = d + t1/86400
  L = L0[index-1] + DL*d
  g = G0[index-1] + DG*d

  while (L lt 0) do L = L + 360
  while (g lt 0) do g = g + 360
    
  L = modulus(L,360.0)
  g = modulus(g,360.0)

  lambda = L + 1.915*sind(g) + 0.020*sind(2*g)
  eps = EPS0[index-1] + DE*d

  dec = asind(sind(eps)*sind(lambda))
  mean_lon = L
  
  return
end


pro convert_geo_coord, lat_in,lon_in,height_in,lat_out,lon_out, $
                       order,error, geo=geo

  common aacgm_com,coef,cint,height_old,first_coeff_old

  flag=keyword_set(GEO);
  
  if lon_in lt 0 then lon_in=lon_in+360
  if (first_coeff_old ne coef[0,0,0,0]) then height_old=[-1.0, -1.0]
  first_coeff_old=coef[0,0,0,0]

  error=-2
  if ((height_in lt 0) or (height_in gt 7200)) then return
  error=-8;
  if (abs(lat_in) gt 90.) then return
  error=-16
  if ((lon_in lt 0) or (lon_in gt 360)) then return
   
  if (height_in ne height_old(flag)) then begin
      alt_var= height_in/7200.0;
      alt_var_sq = alt_var * alt_var;
      alt_var_cu = alt_var * alt_var_sq;
      alt_var_qu = alt_var * alt_var_cu;

      for i=0,2 do begin
        for j=0,120 do begin 
          cint[j,i,flag] =coef[j,i,0,flag]+ $
                coef[j,i,1,flag]*alt_var+ $
                coef[j,i,2,flag]*alt_var_sq+ $
                coef[j,i,3,flag]*alt_var_cu+ $
                coef[j,i,4,flag]*alt_var_qu 
	end
      end
      height_old[flag] = height_in;
  end
  x=0.
  y=0.
  z=0.
 
  lon_input =lon_in*!pi/180.0; 
    
  if (flag eq 0) then colat_input = (90.-lat_in)*!pi/180.0 $
  else begin
   error=-64
    cgm_to_altitude,height_in, lat_in,lat_adj,errflg
    if (errflg ne 0) then return;
    colat_input= (90. - lat_adj)*!pi/180.0;
  end
  ylmval=fltarr(121);
  rylm,colat_input,lon_input,order,ylmval;

  for l = 0, order do begin
     for m = -l,l do begin
       k = l * (l+1) + m+1;
      
       x=x+cint[k-1,0,flag]*ylmval[k-1]
       y=y+cint[k-1,1,flag]*ylmval[k-1]
       z=z+cint[k-1,2,flag]*ylmval[k-1]
     end
   end
   error=-32
   r = sqrt(x * x + y * y + z * z)
   if ((r lt 0.9) or (r gt 1.1)) then return
   
   z=z / r
   x=x / r
   y=y / r

   if (z ge 1.) then colat_temp=0 $ 
   else if (z lt -1.) then colat_temp =!pi $
   else colat_temp= acos(z)
  
   if ((abs(x) lt 1e-8) and (abs(y) lt 1e-8)) then lon_temp =0 $
   else lon_temp = atan(y,x)

   lon_output = lon_temp

   if (flag eq 0) then begin
     lat_alt =90 - colat_temp*180.0/!pi;
     altitude_to_cgm,height_in, lat_alt,lat_adj
     colat_output = (90. - lat_adj) * !pi/180.0;
   end else colat_output = colat_temp

   lat_out =90. - colat_output*180.0/!pi
   lon_out  =lon_output*180.0/!pi
   error=0  
  return
end

pro mlt1,t0,solar_dec,mlon,mlt,mslon
  common mlt_com,sol_dec_old,told,mslon1,mslon2

  if ((abs(solar_dec-sol_dec_old) gt 0.1) or (sol_dec_old eq 0)) then told=1e12
  if (abs(mslon2-mslon1) gt 10) then told=1e12;
    
  if ((t0 ge told) and (t0 lt (told+600))) then $
    mslon=mslon1+(t0-told)*(mslon2-mslon1)/600.0 $
  else begin
    told=t0
    sol_dec_old=solar_dec

    slon1 = (43200.0-t0)*15.0/3600.0
    slon2 = (43200.0-t0-600)*15.0/3600.0

    height = 450
    convert_geo_coord,solar_dec,slon1,height,mslat1,mslon1,4,err
    convert_geo_coord,solar_dec,slon2,height,mslat2,mslon2,4,err
    mslon=mslon1
  end
  

  mlt = (mlon - mslon) /15.0 + 12.0
  if (mlt ge 24) then mlt=mlt-24;
  if (mlt lt 0) then mlt=mlt+24;  

end
  
function calc_mlt,yr,t0,mlong
   if (yr gt 1900) then yr=yr-1900
   mean_lon=0.0
   dec=0.0
   mlt=0.0
   
   solar_loc,yr, t0,mean_lon,dec
   
   et = eqn_of_time(mean_lon, yr)
   dy=floor(t0/(24.*3600.))
   ut=float(t0-(dy*24*3600));
   apparent_time = ut + et;
   mlt1,apparent_time, dec, mlong, mlt,mslong
   return, mlt
end

pro cnv_aacgm, in_lat,in_lon,height,out_lat,out_lon,r,error, geo=geo
   out_lat=0.
   out_lon=0.
   geo=keyword_set(geo)
   convert_geo_coord,in_lat,in_lon,height,out_lat,out_lon,10,error,geo=geo
   r=1.0;
end


pro load_coef,filename

 common aacgm_com,coef,cint,height_old,first_coeff_old

 openr, unit, filename,/GET_LUN  
 coef=fltarr(121,3,5,2)
 readf, unit,coef
 close,unit
 free_lun,unit  
 
end


pro aacgmidl

  common aacgm_com,coef,cint,height_old,first_coeff_old
  common mlt_com,sol_dec_old,told,mslon1,mslon2

  coef=fltarr(121,3,5,2)
  cint=fltarr(121,3,2)
  height_old=[-1.,-1.]
  first_coeff_old=-1.
  sol_dec_old=0
  told=1e12
  mslon1=0
  mslon2=0
  
  ; NOTE: must load the coefficients! they can be found in:
  ; general/cotrans/aacgm/coef
  rt_info = routine_info('aacgmidl',/source)
  path = file_dirname(rt_info.path) + '/coef/'
  load_coef, path+'aacgm_coeffs2010.asc'
  
  ;@default.pro
end


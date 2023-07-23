;+
;
;NAME:
; omti_attitude_params
;
;PURPOSE:
; Output the OMTI Imager Attitude Parameters for Coordinate Transformation.
;
;SYNTAX:
; result = omti_attitude_params(date = date, site = site)
;
;PARAMETERS:
;  date = Unix time
;  site = Site name (ABB code)
;
;CODE:
;  A. Shinbori, 21/07/2022.
;
;MODIFICATIONS:
;
;
;ACKNOWLEDGEMENT:
; $LastChangedBy:
; $LastChangedDate:
; $LastChangedRevision:
; $URL $
;-
function omti_attitude_params, date = date, site = site

  ;========================================
  ;---Keyword check for site code and date:
  ;========================================
   if ~keyword_set(site) then site = 'sgk'
   if ~keyword_set(date) then date = time_double('2015-05-18/00:00:00')

  ;---Definition of array for omti attitude parameters:
   out_params = dblarr(7)
  
  ;---Eureka (EUR) : (80.0N, 274.1E)  
   if site eq 'eur' then begin
      lon_obs = 274.10d
      lat_obs = 80.0d
      alt_obs = 0.127d
      if date ge time_double('2015-05-18/00:00:00') then begin
         xm = 255.700d
         ym = 269.768d
         a_val = 144.598d
         rotation = 23.1193d
      endif
   endif
  ;---
  ;---Resolute Bay (RSB) : (74.7N, 265.1E)  
   if site eq 'rsb' then begin
      lon_obs = 265.07d
      lat_obs = 74.73d
      alt_obs = 0.160d
      if date ge time_double('2005-01-01/00:00:00') then begin
         xm = 138.977d
         ym = 111.149d
         a_val = 75.3824d
         rotation = 11.66d
      endif
   endif
  ;---
  ;---Istok (IST) : (70.03N, 88.01E)
   if site eq 'ist' then begin
      lon_obs = 88.01d
      lat_obs = 70.03d
      alt_obs = 0.038d
      if date ge time_double('2017-10-29/00:00:00') then begin
         xm = 0d
         ym = 0d
         a_val = 0d
         rotation = 0d    
      endif
   endif
  ;---
  ;---Tromsoe (TRS) : (69.59N, 19.227E)
   if site eq 'trs' then begin
      lon_obs=19.22d
      lat_obs=69.5667d
      alt_obs=0.222d
      if date ge time_double('2009-01-11/00:00:00') then begin
         xm = 119.9d
         ym = 137.1d
         a_val = 75.1d
         rotation = -182.2d     
      endif
   endif
  ;---
  ;---Husafell (HUS) : (64.67N, 338.97E)   
   if site eq 'hus' then begin
      lon_obs=338.97d
      lat_obs=64.67d
      alt_obs=0.160d
      if date ge time_double('2017-03-21/00:00:00') then begin
         xm = 251.837d
         ym = 260.692d
         a_val = 164.276d
         rotation= -26.239d
      endif     
   endif
  ;---
  ;---Nain (NAI) : (56.54N, 298.269E) 
   if site eq 'nai' then begin
     lon_obs = 298.269d
     lat_obs = 56.54d
     alt_obs = 0.169d
     if date ge time_double('2018-09-11/00:00:00') and date le time_double('2018-09-15/23:59:59') then begin
        xm = 123.6665778d
        ym = 125.3363562d
        a_val = 80.96082512d
        rotation = -29.12566205d          
     endif
     if date ge time_double('2018-09-16/00:00:00') then begin
        xm = 123.904463d
        ym = 126.0769982d
        a_val = 81.73187528d
        rotation = -29.08460874d
     endif
   endif
  ;---
  ;---Athabasca (ATH) : (54.7N, 246.7E)
   if site eq 'ath' then begin
      lon_obs = 246.686d
      lat_obs = 54.714d
      alt_obs = 0.568d
      if date ge time_double('2005-09-01/00:00:00') and date le time_double('2006-12-09/23:59:59') then begin
         xm = 127.225d
         ym = 124.343d
         a_val = 74.8504d
         rotation= 28.02d
      endif
      if date ge time_double('2006-12-10/00:00:00') and date le time_double('2012-09-25/23:59:59') then begin
         xm = 127.419d
         ym = 123.502d 
         a_val = 74.7895d
         rotation = 28.10d
      endif
      if date ge time_double('2012-09-27/00:00:00') then begin
         xm = 125.544d
         ym = 130.819d
         a_val = 75.449d
         rotation= 9.74d
      endif
   endif
  ;---
  ;---Zhigansk (ZGN) : (66.78N, 123.37E)
   if site eq 'zgn' then begin
      lon_obs = 123.37d
      lat_obs = 66.78d
      alt_obs = 0.063d
      if date ge time_double('2019-09-27/00:00:00') then begin
         xm = 126.220987d
         ym = 128.7920648d
         a_val = 81.60706651d
         rotation= 28.70376834d
      endif
   endif
  ;---
  ;---Gakona (GAK) : (62.39N, 214.78E)
   if site eq 'gak' then begin
      lon_obs = 214.84245d
      lat_obs = 62.407119d
      alt_obs = 0.586d
      if date ge time_double('2017-03-03/00:00:00') then begin
         xm = 257.907d
         ym = 256.131d
         a_val = 162.620d
         rotation= 181.874d
      endif
   endif
  ;---
  ;---Nyrola (NYR) : (62.34N, 25.51E) 
   if site eq 'nyr' then begin
     lon_obs = 25.51d
     lat_obs = 62.34d
     alt_obs = 0.190d
     if date ge time_double('2017-01-24/00:00:00') then begin
        xm = 252.370d
        ym = 257.190d
        a_val = 163.104d
        rotation= -216.268d
     endif     
   endif
  ;---
  ;---Kapuskasing (KAP) : (49.39N, 277.81E)   
   if site eq 'kap' then begin
     lon_obs = 277.81d
     lat_obs = 49.39d
     alt_obs = 0.238d
     if date ge time_double('2017-02-25/00:00:00') then begin
        xm = 255.4477d
        ym = 259.8555d
        a_val = 164.1066d
        rotation= -16.066d
     endif
   endif
  ;---
  ;---Ithaca (ITH) : (42.5N, 283.6E)   
   if site eq 'ith' then begin
      lon_obs = 283.56889d
      lat_obs = 42.49548d
      alt_obs = 0.118d
      if date ge time_double('2006-06-28/00:00:00') and date le time_double('2007-04-17/23:59:59') then begin
         xm = 136.759d
         ym = 127.696d
         a_val = 74.398d
         rotation= -3.51d
      endif
   endif
  ;---      
  ;---Magadan (MGD) : (60.0513467N, 150.7292683E)
   if site eq 'mgd' then begin
      lon_obs=150.7292683d
      lat_obs=60.0513467d
      alt_obs=0.224d
      if date ge time_double('2008-11-04/00:00:00') and date le time_double('2016-05-09/23:59:59') then begin
         xm = 129.6611349d
         ym = 132.7939871d
         a_val = 74.74801171d
         rotation= -11.68421779d
      endif
      if date ge time_double('2016-05-10/00:00:00') then begin
         xm = 121.2306201d
         ym = 136.284137d
         a_val = 74.70055575d
         rotation= -9.571134334d
      endif     
   endif
  ;--- 
  ;---Paratunka (PTK) : (52.9720466, 158.24762E)   
   if site eq 'ptk' then begin
      lon_obs=158.24762d
      lat_obs=52.9720466d
      alt_obs=0.058d
      if date ge time_double('2007-08-19/00:00:00') then begin
         xm = 127.969d
         ym = 130.7456d
         a_val = 74.63278d
         rotation= -7.633543d
      endif
   endif
  ;---
  ;---Rikubetsu (RIK) : (43.5N, 143.8E)   
   if site eq 'rik' then begin
      lon_obs = 143.7600d
      lat_obs = 43.4542d
      alt_obs = 0.272d
      if date ge time_double('1998-10-20/00:00:00') and date le time_double('1998-10-21/23:59:59') then begin
         xm = 245.4600d
         ym = 253.3814d
         a_val = 152.2790d
         rotation = 189.6028d
      endif
      if date ge time_double('1998-10-22/00:00:00') and date le time_double('1999-03-27/23:59:59') then begin
         xm = 245.6783d
         ym = 255.0890d
         a_val = 152.9733d
         rotation = 178.1944d
      endif
      if date ge time_double('1998-04-01/00:00:00') and date le time_double('2008-05-19/23:59:59') then begin
         xm = 250.5931d
         ym = 253.8743d
         a_val = 152.8562d
         rotation = -3.5557d
      endif
      if date ge time_double('2008-05-20/00:00:00') then begin
         xm = 133.9425d
         ym = 128.2934d
         a_val = 73.9317d
         rotation= 10.333d
      endif
   endif
  ;---   
  ;---Shigaraki (SGK) : (34.8N, 136.1E)   
   if site eq 'sgk' then begin
      lon_obs = 136.1089d
      lat_obs = 34.8522d
      alt_obs = 0.388d
      if date le time_double('2000-10-09/23:59:59') then begin
         xm = 256.0258d
         ym = 241.2775d
         a_val = 155.4491d
         rotation= 0.3817d      
      endif
      if date ge time_double('2000-10-10/00:00:00') then begin
         xm = 254.2615d
         ym = 242.6770d
         a_val = 155.9573d
         rotation = 0.3982d     
      endif     
   endif
  ;---    
  ;--- Sata (STA) : (31.0N, 130.7E)   
   if site eq 'sta' then begin
      lon_obs = 130.6837d
      lat_obs = 31.0194d
      alt_obs = 0.018d
      if date le time_double('2003-08-31/23:59:59') then begin
         xm = 258.2739d
         ym = 258.0548d
         a_val = 153.9014d
         rotation = -13.2571d
      endif
      if date ge time_double('2003-09-01/00:00:00') and date le time_double('2009-07-15/23:59:59') then begin
         xm = 256.594d
         ym = 258.213d
         a_val = 153.926d
         rotation = -11.6431d
      endif
      if date ge time_double('2009-10-28/00:00:00') and date le time_double('2021-04-08/23:59:59') then begin
         xm = 261.3298d
         ym = 258.5835d
         a_val = 153.338d
         rotation= -10.8249d     
      endif
   endif
  ;---   
  ;---Yonaguni (YNG): (24.5N, 123.0E)   
   if site eq 'yng' then begin
      lon_obs=123.020d
      lat_obs=24.4693d
      alt_obs=0.039d
      if date ge time_double('2006-03-24/00:00:00') and date le time_double('2009-07-29/23:59:59') then begin
         xm = 254.017d
         ym = 278.050d
         a_val = 148.519d
         rotation= 18.5446d
      endif
      if date ge time_double('2010-09-14/00:00:00') and date le time_double('2013-05-07/23:59:59') then begin
         xm = 261.121d
         ym = 262.952d
         a_val = 146.416d
         rotation= 18.2932d
      endif
   endif
  ;---    
  ;---Ishigaki (ISG): (24.4N, 124.1E)  
   if site eq 'isg' then begin
     lon_obs=124.1447d
     lat_obs=24.4043d
     alt_obs=0.023d
     if date ge time_double('2014-04-22/00:00:00') then begin
        xm = 242.706d
        ym = 267.292d
        a_val = 148.641d
        rotation= 1.71301d
     endif
   endif
  ;---  
  ;---Haleakala (HLK): (20.71N, 203.74E, altitude: 3040m)   
   if site eq 'hlk' then begin
     lon_obs=203.7422d
     lat_obs=20.7085d
     alt_obs=3.027d
     if date ge time_double('2013-03-01/00:00:00') and date le time_double('2016-02-29/23:59:59') then begin
        xm = 235.6541918d
        ym = 262.8874138d
        a_val = 154.7773753d
        rotation = 106.8006359d
     endif     
   endif
  ;---    
  ;---Chiang Mai (CMU): (18.79N, 98.92E)   
   if site eq 'cmu' then begin
     lon_obs = 98.9211d
     lat_obs = 18.7895d
     alt_obs = 0.867d
     if date ge time_double('2017-03-14/00:00:00') then begin
        xm = 256.2966d
        ym = 254.7530d
        a_val = 176.2168d
        rotation = -0.4742d
     endif
   endif
  ;---   
  ;---Chumphon (CPN): (10.73N, 99.37E)
   if site eq 'cpn' then begin
     lon_obs = 99.37d
     lat_obs = 10.73d
     alt_obs = 0.044d
     if date ge time_double('2020-01-16/00:00:00') then begin
        xm = 230.59d
        ym = 242.19d
        a_val = 173.09d
        rotation = -0.98d
     endif     
   endif
  ;---   
  ;---Abuja (ABU): (8.99063N, 7.38359E)    
   if site eq 'abu' then begin
     lon_obs = 7.38d
     lat_obs = 8.99d
     alt_obs = 0.426d
     if date ge time_double('2015-06-09/00:00:00') then begin
        xm = 240.8365d
        ym = 268.2431d
        a_val = 154.8868d
        rotation = 9.3110d
     endif
   endif
  ;--- 
  ;---Darwin (DRW) : (12.4S, 131.0E)
   if site eq 'drw' then begin
      lon_obs = 130.955918d
      lat_obs = -12.443388d
      alt_obs = 0.0444d
      if date ge time_double('2001-10-09/00:00:00') and date le time_double('2011-03-18/23:59:59') then begin
         xm = 237.6321d
         ym = 255.7900d
         a_val = 153.2353d
         rotation = 4.4853d
      endif
      if date ge time_double('2011-03-19/00:00:00') then begin
         xm = 248.7333d
         ym = 257.2224d
         a_val = 151.6393d
         rotation=-0.6261d
      endif          
   endif
  ;---
  ;---Kototabang (KTB) : (0.2S, 100.3E)   
   if site eq 'ktb' then begin
      lon_obs = 100.32d
      lat_obs = -0.2d
      alt_obs = 0.865d
      if date ge time_double('2002-10-26/00:00:00') and date le time_double('2010-04-06/23:59:59') then begin
         xm = 246.783d
         ym = 255.468d
         a_val = 155.572d
         rotation = 0.625049d
      endif
      if date ge time_double('2010-06-11/00:00:00') then begin
         xm = 243.6771d
         ym = 278.7887d
         a_val = 153.1178d
         rotation= -1.145864d
      endif     
   endif
  ;---  
  ;---Syowa Station (SYO) : (69.00S, 39.59E) 
   if site eq 'syo' then begin
     lon_obs = 39.582d
     lat_obs = -69.0045d
     alt_obs = -0.013d
     if date ge time_double('2011-03-01/00:00:00') and date le time_double('2011-10-01/23:59:59') then begin
        xm = 245d
        ym = 241d
        a_val = 148.6508424d
        rotation = 44.2998d
     endif
   endif
  ;---
  ;---New station (NEW) : (xxx, xxx)
  ;if site eq 'new' then begin
  ;  lon_obs = xxx
  ;  lat_obs = xxx
  ;  alt_obs = xxx
  ;  if date ge time_double('start time') and date le time_double('end time') then begin
  ;    xm = xxx
  ;    ym = xxx
  ;    a_val = xxx
  ;    rotation = xxx
  ;  endif
  ;endif
  ;--- 
   
  ;---Substitution of each parameter into out_params array:
   out_params[0] = lon_obs
   out_params[1] = lat_obs
   out_params[2] = alt_obs  
   out_params[3] = xm
   out_params[4] = ym
   out_params[5] = a_val
   out_params[6] = rotation
      
  ;---Return to the information of OMTI Imager Attitude Parameters for Coordinate Transformation:
   return, out_params

end
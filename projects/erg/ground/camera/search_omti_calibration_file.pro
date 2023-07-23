;+
;
;NAME:
; search_omti_calibration_file
;
;PURPOSE:
; Select the OMTI calibration file for site and wavelength at the specified date.
;
;SYNTAX:
; result = select_omti_calibration_file(date = date, site = site, wavelength = wavelength, wid0 = wid0)
;
;PARAMETERS:
;  date = Unix time
;  site = Site name (ABB code)
;  wavelength = Observed wavelength for airglow
;  wid0 = 2x2 binning window
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
function search_omti_calibration_file, date = date, site = site, wavelength = wavelength, wid_cdf = wid_cdf, wid0 = wid0

  ;========================================
  ;---Keyword check for site and wavelength:
  ;========================================
   if ~keyword_set(site) then site = 'sgk'
   if ~keyword_set(wavelength) then wavelength = '5577'

  ;---Definition of array for calibration file names:
   cal_files = strarr(2)

  ;---Eureka (eur):
   if site eq 'eur' then begin
     ;---camera number:
      im = 'F'
     
     ;---2x2 binning pixels:   
      wid0 = wid_cdf * 2
      
     ;---Observed wavelength of airglow data and exposure time:
      if wavelength eq '5577' then begin
         ch = '1'
      endif
      if wavelength eq '6300' then begin
         ch = '2'
      endif

     ;---Calibration file for each observation period:
      if date ge time_double('2015-05-18/00:00:00') then frest = '0001'
      
   endif

  ;---Resolute Bay (rsb):
   if site eq 'rsb' then begin
     ;---camera number:
      im = '6'

     ;---2x2 binning pixels:
      wid0 = wid_cdf * 2
      
     ;---Observed wavelength of airglow data:
      if wavelength eq '5577' then begin
         ch = '1'
      endif
      if wavelength eq '6300' then begin
         ch = '2'
      endif
      if wavelength eq '7774' then begin
         ch = '4'
      endif
      if wavelength eq '5893' then begin
         ch = '6'
      endif
          
     ;---Calibration file for each observation period:
      if date ge time_double('2005-01-01/00:00:00') then frest = '0002'

   endif

  ;---Istok (ist):
   if site eq 'ist' then begin
     ;---camera number:
      im = 'K'

     ;---2x2 binning pixels:
      wid0 = wid_cdf * 2
      
     ;---Observed wavelength of airglow data:
      if wavelength eq '5577' then begin
         ch = '1'
      endif
      if wavelength eq '6300' then begin
         ch = '2'
      endif
      if wavelength eq '4861' then begin
         ch = '4'
      endif

     ;---Calibration file for each observation period:
      if date ge time_double('2017-10-29/00:00:00') then frest = '0001'

   endif

  ;---Tromsoe (trs):
   if site eq 'trs' then begin
     ;---camera number:
      im = 'C'

     ;---2x2 binning pixels:
      wid0 = wid_cdf * 2

     ;---Observed wavelength of airglow data:
      if wavelength eq '5577' then begin
         ch = '1'
      endif
      if wavelength eq '6300' then begin
         ch = '2'
      endif
      if wavelength eq '5893' then begin
         ch = '4'
      endif
      if wavelength eq '7320' then begin
         ch = '6'
      endif   
      
     ;---Calibration file for each observation period:
      if date ge time_double('2009-01-11/00:00:00') then frest = '0001'

   endif

  ;---Husafell (hus):
   if site eq 'hus' then begin
     ;---camera number:
      im = 'L'

     ;---2x2 binning pixels:
      wid0 = wid_cdf * 2

     ;---Observed wavelength of airglow data:
      if wavelength eq '5577' then begin
         ch = '1'
      endif
      if wavelength eq '6300' then begin
         ch = '2'
      endif   
      if wavelength eq '4861' then begin
         ch = '4'
      endif

     ;---Calibration file for each observation period:
      if date ge time_double('2017-03-21/00:00:00') then frest = '0001'

   endif

   ;---Nain (nai):
   if site eq 'nai' then begin
     ;---camera number:
      im = 'H'

     ;---4x4 binning pixels:
      wid0 = wid_cdf * 4

     ;---Observed wavelength of airglow data:
      if wavelength eq '5577' then begin
         ch = '1'
      endif
      if wavelength eq '6300' then begin
         ch = '2'
      endif   
      if wavelength eq '4861' then begin
         ch = '4'
      endif
      
     ;---Calibration file for each observation period:
      if date ge time_double('2018-09-11/00:00:00') then frest = '0001'

   endif

  ;---Athabasca (ath):
   if site eq 'ath' then begin
    ;---camera number:
     im = '7'

    ;---2x2 binning pixels:
      wid0 = wid_cdf * 2

    ;---Observed wavelength of airglow data:
     if wavelength eq '5577' then begin
        ch = '1'
     endif
     if wavelength eq '6300' then begin
        ch = '2'
     endif
     if wavelength eq '4861' then begin
        ch = '4'
     endif
     if wavelength eq '8446' then begin
        ch = '6'
     endif
     if wavelength eq '5893' then begin
        ch = '7'
     endif

    ;---Calibration file for each observation period:
     if date le time_double('2014-11-17/23:59:59') then frest = '2456'
     if date ge time_double('2014-11-18/00:00:00') then frest = '0002'
     
   endif

  ;---Zhigansk (zgn):
   if site eq 'zgn' then begin
     ;---camera number:
      im = 'E'

     ;---2x2 binning pixels:
      wid0 = wid_cdf * 2

     ;---Observed wavelength of airglow data:
      if wavelength eq '5577' then begin
         ch = '1'
      endif
      if wavelength eq '6300' then begin
         ch = '2'
      endif
      if wavelength eq '4861' then begin
         ch = '4'
      endif

     ;---Calibration file for each observation period:
      if date ge time_double('2019-09-27/00:00:00') then frest = '0001'

   endif

  ;---Gakona (gak):
   if site eq 'gak' then begin
     ;---camera number:
      im = 'J'

     ;---2x2 binning pixels:
      wid0 = wid_cdf * 2

     ;---Observed wavelength of airglow data:
      if wavelength eq '5577' then begin
         ch = '1'
      endif
      if wavelength eq '6300' then begin
         ch = '2'
      endif
      if wavelength eq '4861' then begin
         ch = '4'
      endif

     ;---Calibration file for each observation period:
      if date ge time_double('2017-03-03/00:00:00') then frest = '0001'

   endif

  ;---Nyrola (nyr):
   if site eq 'nyr' then begin
     ;---camera number:
      im = 'I'

     ;---2x2 binning pixels:
      wid0 = wid_cdf * 2

     ;---Observed wavelength of airglow data:
      if wavelength eq '5577' then begin
         ch = '1'
      endif
      if wavelength eq '6300' then begin
         ch = '2'
      endif
      if wavelength eq '4861' then begin
         ch = '4'
      endif

     ;---Calibration file for each observation period:
      if date ge time_double('2017-01-24/00:00:00') then frest = '0001'

   endif

  ;---Kapuskasing (kap):
   if site eq 'kap' then begin
     ;---camera number:
      im = 'G'

     ;---2x2 binning pixels:
      wid0 = wid_cdf * 2

     ;---Observed wavelength of airglow data:
      if wavelength eq '5577' then begin
         ch = '1'
      endif
      if wavelength eq '6300' then begin
         ch = '2'
      endif
      if wavelength eq '4861' then begin
         ch = '4'
      endif

     ;---Calibration file for each observation period:
      if date ge time_double('2017-02-25/00:00:00') then frest = '0001'

   endif

  ;---Ithaca (ith):
   if site eq 'ith' then begin
     ;---camera number:
      im = '9'

     ;---2x2 binning pixels:
      wid0 = wid_cdf * 2

     ;---Observed wavelength of airglow data:
      if wavelength eq '5577' then begin
         ch = '1'
      endif   
      if wavelength eq '6300' then begin
         ch = '2'
      endif

     ;---Calibration file for each observation period:
      if date ge time_double('2006-01-28/00:00:00') and date le time_double('2007-04-30/23:59:59') then frest = '0001'

   endif

  ;---Magadan (mgd):
   if site eq 'mgd' then begin
     ;---camera number:
      im = 'B'

     ;---2x2 binning pixels:
      wid0 = wid_cdf * 2

     ;---Observed wavelength of airglow data:
      if wavelength eq '5577' then begin
         ch = '1'
      endif   
      if wavelength eq '6300' then begin
         ch = '2'
      endif
      if wavelength eq '7774' then begin
         ch = '4'
      endif   
      if wavelength eq '4861' then begin
         ch = '6'
      endif
            
     ;---Calibration file for each observation period:
      if date ge time_double('2008-11-04/00:00:00') and date le time_double('2016-05-09/23:59:59') then frest = '0001'
      if date ge time_double('2016-05-10/00:00:00') then frest = '0002'
      
   endif

  ;---Paratunka (ptk) :
   if site eq 'ptk' then begin
     ;---camera number:
      im = 'A'

     ;---2x2 binning pixels:
      wid0 = wid_cdf * 2

     ;---Observed wavelength of airglow data:
      if wavelength eq '5577' then begin
         ch = '1'
      endif   
      if wavelength eq '6300' then begin
         ch = '2'
      endif   
      if wavelength eq '7774' then begin
         ch = '4'
      endif
      if wavelength eq '4861' then begin
         ch = '6'
      endif   
            
     ;---Calibration file for each observation period:
      if date ge time_double('2007-08-17/00:00:00') then frest = '0001'

   endif

  ;---Rikubetsu (rik) :
   if site eq 'rik' then begin
     ;---camera number:
      if date ge time_double('1998-10-01/00:00:00') and date le time_double('2008-05-19/23:59:59') then im = '3'
      if date ge time_double('2008-05-20/00:00:00') then im = '9'

     ;---2x2 binning pixels for im = '9'
      if im eq '9' then wid0 = wid_cdf * 2

     ;---No 2x2 binning pixels for im = '3' 
      if im eq '3' then wid0 = wid_cdf
      
     ;---Observed wavelength of airglow data:
      if wavelength eq '5577' then begin
         ch = '1'
      endif
      if wavelength eq '6300' then begin
         ch = '2'
      endif               

     ;---Calibration file for each observation period:
      if date ge time_double('1998-10-01/00:00:00') and date le time_double('2008-05-19/23:59:59') then frest = '2456'
      if date ge time_double('2008-05-20/00:00:00') and date le time_double('2012-06-29/23:59:59') then frest = '0001'
      if date ge time_double('2012-06-30/00:00:00') then frest = '0002'
            
   endif
      
  ;---Shigaraki (sgk):
   if site eq 'sgk' then begin
     ;---camera number:
      im = '1'

     ;---No 2x2 binning pixels:
      wid0 = wid_cdf
     
     ;---Observed wavelength of airglow data:
      if wavelength eq '5577' then begin
         ch = '1'
      endif   
      if wavelength eq '6300' then begin
         ch = '2'
      endif   
      if wavelength eq '5893' then begin
         ch = '4'
      endif   
      
     ;---Calibration file for each observation period:
      if date le time_double('2000-06-16/23:59:59') then frest = '2456' 
      if date ge time_double('2000-06-17/00:00:00') and date le time_double('2000-12-07/23:59:59') then frest = '0001' 
      if date ge time_double('2000-12-08/00:00:00') and date le time_double('2006-08-30/23:59:59') then frest = '0002'
      if date ge time_double('2006-08-31/00:00:00') and date le time_double('2006-10-30/23:59:59') then frest = '0003'
      if date ge time_double('2006-10-31/00:00:00') and date le time_double('2007-02-26/23:59:59') then frest = '0004'
      if date ge time_double('2007-02-27/00:00:00') and date le time_double('2012-04-18/23:59:59') then frest = '0005'
      if date ge time_double('2012-04-19/00:00:00') then frest = '0006'
     
   endif

  ;---Sata (STA):
   if site eq 'sta' then begin
     ;---camera number:
      if date ge time_double('2000-07-01/00:00:00') and date le time_double('2009-07-15/23:59:59') then im = '2'
      if date ge time_double('2009-10-28/00:00:00') and date le time_double('2021-04-08/23:59:59') then im = '3'
 
     ;---No 2x2 binning pixels:
      wid0 = wid_cdf
     
     ;---Observed wavelength of airglow data:
      if wavelength eq '5577' then begin
         ch = '1'
      endif
      if wavelength eq '6300' then begin
         ch = '2'       
      endif

     ;---Calibration file for each observation period:
      if im eq '2' then begin
         if date le time_double('2010-08-19/23:59:59') then frest = '2456'
      endif
      if im eq '3' then begin
         if date ge time_double('2010-08-20/00:00:00') and date le time_double('2012-04-18/23:59:59') then frest = '0002'
         if date ge time_double('2012-04-19/00:00:00') and date le time_double('2013-01-14/23:59:59') then frest = '0003'
         if date ge time_double('2013-01-15/00:00:00') and date le time_double('2016-05-09/23:59:59') then frest = '0004'
         if date ge time_double('2016-05-10/00:00:00') then frest = '0005'
      endif

   endif

  ;---Yonaguni (YNG):
   if site eq 'yng' then begin
     ;---camera number:
      if date ge time_double('2006-03-01/00:00:00') and date le time_double('2013-05-07/23:59:59') then im = '8'

     ;---No 2x2 binning pixels:
      wid0 = wid_cdf

     ;---Observed wavelength of airglow data:
      if wavelength eq '5577' then begin
         ch = '1'
      endif
      if wavelength eq '6300' then begin
         ch = '2'
      endif
      if wavelength eq '7774' then begin
         ch = '4'
      endif

     ;---Calibration file for each observation period:
      if date le time_double('2013-08-19/23:59:59') then frest = '2456'
      if date ge time_double('2013-08-20/00:00:00') and date le time_double('2013-05-07/23:59:59') then frest = '0002'
   
   endif

  ;---Ishigaki (isg):
   if site eq 'isg' then begin
     ;---camera number:
      if date ge time_double('2014-04-22/00:00:00') then im = '8'

     ;---2x2 binning pixels (no):
      wid0 = wid_cdf

     ;---Observed wavelength of airglow data:
      if wavelength eq '5577' then begin
         ch = '1'
      endif   
      if wavelength eq '6300' then begin
         ch = '2'
      endif
      if wavelength eq '7774' then begin
        ch = '4'
      endif

     ;---Calibration file for each observation period:
      if date ge time_double('2013-08-20/00:00:00') then frest = '0002'

   endif

  ;---Haleakala (hlk):
   if site eq 'hlk' then begin
     ;---camera number:
      if date ge time_double('2013-03-13/00:00:00') then im = '2'

     ;---No 2x2 binning pixels:
      wid0 = wid_cdf

     ;---Observed wavelength of airglow data:
      if wavelength eq '5577' then begin
         ch = '1'
      endif   
      if wavelength eq '6300' then begin
         ch = '2'
      endif
      if wavelength eq '5893' then begin
         ch = '4'
      endif   

     ;---Calibration file for each observation period:
      if date ge time_double('2013-03-13/00:00:00') and date le time_double('2016-05-09/23:59:59') then frest = '0004'
      if date ge time_double('2016-05-10/00:00:00') then frest = '0005'
      
   endif

  ;---Chiang Mai (cmu):
   if site eq 'cmu' then begin
     ;---camera number:
      if date ge time_double('2018-08-16/00:00:00') then im = '2'

     ;---No 2x2 binning pixels:
      wid0 = wid_cdf

     ;---Observed wavelength of airglow data:
      if wavelength eq '5577' then begin
         ch = '1'
      endif   
      if wavelength eq '6300' then begin
         ch = '2'
      endif   
      if wavelength eq '5893' then begin
         ch = '4'
      endif

     ;---Calibration file for each observation period:
      if date ge time_double('2018-08-16/00:00:00') then frest = '0005'
      
   endif

  ;---Chumphon (cpn):
   if site eq 'cpn' then begin
     ;---camera number:
      if date ge time_double('2020-01-15/00:00:00') then im = 'N'

     ;---No 2x2 binning pixels:
      wid0 = wid_cdf

     ;---Observed wavelength of airglow data:
      if wavelength eq '5577' then begin
         ch = '1'
      endif   
      if wavelength eq '6300' then begin
         ch = '2'
      endif   
      if wavelength eq '7774' then begin
         ch = '4'
      endif

     ;---Calibration file for each observation period:
      if date ge time_double('2020-01-15/00:00:00') then frest = '0002'

   endif

  ;---Abuja (abu):
   if site eq 'abu' then begin
     ;---camera number:
      if date ge time_double('2015-06-09/00:00:00') then im = '5'

     ;---No 2x2 binning pixels:
      wid0 = wid_cdf

     ;---Observed wavelength of airglow data:
      if wavelength eq '5577' then begin
         ch = '1'
      endif   
      if wavelength eq '6300' then begin
         ch = '2'
      endif   
      if wavelength eq '7774' then begin
         ch = '4'
      endif

     ;---Calibration file for each observation period:
      if date ge time_double('2015-06-09/00:00:00') then frest = '0002'

   endif
   
  ;---Darwin (drw):
   if site eq 'drw' then begin
     ;---camera number:
      if date ge time_double('2001-10-09/00:00:00') and date le time_double('2007-03-19/23:59:59') then im = '4'
      if date ge time_double('2011-03-19/00:00:00') then im = '4'

     ;---No 2x2 binning pixels:
      wid0 = wid_cdf
     
     ;---Observed wavelength of airglow data:
      if wavelength eq '5577' then begin
         ch = '1'
      endif   
      if wavelength eq '6300' then begin
         ch = '2'
      endif   
      if wavelength eq '7774' then begin
         ch = '4'
      endif
      
     ;---Calibration file for each observation period:
      if date ge time_double('2001-10-09/00:00:00') and date le time_double('2006-04-30/23:59:59') then frest = '0001'
      if date ge time_double('2006-05-01/00:00:00') and date le time_double('2007-03-19/23:59:59') then frest = '0003'
      if date ge time_double('2011-03-19/00:00:00') then frest = '0004'
          
   endif 

  ;---Kototabang (ktb):
   if site eq 'ktb' then begin
     ;---camera number:
      if date ge time_double('2002-10-01/00:00:00') and date le time_double('2010-06-10/23:59:59') then im = '5'
      if date ge time_double('2010-06-11/00:00:00') then im = 'D'

     ;---No 2x2 binning pixels:
      wid0 = wid_cdf

     ;---Observed wavelength of airglow data:
      if wavelength eq '5577' then begin
         ch = '1'
      endif   
      if wavelength eq '6300' then begin
         ch = '2'
      endif   
      if wavelength eq '7774' then begin
         ch = '4'
      endif

     ;---Calibration file for each observation period:
      if date ge time_double('2002-10-01/00:00:00') and date le time_double('2010-06-10/23:59:59') then frest = '0001'
      if date ge time_double('2010-06-11/00:00:00')  then frest = '0001'

   endif

  ;---Syowa Station (syo):
   if site eq 'syo' then begin
     ;---camera number:
      if date ge time_double('2011-03-01/00:00:00') and date le time_double('2011-10-01/23:59:59') then im = '2'

     ;---No 2x2 binning pixels:
     ;wid0 = wid_cdf * 1

     ;---Observed wavelength of airglow data:
      if wavelength eq '5577' then begin
         ch = '1'
         wid0 = wid_cdf * 2 ;---2x2 binning pixels:
      endif   
      if wavelength eq '6300' then begin
         ch = '2'
         wid0 = wid_cdf * 2 ;---2x2 binning pixels:
      endif
      if wavelength eq '5893' then begin
         ch = '4'
         wid0 = wid_cdf * 1 ;---No 2x2 binning pixels:
      endif   

     ;---Calibration file for each observation period:
      if date ge time_double('2011-03-01/00:00:00') and date le time_double('2011-10-01/23:59:59') then frest = '0002'

   endif

   ;---New Station (new):
   ;if site eq 'new' then begin
   ;  ;---camera number:
   ;   if date ge time_double('start time') and date le time_double('endtime') then im = '2'
   ;
   ;   
   ;  ;---2x2 binning pixels
   ;   wid0 = wid_cdf * 2
   ;   
   ;  ;---No 2x2 binning pixels 
   ;   wid0 = wid_cdf
   ;   
   ;  ;---Observed wavelength of airglow data:
   ;   if wavelength eq '5577' then fw = '1'
   ;   if wavelength eq '6300' then fw = '2'
   ;   if wavelength eq '5893' then fw = '4'
   ;
   ;  ;---Calibration file for each observation period:
   ;   if date ge time_double('start time') and date le time_double('endtime') then frest = '0002'
   ;
   ;endif

  ;---Enter the calibration file names:
   cal_files[0] = 'M'+im+'C'+ch+frest+'.OUT'
   cal_files[1] = 'M'+im+'C'+'5'+frest+'.OUT'
     
  ;---Return to the information of calibration file names:
   return, cal_files
   
end
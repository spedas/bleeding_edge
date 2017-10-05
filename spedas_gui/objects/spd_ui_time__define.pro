;+ 
;NAME: 
; spd_ui_time__define
;
;PURPOSE:
; generic time object 
;
;CALLING SEQUENCE:
; To Create:    myTimeObj = Obj_New("SPD_UI_TIME")
; To Use:       data = myDataObj->GetAll() 
;
;INPUT:
;  optional - can provide a time value double, string, or epoch
;             defaults to current time
;  tDouble   
;  tString
;  tEpoch
;
;OUTPUT:
; data object
;
;METHODS:
; UpdateStructure
; GetStructure
; GetAll
; SetProperty 
; GetProperty
;
;HISTORY:
;
;$LastChangedBy: jimm $
;$LastChangedDate: 2014-02-11 10:54:32 -0800 (Tue, 11 Feb 2014) $
;$LastChangedRevision: 14326 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/objects/spd_ui_time__define.pro $
;-----------------------------------------------------------------------------------



FUNCTION SPD_UI_TIME::Copy
   out = Obj_New("SPD_UI_TIME")
   selfClass = Obj_Class(self)
   outClass = Obj_Class(out)
   IF selfClass NE outClass THEN BEGIN
       dprint,  'Object classes not identical'
       RETURN, 1
   END
   Struct_Assign, self, out
   RETURN, out
END ;--------------------------------------------------------------------------------



PRO SPD_UI_TIME::UpdateStructure

   Catch, theError
   IF theError NE 0 THEN BEGIN
      Catch, /Cancel
      ok = Error_Message(Traceback=Keyword_Set(self.debug))
      RETURN
   ENDIF
   
   timeStruc = Time_Struct(self.tDouble)
   
   self.year = timeStruc.year 
   self.month = timeStruc.month 
   self.date = timeStruc.date
   self.hour = timeStruc.hour
   self.min = timeStruc.min
   self.sec = timeStruc.sec
   self.fsec = timeStruc.fsec
   self.dayNum = timeStruc.dayNum
   self.doy = timeStruc.doy
   self.dow = timeStruc.dow
   self.sod = timeStruc.sod
   self.dst = timeStruc.dst
   self.tZone = timeStruc.tzone 
   self.tDiff = timeStruc.tdiff   

END ;--------------------------------------------------------------------------------



PRO SPD_UI_TIME::SetProperty,            $ ; standard set property method
              TDouble=tdouble,           $ ; double precision time (sec. since 1970)
              TString=tstring,           $ ; time string YYYY/MM/DD-hh:mm:ss.ss
              TEpoch=tepoch                ; epoch time (double precision - for CDF)
 
      ; Note - user can only set time with double, string, or epoch
      ; for now, double overrides string which overrides epoch (only if all three
      ; values are set - which shouldn't occur)

      ;Catch any errors here
      
   Catch, theError
   IF theError NE 0 THEN BEGIN
      Catch, /Cancel
      ok = Error_Message(Traceback=Keyword_Set(self.debug))
      RETURN
   ENDIF

      ;Which time option was used 
        
   IF N_Elements(tdouble) NE 0 THEN BEGIN
      self.tDouble = tdouble
      self.tString = Time_String(tdouble)
      self.tEpoch = Time_Epoch(tdouble)
      self->UpdateStructure
      RETURN
   ENDIF   
   IF N_Elements(tstring) NE 0 THEN BEGIN
      self.tString = tstring
      self.tDouble = Time_Double(tstring)
      self.tEpoch = Time_Epoch(tstring)
      self->UpdateStructure
      RETURN
   ENDIF 
   IF N_Elements(tepoch) NE 0 THEN BEGIN
      self.tEpoch = tepoch
      self.tDouble = Time_Double(tepoch)
      self.tString = Time_String(tepoch)
      self->UpdateStructure
      RETURN
   ENDIF 
      
      
END ;--------------------------------------------------------------------------------



FUNCTION SPD_UI_TIME::GetStructure  
  RETURN, Time_Struct(self.tDouble)
END ;--------------------------------------------------------------------------------



FUNCTION SPD_UI_TIME::IsValid, TString=tstring, TDouble=tdouble 
  ; need code to check time validity
  RETURN, 1
END ;--------------------------------------------------------------------------------



FUNCTION SPD_UI_TIME::GetAll
  RETURN, self
END ;--------------------------------------------------------------------------------



PRO SPD_UI_TIME::GetProperty,            $
              TDouble=tdouble,           $ ; double precision time (sec. since 1970)
              TString=tstring,           $ ; time string YYYY/MM/DD-hh:mm:ss.ss
              TEpoch=tepoch,             $ ; epoch time (double precision - for CDF)
              Year=year,                 $ ; year 
              Month=month,               $ ; month (1-12)
              Date=date,                 $ ; day (1-31)
              Hour=hour,                 $ ; hours (0-23)
              Min=min,                   $ ; minutes (0-59)
              Sec=sec,                   $ ; seconds (0-59)
              FSec=fsec,                 $ ; fractional seconds (0-.999999)
              DayNum=daynum,             $ ; days since 0 AD
              DOY=doy,                   $ ; day of year (1-366)
              DOW=dow,                   $ ; day of week (1-7)
              SOD=sod,                   $ ; seconds of day (1-86400)
              DST=dst,                   $ ; daylight savings time flag
              TZone=tzone,               $ ; time zone (Pacific time is -8)
              TDiff=tdiff                  ; hours from UTC
 
   Catch, theError
   IF theError NE 0 THEN BEGIN
      Catch, /Cancel
      ok = Error_Message(Traceback=Keyword_Set(self.debug))
      RETURN
   ENDIF

      ;Return only whats asked for

   IF Arg_Present(tdouble) THEN tdouble = self.tDouble
   IF Arg_Present(tstring) THEN tstring = self.tstring
   IF Arg_Present(tepoch) THEN tepoch = self.tepoch
   IF Arg_Present(year) THEN year = self.year
   IF Arg_Present(month) THEN month = self.month
   IF Arg_Present(date) THEN date = self.date
   IF Arg_Present(hour) THEN hour = self.hour
   IF Arg_Present(min) THEN min = self.min
   IF Arg_Present(sec) THEN sec = self.sec
   IF Arg_Present(fsec) THEN fsec = self.fsec
   IF Arg_Present(daynum) THEN daynum = self.daynum
   IF Arg_Present(doy) THEN doy = self.doy
   IF Arg_Present(dow) THEN dow = self.dow
   IF Arg_Present(sod) THEN sod = self.sod
   IF Arg_Present(dst) THEN dst = self.dst
   IF Arg_Present(tzone) THEN tzone = self.tzone
   IF Arg_Present(tdiff) THEN tdiff = self.tdiff

END ;--------------------------------------------------------------------------------



;FUNCTION SPD_UI_DATA::Cleanup 
;   nothing to clean (yet...)
;END ;--------------------------------------------------------------------------------



FUNCTION SPD_UI_TIME::Init,             $ ; The INIT method of the bar object.
              TDouble=tdouble,          $ ; double precision time (sec. since 1970)
              TString=tstring,          $ ; time string YYYY/MM/DD-hh:mm:ss.ss
              Debug=debug,              $ ; set this value to one for debugging
              _Extra=extra                ; holds extra keywords

   Catch, theError
   IF theError NE 0 THEN BEGIN
      Catch, /Cancel
      ok = Error_Message(Traceback=Keyword_Set(debug))
      RETURN, 0
   ENDIF

   self.debug = Keyword_Set(debug)
 
   ; Check that all parameters have values
   IF N_Elements(tdouble) EQ 0 THEN BEGIN
      IF N_Elements(tstring) EQ 0 THEN BEGIN
         tstring=Time_String(SysTime(/sec))
         tdouble=Time_Double(tstring)
      ENDIF ELSE BEGIN
         IF Size(tstring, /Type) EQ 7 THEN tdouble = Time_Double(tstring) ELSE RETURN, 0
      ENDELSE
   ENDIF ELSE BEGIN
      IF Size(tdouble, /Type) EQ 5 THEN tstring = Time_String(tdouble)ELSE RETURN, 0   
   ENDELSE   
   
      ; Set all parameters
   
   self.tDouble = tdouble
   self.tString = tstring
   self.tEpoch = Time_Epoch(tdouble)
   self->UpdateStructure

   RETURN, 1
END ;--------------------------------------------------------------------------------



PRO SPD_UI_TIME__DEFINE

   struct = { SPD_UI_TIME,              $ ; 

              tDouble: 0.0D,            $ ; double precision time (sec. since 1970)
              tString: ' ',             $ ; time string YYYY/MM/DD-hh:mm:ss.ss
              tEpoch: 0.0D,             $ ; epoch time (double precision - for CDF)
              year: 0,                  $ ; year 
              month: 0,                 $ ; month (1-12)
              date: 0,                  $ ; day (1-31)
              hour: 0,                  $ ; hours (0-23)
              min: 0,                   $ ; minutes (0-59)
              sec: 0,                   $ ; seconds (0-59)
              fsec: 0,                  $ ; fractional seconds (0-.999999)
              dayNum: 0l,               $ ; days since 0 AD
              doy: 0,                   $ ; day of year (1-366)
              dow: 0,                   $ ; day of week (1-7)
              sod: 0,                   $ ; seconds of day (1-86400)
              dst: 0,                   $ ; daylight savings time flag
              tZone: 0,                 $ ; time zone (Pacific time is -8)
              tDiff: 0.0,               $ ; hours from UTC
              debug: 0                  $ ; set this value to one for debugging

}

END

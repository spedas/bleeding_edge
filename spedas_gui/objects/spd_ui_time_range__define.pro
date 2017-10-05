;+ 
;NAME: 
; spd_ui_time_range__define
;
;PURPOSE:  
; time range object 
;
;CALLING SEQUENCE:
; timeRange = Obj_New("SPD_UI_TIME_RANGE")
;
;INPUT:
; none
;
;KEYWORDS:
; startTime  start time 
; endTime    end time        
;
;OUTPUT:
; time range object reference
;
;METHODS:
; SetProperty  procedure to set keywords 
; GetProperty  procedure to get keywords
; GetStartTime returns the start time (default format is double)
; GetEndTime  returns the stop time (default format is double)
; GetDuration  returns duration in seconds 
; SetStartTime set start time
; SetEndTime   set end time
;HISTORY:
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2015-07-13 09:09:53 -0700 (Mon, 13 Jul 2015) $
;$LastChangedRevision: 18094 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/objects/spd_ui_time_range__define.pro $
;-----------------------------------------------------------------------------------



FUNCTION SPD_UI_TIME_RANGE::Copy
   out=Obj_New("SPD_UI_TIME_RANGE")
  ; newStart=Obj_New("SPD_UI_TIME")
  ; newEnd=Obj_New("SPD_UI_TIME")
   IF Obj_Valid(self.startTime) THEN newStart = self.startTime->Copy() ELSE $
      newStart = Obj_New()
   IF Obj_Valid(self.endTime) THEN newEnd = self.endTime->Copy() ELSE $
      newEnd = Obj_New()
   out->SetProperty, StartTime=newStart, EndTime=newEnd
   RETURN, out
END ;--------------------------------------------------------------------------------

FUNCTION SPD_UI_TIME_RANGE::GetStartTime, String=string
IF Keyword_Set(string) THEN self.startTime->GetProperty, TString=starttime $
   ELSE self.startTime->GetProperty, TDouble=starttime
RETURN, starttime
END ;--------------------------------------------------------------------------------



FUNCTION SPD_UI_TIME_RANGE::GetEndTime, String=string
IF Keyword_Set(string) THEN self.endTime->GetProperty, TString=endtime $
   ELSE self.endTime->GetProperty, TDouble=endtime
RETURN, endtime
END ;--------------------------------------------------------------------------------



FUNCTION SPD_UI_TIME_RANGE::GetDuration
self.startTime->GetProperty, TDouble=starttime
self.endTime->GetProperty, TDouble=endtime
RETURN, endtime - starttime
END ;--------------------------------------------------------------------------------


FUNCTION SPD_UI_TIME_RANGE::SetStartTime, starttime
   startType = Size(starttime, /Type)
   CASE startType OF
;   double precision
     5:  self.starttime -> SetProperty, TDouble = starttime
;   string
     7:  self.starttime -> SetProperty, TString = starttime
;   object - don't need to do anything
     11: self.starttime = starttime
;   if not one of the above types - something went wrong
     ELSE: RETURN, 0b
   ENDCASE 
RETURN, 1b
END ;--------------------------------------------------------------------------------


FUNCTION SPD_UI_TIME_RANGE::SetEndTime, endtime
   endType = Size(endtime, /Type)
   CASE endType OF
;   double precision
     5:  self.endtime -> SetProperty, TDouble = endtime
;   string
     7:  self.endtime -> SetProperty, TString = endtime
;   object - don't need to do anything
     11: self.endtime = endtime
;   if not one of the above types - something went wrong
     ELSE: RETURN, 0b
   ENDCASE 
RETURN, 1b
END ;--------------------------------------------------------------------------------



PRO SPD_UI_TIME_RANGE::Cleanup
    Obj_Destroy, self.startTime
    Obj_Destroy, self.endTime
END ;--------------------------------------------------------------------------------



FUNCTION SPD_UI_TIME_RANGE::Init, $
      StartTime=starttime,        $ ; start time 
      EndTime=endtime,            $ ; end time           
      Debug=debug                   ; flag to debug

   Catch, theError
   IF theError NE 0 THEN BEGIN
      Catch, /Cancel
      ok = Error_Message(Traceback=Keyword_Set(debug))
      RETURN, 0
   ENDIF
   
      ; start time, figure out what type of data was passed
      ; and set it appropriately
      
   startType = Size(starttime, /Type)
   CASE startType OF
      ;   undefined - set to default time object 
      0:  starttime = Obj_New("SPD_UI_TIME") 
      ;   double precision
      5:  starttime = Obj_New("SPD_UI_TIME", TDouble=starttime) 
      ;   string
      7:  starttime = Obj_New("SPD_UI_TIME", TString=starttime)
      ;   object - don't need to do anything
      11: starttime = starttime
      ;   if not one of the above types - something went wrong
     ELSE: RETURN, 0
   ENDCASE 

      ; end time, figure out what type of data was passed
      ; and set it appropriately
      
   endType = Size(endtime, /Type)   
   CASE endType OF
      ;   undefined - set to default time object 
      0:  endtime = Obj_New("SPD_UI_TIME") 
      ;   double precision
      5:  endtime = Obj_New("SPD_UI_TIME", TDouble=endtime) 
      ;   string
      7:  endtime = Obj_New("SPD_UI_TIME", TString=endtime)
      ;   object - don't need to do anything
      11: endtime = endtime
      ;   if not one of the above types - something went wrong
     ELSE: RETURN, 0
   ENDCASE 
   
      ; Set all time range object attributes

   self.startTime = starttime
   self.endTime = endtime
                 
RETURN, 1
END ;--------------------------------------------------------------------------------



PRO SPD_UI_TIME_RANGE__DEFINE

   struct = { SPD_UI_TIME_RANGE,   $

      startTime : Obj_New(),   $ ; start time 
      endTime : Obj_New(),      $ ; end time
      inherits spd_ui_getset $  ;general purpose getProperty/setProperty/getAll/setAll methods
 
}

END

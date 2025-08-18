PRO spd_ui_display_tracking_data, xy, event, showPosition, data

      ; Catch any errors here
      
   Catch, theError
   IF theError NE 0 THEN BEGIN
      Catch, /Cancel
      ok = Error_Message(Traceback=1)
      RETURN
   ENDIF

   red=GetColor('Red', !d.table_size-3)
   blue=GetColor('Blue', !d.table_size-4)
   green=GetColor('Green', !d.table_size-5)
   
      ; this is a kluge, need to have interpolation routine available
      
   IF data EQ 0 THEN BEGIN        
      IF event.x LT 84 or event.x GT 917 THEN BEGIN
      ENDIF ELSE BEGIN
         xyOuts, 0.92, 0.9,String(StrCompress(xy(0))), /Normal, Charsize=0.8
         xyOuts, 0.92, 0.885, String(StrCompress(xy(1))), /Normal, Charsize=0.8, Color=red
         xyOuts, 0.92, 0.87, String(StrCompress(event.x)), /Normal, Charsize=0.8, Color=green
         xyOuts, 0.92, 0.855, String(StrCompress(event.Y)), /Normal, CharSize=0.8, Color=blue
         xyOuts, 0.92, 0.6, String(StrCompress(xy(0))), /Normal, CharSize=0.8
         xyOuts, 0.92, 0.585, String(StrCompress(xy(1))), /Normal, CharSize=0.8, Color=red
         xyOuts, 0.92, 0.57, String(StrCompress(event.x)), /Normal, CharSize=0.8, Color=green
         xyOuts, 0.92, 0.555, String(StrCompress(event.Y)), /Normal, CharSize=0.8, Color=blue
         xyOuts, 0.92, 0.3, String(StrCompress(xy(0))), /Normal, CharSize=0.8
         xyOuts, 0.92, 0.285, String(StrCompress(xy(1))), /Normal, CharSize=0.8, Color=red
         xyOuts, 0.92, 0.27, String(StrCompress(event.x)), /Normal, CharSize=0.8, Color=green
         xyOuts, 0.92, 0.255, String(StrCompress(event.Y)), /Normal, CharSize=0.8, Color=blue
         result = Widget_Info(showPosition, /Button_Set)
         IF result NE 0 THEN BEGIN                
            xyOuts, 0.92, 0.09, String(StrCompress(xy(1))), /Normal, CharSize=0.8, Color=red
            xyOuts, 0.92, 0.075, String(StrCompress(event.x)), /Normal, CharSize=0.8, Color=red
            xyOuts, 0.92, 0.06, String(StrCompress(event.Y)), /Normal, CharSize=0.8, Color=red
         ENDIF
      ENDELSE
   ENDIF ELSE BEGIN
      xyOuts, 0.92, 0.9,String(StrCompress(xy(0))), /Normal, CharSize=0.8
      xyOuts, 0.92, 0.885, String(StrCompress(xy(1))), /Normal, CharSize=0.8, Color=blue
   ENDELSE
   
RETURN
END

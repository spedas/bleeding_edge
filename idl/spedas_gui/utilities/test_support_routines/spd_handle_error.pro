;+
;procedure: spd_handle_error
;
; purpose: Properly prints and stores the result of a testscript test,
;          regardless of whether a test succeeded or failed
;
;
; $LastChangedBy: aaflores $
; $LastChangedDate: 2015-07-27 10:25:20 -0700 (Mon, 27 Jul 2015) $
; $LastChangedRevision: 18285 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/utilities/test_support_routines/spd_handle_error.pro $
;-

pro spd_handle_error, e, t_name, t_num

compile_opt idl2

  ;bwahahahahha
  outputs = csvector(0,!output,/read)
  
  tmp = csvector(!output,/free)

  if(e ne 0) then begin
          

    outputs = csvector("Test" + strcompress(string(t_num)) + " Failed: " + t_name,outputs)
    outputs=  csvector("ERROR: "+ strcompress(string(e)),outputs)
    Help, /Last_Message, Output=theErrorMessage
    for i=0,n_elements(theErrorMessage)-1 do outputs=csvector("ERROR: "+theErrorMessage[i],outputs)

    outputs = csvector('',outputs)
    
    print, "Test" + strcompress(string(t_num)) + " Failed: " + t_name
    print, "ERROR: ", e
    Help, /Last_Message, Output=theErrorMessage
    print, "ERROR: ",theErrorMessage

  endif else begin

      outputs=csvector("Test" + strcompress(string(t_num)) + " Succeeded: " + t_name,outputs)

      print, "Test" + strcompress(string(t_num)) + " Succeeded: " + t_name

  endelse

  !output = csvector(outputs)

end

;+
; PROCEDURE sd_init
; 
; :DESCRIPTION:
;    Initialize the environment for drawing SD data 
;
; :NOTE:
;    This procedure is called automatically on executing most of 
;    sd_*.pro.   
;    
;
; :AUTHOR: 
;   Tomo Hori (E-mail: horit@isee.nagoya-u.ac.jp)
; :HISTORY: 
;   2010/03/10: Created
;   2014/08/12: Major changes to move on to the new "map2d" environment 
;   
; $LastChangedDate: 2019-03-17 21:51:57 -0700 (Sun, 17 Mar 2019) $
; $LastChangedRevision: 26838 $
;-
pro sd_init, reset=reset

;Initialize the map2d environment 
map2d_init  ; To set only the AACGM DLM flag for now

defsysv,'!sdarn',exists=exists
if (not keyword_set(exists)) or (keyword_set(reset)) then begin

  ;Set the AACGM coef. file path and year list
  aacgmfindcoeffile, prefix, yrlist
  
  defsysv,'!sdarn', $
    { $
      init: 0 $
      ,sd_polar: { $
                  charsize: 1.0 $
                } $
      ,remote_data_dir:'http://ergsc.isee.nagoya-u.ac.jp/data/ergsc/ground/radar/sd/fitacf/' $
      , aacgm: { $
                  coefprefix:prefix $
                  , coefyrlist:yrlist $
                } $
    }
    
    
    
endif

if keyword_set(reset) then !sdarn.init=0

if !sdarn.init ne 0 then return


!sdarn.init = 1

return
end

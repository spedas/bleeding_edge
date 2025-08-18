;+
;
;spd_ui_draw_object method: niceNumTime
;
;Function adapted from Graphics Gems:
;Heckbert, Paul S., Nice Numbers for Graph Labels, Graphics Gems, p. 61-63, code: p. 657-659
;It identifies the closest "nice" number
;Nice being a number j * 10 ^ n where j = 1,2,5 and n = any integer
;
;This routine performs nicenum on a time in seconds, it will
;account for whether the input is closer to an hour or a minute or a day.
;Good factors to use with this routine are [1,2,3,6,10]
; 
;Its Input/Output/Return parameter are identifcal to niceNum
;
;$LastChangedBy: jimm $
;$LastChangedDate: 2014-02-11 10:54:32 -0800 (Tue, 11 Feb 2014) $
;$LastChangedRevision: 14326 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/display/draw_object/spd_ui_draw_object__nicenumtime.pro $
;-

function spd_ui_draw_object::niceNumTime,n,factor_index=factor_index,_extra=ex

  compile_opt idl2,hidden

  if n le 60D then begin
    return,self->niceNum(n,factor_index=factor_index,_extra=ex)
  endif else if n le 60D*60D then begin
    return,self->niceNum(n/60D,factor_index=factor_index,_extra=ex)*60D
  endif else if n le 60D*60D*24D then begin
    return,self->niceNum(n/(60D*60D),factor_index=factor_index,_extra=ex)*60D*60D
  endif else begin
    return,self->niceNum(n/(60D*60D*24D),factor_index=factor_index,_extra=ex)*60D*60D*24D
  endelse
  
end

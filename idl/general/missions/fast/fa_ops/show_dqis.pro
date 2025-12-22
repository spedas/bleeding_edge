;+
; PROCEDURE:
; 	 SHOW_DQIS
;
; DESCRIPTION:
;
;	Procedure to show what sdt data quantities are loaded into 
;	local shared memory.  These quantities should be accessable
;	from the loadSDTBuf package.
;
; CALLING SEQUENCE:
;
;	show_dqis
;
; REVISION HISTORY:
;
;	@(#)show_dqis.pro	1.4 08/19/97
; 	Originally written by Jonathan M. Loran,  University of 
; 	California at Berkeley, Space Sciences Lab.   Sep '95
;       Added RESULT keyword 19-Aug-97, Bill Peria
;-

pro show_dqis, result = result

prog = getenv('FASTBIN') + '/showDQIs'

if defined(result) then begin
    spawn, prog, result, /noshell
endif else begin
    spawn, prog, /noshell
endelse

end

;+
;PROCEDURE:  xyouts2,[x,y,],string,pnorm=pnorm,_extra=e
;INPUT:
;	x,y	real,fltarr(n)		position on plot for string (optional)
;					if not set, default to xyouts.pro
;	string	string,strarr(n)	character string(s) to add to plot
;
;KEYWORDS:
;	PNORM:	0,1		If set, normalize to the current plot box
;				If not set, default to xyouts.pro
;PURPOSE:  
;	Same as xyouts except will normalize to the current plot box
;
;CREATED BY:	J.McFadden	97-3-10
;LAST MODIFICATION:  97-3-10
;MOD HISTORY
;-

pro xyouts2,x,y,string,pnorm=pnorm,_extra=e

if n_params() ne 1 and n_params() ne 3 then begin
	print,' Wrong format, Use: xyouts2,[x,y,]string,pnorm=pnorm,...'
	return
endif

if keyword_set(pnorm) and n_params() eq 3 then begin
	xn=!x.window(0)*(1-x)+!x.window(1)*x
	yn=!y.window(0)*(1-y)+!y.window(1)*y
	xyouts,xn,yn,string,_extra=e
endif else begin
	if n_params() eq 3 then xyouts,x,y,string,_extra=e else xyouts,x,_extra=e 
endelse

return
end
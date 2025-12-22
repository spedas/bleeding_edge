;+
; NAME: INT_UP_TO
;
; PURPOSE: Computes the succesive definite integrals of an array 
;
; CALLING SEQUENCE: int = int_up_to(time,data)
; 
; INPUTS: TIME - the independent variable 
;         DATA - dependent variable
;
;
; KEYWORDS: ADAMS - if set, uses the somewhat more accurate
;           Adams-Bashforth two-step method. 
;
;                    /time
; OUTPUTS: INT =     |        data*d(time)
;                    /time(0)
;
;
; RESTRICTIONS: You must make sure about things like sufficient
;               resolution, etc., because no error estimate or sorting
;               or anything of the kind is done, and the area under
;               the curve between adjacent points is approximated by a
;               trapezoid. 
;
; MODIFICATION HISTORY: written long, long ago by Bill Peria. Finally
;                       documented 16-March-1997. 
;
;-
;	@(#)int_up_to.pro	1.8	01/31/00
function int_up_to,tcall,xcall,ADAMS=adams, OLD_WAY = old_way

not_nan = where((tcall eq tcall) and (xcall eq xcall),nnn)
nan = where((tcall ne tcall) or (xcall ne xcall),nnan)

if nnn eq 0 then begin
    message,' Input is all NaN''s!',/continue
    return,replicate(!values.f_nan, nnan)
endif

t = tcall(not_nan)
x = xcall(not_nan)

nt = long(n_elements(t))

if nt lt 3 then begin
    case nt of 
        1:return,[0.0]
        2:return,[0.0,(t[1]-t[0])*(x[1]+x[0])/2.0]
    endcase
endif

if keyword_set(adams) then begin
    message,'ADAMS keyword is obsolete...using trapezoidal ' + $
      'rule...',/continue
endif

i1 = dblarr(nt)
dt = t - shift(t,1) 
dt(0) = dt(1)
dt(nt-1) = dt(nt-2)
sx = x + shift(x,1)
sx(0) = sx(1)
sx(nt-1l) = sx(nt-2l)

if keyword_set(old_way) then begin
    i1(0) = 0.0
    for i=1l,nt-2l do begin
        i1(i) = i1(i-1l) + sx(i)*dt(i)
    endfor
    i1(nt-1l) = i1(nt-2l) + (i1(nt-2l) - i1(nt-3l))
    i1 = i1/2.0
endif else begin
    a = dblarr(nt) - 1.d
    b = a + 2.d
    c = b - b
    r = sx * dt
    i1 = trisol(a, b, c, r)/2.0 - r[0]/2.
endelse

if nnan ne 0 then begin
    i1r = allocatearray(data_type(xcall),1,n_elements(xcall))
    i1r(not_nan) = i1
    i1r(nan) = !values.f_nan
endif else begin
    i1r = temporary(i1)
endelse

return,i1r

end

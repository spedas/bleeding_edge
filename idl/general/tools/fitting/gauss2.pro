;+
;FUNCTION:  GAUSS
;PURPOSE:
;  Evaluates a gaussian function with background.
;  This function may be used with the "fit" curve fitting procedure.
;
;KEYWORDS:
;  PARAMETERS: structure with the format:
;** Structure <275ac0>, 6 tags, length=48, refs=1:
;   a               DOUBLE           1.0000000      ; area
;   s               DOUBLE           1.0000000      ; sigma
;   X0              DOUBLE           0.0000000      ; center
;     If this parameter is not a structure then it will be created.
;
;USAGE:
;  x = findgen(100)/10.
;  y = gaussian(x,par=p)
;  plot,x,y
;RETURNS:
;  result
;-

function gauss2, x, parameters=p

if not keyword_set(p) then $
   p = {func:"gauss2",a:1.d, x0:0.d, s:1.0d}  ;, a0:0.d, a1:0.d, a2:0.d }

if n_params() eq 0 then return,p

z = (x - p.x0)/p.s
e = exp(- z^2/2 )
height = p.a / p.s / sqrt(2*!dpi)
f =  height * e                               ; +p.a0 + p.a1*x +  p.a2*x^2

return,f
end



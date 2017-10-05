function defined,var
;+
;  brief way to check if a variable has been defined yet. 
;   returns 1 for defined variables, 0 for undefined. 
;  
;  example:
;
;      if defined(x) then begin
;          do_stuff_to(x)
;      endif
;
;  Originally written 9-July-1996 by Bill Peria
;-
s = size(var)
return,(s(s(0)+1) ne 0)
end

function func,x,y,z,parameter=p,_extra=ex
;on_error,2
;common func_com,func_parameter
;ptype = size(p,/type)
;valid = (ptype eq 8 or ptype eq 7)
;if not valid then p=func_parameter
;if not keyword_set(x) then x=dgen()
if ~keyword_set(p) then begin
   dprint,'No function or parameter defined'
   return,0
endif
case n_params() of
  0:  f = (size(/type,p) eq 8) ? call_function(p.func,param=p,_extra=ex) : call_function(p,_extra=ex)
  1:  f = (size(/type,p) eq 8) ? call_function(p.func,x,param=p,_extra=ex) : call_function(p,x,_extra=ex)
  2:  f = (size(/type,p) eq 8) ? call_function(p.func,x,y,param=p) : call_function(p,x,y)
  3:  f = (size(/type,p) eq 8) ? call_function(p.func,x,y,z,param=p) : call_function(p,x,y,z)
endcase
;if valid then func_parameter=p
return,f
end

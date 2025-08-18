
;+
;
;Procedure: mini_routines
;
;Purpose:  Compiles a bunch of routines used to describe the evaluation rules
;          used by the language.  
;          
;          productions.pro actually describes which syntactical
;          rules used to compose each of the routines in this file.
;          
;          Routines in this file should be used to evaluate a production.
;          Helper routines should go in evaluator_routines.pro or mini_predicates.pro
;          Exceptions: function_list,operator_list,get_function,mini_routines
;
;TODO: 1. need to include linear algebraic functions in the set of available routines
;        (crossp,norm,normalize), also multivariable calculus functions(gradient,curl)
;        /nan flag set whenever possible, & statistical routines, skew,kurtosis,variance,stddev
;
;      2. consider putting function/operator list inside common block
;
; NOTES:
;      these routines are intentionally designed to preserve type
;      i.e. not upgrade float to double or short to long unless required
;      It leaves decisions about type to the evaluator and/or user 
;      trigonometric routines will transform inputs into floating point,
;      however
;
;
; $LastChangedBy: pcruce $
; $LastChangedDate: 2016-08-02 16:55:11 -0700 (Tue, 02 Aug 2016) $
; $LastChangedRevision: 21594 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/mini/mini_routines.pro $
;- 

function mini_log,arg_list

  compile_opt hidden,strictarr

  evaluator_routines
  
  keyword_list = ''
  
  validate_mini_func_args,1,1,keyword_list,arg_list
  
  out = get_positional_arg(arg_list,0)
  
  b = get_positional_arg(arg_list,1)

  if ~keyword_set(b) then begin
    out.data = alog10(out.data)
  endif else begin
    out.data = alog10(out.data) / alog10(b.data)
  endelse
  
  return,out

end

function mini_ln,arg_list

  compile_opt hidden,strictarr
  
  evaluator_routines
  
  keyword_list = ''
  
  validate_mini_func_args,1,0,keyword_list,arg_list
  
  out = get_positional_arg(arg_list,0)
  
  out.data = alog(out.data)
  
  return,out
  
end

function mini_exp,arg_list

  compile_opt hidden,strictarr
  
  evaluator_routines
  
  keyword_list = ''
  
  validate_mini_func_args,1,1,keyword_list,arg_list
  
  out = get_positional_arg(arg_list,0)
  
  b = get_positional_arg(arg_list,1)
  
  if ~keyword_set(b) then begin
    out.data = exp(out.data)
  endif else begin
    out.data = b.data ^ out.data
  endelse
  
  return,out
  
end

function mini_sqrt,arg_list

  compile_opt hidden,strictarr
  
  evaluator_routines
  
  keyword_list = ''
  
  validate_mini_func_args,1,0,keyword_list,arg_list
  
  out = get_positional_arg(arg_list,0)
  
  out.data = sqrt(out.data)
  
  return,out
  
end
  
function mini_abs,arg_list

  compile_opt hidden,strictarr
  
  evaluator_routines
  
  keyword_list = ''
  
  validate_mini_func_args,1,0,keyword_list,arg_list
  
  out = get_positional_arg(arg_list,0)
  
  out.data = abs(out.data)
  
  return,out
  
end
  
function mini_sin,arg_list

  compile_opt hidden,strictarr
  
  evaluator_routines
  
  keyword_list = ''
  
  validate_mini_func_args,1,0,keyword_list,arg_list
  
  out = get_positional_arg(arg_list,0)
    
  out.data = sin(out.data)
  
  return,out
  
end 

function mini_asin,arg_list

  compile_opt hidden,strictarr
  
  evaluator_routines
  
  keyword_list = ''
  
  validate_mini_func_args,1,0,keyword_list,arg_list
  
  out = get_positional_arg(arg_list,0)
  
  out.data = asin(out.data)
  
  return,out
  
end 

function mini_sinh,arg_list

  compile_opt hidden,strictarr
  
  evaluator_routines
  
  keyword_list = ''
  
  validate_mini_func_args,1,0,keyword_list,arg_list
  
  out = get_positional_arg(arg_list,0)
  
  out.data = sinh(out.data)
  
  return,out
  
end 

function mini_asinh,arg_list

  compile_opt hidden,strictarr

  evaluator_routines

  keyword_list = ''

  validate_mini_func_args,1,0,keyword_list,arg_list

  out = get_positional_arg(arg_list,0)

  out.data = alog(out.data + sqrt(out.data*out.data+1.))

  return,out

end


function mini_cos,arg_list

  compile_opt hidden,strictarr
  
  evaluator_routines
  
  keyword_list = ''
  
  validate_mini_func_args,1,0,keyword_list,arg_list
  
  out = get_positional_arg(arg_list,0)
  
  out.data = cos(out.data)
  
  return,out
  
end 

function mini_acos,arg_list

  compile_opt hidden,strictarr
  
  evaluator_routines
  
  keyword_list = ''
  
  validate_mini_func_args,1,0,keyword_list,arg_list
  
  out = get_positional_arg(arg_list,0)
  
  out.data = acos(out.data)
  
  return,out
  
end 

function mini_cosh,arg_list

  compile_opt hidden,strictarr
  

  evaluator_routines
  
  keyword_list = ''
  
  validate_mini_func_args,1,0,keyword_list,arg_list
  
  out = get_positional_arg(arg_list,0)
  
  out.data = cosh(out.data)
  
  return,out
  
end 

function mini_acosh,arg_list

  compile_opt hidden,strictarr

  evaluator_routines

  keyword_list = ''

  validate_mini_func_args,1,0,keyword_list,arg_list

  out = get_positional_arg(arg_list,0)

  out.data = alog(out.data + sqrt(out.data*out.data-1.))

  return,out

end

function mini_tan,arg_list

  compile_opt hidden,strictarr
  
  evaluator_routines
  
  keyword_list = ''
  
  validate_mini_func_args,1,0,keyword_list,arg_list
  
  out = get_positional_arg(arg_list,0)
  
  out.data = tan(out.data)
  
  return,out
  
end 

function mini_atan,arg_list

  compile_opt hidden,strictarr
  
  evaluator_routines
  
  keyword_list = ''
  
  validate_mini_func_args,1,0,keyword_list,arg_list
  
  out = get_positional_arg(arg_list,0)
  
  out.data = atan(out.data)
  
  return,out
  
end 

function mini_tanh,arg_list

  compile_opt hidden,strictarr
  
  evaluator_routines
  
  keyword_list = ''
  
  validate_mini_func_args,1,0,keyword_list,arg_list
  
  out = get_positional_arg(arg_list,0)
  
  out.data = tanh(out.data)
  
  return,out
  
end 

function mini_atanh,arg_list

  compile_opt hidden,strictarr

  evaluator_routines

  keyword_list = ''

  validate_mini_func_args,1,0,keyword_list,arg_list

  out = get_positional_arg(arg_list,0)

  out.data = alog((1.+out.data)/(1.-out.data))/2.

  return,out

end

function mini_cosecant,arg_list

  compile_opt hidden,strictarr

  evaluator_routines
  
  keyword_list = ''
  
  validate_mini_func_args,1,0,keyword_list,arg_list
  
  out = get_positional_arg(arg_list,0)

  out.data = 1./sin(out.data)
  
  return,out

end

function mini_arccosecant,arg_list

  compile_opt hidden,strictarr

  evaluator_routines
  
  keyword_list = ''
  
  validate_mini_func_args,1,0,keyword_list,arg_list
  
  out = get_positional_arg(arg_list,0)

  out.data = asin(1./out.data)
  
  return,out

end

function mini_cosecanthyp,arg_list

  compile_opt hidden,strictarr

  evaluator_routines
  
  keyword_list = ''
  
  validate_mini_func_args,1,0,keyword_list,arg_list
  
  out = get_positional_arg(arg_list,0)
  
  out.data = 1./sinh(out.data)
  
  return,out
  
end

function mini_arccosecanthyp,arg_list

  compile_opt hidden,strictarr

  evaluator_routines

  keyword_list = ''

  validate_mini_func_args,1,0,keyword_list,arg_list

  out = get_positional_arg(arg_list,0)

  out.data = alog((1.+sqrt(out.data*out.data+1.))/out.data)

  return,out

end

function mini_secant,arg_list

  compile_opt hidden,strictarr

  evaluator_routines
  
  keyword_list = ''
  
  validate_mini_func_args,1,0,keyword_list,arg_list
  
  out = get_positional_arg(arg_list,0)

  out.data = 1./cos(out.data)
  
  return,out

end

function mini_arcsecant,arg_list

  compile_opt hidden,strictarr
  
  evaluator_routines
  
  keyword_list = ''
  
  validate_mini_func_args,1,0,keyword_list,arg_list
  
  out = get_positional_arg(arg_list,0)
  
  out.data = acos(1./out.data)
  
  return,out

end

function mini_secanthyp,arg_list

  compile_opt hidden,strictarr
  
  evaluator_routines
  
  keyword_list = ''
  
  validate_mini_func_args,1,0,keyword_list,arg_list
  
  out = get_positional_arg(arg_list,0)
  
  out.data = 1./cosh(out.data)
  
  return,out
  
end

function mini_arcsecanthyp,arg_list

  compile_opt hidden,strictarr

  evaluator_routines

  keyword_list = ''

  validate_mini_func_args,1,0,keyword_list,arg_list

  out = get_positional_arg(arg_list,0)

  out.data = alog((1.+sqrt(1.-out.data*out.data))/out.data)
  
  return,out

end

function mini_cotangent,arg_list

  compile_opt hidden,strictarr
  
  evaluator_routines
  
  keyword_list = ''
  
  validate_mini_func_args,1,0,keyword_list,arg_list
  
  out = get_positional_arg(arg_list,0)
  
  out.data = cos(out.data)/sin(out.data)
  
  return,out

end

function mini_arccotangent,arg_list

  compile_opt hidden,strictarr
  
  evaluator_routines
  
  keyword_list = ''
  
  validate_mini_func_args,1,0,keyword_list,arg_list
  
  x = get_positional_arg(arg_list,0)
  
  out = x
  
  if is_num(x.data,/double) then begin ;prevent accidental type upgrade
    pi = !DPI
  endif else begin
    pi = !PI
  endelse
  
  if ~is_array(x.data) then begin  ;single element case
    if x.data lt 0 then begin
      out.data = atan(1/x.data)+pi
    endif else begin
      out.data = atan(1/x.data)
    endelse
  endif else begin  ;array case
  
    out.data = atan(1/x.data)
    
    idx = where(x.data lt 0)
    
    if idx[0L] ne -1 then begin
      out.data[idx] += pi
    endif
 
  endelse
  
  return,out
      
end

function mini_cotangenthyp,arg_list

  compile_opt hidden,strictarr
  
  evaluator_routines
  
  keyword_list = ''
  
  validate_mini_func_args,1,0,keyword_list,arg_list
  
  out = get_positional_arg(arg_list,0)
  
  out.data = cosh(out.data)/sinh(out.data)
  
  return,out
  
end

function mini_arccotangenthyp,arg_list

  compile_opt hidden,strictarr

  evaluator_routines

  keyword_list = ''

  validate_mini_func_args,1,0,keyword_list,arg_list

  out = get_positional_arg(arg_list,0)

  out.data = alog((out.data+1.)/(out.data-1))/2.

  return,out

end

function mini_min,arg_list

  compile_opt hidden,strictarr
   
  evaluator_routines
  
  keyword_list = ['nan','subscript']
  
  validate_mini_func_args,1,1,keyword_list,arg_list
  
  x = get_positional_arg(arg_list,0)
  d = get_positional_arg(arg_list,1)
  nan = is_mini_keyword_set(arg_list,keyword_list[0])
  subscript = is_mini_keyword_set(arg_list,keyword_list[1])
  
  if keyword_set(d) then begin 
    data = dim_correct_data(min(x.data,sub,dim=d.data,nan=nan),ndimen(x.data),d.data)
  endif else begin
    data = min(x.data,sub,nan=nan)
  endelse

  if keyword_set(subscript) then begin
    sub_arg = get_keyword_arg(arg_list,subscript-1)
    store_var_data,sub_arg.value2,{data:sub}
  endif

  return,reduce_dlimits(reduce_yvalues(reduce_times(replace_data(x,data),d),d),'min',d)
   
end

function mini_max,arg_list

  compile_opt hidden,strictarr
  
  evaluator_routines
  
  keyword_list = ['nan','subscript']
  
  validate_mini_func_args,1,1,keyword_list,arg_list
  
  x = get_positional_arg(arg_list,0)
  d = get_positional_arg(arg_list,1)
  nan = is_mini_keyword_set(arg_list,keyword_list[0])
  subscript = is_mini_keyword_set(arg_list,keyword_list[1])
  
  if keyword_set(d) then begin
    data = dim_correct_data(max(x.data,sub,dim=d.data,nan=nan),ndimen(x.data),d.data)
  endif else begin
    data = max(x.data,sub,nan=nan)
  endelse
  
  if keyword_set(subscript) then begin
    sub_arg = get_keyword_arg(arg_list,subscript-1)
    store_var_data,sub_arg.value2,{data:sub}
  endif
  
  return,reduce_dlimits(reduce_yvalues(reduce_times(replace_data(x,data),d),d),'max',d)

end

function mini_mean,arg_list

  compile_opt hidden,strictarr

  evaluator_routines
  
  keyword_list = ['nan']
  
  validate_mini_func_args,1,1,keyword_list,arg_list
  
  x = get_positional_arg(arg_list,0)
  d = get_positional_arg(arg_list,1)
  nan = is_mini_keyword_set(arg_list,keyword_list[0])

  if keyword_set(d) then begin
    data = dim_correct_data(average(x.data,d.data,nan=nan),ndimen(x.data),d.data)
  endif else begin
    data = average(x.data,nan=nan)
  endelse
  
  return,reduce_dlimits(reduce_yvalues(reduce_times(replace_data(x,data),d),d),'mean',d)

end

function mini_median,arg_list

  compile_opt hidden,strictarr

  evaluator_routines
  
  keyword_list = ['even']
  
  validate_mini_func_args,1,1,keyword_list,arg_list
  
  x = get_positional_arg(arg_list,0)
  d = get_positional_arg(arg_list,1)
  even = is_mini_keyword_set(arg_list,keyword_list[0])
  
  if keyword_set(d) then begin
    data = dim_correct_data(median(ndimen(x.data)?x.data:[x.data],dim=d.data,even=even),ndimen(x.data),d.data)
  endif else begin
    data = median(ndimen(x.data)?x.data:[x.data],even=even)
  endelse
    
  return,reduce_dlimits(reduce_yvalues(reduce_times(replace_data(x,data),d),d),'median',d)

end

function mini_count,arg_list

  compile_opt hidden,strictarr

  evaluator_routines

  keyword_list = ''
  
  validate_mini_func_args,1,1,keyword_list,arg_list
  
  x = get_positional_arg(arg_list,0)
  d = get_positional_arg(arg_list,1)
  
  if keyword_set(d) then begin
    data = (size(x.data,/dimensions))[d.data-1L]
  endif else begin  
    data = n_elements(x.data)
  endelse
  
  return,reduce_dlimits(reduce_yvalues(reduce_times(replace_data(x,data))),'#',d)
 
end

function mini_total,arg_list
    
  compile_opt hidden,strictarr
  
  evaluator_routines
  
  keyword_list = ['nan','cumulative']
  
  validate_mini_func_args,1,1,keyword_list,arg_list
  
  x = get_positional_arg(arg_list,0)
  d = get_positional_arg(arg_list,1)
  nan = is_mini_keyword_set(arg_list,keyword_list[0])
  cumulative = is_mini_keyword_set(arg_list,keyword_list[1])
    
  if keyword_set(d) then begin
    if ~keyword_set(cumulative) then begin
      data = dim_correct_data(total(x.data,d.data,nan=nan),ndimen(x.data),d.data)
    endif else begin ;no dimension reduction occurs if the /cumulative keyword is set, even if d is set
      data = total(x.data,d.data,nan=nan,cumulative=cumulative)
    endelse
  endif else begin
    data = total(x.data,nan=nan,cumulative=cumulative)
  endelse
  
  if keyword_set(cumulative) then begin ;no dimension reduction occurs if the /cumulative keyword is set, even if d is set
    return,reduce_dlimits(reduce_yvalues(reduce_times(replace_data(x,data))),'total')
  endif else begin
    return,reduce_dlimits(reduce_yvalues(reduce_times(replace_data(x,data),d),d),'total',d)
  endelse
  
 
end

function mini_return,arg

  compile_opt hidden,strictarr
  
  if ~keyword_set(arg) then begin
    message,'No arg passed to mini_return'
  endif
  
  return,arg
  
end

function mini_number,arg

  compile_opt hidden,strictarr
  
  if ~keyword_set(arg) then begin
    message,'No arg passed to mini_return'
  endif
  
  return,{type:'literal_data',name:arg.name,data:arg.value}
  
end

;This routine breaks token abstraction for operators/assignments
;It should be fixed
function mini_assign,arg1,arg2,arg3

  compile_opt hidden,strictarr
  
  evaluator_routines
  mini_predicates
  
  if ~is_assignment_type(arg2) then begin
    message,'Arg2 to mini_assign not assignment type'
  endif
  
  if arg2.value ne '=' then begin
    
    op = arg2
    
    op.type = 'operator'
    op.name = op.value
    
    var = mini_var(arg1)
    
    value = mini_bop(var,op,arg3)
    
  endif else begin
  
    value = arg3
    
  endelse
  
  store_var_data,arg1,value
  
  return,{type:'empty'}
  
end

function mini_var,arg1

  compile_opt hidden,strictarr
  
  evaluator_routines
  mini_predicates
  
  if is_tvar_type(arg1) then begin
  
    if obj_valid(!mini_globals.gui_data_obj) then begin
      ;export variable to tplot
      tname = !mini_globals.gui_data_obj->getTvarData(arg1.value)
      
      if tname eq '' then begin
        message,'error reading gui variable: ' + arg1.value
      endif
      get_data,arg1.value,data=d,limit=l,dlimit=dl
      
      ;quick hack to implement gui variables
      ;I store the inherited meta-data in the dlimits
      ;(af 2015-05-08) - Hack no longer necessary, but 
      ; I'm leaving the struct-in-struct lest everything break
      dl = {dlimits:dl}
    endif else begin
  
      get_data,arg1.value,data=d,limit=l,dlimit=dl
    
      if ~is_struct(d) then begin
        message,'error reading tplot variable: ' + arg1.value
      endif
      
    endelse
    
    return,make_tvar_data(arg1.value,d,l,dl)
    
  endif else if is_var_type(arg1) then begin
  
    varnames = scope_varname(level=!mini_globals.scope_level)
    
    idx = where(strupcase(arg1.value) eq varnames,c)
    
    if ~in_set(strupcase(arg1.value),varnames) then begin
      message,'error reading variable: ' + arg1.value
    endif
  
    return,make_var_data(arg1.value,scope_varfetch(arg1.value,level=!mini_globals.scope_level))
    
  endif else begin
  
    message,'mini_var passed illegal argument type'
 
  endelse
 
  return,0
  
end

function mini_incdec,arg1,arg2

  compile_opt hidden,strictarr
  
  evaluator_routines
  mini_predicates
  
  if is_operator_type(arg1) then begin
  
    out_var = mini_var(arg2)   
  
    if arg1.value eq '++' then begin

      out_var.data++
      
   endif else if arg1.value eq '--' then begin
      
      out_var.data--

    endif else begin
      message,"wrong operator passed to mini_incdec"
    endelse
    
    store_var_data,arg2,out_var
    
  endif else if is_operator_type(arg2) then begin
     
    out_var = mini_var(arg1)
     
    store_var = out_var
     
    if arg2.value eq '++' then begin
 
      store_var.data++
 
    endif else if arg2.value eq '--' then begin
    
      store_var.data--
       
    endif else begin
      message,'wrong operator passed to mini_incdec'
    endelse
    
    store_var_data,arg1,store_var
    
  endif else begin
    message,'no operator passed to mini_incdec'
  endelse
  
  return,out_var
  
end

function mini_uop,arg1,arg2

  compile_opt hidden,strictarr
  
  evaluator_routines
  mini_predicates
  
  if ~is_operator_type(arg1) then begin
    message,'arg1 to mini_uop not operator'
  endif
  
  if arg1.value eq '+' then begin
  
      out = arg2
      out.data = +out.data
      
  endif else if arg1.value eq '~' then begin

      out = arg2
      out.data = ~out.data

  endif else if arg1.value eq '-' then begin

      out = arg2
      out.data = -1*out.data

  endif else if arg1.value eq 'not' then begin

      out = arg2
      out.data = not out.data

  endif else begin
    message,'illegal operator passed to mini_uop'
  endelse
  
  return,out
  
end
  
function mini_paren,arg1,arg2,arg3

  compile_opt hidden

  return,arg2

end

function mini_func,arg1,arg2,arg3,arg4

  compile_opt hidden,strictarr
  
  mini_predicates
  
  if is_empty_type(arg3) then begin
    return,call_function(arg1.value)
  endif else if arg3.length ge 1 then begin
    return,call_function(arg1.value,arg3)
  endif
  
;   else if arg3.length ge 2 then begin
;    return,call_function(arg1.value,arg3.data,arg3.next.data)
;  endif else if arg3.length eq 3 then begin
;    return,call_function(arg1.value,arg3.data,arg3.next.data,arg3.next.next.data)
;  endif else if arg3.length eq 4 then begin
;    return,call_function(arg1.value,arg3.data,arg3.next.data,arg3.next.next.data,arg3.next.next.next.data)
;  endif else begin
;    message,'wrong number of arguments to mini_func'
;  endelse

end



function mini_bop,arg1,arg2,arg3

  compile_opt hidden,strictarr
  
  evaluator_routines
  
  if is_tvar_data(arg1) && is_tvar_data(arg3) && $  ;if data is tplot
     in_set('times',strlowcase(tag_names(arg1))) && $ ;and it has valid times
     in_set('times',strlowcase(tag_names(arg3))) then begin
         
     if ~is_equal(arg1.times,arg3.times,/nan) then begin
       if is_string(*!mini_globals.interpolate) then begin ;interpolate all quantities to used named variable
         if keyword_set(!mini_globals.verbose) then begin
           dprint,'Interpolating ' + arg1.name + ' and ' + arg3.name + ' to match ' + *!mini_globals.interpolate
         endif
         
         if is_struct(*!mini_globals.extra) then begin
           tinterpol_mxn,make_data_type(arg1),*!mini_globals.interpolate,out=out1,_extra=*!mini_globals.extra
         endif else begin
           tinterpol_mxn,make_data_type(arg1),*!mini_globals.interpolate,out=out1
         endelse
         
         if ~is_struct(out1) then begin
           message,'Problem interpolating ' + arg1.name + ' to ' + *!mini_globals.interpolate
         endif
        
         arg1 = make_tvar_data(arg1.name,out1,arg1.limits,arg1.dlimits)
        
         if is_struct(*!mini_globals.extra) then begin
           tinterpol_mxn,make_data_type(arg3),*!mini_globals.interpolate,out=out3,_extra=*!mini_globals.extra
         endif else begin
           tinterpol_mxn,make_data_type(arg3),*!mini_globals.interpolate,out=out3
         endelse
         
         if ~is_struct(out3) then begin
           message,'Problem interpolating ' + arg3.name + ' to ' + *!mini_globals.interpolate
         endif
         
         arg3 = make_tvar_data(arg3.name,out3,arg3.limits,arg3.dlimits)
         
       endif else if *!mini_globals.interpolate ne 0 then begin ;interpolate quantities to left operand
       
         if keyword_set(!mini_globals.verbose) then begin
           dprint,'Interpolating ' + arg3.name + ' to match ' + arg1.name
         endif
       
         if is_struct(*!mini_globals.extra) then begin
           tinterpol_mxn,make_data_type(arg3),arg1.times,out=out3,_extra=*!mini_globals.extra
         endif else begin
           tinterpol_mxn,make_data_type(arg3),arg1.times,out=out3
         endelse
         
         if ~is_struct(out3) then begin
           message,'Problem interpolating ' + arg3.name + ' to ' + arg1.name
         endif
         
         arg3 = make_tvar_data(arg3.name,out3,arg3.limits,arg3.dlimits)
       
       endif else if n_elements(arg1.times) ne n_elements(arg3.times) && $ ;allow exception for times that match in number or scalar
                     n_elements(arg1.data) gt 1 && n_elements(arg3.data) gt 1 then begin  
         message,'times in tvar "' +arg1.name + '" and tvar "' + arg3.name + '" do not match'
       endif
     endif
     
  endif
  
  if ~is_valid_bop_arg(arg1,arg2,arg3) then begin
    message,'The dimensions of "' + arg1.name + '"['+strjoin(strtrim(dimen(arg1.data),2),',')+'] and "' + arg3.name + '"['+strjoin(strtrim(dimen(arg3.data),2),',')+'] do not match'
  endif
  
  if arg2.name eq '^' then begin
    out = arg1.data ^ arg3.data
  endif else if arg2.name eq '*' then begin
    out = arg1.data * arg3.data
  endif else if arg2.name eq '#' then begin
    out = arg1.data # arg3.data
  endif else if arg2.name eq '##' then begin
    out = arg1.data ## arg3.data
  endif else if arg2.name eq 'b/' then begin
    out = arg1.data / arg3.data
  endif else if arg2.name eq 'mod' then begin
    out = arg1.data mod arg3.data
  endif else if arg2.name eq 'b+' then begin
    out = arg1.data + arg3.data
  endif else if arg2.name eq 'b-' then begin
    out = arg1.data - arg3.data
  endif else if arg2.name eq '<' then begin
    out = arg1.data < arg3.data  
  endif else if arg2.name eq '>' then begin
    out = arg1.data > arg3.data 
  endif else if arg2.name eq 'eq' then begin
    out = arg1.data eq arg3.data 
  endif else if arg2.name eq 'ne' then begin
    out = arg1.data ne arg3.data  
  endif else if arg2.name eq 'le' then begin
    out = arg1.data le arg3.data  
  endif else if arg2.name eq 'lt' then begin
    out = arg1.data lt arg3.data  
  endif else if arg2.name eq 'ge' then begin
    out = arg1.data ge arg3.data   
  endif else if arg2.name eq 'gt' then begin
    out = arg1.data gt arg3.data    
  endif else if arg2.name eq 'and' then begin
    out = arg1.data and arg3.data   
  endif else if arg2.name eq 'or' then begin
    out = arg1.data or arg3.data   
  endif else if arg2.name eq 'xor' then begin
    out = arg1.data xor arg3.data   
  endif else if arg2.name eq '&&' then begin
    out = logical_and(arg1.data,arg3.data)
  endif else if arg2.name eq '||' then begin
    out = logical_or(arg1.data,arg3.data)
  endif else begin
    message,'Unrecognized operator passed to mini_bop'
  endelse
     
  ;not really sure what constitutes a good rule for limit inheritance
  if is_tvar_data(arg1) then begin
    out_var = arg1
    out_var.name = 'composite'
    return,replace_data(out_var,out)
  endif else if is_tvar_data(arg3) then begin
    out_var = arg3
    out_var.name = 'composite'
    return,replace_data(out_var,out)
  endif else begin
    return,make_var_data('composite',out)
  endelse
  
end

function mini_keyword,arg1,arg2,arg3,arg4

 if n_params() eq 4 then begin
   out={type:'identifier',name:'keyword',value:arg2.value,value2:arg4}
 endif else begin
   out={type:'identifier',name:'keyword',value:arg2.value}
 endelse

 return,out

end

function mini_empty,arg1

  compile_opt hidden

  return,{type:'empty',length:0}
  
end

function mini_arg,arg1

  compile_opt hidden,strictarr

  evaluator_routines

  return, make_arg_list(arg1)

  ;return,{type:'arg_list',data:arg1,length:1,next:''}

end

function mini_args,arg1,arg2,arg3

  compile_opt hidden,strictarr

  evaluator_routines

  return,make_arg_list(arg1,arg3)
  
  ;return,{type:'arg_list',data:arg1,length:(arg3.length+1),next:arg3}

end

;Not used directly to evaluate. Function list returns a list of functions and
;the 
;collection of function/procedures related to running various routines in the mini
;consider putting this is common block
function function_list

  compile_opt idl2,hidden


  fun = {type:'function',name:'name',value:'idlname',index:0,syntax:'helpsyntax'} 

  f_list = replicate(fun,36)
  
  i=0
  f_list[i].name = 'log'
  f_list[i].value = 'mini_log'
  f_list[i].syntax= '(x[,base])'
  i++
  
  f_list[i].name = 'ln'
  f_list[i].value = 'mini_ln'
  f_list[i].syntax= '(x)'
  i++
  
  f_list[i].name = 'exp'
  f_list[i].value = 'mini_exp'
  f_list[i].syntax= '(x[,base])'
  i++
  
  f_list[i].name = 'sqrt'
  f_list[i].value = 'mini_sqrt'
  f_list[i].syntax= '(x)'
  i++
  
  f_list[i].name = 'abs'
  f_list[i].value = 'mini_abs'
  f_list[i].syntax= '(x)'
  i++
  
  f_list[i].name = 'min'
  f_list[i].value = 'mini_min'
  f_list[i].syntax= '(x,[,dim][,/nan],[/subscript=varname])'
  i++
 
  f_list[i].name = 'max'
  f_list[i].value = 'mini_max'
  f_list[i].syntax= '(x,[,dim][,/nan],[/subscript=varname])'
  i++
 
  f_list[i].name = 'mean'
  f_list[i].value = 'mini_mean'
  f_list[i].syntax= '(x,[,dim][,/nan])'
  i++
  
  f_list[i].name = 'average'
  f_list[i].value = 'mini_mean'
  f_list[i].syntax= '(x,[,dim][,/nan])'
  i++
 
  f_list[i].name = 'median'
  f_list[i].value = 'mini_median'
  f_list[i].syntax= '(x,[,dim][,/even])'
  i++
 
  f_list[i].name = 'total'
  f_list[i].value = 'mini_total'
  f_list[i].syntax= '(x,[,dim][,/nan] [,/cumulative])'
  i++
  
  f_list[i].name = 'count'
  f_list[i].value = 'mini_count'
  f_list[i].syntax= '(x,[,dim])'
  i++
  
  f_list[i].name = 'sin'
  f_list[i].value = 'mini_sin'
  f_list[i].syntax= '(x)'
  i++
  
  f_list[i].name = 'arcsin'
  f_list[i].value = 'mini_asin'
  f_list[i].syntax= '(x)'
  i++
  
  f_list[i].name = 'sinh'
  f_list[i].value = 'mini_sinh'
  f_list[i].syntax= '(x)'
  i++
  
  f_list[i].name = 'arcsinh'
  f_list[i].value = 'mini_asinh'
  f_list[i].syntax= '(x)'
  i++
 
  f_list[i].name = 'cos'
  f_list[i].value = 'mini_cos'
  f_list[i].syntax= '(x)'
  i++
  
  f_list[i].name = 'arccos'
  f_list[i].value = 'mini_acos'
  f_list[i].syntax= '(x)'
  i++
  
  f_list[i].name = 'cosh'
  f_list[i].value = 'mini_cosh'
  f_list[i].syntax= '(x)'
  i++
  
  f_list[i].name = 'arccosh'
  f_list[i].value = 'mini_acosh'
  f_list[i].syntax= '(x)'
  i++
 
  f_list[i].name = 'tan'
  f_list[i].value = 'mini_tan'
  f_list[i].syntax= '(x)'
  i++
 
  f_list[i].name = 'arctan'
  f_list[i].value = 'mini_atan'
  f_list[i].syntax= '(x)'
  i++
 
  f_list[i].name = 'tanh'
  f_list[i].value = 'mini_tanh'
  f_list[i].syntax= '(x)'
  i++
  
  f_list[i].name = 'arctanh'
  f_list[i].value = 'mini_atanh'
  f_list[i].syntax= '(x)'
  i++
  
  f_list[i].name = 'csc'
  f_list[i].value = 'mini_cosecant'
  f_list[i].syntax= '(x)'
  i++
  
  f_list[i].name = 'arccsc'
  f_list[i].value = 'mini_arccosecant'
  f_list[i].syntax= '(x)'
  i++
 
  f_list[i].name = 'csch'
  f_list[i].value = 'mini_cosecanthyp'
  f_list[i].syntax= '(x)'
  i++
 
  f_list[i].name = 'arccsch'
  f_list[i].value = 'mini_arccosecanthyp'
  f_list[i].syntax= '(x)'
  i++
 
  f_list[i].name = 'sec'
  f_list[i].value = 'mini_secant'
  f_list[i].syntax= '(x)'
  i++
  
  f_list[i].name = 'arcsec'
  f_list[i].value = 'mini_arcsecant'
  f_list[i].syntax= '(x)'
  i++
 
  f_list[i].name = 'sech'
  f_list[i].value = 'mini_secanthyp'
  f_list[i].syntax= '(x)'
  i++
  
  f_list[i].name = 'arcsech'
  f_list[i].value = 'mini_arcsecanthyp'
  f_list[i].syntax= '(x)'
  i++
 
  f_list[i].name = 'cot'
  f_list[i].value = 'mini_cotangent'
  f_list[i].syntax= '(x)'
  i++
  
  f_list[i].name = 'arccot'
  f_list[i].value = 'mini_arccotangent'
  f_list[i].syntax= '(x)'
  i++
 
  f_list[i].name = 'coth'
  f_list[i].value = 'mini_cotangenthyp'
  f_list[i].syntax= '(x)'
  i++  
  
  f_list[i].name = 'arccoth'
  f_list[i].value = 'mini_arccotangenthyp'
  f_list[i].syntax= '(x)'
  i++
  
  f_list.index=lindgen(n_elements(f_list))
  
  return,f_list

end

;consider putting this is common block
function operator_list

  compile_opt idl2,hidden

  op_names = [$  ;list of names as they appear in mini-language code
    '~',$
    '++',$
    '--',$
    'u-',$
    'b-',$
    'u+',$
    'b+',$
    '*',$
    'b/',$
    'k/',$
    '^',$
    '<',$
    '>',$
    '&&',$
    '||',$
    '#',$
    '##',$
    'mod',$
    'and',$
    'eq',$
    'ge',$
    'gt',$
    'le',$
    'lt',$
    'or',$
    'xor',$
    '+$']
    
  op_values = [$ ;list of names as they will be called by 'call_function'
    'mini_not',$
    'mini_increment',$
    'mini_decrement',$
    'mini_uminus',$
    'mini_bminus',$
    'mini_uplus',$
    'mini_bplus',$
    'mini_multiply',$
    'mini_divide',$
    'mini_keyword',$
    'mini_power',$
    'mini_less',$
    'mini_greater',$
    'mini_and_logical',$
    'mini_or_logical',$
    'mini_matrix_column',$
    'mini_matrix_row',$
    'mini_mod',$
    'mini_and_vector',$
    'mini_or_vector',$
    'mini_eq',$
    'mini_ge',$
    'mini_gt',$
    'mini_le',$
    'mini_lt',$
    'mini_xor',$
    'mini_svar']
    
  ;As it turns out, most of this stuff doesn't matter for operators
  ;Instead operators are handled by 
  op = {type:'operator',name:'name',value:'idlname',index:0}
  
  op_list = replicate(op,n_elements(op_names))
  
  op_list[*].name = op_names
  op_list[*].value = op_values
  op_list[*].index = lindgen(n_elements(op_names))
  
  return,op_list

end

function get_function,tok

  compile_opt idl2,hidden
  
  fl = function_list()
  
  idx = where(tok.name eq fl.name)
  
  if idx[0] eq -1L then begin
    return,''
  endif else if n_elements(idx) gt 1 then begin
    return,''
  endif else begin
    return,fl[idx]
  endelse

end

pro mini_routines

;do nothing

end

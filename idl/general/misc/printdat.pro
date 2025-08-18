;+
;PROCEDURE: printdat,[x]
;PURPOSE:
;   Displays information and contents of a data variable. (Very similar to HELP procedure but much more verbose.)
;   This routine is most useful for displaying contents of complex
;   data structures.
;   If printdat is called without arguments then information on all variables
;   within the calling routine are displayed.
;   POINTER occurences are recursively displayed as well. (only non-null pointers are listed)
;
;Keywords:
;   FULL     Set this keyword to display full variable output.
;   NAMES = string:  Optional list of variables to display (Same as for HELP)
;   WIDTH:   Width of screen (Default is 120).
;   MAX:     Maximum number of array elements to print.  (default is 30)
;   NSTRMAX  Maximum number of structure elements to print. (default is 3)
;   NPTRMAX  Maximum number of pointer elements to print. (default is 5)
;   OUTPUT=string :  named variable in which the output is dumped.
;   VARNAME=string : [optional] name of variable to be displayed. (useful if input is an expression instead of a variable)
;   RECURSEMAX = integer :  Maximum number of levels to dive into. (Useful for limiting the output for heavily nested structures or pointers)
;
;Written by Davin Larson, May 1997.
;
; $LastChangedBy: davin-mac $
; $LastChangedDate: 2018-11-01 15:30:14 -0700 (Thu, 01 Nov 2018) $
; $LastChangedRevision: 26039 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/misc/printdat.pro $
;-
pro printdat,data,data2,data3,data4,data5,data6,data7,data8,  $
   varname=varname,  $
   unit=unit, $
   level=level,  $
   recursemax=recursemax, $
   rlevel=rlevel, $
   options=opts,ptrs=ptrs, $  ; for recursive use only!
   allptrs=allptrs, $
   allobjs=allobjs, $
   values_only=values_only, $
   addname = addname, $
   names=names,  $
   iformat = iformat,hexadecimal=hexadecimal, $   ; This keyword is experimental and subject to change!
   full= full, $
   pgmtrace = pgmtrace, $   ;  beta test
   nm_width=nm_width, $
   max=max,output=outstring,nstrmax=nstrmax,nptrmax=nptrmax,width=width

;help,/trac
if not keyword_set(rlevel) then rlevel=0
;dprint,'Begin ',recurse_level
if size(/type,data2) eq 7 and not keyword_set(varname) then varname=data2[0]  ; Cluge for backward compatibility
;if keyword_set(data2) then dprint,'Using old convention in routine '   ;+ (reverse(scope_traceback()))[[1]]

if not keyword_set(level) then level = ''
if n_elements(unit) eq 0 then unit=-1

if keyword_set(pgmtrace) then  level = ptrace(sublevel=pgmtrace) + level

if not keyword_set(allptrs) then allptrs=ptr_new()
if not keyword_set(allobjs) then allobjs=obj_new()

if keyword_set(hexadecimal) then iformat = '(Z,"x")'
if not keyword_set(opts) then begin
  opts={ $
      width: keyword_set(width) ? width : 120, $
      max:   keyword_set(max)   ? max   : 32, $
      values_only: keyword_set(values_only), $
      nstrmax: n_elements(nstrmax) ne 0  ? nstrmax : 1, $
      nptrmax: n_elements(nptrmax) ne 0  ? nptrmax : 2, $
      recursemax: n_elements(recursemax) ne 0 ? recursemax : 20, $
      iformat:  keyword_set(iformat) ? iformat : '', $
      full:    keyword_set(full) , $
      unit:  unit, $
      outs:   arg_present(outstring)  }
  outstring=''
  ptrs = ptr_new()     ; array to detect pointer recursion
endif

np=n_params()

if np gt 1 then begin
   vars1 = scope_varname(data,data2,data3,data4,data5,data6,data7,data8,count=c,level=-1)
   vars0 = scope_varname(data,data2,data3,data4,data5,data6,data7,data8,count=c,level=0)
   w = where(vars1 eq '',nw)
   if nw ne 0 then vars1[w] = string(w+1,format='("<Expr",i0.0,">")')
   if n_elements(nm_width) eq 0 then nm_width = max(strlen(vars1))
   for i=0,np-1 do begin
       printdat,scope_varfetch(vars0[i],level=0), varname=vars1[i] $
          ,nm_width = nm_width $
           ,level = level  $
           ,output=outstring  $
           ,options = opts  $
           ,ptrs=ptrs
   endfor
   return
endif

if np eq 0 and keyword_set(names) eq 0 then names='*'
if keyword_set(names) then begin
   allvars = scope_varname(level=-1)
   if not keyword_set(allvars) then return
   vars = strfilter(allvars,names,count=c,/fold_case,delim=' ')
   if n_elements(nm_width) eq 0 then nm_width = max(strlen(vars))
   opts.full = 1
   for i=0,c-1 do begin
       printdat,scope_varfetch(vars[i],level=-1) ,varname=vars[i] $
           ,nm_width = nm_width $
           ,level = level  $
           ,output=outstring  $
           ,options = opts $
           ,ptrs = ptrs
   endfor
   return
endif

if not keyword_set(varname) then begin
   varname = (scope_varname(data,level=-1))[0]
   if not keyword_set(varname) then varname='<Expr>'
endif

if not keyword_set(rlevel) then rlevel=0
if rlevel ge opts.recursemax then return


dt = size(/type,data)
n =  size(/n_elements,data)
tnam = size(/tname,data)            ;String describing data type

dim = size(/dimension,data)
ndim = size(/n_dimension,data)
nm = (n < opts.max)
if dt eq 8 and n eq 1 then ndim=0   ;fix of IDL bug
if dt eq 11 then begin
   if typename(data) ne 'OBJREF' then begin  
      dim = [0]
      ndim = 0
   endif else begin
      
   endelse
   
endif

if ndim ge 1 then dimstr = '['+string(dim,format="(8(i0.0,:,','))")+']' $
else dimstr=''

quote = "'"
;quote = '"'

case dt of
 0:    valstr = 'Undefined'                                    ;Undefined
 1:    valstr = strcompress(string(fix(data[0:nm-1]),format=opts.iformat),/remove_all)     ;bytes
 7:    valstr = quote+data[0:nm-1]+quote                           ;strings
 8:    valstr = string(format="(a,' --(',i0.0,' Tags/',i0.0,' Bytes)-->')", $
            tag_names(data,/struct),n_tags(data),n_tags(data,/length))   ;structures
 10:   begin                                                   ;pointers
        valstr = strarr(nm)
        for i=0,nm-1 do valstr[i] = string(/print,data[i])
       end
 11:   begin  
          tname = typename(data)  
          valstr = tname
          help,data,output=valstr 
          valstr = '<' + valstr + '>'
;         help,data, output= valstr                                       ;objects  - very difficult to distinguish lists and arrays of lists
          nm = 1
;        valstr = strarr(nm)
;        for i=0,nm-1 do valstr[i] = (string(/print,data[i]))[0]
          case tname of
            'OBJREF': begin
              valstr1 = tname  ; arrays of objects  or invalid objects
              dim = size(/dimen,data)
              ndim = dim[0]
              if ndim ne 0 then message,/info, 'Array of objects'+' ['+strjoin(strtrim(dim,2),',')+']'
;              stop
              end
            else:  begin
                ndim = 0
                dimstr=''
              end
          endcase
       end
 else: valstr = strcompress(string(data[0:nm-1],format=opts.iformat),/remove_all)
endcase

if keyword_set(nm_width) then begin
   s1 = string(replicate(32b,nm_width))
   strput,s1,varname
endif else s1 = varname

if opts.values_only then s2='' else begin
    s2=string(replicate(32b,strlen(tnam+dimstr)>8))
    strput,s2,tnam+dimstr
    s2= ' = ' + s2
    if keyword_set(addname) then s2 = ' = ' + addname + s2
endelse

s = level + s1 + s2 + ' = '

if (dt ne 8) and ndim ge 1 then begin      ; Truncate array if needed
   w = strlen(s)
   ls = strlen(valstr)
   for i=0,nm-1 do begin
      w = w+ls[i]+2
      if w gt opts.width then goto,break1
   endfor
   break1:
   i = i > 1
   if i lt n then valstr[i-1] = ' ...'
   valstr = '['+string(/print,valstr[0:i-1],format="(32(a,:,', '))")+']'
endif

s = s + valstr

if opts.outs then   append_array,outstring,s   $
else printf,opts.unit,s

if dt eq 8 then begin        ;structures
   for j=0l,n-1 do begin
     if j ge opts.nstrmax then begin
        s3 = level+'Array truncated ...'
        if opts.outs then  append_array,outstring,s3 $
        else printf,opts.unit,s3
        break
     endif
     tags = tag_names(data)
     nvarname = varname
     if ndim ge 1 then begin
         nvarname = nvarname+'['+strtrim(j,2)+']'
         if opts.outs then  append_array,outstring,level+nvarname $
         else printf,opts.unit,level+nvarname
     endif
     if opts.full then begin
         if strmid(nvarname,0,1) eq '*' then nvarname='('+nvarname+')'
         prefix = nvarname+'.'
     endif else prefix = ''
     nwdth = max(strlen(prefix+tags))
     for i=0,n_elements(tags)-1 do begin
       printdat,data[j].(i),varname=prefix+tags[i],level=level+'   ',nm_width=nwdth,  $
          output=outstring,options=opts,ptrs=ptrs,allptrs=allptrs,allobjs=allobjs,rlevel=rlevel+1
     endfor
   endfor
endif

if dt eq   10  then begin      ; pointers
    wnn = where(data ne ptr_new() ,nwnn)
    for w=0,nwnn-1 do begin
        j = wnn[w]
        if w gt opts.nptrmax  then break
        pvarname = varname
        if ndim ge 1 then pvarname = pvarname + '['+strtrim(j,2)+']'
        pvarname = '*' + '(' + pvarname + ')'
        plevel = level+'  '
        if w ge opts.nptrmax then begin
            s3 = plevel+'Array truncated ...'
            goto,break3
        endif
        if total(/preserve,data[j] eq allptrs) gt 0 then begin   ; Deja Vu
            s3= plevel+pvarname+' = Deja Vu!'
        endif  else begin
        allptrs = [allptrs,data[j]]
        if ptr_valid(data[j]) then begin   ; pointer is defined
            if keyword_set(ptrs) && total(data[j] eq ptrs) gt 0 then begin  ;recursive pointer
                s3=plevel+ pvarname+' = RECURSIVE POINTER IGNORED!'
            endif else begin
                printdat,*data[j],level=plevel,varname=pvarname,output=outstring, $
                    options=opts,ptrs= [ptrs,data[j]] , allptrs=allptrs, allobjs=allobjs, rlevel=rlevel+1, addname='*'+string(/print,data[j])
                continue
            endelse
        endif else begin
            s3= plevel + pvarname + ' = (Invalid pointer dereference)'
        endelse
        endelse
        break3:
        if opts.outs then  append_array,outstring,s3 $
        else printf,opts.unit,s3
    endfor
endif


if dt eq 11 then begin      ; objects
  n = ndim > 1
  for j=0,n-1 do begin
    if ndim ge 1  then dj = data[j] else dj=data
    tname = typename(dj)
    nvarname = varname
    if ndim ge 1 then begin
      nvarname = nvarname+'['+strtrim(j,2)+']'
    endif
    switch tname of
      'OBJREF' :  begin
        if obj_valid(dj) eq 0 then nvarname = nvarname + ' (INVALID)'
 ;       if opts.outs then  append_array,outstring,level+nvarname   else printf,opts.unit,level+nvarname
        break
      end
      'DICTIONARY':
      'HASH':
      'LIST' :
      'ORDEREDHASH':      begin
        if opts.full then begin
          if strmid(nvarname,0,1) eq '*' then nvarname='('+nvarname+')'
          prefix = nvarname+''
        endif else prefix = '->'
        foreach v,dj,k do begin
          if isa(k,'STRING') then ks = quote + k + quote  else if isa(k,/number) then ks = strtrim(k,2)  else ks ='<????>'
          printdat,v,varname=prefix+'['+ks+']',level=level+'   ',nm_width=nwdth, $
            output=outstring,options=opts,ptrs=ptrs,allptrs=allptrs,allobjs=allobjs,rlevel=rlevel+1
        endforeach     
        break   
      end
      else:   begin
        if obj_valid(dj) eq 0 then break
;        message,/info,'Unknown object'
        if (obj_valid(dj) && obj_hasmethod(dj,'printdat_string')) then begin   ; object has printdat method
            s4 = level+'   '+dj.printdat_string()
            if opts.outs then  append_array,outstring,s4     else for i=0,n_elements(s4)-1 do  printf,opts.unit,s4[i]
        endif
;        wnn = where(data ne obj_new() ,nwnn)
;        for w=0,nwnn-1 do begin
;          j = wnn[w]
;          if w gt opts.nptrmax  then break
;          pvarname = varname
;          if ndim ge 1 then pvarname = pvarname + '['+strtrim(j,2)+']'
;          pvarname =  pvarname + '->getall()'
;          plevel = level+'  '
;          if w ge opts.nptrmax then begin
;            s4 = plevel+'Array truncated ...'
;            goto,break_obj
;          endif
;          if total(/preserve,data[j] eq allobjs) gt 0 then begin   ; Deja Vu
;            s4= plevel+pvarname+' = Deja Vu!'
;          endif  else begin
;            allobjs = [allobjs,data[j]]
;            if (obj_valid(data[j]) && obj_hasmethod(data[j],'getall')) then begin   ; object has dereference
;              if keyword_set(objs) && total(data[j] eq objs) gt 0 then begin  ;recursive object
;                s4=plevel+ pvarname+' = RECURSIVE OBJECT IGNORED!'
;              endif else begin
;                printdat,data[j]->getall(),level=plevel,varname=pvarname,output=outstring, $
;                  options=opts ,ptrs=ptrs, allptrs=allptrs, allobjs=allobjs, rlevel=rlevel+1  , addname='{'+string(/print,data[j])+'}'
;                continue
;              endelse
;            endif else begin
;              continue
;              ;                s4= plevel + pvarname + ' = (unknown object dereference)'
;            endelse
;          endelse
;          break_obj:
;          if opts.outs then  append_array,outstring,s4     else printf,opts.unit,s4
;        endfor
      end  
    endswitch
  endfor
endif


;dprint,'End'





end

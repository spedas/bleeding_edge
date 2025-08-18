;+
;Procedure: tKm2Re
;
;Purpose: Converts a variable to RE or KM
;
;Inputs: name: a string naming the tplot variable to be modified
;              globbing may be used
;
;Keywords:
;          newname: set this keyword to a string to store the
;                   output in(only works when globbing is not used)
;          suffix:  set this keyword to a string indicating the
;                   suffix to be appended to the input variable(s)
;          /replace: set this option to replace the variable being modified
;          /KM : converts to KM from RE rather than to RE from KM
; 
;
;  examples:
;        tKm2Re,'thb_state_pos'
;        tKm2Re,'thb_state_pos',/replace
;        tKm2Re,'thb_state_pos',/KM
;        tKm2Re,'thb_state_pos',newname='pos_in_re'
;        tKm2Re,'th?_state_pos',suffix='_converted'
;
;  NOTES: Uses conversion of 6371.2 KM/RE ;mean radius
;         By default output will be called: input_name+'_RE'
;
;
;$LastChangedBy: adrozdov $
;$LastChangedDate: 2019-03-26 12:08:00 -0700 (Tue, 26 Mar 2019) $
;$LastChangedRevision: 26907 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/misc/tkm2re.pro $
;-

pro tkm2re,name,newname=newname,suffix=suffix,replace=replace,km=km

compile_opt idl2

km_in_re = 6371.2

if undefined(name) then begin
  message,'Please define tvar name'
endif

names = tnames(name)

if n_elements(names) eq 1 && names[0] eq '' then begin
   message,'Illegal tvar name'
endif

if keyword_set(newname) then begin
   if n_elements(names) gt 1 then begin
      message,'Newname cannot be set when globbing is used'
   endif

   newnames=newname

endif else begin
   newnames = names
endelse

if keyword_set(suffix) then begin
   newnames += suffix
endif else if ~keyword_set(replace) then begin 

   if keyword_set(KM) then begin
      newnames += '_km'
   endif else begin
      newnames += '_re'
   endelse
   
endif

for i = 0,n_elements(names)-1 do begin

   d = 0

   get_data,names[i],data=d,dlimits=dl,limits=l

   if ~keyword_set(d) then message,'D component of tplot variable ' + names[i] + ' not set' 

   if keyword_set(KM) then begin 
      d.y *= km_in_re
      label = 'KM'
      old = 'RE'
   endif else begin
      d.y /= km_in_re
      label = 'RE'
      old = 'KM'
   endelse
   
   str_element,dl,'data_att',success=s
   
   if s then begin
     str_element,dl.data_att,'units',label,/add
   endif else begin
     str_element,data_att,'units',label,/add
     str_element,dl,'data_att',data_att,/add
   endelse
   
   str_element,dl,'ysubtitle',success=s    
   
   if s then begin
     pos = stregex(dl.ysubtitle,old,/fold_case)
     
     if pos ne -1 then begin
       tmp = dl.ysubtitle
       strput,tmp,label,pos
       dl.ysubtitle=tmp
     endif
     
   endif

   store_data,newnames[i],data=d,dlimits=dl,limits=l

endfor

end

;+
;Procedure: tvectot(tplot vector total)
;
;Purpose: Add or remove the magnitude of a vector to a tplot quantity
;
;Inputs: name: a string naming the tplot variable to be modified,  may
;use regex
;
;Keywords: /remove: set this keyword to remove the magnitude from
;                   vector
;          newname: set this keyword to a string to store the(this
;          option will not work properly if regex is used)
;          output in a different variable instead of overwriting
;          tot: set this keyword to a named variable to store
;             the magnitude as an array or set it to a string to store
;             the magnitude as a tplot variable(this option will not
;             work properly if regex is used)
;
;
;  examples:
;        tvectot,'tha_fgs_dsl'
;        tvectot,'tha_fgs_dsl',/remove
;        tvectot,'tha_fg*_dsl'
;        tvectot,'tha_fgs_dsl',newname='tha_fgs_dsl_mag'
;        tvectot,'tha_fgs_dsl',tot=var
;        tvectot,'tha_fgs_dsl',tot='mag_t_var'
;
;$LastChangedBy: pcruce $
;$LastChangedDate: 2012-01-27 11:23:20 -0800 (Fri, 27 Jan 2012) $
;$LastChangedRevision: 9637 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/misc/tvectot.pro $
;-


pro tvectot,name,remove=remove,newname=newname,tot=tot

COMPILE_OPT idl2

names = tnames(name)

n_type = size(newname,/type)

t_type = size(tot,/type)

if names[0] eq '' then begin
    dprint,'No valid tplot variables with name: ' + name,dlevel=2
    return
endif

;some switches
n_bool = 0
t_bool = 0
a_bool = 0

;set the switches
if n_type eq 7 then n_bool = 1 $
else if n_type ne 0 then begin
    dprint,'newname is set but it is not of type string, returning',dlevel=2
    ;message,/info,'newname is set but it is not of type string, returning'
    return
endif

if t_type eq 7 then t_bool = 1 $
else if arg_present(tot) then a_bool = 1

if (n_bool eq 1 || t_bool eq 1 || a_bool eq 1) && n_elements(names) gt 1 then begin
    dprint,'newname or tot are set and regex is being used, returning',dlevel=2
    ;message,/info,'newname or tot are set and regex is being used, returning'
    return
endif


for i = 0,n_elements(names)-1 do begin

    name_i = names[i]

    get_data,name_i,data=d,dlimits=dl

    if not keyword_set(d) then begin
        dprint,'Data element of: ' + name_i + ' not set',dlevel=2
        return
    endif

    size_d = size(d.y,/dimensions)

    ele_d = n_elements(size_d)

    if(ele_d ne 2) then begin
        dprint,'Data of ' + name_i + ' has the wrong number of elements',dlevel=2
        return
    endif

    if not keyword_set(remove) then begin
    
        mag = sqrt(total(d.y^2,2))

        new_y = transpose([transpose(d.y),reform(mag,1,n_elements(mag))])

        new_v = indgen(size_d[1]+1)+1

        new_d = {x:d.x,y:new_y,v:new_v}

        new_color = [(indgen(size_d[1])+1)*2,0]

	if keyword_set(dl) then begin

	  str_element,dl,'colors',success=s 
	
	  if s then $
            str_element,dl,'colors',new_color,/add

	  str_element,dl,'labels',success=s
	
	  if s then $
            str_element,dl,'labels',[dl.labels,'mag'],/add
	
	endif

        if n_bool eq 1 then $
          store_data,newname,data=new_d,dlimits=dl $
        else if t_bool eq 1 then begin
            mag_d = {x:d.x,y:mag}
            store_data,tot,data=mag_d
        endif else if a_bool eq 1 then tot = mag else $
          store_data,name_i,data=new_d,dlimits=dl

    endif else begin

        new_y = d.y[*,0:size_d[1]-2]

        new_v = d.v[0:size_d[1]-2]
        
        new_d = {x:d.x,y:new_y,v:new_v}

	if keyword_set(dl) then begin

	  str_element,dl,'colors',success=s

	  if s then begin 

            new_color = dl.colors[0:n_elements(dl.colors)-2]

            str_element,dl,'colors',new_color,/add
  	  
  	  endif

	  str_element,dl,'labels',success=s

	  if s then begin

            new_labels = dl.labels[0:n_elements(dl.labels)-2]

            str_element,dl,'labels',new_labels,/add

	  endif

	endif
        
        if n_bool eq 1 then $
          store_data,newname,data=new_d,dlimits=dl $
        else $
          store_data,name_i,data=new_d,dlimits=dl

    endelse

endfor

end

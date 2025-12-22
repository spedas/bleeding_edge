;	@(#)coord_trans.pro	1.8	07/20/02
;+
;PROCEDURE:	coord_trans, str_in, str_out, type
;INPUT:	
;	str_in	string		name of tplot structure with the form 
;				d.x and d.y where d.x contains the
;				time array and d.y the vector array
;	str_out	string		name of output tplot structure
;	type	string		A string indicating the type of transformation
;				example: 'GSEGSM' does the GSE to GSM transformation
;
;PURPOSE:
; 	Transforms vectors from one coordinate system to another.
;	Output: a tplot structure which contains the transformed vector
;
;NOTES: 
;	At present, this routine can perform the 'GSEGSM', 'GSMGSE',
;		'GEIGSE','GSEGEI','GEIGEO' transformations.
;
;CREATED BY: Tai Phan
;
;	First version: 95-10-28
;	last modified: 97-03-13 Bill Peria

pro coord_trans, str_in, str_out, type, slow = slow
;
; Branch to C code unless user has requested old, slow version.
;   NOT YET READY! WJP 20-July-2002
;if not keyword_set(slow) then begin
;    ctrans, str_in, str_out, type
;    return
;endif


get_data, str_in, data=d, index=index

if ((idl_type(str_in) ne 'string') or  $
    (idl_type(str_out) ne 'string') or  $
    (idl_type(type) ne 'string')) then begin
    message,'improper input types!',/continue
endif

if index eq 0 then begin
    message,str_in+' has not been stored...',/continue
    return
endif

if defined(type) then begin
    type = strupcase(type)
endif else begin
    message,'You must define a transformation type...',/continue
    return
endelse

npt= n_elements(d.x)
vec_out= allocatearray(data_type(d.y),2,[npt,3]) 

case type of

    'GSEGSM':	begin
        for i=0L, npt-1L do begin
            rotmat, d.x[i], GEOGEI, GEIGSE, GEIGSM, GEISM, GEIGSQ,$
              GEIGSR,DGEI,RGEI,S
            if (npt ne 1) then begin
                vec_out[i,*]= transpose(geigse)#reform(d.y[i,*])
                vec_out[i,*]= geigsm#reform(vec_out[i,*])
            endif else begin
                vec_out[i,*]= transpose(geigse)#d.y[*]
                vec_out[i,*]= geigsm#reform(vec_out[i,*])
            endelse
        endfor
    end

    'GSMGSE':	begin
        for i=0L, npt-1L do begin
            rotmat, d.x[i], GEOGEI, GEIGSE, GEIGSM, GEISM, GEIGSQ,$
              GEIGSR,DGEI,RGEI,S
            if (npt ne 1) then begin
                vec_out[i,*]= transpose(geigsm)#reform(d.y[i,*])
                vec_out[i,*]= geigse#reform(vec_out[i,*])
            endif else begin
                vec_out[i,*]= transpose(geigsm)#d.y[*]
                vec_out[i,*]= geigse#reform(vec_out[i,*])
            endelse
        endfor
    end


    'GSEGEI':	begin
        for i=0L, npt-1L do begin
            rotmat, d.x[i], GEOGEI, GEIGSE, GEIGSM, GEISM, GEIGSQ,$
              GEIGSR,DGEI,RGEI,S
            if (npt ne 1) then begin
                vec_out[i,*]= transpose(geigse)#reform(d.y[i,*])
            endif else begin
                vec_out[i,*]= transpose(geigse)#d.y[*]
            endelse

        endfor
    end


    'GEIGSE':	begin
        for i=0L, npt-1L do begin
            rotmat, d.x[i], GEOGEI, GEIGSE, GEIGSM, GEISM, GEIGSQ,$
              GEIGSR,DGEI,RGEI,S
            if (npt ne 1) then begin
                vec_out[i,*]= geigse#reform(d.y[i,*])
            endif else begin
                vec_out[i,*]= geigse#d.y[*]
            endelse
        endfor
    end
    
    'GEIGSQ':	begin
        for i=0L, npt-1L do begin
            rotmat, d.x[i], GEOGEI, GEIGSE, GEIGSM, GEISM, GEIGSQ,$
              GEIGSR,DGEI,RGEI,S
            if (npt ne 1) then begin
                vec_out[i,*]= geigsq#reform(d.y[i,*])
            endif else begin
                vec_out[i,*]= geigsq#d.y[*]
            endelse
        endfor
    end
    
    'GEIGEO':	begin
        for i=0L, npt-1L do begin
            rotmat, d.x[i], GEOGEI, GEIGSE, GEIGSM, GEISM, GEIGSQ,$
              GEIGSR,DGEI,RGEI,S 
            if (npt ne 1) then begin
                vec_out[i,*]= transpose(geogei)#reform(d.y[i,*])
            endif else begin
                vec_out[i,*]= transpose(geogei)#d.y[*]
            endelse
        endfor
    end
    
    'GEOGEI':	begin
        for i=0L, npt-1L do begin
            rotmat, d.x[i], GEOGEI, GEIGSE, GEIGSM, GEISM, GEIGSQ,$
              GEIGSR,DGEI,RGEI,S 
            
            if (npt ne 1) then begin
                vec_out[i,*]= geogei#reform(d.y[i,*])
            endif else begin
                vec_out[i,*]= geogei#d.y[*]
            endelse
        endfor
    end
    
    'GSEGEO':	begin
        for i=0L, npt-1L do begin
            rotmat, d.x[i], GEOGEI, GEIGSE, GEIGSM, GEISM, GEIGSQ,$
              GEIGSR,DGEI,RGEI,S 
            
            gsegei = transpose(geigse)
            geigeo = transpose(geogei)
            gsegeo = geigeo # gsegei
            
            if (npt ne 1) then begin
                vec_out[i,*]= gsegeo#reform(d.y[i,*])
            endif else begin        
                vec_out[i,*]= gsegeo#d.y[*]
            endelse
        endfor
    end
    
    'GEOGSE':	begin
        for i=0L, npt-1L do begin
            rotmat, d.x[i], GEOGEI, GEIGSE, GEIGSM, GEISM, GEIGSQ,$
              GEIGSR,DGEI,RGEI,S 
            
            gsegei = transpose(geigse)
            geigeo = transpose(geogei)
            gsegeo = geigeo # gsegei
            geogse = transpose(gsegeo)
            
            if (npt ne 1) then begin
                vec_out[i,*]= geogse#reform(d.y[i,*])
            endif else begin        
                vec_out[i,*]= geogse#d.y[*]
            endelse
        endfor
    end
    
    else: begin
        message,'You did not request a known ' + $
          'transformation...',/continue
        return
    end

endcase

store_data,str_out,data={x:d.x,y:vec_out}
return

end

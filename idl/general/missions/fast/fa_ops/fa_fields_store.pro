;+
; NAME: FA_FIELDS_STORE
;
; PURPOSE: To perform a tplot store of FAST fields structures, like
;          those returned by GET_FA_FIELDS.
;
; CALLING SEQUENCE: data = get_fa_fields('V5-V8_S')
;                   fa_fields_store,data
;
; INPUTS: A fields structure (up to six of them, actually.) The tags
;         DATA_NAME, VALID, and COMP* TIME are required.
;
; KEYWORDS: NAME - a string for an alternate name to use for TPLOT
;           storage, otherwise, DATA.DATA_NAME is used. 
;
; SIDE EFFECTS: The data are TPLOT stored. The data are assumed to be
;               in the COMP* tags, and the TIME tag is used for time. 
;
; MODIFICATION HISTORY: written 29-April-1997 by Bill Peria UCB/SSL
;
;-
;       @(#)fa_fields_store.pro	1.4     

pro fa_fields_store,data,next_data,junk1,junk2,junk3, $
                    junk4,junk5,junk6,NAME = name
;
; recurse first if more than one param is defined, otherwise, just store the
; data.
;
if defined(b) then begin
    fa_fields_store,next_data,junk1,junk2,junk3,junk4,junk5,junk6
endif 

if idl_type(data) ne 'structure' then begin
    message,'Need a structure in GET_FA_FIELDS format.',/continue
    return
endif
;
; check for tags...
;
tags = strlowcase(tag_names(data))
req_tags = ['data_name','valid','comp*','time']
if missing_tags(data,req_tags,/quiet) ne 0 then begin
    bomb:message,'Unable to perform store...',/continue
    return
endif
if data.valid eq 0 then goto,bomb

if not keyword_set(name) then name = data.data_name

if missing_tags(data,'units_name',/quiet) eq 0 then begin
    units = data.units_name
endif else begin
    units = ''
endelse

two_d = (missing_tags(data,'yaxis',/quiet) eq 0)

compspots = where(strmid(tags,0,4) eq 'comp',ncs)
;
; loop over comp* tags...
;
for i=0,ncs-1l do begin
    nnz = 0
    use_log = 0
    not_nan = where(finite(data.(compspots(i))),nnn)
    if nnn gt 0 then not_zero = where((data.(compspots(i)))(not_nan) ne 0.0,nnz)
    if nnz gt 0 then begin
        ok = not_nan(not_zero)
        use_log = (((where(data.(compspots(i))(ok) le 0.0))(0) lt 0) and $
                   (max((data.(compspots(i)))(ok))/ $
                    min((data.(compspots(i)))(ok)) gt 100.))
    endif
    
    if ncs gt 1 then begin
        dataname = name+' '+tags(compspots(i))
    endif else begin
        dataname = name
    endelse
    
    if find_handle(dataname) ne 0 then store_data,dataname,/delete
    if two_d then begin 
        store_data,dataname, $
          data={x:data.time,y:data.(compspots(i)),v:data.yaxis}, $
          dlimits = {zlog:use_log, $
                     spec:1, $
                     ystyle:1, $
                     ytitle:data.yaxis_units, $
                     ztitle:dataname+'!C ('+ units +')', $
                     zrange:var_range(data.(compspots(i)))} 
    endif else begin
        store_data,dataname, $
          data={x:data.time,y:data.(compspots(i))}, $
          dlimits = {ylog:use_log, $
                     ystyle:1, $
                     ytitle:dataname+'!C ('+ units +')'}

    endelse
endfor

return
end


;+
; PRO: MAKE_DATA_DOUBLE, dat
;
; PURPOSE: Converts data.comp* to double. Written for MagAC data. 
; Can be used for any standard dqd. 
;
; CALLING: make_data_double(dat)
; 	   Pretty simple! 
;
; INPUTS: A valid data structure.
;       
; KEYWORD PARAMETERS:  	NONE!
;
; OUTPUTS: Makes data.comp* into double.
;
; INITIAL VERSION: REE 96_11_06
; REVISED: REE 97_10_20. Fixed bug on multiple components.
; MODIFICATION HISTORY: 
; Space Sciences Lab, UCBerkeley
; 
;-
pro make_data_double, data

; Locate all tags that start with comp.
tags_all           = strlowcase(tag_names(data))
data_tag_indecies  = where(strmid(tags_all,0,4) eq 'comp',ndts)
if (ndts LT 1) then return

tag_comp           = tags_all(data_tag_indecies)

FOR  i=0,ndts-1 do BEGIN
    tags_all       = strlowcase(tag_names(data))
    data_tag_index = where(tags_all eq tag_comp(i),better_be_one)
    
    IF data_type( data.(data_tag_index(0)) ) ne 5 then BEGIN ; Check if double
         temp = double( data.(data_tag_index(0)) )
         add_str_element, data, tag_comp(i), /del
         add_str_element, data, tag_comp(i), temp
    ENDIF
ENDFOR

return
end

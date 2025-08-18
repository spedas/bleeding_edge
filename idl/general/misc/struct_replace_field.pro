pro struct_replace_field, struct, tag, data, newtag=newtag
;Change the type, dimensionality, and contents of an existing structure
; field. The tag name may be changed in the process.
;
;Inputs:
; tag (string) Case insensitive tag name describing structure field to
;  modify. Leading and trailing spaces will be ignored. If the field does
;  not exist, the structure is not changed and an error is reported.
; data (any) data that will replace current contents  of 
; [newtag=] (string) new tag name for field being replaced. If not
;  specified, the original tag name will be retained.
;
;Input/Output:
; struct (structure) structure to be modified.
;
;Examples:
;
; Replace sme.wave with the arbitrary contents of wave:
;
;   IDL> struct_replace_field, sme, 'wave', wave
;
; The tag name for a field can be changed without altering the data:
;
;   IDL> struct_replace_field, clients, 'NMAE', clients.nmae, newtag='Name'
;
;History:
; 2003-Jul-20 Valenti  Initial coding

if n_params() lt 3 then begin
  print, 'syntax: struct_replace_field, struct, tag, data [,newtag=]'
  return
endif

;Check that input is a structure.
  if size(struct, /tname) ne 'STRUCT' then begin
    message, 'first argument is not a structure'
  endif

;Get list of structure tags.
  tags = tag_names(struct)
  ntags = n_elements(tags)

;Check that requested field exists in input structure.
  ctag = strupcase(strtrim(tag, 2))		;canoncial form of tag
  itag = where(tags eq ctag, nmatch)
  if nmatch eq 0 then begin
    message, 'structure does not contain ' + ctag + ' field'
    return
  endif
  itag = itag[0]				;convert to scalar

;Choose tag name for the output structure.
  if keyword_set(newtag) then otag = newtag else otag = ctag

;Copy any fields that precede target field. Then add target field.
  if itag eq 0 then begin			;target field occurs first
    new = create_struct(otag, data)
  endif else begin				;other fields before target
    new = create_struct(tags[0], struct.(0))	;initialize structure
    for i=1, itag-1 do begin			;insert leading unchange
      new = create_struct(new, tags[i], struct.(i))
    endfor
    new = create_struct(new, otag, data)	;insert new data
  endelse

;Replicate remainder of structure after desired tag.
  for i=itag+1, ntags-1 do begin
    new = create_struct(new, tags[i], struct.(i))
  endfor

;Replace input structure with new structure.
  struct = new

end

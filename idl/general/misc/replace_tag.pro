;+
; NAME:
;       REPLACE_TAG
;
; PURPOSE:
;       Replaces a tag in a structure by another
;
; CALLING:
;       replace_tag, struct, old_tag, new_tag, value
;
; INPUTS:
;	struct		- the structure to be changed
;	old_tag		- name of the tag to be changed
;	new_tag		- name of the new tag
;			  If set to '', old_tag is deleted from the structure
;	value		- value of the new tag
;
; RESTRICTIONS:
;	Does not work with named structures
;
; MODIFICATION HISTORY:
;       Alex Schuster, MPIfnF, 8/97 - Written
;-

pro replace_tag, struct, old_tag, new_tag, value

	tags = tag_names( struct )

	pos = (where( tags eq strupcase( old_tag ) ))[0]
	if ( pos eq -1L ) then begin
		print, 'Error: Tag ', old_tag, ' not in struct.' 
		return
	endif

	if ( ( pos eq 0 ) and ( new_tag ne '' ) ) then begin
		new_struct = create_struct( new_tag, value )
	endif else begin
		new_struct = create_struct( tags[0], struct.(0) )
		for i = 1, pos-1 do $
			new_struct = create_struct( new_struct, tags[i], struct.(i) )
		if ( new_tag ne '' ) then $
			new_struct = create_struct( new_struct, new_tag, value )
	endelse
	for i = pos+1, n_elements( tags )-1 do $
		new_struct = create_struct( new_struct, tags[i], struct.(i) )

	struct = new_struct

end
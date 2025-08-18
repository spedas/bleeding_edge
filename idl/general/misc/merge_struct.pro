;+
;PROCEDURE:  rename_struct_tag, struct_i, new_tag_name, index=index, old_tag_name=old_tag_name, remove=remove
;PURPOSE:
; Renames structure element with name "old_tag_name" or index "index",
; to "new_tag_name" in structure "struct_i".
; 
; This is equivalent to replace_tag.pro, but uses str_element and extract_tags.
; It runs slower in merge_struct (0.13 sec) than replace_tag.pro (0.03 sec).
;
; Input:
;   struct_i - structure with tags
;   index or old_tag_name - reference to structure tag to rename
; Output:
;   struct_i - structure with renamed tag 
; Purpose:
;   Relabels a tag in the structure.
;KEYWORDS:
;  remove: removes the old tag name
;
;LAST MODIFICATION: 
; $LastChangedBy: rjolitz $
; $LastChangedDate: 2025-03-23 18:07:39 -0700 (Sun, 23 Mar 2025) $
; $LastChangedRevision: 33198 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/misc/merge_struct.pro $
;-


pro rename_struct_tag, struct_i, new_tag_name, index=index, old_tag_name=old_tag_name, remove=remove

    ; Get index if not provided:
    if keyword_set(old_tag_name) then index = find_str_element(struct_i, old_tag_name)

    ; data from struct
    v = struct_i.(index)

    ; Add the renamed struct element:
    str_element, struct_i, new_tag_name, v, /add

    ; Remove the tag if have the name:
    if keyword_set(remove) and keyword_set(old_tag_name) then extract_tags, struct_f, struct_i,$
        EXCEPT_TAGS=old_tag_name else struct_f = struct_i
    struct_i = struct_f

    return
end


;+
;FUNCTION:  merge_struct(structs, struct_names)
;PURPOSE:
; Find (or add) an element of a structure.
;
; Input:
;   structs, array of structures
;   struct_names, array of strings containing names
; Output:
;   merged, a structure with all the tag:values
;       in supplied structs 
; Purpose:
;   Merges multiple structures EVEN IF identical tag names
;   in multiple structures. will prepend all var names by default.
;KEYWORDS:
;  PREPEND_ONLY_IDENTICAL: prepend the identical substructure tags
;
;CREATED BY:    Rebecca Jolitz
;FILE:  merge_struct.pro
;LAST MODIFICATION: 
; $LastChangedBy: rjolitz $
; $LastChangedDate: 2025-03-23 18:07:39 -0700 (Sun, 23 Mar 2025) $
; $LastChangedRevision: 33198 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/misc/merge_struct.pro $
;-


function merge_struct, struct_1, struct_2, struct_names,$
    prepend=prepend


; recursive call for more than 1 struct
; if n_elements(structs) gt 2 then structs = merge_struct([structs[0], structs[1]])

; prepend:
; 0 - prepend to all
; 1 - prepend only overlapping tags
if not keyword_set(prepend) then prepend = 0

; struct names
struct_1_name = struct_names[0]
struct_2_name = struct_names[1]

if struct_1_name eq '' then prepend_str_1 = '' else prepend_str_1 = struct_1_name + "_"
if struct_2_name eq '' then prepend_str_2 = '' else prepend_str_2 = struct_2_name + "_"

; Get structure tags:
struct_1_tag_names = tag_names(struct_1)
N_1_tag_names = n_elements(struct_1_tag_names)
struct_2_tag_names = tag_names(struct_2)
N_2_tag_names = n_elements(struct_2_tag_names)

; print, struct_1_tag_names, N_1_tag_names
; print, struct_2_tag_names, N_2_tag_names

if prepend then begin

    ; match, a, b, suba, subb, [ COUNT =, /SORT, EPSILON = ]
    ; a,b - two vectors to match elements, numeric or string data types
    ; suba - subscripts of elements in vector a with a match in vector b
    ; subb - subscripts of the positions of the elements in vector b with matchs in vector a.
    ; suba and subb sorted so give same order of tags:
    match, struct_1_tag_names, struct_2_tag_names, $
        index_str2_tag_in_str1, index_str1_tag_in_str2

    shared_tag_names = struct_1_tag_names[index_str2_tag_in_str1]
    ; stop

    uniq_str1_index = indgen(n_elements(struct_1_tag_names))
    uniq_str1_index[index_str2_tag_in_str1] = -1
    uniq_str1_index = uniq_str1_index[where(uniq_str1_index ge 0)]
    ; only_str_1_index = where(intarr)
    uniq_str2_index = indgen(n_elements(struct_2_tag_names))
    uniq_str2_index[index_str2_tag_in_str1] = -1
    uniq_str2_index = uniq_str2_index[where(uniq_str2_index ge 0)]

    ; print, uniq_str1_index
    ; print, uniq_str2_index

    ; print, 'shared names:'
    ; print, 'in 1: ', struct_1_tag_names[index_str2_tag_in_str1]
    ; print, 'in 2: ', struct_2_tag_names[index_str1_tag_in_str2]
endif else begin

    uniq_str1_index = indgen(N_1_tag_names)
    uniq_str2_index = indgen(N_2_tag_names)

    old_uniq_names_1 = struct_1_tag_names[uniq_str1_index]
    old_uniq_names_2 = struct_2_tag_names[uniq_str2_index]
    ; print, 'oldnames'


endelse


; stop
; Go through the overlapping tags and rename and delete old:
for i = 0, n_elements(shared_tag_names) - 1 do begin

    shared_tagindex_str1 = index_str2_tag_in_str1[i]
    shared_tagindex_str2 = index_str1_tag_in_str2[i]

    tag_name_i = struct_1_tag_names[shared_tagindex_str1]
    ; print, tag_name_i, struct_2_tag_names[shared_tagindex_str2]

    ; Relabel in str 1
    if prepend_str_1 ne '' then begin
        new_tag_name_str1_i = prepend_str_1 + tag_name_i
        rename_struct_tag, struct_1, new_tag_name_str1_i, $
            old_tag_name=tag_name_i, index=shared_tagindex_str1, /remove

    endif

    ; Relabel in str 2:
    if prepend_str_2 ne '' then begin
        new_tag_name_str2_i = prepend_str_2 + tag_name_i
        rename_struct_tag, struct_2, new_tag_name_str2_i, $
            old_tag_name=tag_name_i, index=shared_tagindex_str2, /remove
    endif

endfor


; Relabel in str 1, if nonempty str
if prepend_str_1 then begin
    ; print, 'now labeling unique keys in str 1'
    foreach i, uniq_str1_index do begin
        ; Old tag name
        old_tag_name_i = struct_1_tag_names[i]

        ; new tag name:
        new_tag_name_i = prepend_str_1 + old_tag_name_i

        replace_tag, struct_1, old_tag_name_i, new_tag_name_i, struct_1.(i)
        ; rename_struct_tag, struct_1, new_tag_name_i, $
        ;     old_tag_name=old_tag_name_i, index=i, /remove
    endforeach
endif

; Relabel in str 2:
if prepend_str_2 then begin
    ; print, 'now labeling unique keys in str 2'
    foreach i, uniq_str2_index do begin

        ; Old tag name
        old_tag_name_i = struct_2_tag_names[i]

        ; new tag name:
        new_tag_name_i = prepend_str_2 + old_tag_name_i

        replace_tag, struct_2, old_tag_name_i, new_tag_name_i, struct_2.(i)
        ; rename_struct_tag, struct_2, new_tag_name_i, $
        ;     old_tag_name=old_tag_name_i, index=i, /remove
    endforeach
endif


merged = create_struct(struct_1, struct_2)

; stop

return, merged

end
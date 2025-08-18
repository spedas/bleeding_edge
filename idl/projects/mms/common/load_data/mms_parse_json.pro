;+
; PROCEDURE:
;         mms_parse_json
;
; PURPOSE:
;         Parse the json object returned by the SDC for file name and size information
;         
; OUTPUT: 
;         returns an array of structs with the names and sizes
;
;
; Written by:
; Eric Grimes / egrimes@igpp.ucla.edu
; 
; Modifed by:
;  LMI / Laurent Mirioni (LPP) / laurent.mirioni@lpp.polytechnique.fr) 
;  Cindy Russell / clrussell@igpp.ucla.edu
;  
; History:
; 11 Aug 2015 (LMI) New parse of json_object
; 11 Aug 2015 (LMI) Imporove parsing of json_object
; 11 Aug 2015 (LMI) Bugfix for multiple files
; 26 Aug 2015 (IGPP) added support for the 'start_date' and 'end_date' tags
; 
;$LastChangedBy: egrimes $
;$LastChangedDate: 2015-12-10 14:33:38 -0800 (Thu, 10 Dec 2015) $
;$LastChangedRevision: 19596 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/load_data/mms_parse_json.pro $
;-

function mms_parse_json, json_object

    ;Init
    num_structs=0
    json_object_clean=json_object

    ; Exploding json_object into separated elements    
    for json_index=0,n_elements(json_object)-1 do begin
      json_object_clean[json_index]=strtrim(json_object[json_index],2)
      if strpos(json_object_clean[json_index],'{') eq 0 then begin
        num_structs+=1
        json_elt=strmid(json_object_clean[json_index],1,strlen(json_object_clean[json_index])-1)
      endif else begin
        if strpos(json_object_clean[json_index],'}') ne -1 then begin
          json_elt=[json_elt,strmid(json_object_clean[json_index],0,strlen(json_object_clean[json_index])-1)]
          if (num_structs eq 1) then json_elts=json_elt else json_elts=[[json_elts],[json_elt]]
        endif else begin
          json_elt=[json_elt,json_object_clean[json_index]]
        endelse
      endelse
    endfor

    if num_structs eq 1 then json_elts=[json_elt]
    
    remote_file_info = replicate({filename: '', filesize: 0l, startdate:'', enddate:'', timetag:''}, num_structs)
    date_pattern = '[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}'
  
    ;Filling remote_file_info
    counter=0
    for json_index=0,num_structs-1 do begin
      for json_elt_index=0,n_elements(json_elts[*,json_index])-1 do begin
        if strpos(json_elts[json_elt_index,json_index],'file_name') ne -1 then begin
          remote_file_info[json_index].filename = (strsplit(json_elts[json_elt_index,json_index], '": "', /extract))[1]
          counter+=1
        endif
        if strpos(json_elts[json_elt_index,json_index],'file_size') ne -1 then begin
          remote_file_info[json_index].filesize = (strsplit(json_elts[json_elt_index,json_index], '": ', /extract))[1]
        endif       
        if strpos(json_elts[json_elt_index,json_index],'start_date') ne -1 then begin
           remote_file_info[json_index].startdate=stregex(json_elts[json_elt_index,json_index], date_pattern, /subexpr, /extract)
         endif
        if strpos(json_elts[json_elt_index,json_index],'end_date') ne -1 then begin
          remote_file_info[json_index].enddate=stregex(json_elts[json_elt_index,json_index], date_pattern, /subexpr, /extract)
        endif
        if strpos(json_elts[json_elt_index,json_index],'timetag') ne -1 then begin
          remote_file_info[json_index].timetag=stregex(json_elts[json_elt_index,json_index], date_pattern, /subexpr, /extract)
        endif
      endfor
    endfor

    if (counter eq num_structs) then return, remote_file_info else begin
      print, 'ERROR'
    endelse

end
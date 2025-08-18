;+
; PROCEDURE:
;         mms_get_ancillary_file_info
;         
; PURPOSE:
;         Gets information (filenames, sizes) on ancillary files via the MMS web services API
; 
; KEYWORDS:
;         filename: filename to get information on
;         sc_id: MMS spacecraft ID (mms1, mms2, etc)
;         product: ancillary product info ("defatt", etc)
;         start_date: starting date
;         end_date: end date
; 
; OUTPUT:
;        returns information on the available files 
; 
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2016-03-09 13:39:34 -0800 (Wed, 09 Mar 2016) $
;$LastChangedRevision: 20376 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/mms_data_fetch/mms_get_ancillary_file_info.pro $
;-

function mms_get_ancillary_file_info, filename=filename, sc_id=sc_id, $
         product=product, start_date=start_date, end_date=end_date, $
         public=public

    if ~undefined(sc_id) then sc_id = strlowcase(sc_id)
    if ~undefined(product) then product = strlowcase(product)
    
    if ~undefined(filename) then append_array, query_args, "file=" + strjoin(filename, ",")
    if ~undefined(sc_id) then append_array, query_args, "sc_id=" + strjoin(sc_id, ",")
    if ~undefined(product) then append_array, query_args, "product=" + strjoin(product, ",")
    if ~undefined(start_date) then append_array, query_args, "start_date=" + start_date
    if ~undefined(end_date) then append_array, query_args, "end_date=" + end_date
    
    ; join the query arguments with "&"
    if n_elements(query_args) lt 2 then query = '' $
    else query = strjoin(query_args, '&')
    
    file_data = get_mms_file_info('ancillary', query=query, public=public)
    
    return, file_data
end
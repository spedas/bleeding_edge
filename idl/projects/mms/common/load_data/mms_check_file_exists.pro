;+
; PROCEDURE:
;         mms_check_file_exists
;
; PURPOSE:
;         Checks if a remote MMS data file exists locally. If it does, checks the file size
;         of the remote file to ensure they're the same.
;         
; INPUT: 
;         remote_file_info: structure containing the following tags:
;             filename: name of the remote file
;             filesize: size of the remote file
;
; KEYWORDS:
;         file_dir: 
;
; OUTPUT:
;         returns 1 for the file exists and has the same filesize as the remote file
;         returns 0 otherwise
;
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2015-12-10 14:33:38 -0800 (Thu, 10 Dec 2015) $
;$LastChangedRevision: 19596 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/load_data/mms_check_file_exists.pro $
;-

function mms_check_file_exists, remote_file_info, file_dir = file_dir
    filename = remote_file_info.filename

    ; make sure the directory exists
    dir_search = file_search(file_dir, /test_directory)
    if dir_search eq '' then file_mkdir2, file_dir

    ; check if the file exists
    file_exists = file_test(file_dir + '/' + filename, /regular)

    ; if it does, only download if it the sizes are different
    same_file = 0
    if file_exists eq 1 then begin
        ; the file exists, check the size
        f_info = file_info(file_dir + '/' + filename)
        local_file_size = f_info.size
        remote_file_size = remote_file_info.filesize
        if long(local_file_size) eq long(remote_file_size) then same_file = 1
    endif
    return, same_file
end
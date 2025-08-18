;+
;Check if a file is saved; print answer to terminal.
;
;fname: string: full directory and filename including extension.
;
;-
;

pro mvn_sta_checkfilesave, fname

proname = 'mvn_sta_checkfilesave'

if file_search(fname) ne '' then print, proname, ": file saved: ", fname else print, proname, ": ### FILE DID NOT SAVE ### : ", fname

end
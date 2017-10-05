
;+
;Routine to get the latest version and revision numbered file from an input directory and filename.
;
;INPUT:
;file: directory including start of filename upto but not including the version and revision part, for example the file test_v01_r02.sav
;      would be entered as 'test'
;      
;      NOTE this routine assumes that the string format is as above, that the v and r numbers are two long, followed by four string characters (.cdf, .sav, etc)
;      
;      
;OUTPUT:
;function returns the directory and full filename to the latest file. If no files are found matching the input format, the string 'none_found' is returned.
;
;
;NOTE:
;This file assumes that the end format of the file is v##_r##.sav, and uses this to get version and revision numbers. If used on files of a different
;format this routine will crash.
;
;-
;


function mvn_lpw_cdf_latest_file, file

sl = path_sep()


;Check that we have files matching the input basic format:
files = file_search(file+'*')
if files[0] eq '' then ffile = 'none_found' else begin
    nf = n_elements(files)  ;number of files found
    
    ;Extract the version numbers:
    vers = strarr(nf)
    rev = strarr(nf)
    for ii = 0, nf-1 do begin
          slen = strlen(files[ii]) ;length of string
          vers[ii] = strmid(files[ii], slen-10,3)  ;version #
          rev[ii] = strmid(files[ii], slen-6, 2)  ;revision #   
    endfor
    
    vers=float(vers)
    rev = float(rev)
    
    ;Get highest version:
    i1 = where(vers eq max(vers), ni1)
    
    if ni1 eq 1 then ffile = files[i1] else begin ;if only one max version number, doesn't matter what rev number is
        mrev = rev[i1]  ;when we have multiple max version numbers, now get highest rev number
        files2 = files[i1]  ;corresponding files
        i2 = where(mrev eq max(mrev))
        ffile = files2[i2]  ;file with latest version, and then latest rev, numbers
    endelse
     
endelse

return, ffile

end




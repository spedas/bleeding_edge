function barrel_find_file,fname,dirname

; test to see whether it's in the current directory
         CD, CURRENT=current_working_directory
         candidate = current_working_directory + PATH_SEP() + fname
        
        IF FILE_TEST(candidate, /READ, /REGULAR) THEN return,candidate

          pathsep = PATH_SEP(/SEARCH_PATH)
          all_pathfolders = STRSPLIT(!PATH, pathsep, /EXTRACT, COUNT=n_pathfolders)
          IF (n_pathfolders NE 0) THEN BEGIN
             ; we can create a subfolder named "barrel_sp_v*" within the BDAS folder, for example
             spec_folder_search = STRMATCH(all_pathfolders, "*"+dirname+"*", /FOLD_CASE) ;<--search for it!
             spec_folder_index = WHERE(spec_folder_search, n_matches)
             
             ; treat the unexpected case that we have multiple matches (multiple versions in path, hardlinks, etc)
             FOR i=0, n_matches-1 DO BEGIN
                  candidate = all_pathfolders[spec_folder_index[i]] + PATH_SEP() + fname
                  IF FILE_TEST(candidate, /READ, /REGULAR) THEN return,candidate
             ENDFOR
          ENDIF ; ELSE panic (no !PATH??)
          return,fname ;let's hope it's a complete path and will work.
       end


        

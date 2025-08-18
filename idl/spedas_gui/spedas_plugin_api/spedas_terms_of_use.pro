;+
; NAME:
; spedas_terms_of_use
;
; PURPOSE:
; Terms of use for the data of missions included in SPEDAS
;
; INPUT
; mission_name: (string) the name of the mission
; KEYWORD ARGUMENTS
; filename: (string) the full path of a text file with the terms of use, or ''
; agreement_text: (string) the actual string of terms of use
;
; OUTPUT
; 1 (terms accepted) or 0 (terms rejected)
;
; CALLING SEQUENCE:
; spedas_terms_of_use(mission_name)  ; same as filename=''
; or spedas_terms_of_use(mission_name, filename='path_to_agreement_text') 
; or spedas_terms_of_use(mission_name, agreement_text='text of agreement') 
; 
; to reset: spedas_terms_of_use_set(mission_name, 0)
;
; NOTES:
; Works both from Command Line and GUI. Detects it automatically.
; Caller should provide either the filename or agreement_text keyword arguments.
;
; If the filename is '', we assume that there is a file mission_name.txt inside the Resources/terms_of_use directory.
; Writes lines to the file terms_of_use.txt which resides in user's data folder.
; If the user has not agreed before it will show terms of use. If the user has agreed it will just return 1.
; It can be reset (for example when the interface starts) using spedas_terms_of_use_set(mission_name, 0).
;
;
; HISTORY:;
; $LastChangedBy: nikos $
; $LastChangedDate: 2013-03-22 15:47:22 -0700 (Fri, 22 Mar 2013) $
; $LastChangedRevision: 11876 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/spedas_plugin_api/spedas_terms_of_use.pro $
;-----------------------------------------------------------------------------------

; Function spedas_config_dir creates the directory
; that will host the terms of use text file
; In windows the directory is something like:
; C:\Users\username\.idl\spedas\spedas_terms-9-1_0-windows
FUNCTION spedas_config_dir

  ;COMMON spedas_common, config_dir
  
  IF (N_ELEMENTS(config_dir) NE 1) THEN BEGIN
  
    ; Increment if author_readme_text is changed
    author_readme_version = 1
    
    author_readme_text = $
      ['This is the user configuration directory for', $
      'IDL based products from SPEDAS.' ]
      
    ; Increment if app_readme_text is changed
    app_readme_version = 1
    
    app_readme_text = $
      ['This is the configuration directory for the', $
      'SPEDAS terms of use for mission data.']
      
    config_dir = APP_USER_DIR('spedas', 'SPEDAS team', $
      'spedas_terms', 'SPEDAS Software', $
      app_readme_text, app_readme_version, $
      AUTHOR_README_TEXT=author_readme_text, $
      AUTHOR_README_VERSION=author_readme_version, $
      RESTRICT_APPVERSION='1.0', /RESTRICT_FAMILY)
      
  ENDIF
  
  RETURN, config_dir
  
END

; Function spedas_read_file reads a ASCII text file
; and returns a string with the contents
; filename should contain the full path of the file
; C:\Users\username\Documents\mission.txt
function spedas_read_file, filename
  if (!D.NAME EQ 'WIN') then newline = string([13B, 10B]) else newline = string(10B)
  result = FILE_TEST(filename, /read)
  if result EQ 0  then begin
    return, filename + ' not found!'
  endif
  OPENR, lun, filename, /GET_LUN
  mytext = ''
  line = ''
  WHILE NOT EOF(lun) DO BEGIN
    READF, lun, line
    mytext = mytext +newline + line
  ENDWHILE
  FREE_LUN, lun
  
  return, mytext
end

; Function terms_of_use_check checks if there is a previous agreement
; Returns 0 if there is not previous agreement and 1 if there is
; Stores the agreement in a line like mission=1 in file terms_of_use.txt
; in directory spedas_config_dir()
function terms_of_use_check, mission_name
  terms_filename = spedas_config_dir() + '/terms_of_use.txt'
  result = FILE_TEST(terms_filename, /read)
  res = 0
  if result EQ 0  then begin ; file does not exist, no agreement
    return, res
  endif
  ;file exists, read it
  OPENR, lun, terms_filename, /GET_LUN
  line = ''
  mission_name = STRLOWCASE(mission_name)
  mission_name = STRCOMPRESS(mission_name, /REMOVE_ALL)
  seek_text = mission_name + '=1'
  WHILE NOT EOF(lun) DO BEGIN
    READF, lun, line
    if line EQ seek_text then begin
      res = 1
      break
    endif
  ENDWHILE
  FREE_LUN, lun
  
  return, res
end

; Function spedas_terms_of_use_set sets the value for a particular mission
; Value has to be 0 (disagree) or 1 (agree)
; Stores the agreement in a line like mission=1, or mission=0 at the end of the file terms_of_use.txt
; in directory spedas_config_dir()
function spedas_terms_of_use_set, mission_name, value

  if (!D.NAME EQ 'WIN') then newline = string([13B, 10B]) else newline = string(10B)
  terms_filename = spedas_config_dir() + '/terms_of_use.txt'
  mission_name = STRLOWCASE(mission_name)
  mission_name = STRCOMPRESS(mission_name, /REMOVE_ALL)
  new_value = mission_name + '=' + string(value)
  new_value = STRCOMPRESS(new_value, /REMOVE_ALL)
  result = FILE_TEST(terms_filename, /read)
  if result EQ 0 then begin ; file does not exist, create it
    openw,lun,terms_filename,/get_lun
    printf, lun, new_value
    Free_lun, lun
    return, value
  endif
  
  ;file exists, read it
  OPENR, lun, terms_filename, /GET_LUN
  mytext = ''
  line = ''
  seek_text = mission_name + '=*'
  seek_text = STRLOWCASE(seek_text)
  seek_text = STRCOMPRESS(seek_text, /REMOVE_ALL)
  WHILE NOT EOF(lun) DO BEGIN
    READF, lun, line
    line = STRTRIM( line, 2 )
    if line EQ '' then continue
    res = STRMATCH( line, seek_text, /FOLD_CASE)
    if res EQ 0 then begin
      if mytext EQ '' then mytext = line else mytext = mytext + newline + line
    end
  ENDWHILE
  FREE_LUN, lun
  if mytext EQ '' then mytext = new_value else mytext = mytext + newline + new_value
  
  ;write result
  openw, lun, terms_filename, /get_lun
  printf, lun, mytext
  Free_lun, lun
  
  return, value
end

pro mission_terms_of_use_event, event
  mission_name='temp'
  WIDGET_CONTROL, event.TOP, GET_UVALUE=mission_name
  Widget_Control, event.id, Get_UValue=userValue
  CASE userValue OF
  
    'YES':BEGIN
    
    res = spedas_terms_of_use_set(mission_name, 1)
    WIDGET_CONTROL, event.TOP, /DESTROY
  END
  
  'NO':BEGIN
  res= spedas_terms_of_use_set(mission_name, 0)
  WIDGET_CONTROL, event.TOP, /DESTROY
END
ENDCASE
return
END

; This UI terms_of_use should not be called directly. It is called by the function mission_terms_of_use when needed.
pro mission_terms_of_use, mission_name=mission_name, agreement_text=agreement_text 


  If N_ELEMENTS(mission_name) EQ 0 then mission_name = 'testmission'
  If N_ELEMENTS(agreement_text) EQ 0 then agreement_text = 'Terms of Use'
  base = WIDGET_BASE(/column, /NO_COPY, TITLE='Terms of Use: '+mission_name , TAB_MODE=1,  XSIZE=610, YSIZE=650, uvalue=mission_name )
  mainBase = Widget_Base(base, column=1,XSIZE=600, YSIZE=600)
  bottomBase = Widget_Base(base, /row, /align_center)
  result = WIDGET_TEXT( mainBase, value=agreement_text, uname='textbox',SCR_XSIZE=600, SCR_YSIZE=600, /SCROLL)
  button1 = WIDGET_BUTTON(bottomBase, value='Disagree', uvalue='NO',SCR_XSIZE=125 )
  button2 = WIDGET_BUTTON(bottomBase, value='Agree', uvalue='YES',SCR_XSIZE=125 )
  WIDGET_CONTROL, base, /REALIZE
  XMANAGER, 'mission_terms_of_use', base 
  
end


; Main function to call from outside
function spedas_terms_of_use, mission_name, filename=filename,agreement_text=agreement_text

  isWindow = WIDGET_INFO(/ACTIVE )
  if (!D.NAME EQ 'WIN') then newline = string([13B, 10B]) else newline = string(10B)
  
  has_agreed = terms_of_use_check(mission_name)
  if has_agreed then return, 1
  
  if ~keyword_set(agreement_text) then begin 
    if ( N_Elements(filename) EQ 0) || (filename EQ '') then begin ;assume file is in the resource directory
      getresourcepath,path
      filename = path + 'terms_of_use/' + mission_name + '.txt'
    end
    result = FILE_TEST(filename, /read)
    if result EQ 0  then begin
      if isWindow gt 0 then begin
        answer = dialog_message('File Not Found! (' + filename + ')' ,/information)
      endif else begin
        print, 'File Not Found! (' + filename + ')'
      endelse
      return, 0
    endif
    agreement_text = spedas_read_file(filename) + newline
  endif
  
  answer_agreed = ''
  res = 0
  mission_name_loc = mission_name
  if isWindow gt 0 then begin
    agreement_text = agreement_text + newline  + newline + 'Do you agree with the above?' 
    mission_terms_of_use,mission_name=mission_name, agreement_text=agreement_text  
  endif else begin
    print, agreement_text
    read, "Do you agree with the above? (Type yes if you agree, anything else is no.)" +  string(10B) , answer_agreed
    yes_or_no = STRCMP( answer_agreed, 'yes',/FOLD_CASE)
    if yes_or_no then res=1
    setagreement = spedas_terms_of_use_set(mission_name, res)
  endelse

  res = terms_of_use_check(mission_name_loc)
  return, res
end


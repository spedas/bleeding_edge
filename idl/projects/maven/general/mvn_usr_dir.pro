;+
; FUNCTION mvn_usr_dir()
;NAME:
; mvn_usr_dir
;PURPOSE:
; returns a user directory that can be used to store user specific files. Use sparingly!
;Typical Usage:  
;  file = mvn_usr_dir() + '/mvn_user_pass.sav'
;Keywords:
; $LastChangedBy: $
; $LastChangedDate: $
; $LastChangedRevision: $
; $URL: $
;-

function mvn_usr_dir,PFP=PFP
  subdir = 'MISC'
  if keyword_set(PFP) then subdir =  'PFP'
  return, app_user_dir('MAVEN','MAVEN Project',subdir,subdir+' specific stuff','Feel free to delete this directory',1)
end

;+
;program: SPICE_INSTALL
;
;Purpose:  Installs SPICE dlm and binary object modules.
;
;Note:  This routine has not been tested on all platforms. (But should be safe)
;
; Author: Davin Larson   
; $LastChangedBy: $
; $LastChangedDate: $
; $LastChangedRevision: $
; $URL: $
;-
pro spice_install,no_download=no_download,force=force,localdir=localdir
   if keyword_set(localdir) then dlmdir = localdir+'/' else dlmdir = !dlm_path+'/'
   if (file_test(dlmdir,/write,/direc) ne 1) and ~keyword_set(localdir) then begin
      dprint,dlmdir+' is write protected.'
      dprint,'Download to a different directory, i.e.:  SPICE_INSTALL,localdir="TEMP/icyDLMs"'
      dprint,'and then manually copy the files to: '+ !dlm_path
      dprint,'(or use DLM_REGISTER routine - not recommended)'
      message,'Sorry!'
   endif
   OS = file_basename(!dlm_path)
   serverdir = 'http://sprg.ssl.berkeley.edu/data/misc/spice/lib/'+OS+'/'

   help,/dlm,'icy',output=s
   for i=0,n_elements(s)-1 do dprint,s[i]
   if ~keyword_set(force) && spice_test(verbose=0) then begin
      dprint,'SPICE/ICY already installed in '+!dlm_path
      return
   endif else begin
      dprint,'This procedure will download ICY modules from: '+serverdir
      dprint,'And install them in the directory: '+dlmdir
      dprint,'Previous versions of these modules will be given the extension: ".arc*"'
      if ~keyword_set(force) then begin
        dprint,'Must verify....'
        answer = ''
        read,answer,Prompt = 'Are you sure you want to do this? (must type "yes") '
        if answer ne 'yes' then return
      endif    
   endelse
   modules='icy.*'
   file_http_copy,modules,serverdir=serverdir,localdir=dlmdir,url_info=ui,archive_ext='.arc',/preserve_mtime,no_download=no_download,force_download=force,verbose=3
   if n_elements(ui) eq 1 && ui.localname eq '' then begin
      dprint,'Sorry. No icy library found for your platform.'
   endif else begin
      dprint, 'Found: ',ui.localname
 ;     dlm_load,'icy'
      if keyword_set(localdir) then dprint,'You must copy these files to: '+!dlm_path + ' to complete the installation.'
      dprint, 'You may need to exit IDL and run IDL again to use any new installation.'
   endelse

end

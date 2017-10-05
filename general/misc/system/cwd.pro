;+
;Procedure:  CWD  [,newdir]
;Purpose:    Change working directory
;Keywords:
;       /PICK   use dialog_pickfile to choose a directory
;       PROMPT = STRING   - Changes prompt to STRING+newdir
;                The value STRING is stored in a common block variable and
;                is not required in subsequent calls to CWD
;       PROMPT = 0    - Clear prompt string
;
;Other options:
;
;-
pro cwd,newdir,pick=pick,current=current,finaldir=finaldir,prompt=prompt,thisfile=thisfile,verbose=verbose
common cwd_com,prompt_root
if keyword_set(thisfile) then begin   ; change to directory of calling routine
    stack = scope_traceback(/structure)
    filename = stack[scope_level()-2].filename
    newdir = file_dirname(filename)
endif
if n_elements(prompt) ne 0 then prompt_root=prompt
if keyword_set(pick) then newdir = DIALOG_PICKFILE(/DIRECTORY)
if keyword_set(newdir) then cd,newdir,current=current
cd,current=finaldir
dprint,verbose=verbose,dlevel=1,'Directory changed to: '+finaldir
if size(prompt_root,/type) eq 7 then  !prompt=prompt_root+finaldir+'> '
end
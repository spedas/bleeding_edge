pro write_ascii,array,filename,form
;
; This subroutine writes into an ascii file the contents of the
; multi-dimensional array 'array'. This array is constructed in the
; higher level before calling the subroutine.
;
; array               = [[col1],[col2],[col3],...] where colx is a 1-D array
; filename            =the output filename. If null then output is screen.
; form                = The format of writing the sequence of data in array.
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;write_ascii,[[ct.value],[Bx_sc.value],[By_sc.value],[Bz_sc.value]],'minvar.dat','(f13.3,3(f8.3))'
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
outarray=transpose(array)
nrows=long(n_elements(outarray(0,*)))
if (nrows gt 1000000) then print,"nrows to write in ascii file may be too large..., nrows=",nrows
if (nrows gt 32766) then begin
  form2add=string(32766)+"("+form+",/),"
  forminside=""
  ntimesform=0
  STARTFORM:
  nrows=nrows-32766l
  ntimesform=ntimesform+1
  forminside=forminside+form2add
  if (nrows gt 32766) then goto, STARTFORM
  if (ntimesform gt 20) then forminside=string(ntimesform)+"("+string(32766)+"("+form+",/)"+"),"
  forminside="("+forminside+string(nrows-1)+"("+form+",/),"+form+")"
endif else begin
  if (nrows gt 1) then begin
   forminside="("+string(nrows-1)+"("+form+",/),"+form+")"
  endif else begin
    forminside=form
  endelse
endelse
if (filename ne '') then begin
  openw,unit,filename,/get_lun
  printf,unit,outarray,format=forminside
  free_lun,unit
endif else begin
  print,outarray,format=form
endelse
return
end

 

 

 

;+
;PROCEDURE:     ssl_time_check.pro
;PURPOSE:   prints information about gaps between timestamps in cdf files
;INPUT:
;   dir: The directory in which to search for cdfs
;   out: the output directory for the limit files
;   LIM: reassign the limit if you want it is a 2 element array
;   MNEM: optional regex to filter timestamp mnems
;KEYWORDS:
;   none
;
;COMMENTS: Will check all timestamps for all cdfs in the directory and
;output a seperate file for each type of timestamp.
;File format is:
;timestamp1 timestamp2 gap_size record_number
;
;currently it signals a gap if a gap is over 180 seconds or negative
;
;EXAMPLE: ssl_time_check,'/','/dev/null'
;
;CREATED BY:    Patrick Cruce (pcruce@gmail.com)
;
;$LastChangedBy: crussell $
;$LastChangedDate: 2012-05-15 14:43:24 -0700 (Tue, 15 May 2012) $
;$LastChangedRevision: 10431 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/misc/ssl_time_check.pro $
;-

;SUB-FUNCTION:     variable_defined
;PURPOSE:   checks to see if a variable is defined in a given cdf file
;INPUT:
;   file: the name of the file
;   mnem: the name of the mnem
;OUTPUT: 
;   returns 1 if yes 0 if no   
;KEYWORDS:
;   none
;
;EXAMPLE: b=thm_variable_defined('filename','variable')
;
;CREATED BY:    Patrick Cruce (pcruce@gmail.com)

function variable_defined, file, mnem

id = cdf_open(file)

cdf_in =  cdf_info(id)

cdf_close, id

;dprint,  cdf_in.nv

;dprint,  cdf_in.vars[125].name

;iterate over variables
for i = 0, cdf_in.nv-1 do begin

  ;dprint, cdf_in.vars[i-1].name	

  if cdf_in.vars[i].name eq mnem && cdf_in.vars[i].numrec gt 1 then begin

    ;dprint, cdf_in.vars[i].name, i, cdf_in.vars[i].numrec

    return, 1

  endif

endfor

return, 0

end

;SUB-FUNCTION:     union
;PURPOSE: returns the union of two arrays,elements returned sorted
;         runs in O(nlogn)
;
;INPUT:
;   a:the first array
;   b:the second array
;KEYWORDS:
;   none
;
;EXAMPLE: c = union(a,b)
;
;CREATED BY:    Patrick Cruce (pcruce@gmail.com)

function union, a, b

  ;alg is O(n^2) without sort, but
  ;O(nlogn) with sort(assuming efficient sort)
  c = [a, b]

  c = c[sort(c)]

  ;omg this is soooo cool, it eliminates all non-unique elements
  d = c(where(c ne shift(c, 1))) 

  ;iterate through elements of c
  ;for i = 1, N_ELEMENTS(c)-1 do begin

    ;only copy unique elements
   ; if d[N_ELEMENTS(d)-1] ne c[i] then d = [d, c[i]]

    ;I'm very suspicious of the efficiency
    ;of d=[d,c[i]] this would be best done
    ;with a stack push or a linked list
    ;I think I'm going to write a vector "class"

  ;endfor

  return, d

end

;SUB-FUNCTION: discrete_derivative
;PURPOSE:   takes a length n array and returns a length n-1 array with
;each element of the return array representing the ith-(i-1th) element
;of that array
;INPUT:
;   a = the array on which the check is done
;   b = name var to return result in
;KEYWORDS:
;   none
;
;EXAMPLE: discrete_derivative,a,b
;
;CREATED BY:    Patrick Cruce (cruce@gmail.com)

pro discrete_derivative, a, b

n = n_elements(a)

if n gt 1 then begin

  b = double(indgen(n-1))

  for i = 1L, (n-1) do begin

    b[i-1] = a[i]-a[i-1]

  endfor

endif else begin

b = a

endelse

end

;SUB-PROCEDURE:     write_derivative_limits
;PURPOSE:   takes the discrete derivative of a 1-d input array, and
;writes an entry to a specified file whenever that derivative is out
;of range
; output format is:
; v e1 e2 d i
; where:
; v= -1 if d le lim[0] and 1 if d gt lim[1]  
; e1 = the preceding element to the boundary violation
; e2 = the following element 
; d = e2-e1 or the difference that generated the violation 
; i = the approximate record entry where the violation occurred
;INPUT:
;   file: the file to be written
;   a: the array to be analysed
;   lim: 2-element array with format [low,high] representing interval [low,high)
;KEYWORDS:
;   none
;
;EXAMPLE: write_derivative_limits,file,a,lim
;
;CREATED BY:    Patrick Cruce (pcruce@gmail.com)

pro write_derivative_limits, file, a, lim

get_lun, lun

openw, lun, file, /APPEND

discrete_derivative, a, b

for i = 0L, (N_ELEMENTS(b)-1) do begin
                                ;used to behave differently, now the
                                ;same thing could be accomplished with
                                ;an or
  if b[i] lt lim[0] then begin
    printf, lun, a[i], a[i+1], b[i],i
  endif else if b[i] ge lim[1] then begin
    printf, lun, a[i], a[i+1], b[i],i
  endif
endfor

close, lun

free_lun, lun

end

;SUB-PROCEDURE:     get_mnem_file
;PURPOSE:   gets every value of a 1-d mnemonic from a file
;INPUT:
;   filename: The name of the file from which the values should be
;   acquired
;   mnem: the mnem from which the values should be acquired
;   a: the named var in which values should be stored 
;
;KEYWORDS:
;   none
;
;EXAMPLE: get_mnem_file,'filename','mnem',a
;
;CREATED BY:    Patrick Cruce (pcruce@gmail.com)


pro get_mnem_file, filename, mnem, a

;open cdf file
id=cdf_open(filename)
;calls cdf_info.pro from $IDL_BASE_DIR/ssl_general/CDF/ to get cdf info
in =  cdf_info(id)

;iterate over variables
for i = 1, in.nv do begin

  ;if its a time variable
  if stregex(in.vars[i-1].name, mnem, /BOOLEAN) && in.vars[i-1].numrec gt 0 then begin

    ;print the variable in question
    ;dprint,  in.vars[i-1].name, i-1, in.vars[i-1].numrec

    ;get the values
    cdf_varget, id, in.vars[i-1].name, a,  REC_COUNT = in.vars[i-1].numrec, /ZVARIABLE

  endif

endfor

cdf_close, id

end


;SUB-PROCEDURE:     time_list
;PURPOSE:   lists the timestamp mnemonics for in a cdf file
;INPUT:
;   filename: The name of the file to be checked, or no filename to
;   get dialog
;   in: a named var to return the array of time names in
;KEYWORDS:
;   none
;
;EXAMPLE: time_list,'filename'
;
;CREATED BY:    Patrick Cruce (pcruce@gmail.com)

pro time_list, filename, in

;cdf open is part of the standard idl cdf interface
id=cdf_open(filename)
;calls cdf_info.pro from $IDL_BASE_DIR/ssl_general/CDF/ to get cdf info
cdf_in =  cdf_info(id)

in = ['']

;iterate over variables
for i = 1, cdf_in.nv do begin

  ;if its a time variable
  if stregex(cdf_in.vars[i-1].name, '.*_time', /BOOLEAN) && cdf_in.vars[i-1].numrec gt 0 then begin

    ;concatenate the variable in question
    ;dprint,  cdf_in.vars[i-1].name, i-1, cdf_in.vars[i-1].numrec]

    in =  [in, cdf_in.vars[i-1].name]

    ;functionality below removed to turn time_check into time_list
    ;get the values
    ;cdf_varget, id, in.vars[i-1].name, values,  REC_COUNT = in.vars[i-1].numrec, /ZVARIABLE

    ;calculate the change from one element to the next
    ;discrete_derivative, values, values_d

    ;dprint,  'Got Values Plotting'

    ;plot them
    ;plot, values_d

    ;dprint,  'Plotted Press .C to continue'

    ;stop

  endif

endfor

cdf_close, id

end


;SUB-PROCEDURE:     write_lims_dir
;PURPOSE:   searches all the cdfs in a directory and writes the
;results of a limit check over the discrete derivative of the
;specified mnem in a file
;INPUT:
;   dir: The directory in which to search for cdfs
;   mnem: the mnemonic to be acquired
;   lim: a 2-element array specifying the required limits
;   out: the output directory for the limit file
;KEYWORDS:
;   none
;
;EXAMPLE: write_lims_dir,'in_directory','out_directory','mnem_name',[0.0,1.0]
;
;CREATED BY:    Patrick Cruce (pcruce@gmail.com)

pro write_lims_dir, dir, mnem, lim, out

;get a list of cdfs to search
s = file_search(dir+'/*.cdf')
;no empty arrays wtf?
a = [0]
 
;iterate over files
for i = 0, (N_ELEMENTS(s)-1) do begin

  dprint, s[i]

  if variable_defined(s[i], mnem) then begin
  
    ;get the values from a given file
    get_mnem_file, s[i], mnem, v
  
    ;the reform function removes the the dimension of size 1 so dims match
    v =  reform(v)

    ;concatenate
    b = [a, v]

    discrete_derivative, b, c

    spl = strsplit(s[i], '/', /EXTRACT)

    write_derivative_limits, out+'/'+mnem+'.lim', b, lim

    a = v[N_ELEMENTS(v)-1]

  endif

endfor

end


;SUB-PROCEDURE:     time_list_dir
;PURPOSE:   lists the union of timestamp mnemonics for all cdfs in a directory 
;INPUT:
;   list: a list of files to be searched
;   in: a named var to return the array of time names in
;KEYWORDS:
;   none
;
;EXAMPLE: time_list_dir,'dirname'
;
;CREATED BY:    Patrick Cruce (pcruce@gmail.com)

pro time_list_dir, list, in
  
  time_list, list[0], in

  for i = 1, N_ELEMENTS(list)-1 do begin
      
    time_list, list[i], out

    in = union(in, out)
      
  endfor  

end


pro ssl_time_check, dir, out,  LIM = lim, MNEM = mnem

s = file_search(dir+'/*.cdf')

time_list_dir, s, a

if(not keyword_set(lim)) then lim = [0, 1500.0]

if(not keyword_set(mnem)) then mnem = '.*'

dprint,   'Limit: '+ lim

for i = 1,(n_elements(a)-1 ) do begin
  
  if(stregex(a[i], mnem, /BOOLEAN)) then begin

    dprint,  'Mnem:'+a[i]

    write_lims_dir, dir, a[i], lim, out

  endif

endfor

end

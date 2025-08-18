;+
; PROCEDURE: hdf_list_anns
;
; PURPOSE: prints the annotations in an hdf file
;
; KEYWORDS:
;   filename: the filename from which annotations should be lifted
;
;   anns(optional): a named variable in which the annotations will be returned
;
; $LastChangedBy: pcruce $
; $LastChangedDate: 2007-12-07 22:48:56 -0800 (Fri, 07 Dec 2007) $
; $LastChangedRevision: 2165 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/idl_socware/trunk/external/IDL_GEOPACK/trace/ttrace2iono.pro $
;-


pro hdf_list_anns,filename,anns=anns

COMPILE_OPT idl2

file = HDF_OPEN(filename)

anid = HDF_AN_START(file)

n = intarr(4)

res = HDF_AN_FILEINFO(anid,n2,n3,n0,n1)

n[2] = n2
n[3] = n3
n[0] = n0
n[1] = n1 

t = 1

anns = strarr(n0+n1+n2+n3)

print,'Printing annotations: press .c after each annotation to continue'

for j=0,3 do begin
   for i=0,n[j]-1 do begin

      print,'Annotation:',t

      id = HDF_AN_SELECT(anid,i,j)

      res = HDF_AN_READANN(id,ann)

      print,ann

      anns[t] = ann

      t = t+1

      stop

   endfor
endfor

end

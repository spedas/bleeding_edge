;+
; NAME:	ffo_string - substitute for string()
;
; PURPOSE: allows override of free format I/O specifications 
;
; INPUT: format - a format specification, value - a value to be string'ed
;
; Examples: newstring = ffo_string( 'F10.2', 354.9985 )
;           newstring = ffo_string( struct.format, struct.dat )
;
; NOTE: this function wraps the format string in parenthesis
;
; original version - JWJ 08/08/2000
;
FUNCTION ffo_string, format, value

  ; First, if format is defined, just use it against the value
  ; and return the result
  if strlen( format ) gt 0 then begin
    ; print, 'ffo_string using given format: string( FORMAT = (' + format + '), value)'
    return, string( FORMAT = '(' + format + ')', value )
  endif

  ; Here's the original reason this function was developed.
  ; If the format is not defined and the data type
  ; is FLOAT, use F13.6 instead of the IDL 5.2 free format 
  ; specifier of G13.6 which is causes us particular problems
  if size( value, /type ) eq 4 then begin
    ; print, 'ffo_string overriding free format for FLOAT type: string( FORMAT = (F13.6), value)'
    return, string( FORMAT = '(F13.6)', value )
  endif

  ; At last, if no particular rules were met for overriding the
  ; format specifcation, use the free format I/O
  ; print, 'ffo_string doing free format I/O: string( value )'
  return, string( value )

end ; ffo_string

;----------------------------------------------------------------------------
;+
; NAME: delete.pro
;
; PURPOSE: Frees memory
;
; INPUT;  var   - any variable
;
PRO delete, var
;
;    ptr=PTR_NEW(var)
;   PTR_FREE, ptr
var = 0B
;
end
;----------------------------------------------------------------------------
;+                                                                            
; NAME: reform_strc.pro
;
; PURPOSE: Reforms the data array from a (1,N) to a (N).
;
; astrc    -  Input structure
;
FUNCTION reform_strc, astrc
istr=0
namest=tag_names(astrc)
ns_tags=n_tags(astrc)

for k=0, ns_tags-1 do begin
   tagname=namest[k]
   names=tag_names(astrc.(k))
   ntags=n_tags(astrc.(k))
   mc=where((names eq 'VAR_NOTES'),nc)
   for j=0, ntags-1 do begin
      if(names[j] eq 'DAT') then begin
         asize=size(astrc.(k).dat)
         if(asize[0] gt 0) then newdata=reform(astrc.(k).dat) else $
                              newdata=astrc.(k).dat
         tempa=create_struct('DAT',newdata)
         tempb=create_struct(tempb,tempa)
      endif else begin
         str_p=astrc.(k).(j)
         if(j eq 0) then begin
            tempb=create_struct(names[j],str_p)
         endif else begin
            tempa=create_struct(names[j],str_p)
            tempb=create_struct(tempb,tempa)
         endelse
      endelse
   endfor  ; end j
   ; Add VAR_NOTES to each variable that does not have this attribute
   if(mc[0] lt 0) then begin
      tempa=create_struct('VAR_NOTES','')
      tempb=create_struct(tempb,tempa)
   endif
   ; Add each variable to the overall structure
   if(istr eq 0) then begin
      temp2=create_struct(namest[k],tempb)
      b=create_struct(temp2)
   endif else begin
      temp2=create_struct(namest[k],tempb)
      b=create_struct(b,temp2)
   endelse
   istr=istr+1
endfor    ; end k

; Free Memory
delete, tempa
delete, tempb
delete, temp2

return, b
end
;
;12/13/2006 - TJK moved parse_mydepend0 out of this file to its own
;file (w/ same name so that it can be called by spd_cdawlib_read_mycdf.pro
;

;----------------------------------------------------------------------------
;+
; NAME: reform_mystruc.pro
;
; PURPOSE: Reforms the data array from a (i,j,k) to a (i*j,k) and (i,j,k,l) to a (i*j*k,l)
;
; astrc    -  Input structure

FUNCTION reform_mystruct, astrc

  CATCH, err
  IF err NE 0 THEN BEGIN
    CATCH, /CANCEL
    PRINT, !ERROR_STATE.MSG
    RETURN,-1
  ENDIF


istr=0
namest=tag_names(astrc)
ns_tags=n_tags(astrc)

for k=0, ns_tags-1 do begin
   sz=size(astrc.(k).dat)
   names=tag_names(astrc.(k))
   ntags=n_tags(astrc.(k))
   ;
   ;
   case sz[0] of
     3: begin
      tagname=namest[k]
      newsz=sz(1)*sz(2)
      newdata=reform(astrc.(k).dat,newsz,sz(3))
      astrc.(k).var_notes='ListImage'
      for j=0, ntags-1 do begin
         if(names[j] eq 'DAT') then begin
            tempa=create_struct('DAT',newdata)
            tempb=create_struct(tempb,tempa)
         endif else begin
            str_p=astrc.(tagname).(j)
            if(j eq 0) then begin
               tempb=create_struct(names[j],str_p)
            endif else begin
               tempa=create_struct(names[j],str_p)
               tempb=create_struct(tempb,tempa)
            endelse
         endelse
      endfor   ; end j
      temp2=create_struct(namest[k],tempb)
      b=create_struct(b,temp2)
     end
     4: begin
      tagname=namest[k]
      newsz=sz(1)*sz(2)*sz(3)
      newdata=reform(astrc.(k).dat,newsz,sz(4))
      astrc.(k).var_notes='ListImage3D'
      for j=0, ntags-1 do begin
         if(names[j] eq 'DAT') then begin
            tempa=create_struct('DAT',newdata)
            tempb=create_struct(tempb,tempa)
         endif else begin
            str_p=astrc.(tagname).(j)
            if(j eq 0) then begin
               tempb=create_struct(names[j],str_p)
            endif else begin
               tempa=create_struct(names[j],str_p)
               tempb=create_struct(tempb,tempa)
            endelse
         endelse
      endfor   ; end j
      temp2=create_struct(namest[k],tempb)
      b=create_struct(b,temp2)
      ;
     end
     else: begin
      if(istr eq 0) then begin
         b=create_struct(namest[k],astrc.(k))
      endif else begin
         temp=create_struct(namest[k],astrc.(k))
         b=create_struct(b,temp)
      endelse
     end
   endcase 
   istr=istr+1
endfor

; Free Memory
delete, tempa
delete, tempb
delete, temp

return, b
end

;----------------------------------------------------------------------------
;+
; NAME: ord_mystruc.pro
;
; PURPOSE: Reorders the given structure so that the dimension of the data 
;          variables is increasing w/ each entry. 
;
;   astrc  -  Input structure
;   vorder -  An array of the dimension of each variable in the structure
;
;  RCJ 04/24/2008 Before the structure is reordered,
;      look for vars w/ uncertainties associated w/ them, create
;      and index and reorder the structure according to this index. 
;      This will make var and uncertainty be listed side by side. 

FUNCTION ord_mystruct, astrc, vorder, is

vlen=n_elements(vorder)
vmax=max(vorder)
istr=0
names=tag_names(astrc)
;
; RCJ 04/24/2008
; Reorder names so that uncertainties go right next to their respective vars.
; Note: astrc is not being reordered!  only names!  So we also need 'order'
;
nnames=[names[0]]  ; Start w/ Epoch.
order=0            ; Position of Epoch in astrc
for i=1,n_elements(names)-1 do begin
   q=where(nnames eq names[i])
   if q[0] eq -1 then begin  ;  Avoid repeating vars already listed
      nnames=[nnames,names[i]]
      q=where(names eq names[i])
      order=[order,q[0]]
      qq=where(tag_names(astrc.(i)) eq 'DELTA_PLUS_VAR')
      qqq=where(tag_names(astrc.(i)) eq 'DELTA_MINUS_VAR')
      if qq[0] ne -1 and qqq[0] ne -1 then begin
         if astrc.(i).delta_plus_var ne '' then begin
            q=where(names eq strupcase(astrc.(i).delta_plus_var))
	    qq=where(nnames eq strupcase(astrc.(i).delta_plus_var))
	    ;if q[0] ne -1 then begin  ; if, for whatever reason, this var is not
	    if (q[0] ne -1 and qq[0] eq -1) then begin  ; if, for whatever reason, this var is not
	       ;  included in the input structure, then skip it; or if it's already
	       ; in nnames due to another var
               nnames=[nnames,strupcase(astrc.(i).delta_plus_var)]
               order=[order,q[0]]
	    endif
         endif
         if astrc.(i).delta_minus_var ne '' and $
            astrc.(i).delta_minus_var ne astrc.(i).delta_plus_var then begin
            q=where(names eq strupcase(astrc.(i).delta_minus_var))
	    qq=where(nnames eq strupcase(astrc.(i).delta_minus_var))
            ;if  q[0] ne -1 then begin  ; if, for whatever reason, this var is not
            if (q[0] ne -1 and qq[0] eq -1) then begin  ; if, for whatever reason, this var is not
	       ;  included in the input structure, then skip it; or if it's already
	       ; in nnames due to another var
	       nnames=[nnames,strupcase(astrc.(i).delta_minus_var)]
               order=[order,q[0]]
	    endif  
         endif
      endif
   endif      
endfor
;
;   Need to reorder vorder:
vorder=vorder(order)
; RCJ 07/10/2013  RBSP test revealed that 'names' should be ordered too:
names=names(order)
;
for k=is, vmax do begin
   for i=0, vlen-1  do begin
      if(vorder[i] eq k) then begin
         if(istr eq 0) then begin
            bnew=create_struct(names[i],astrc.(i))
         endif else begin
            temp=create_struct(names[i],astrc.(order[i]))
            bnew=create_struct(bnew,temp)
         endelse
         istr=istr+1
      endif
   endfor   ; end i
endfor   ; end k
;
; Free Memeory
delete, temp

return, bnew
end
;
;----------------------------------------------------------------------------
;
FUNCTION dependn_search,a,i,d
;
; INPUT: a - data structure
;	 i - index of variable for which we want the values of depend_n
;        d - which depend? 1? 2? 3?
; OUTPUT: array of depend_n values
;
; Establish error handler
catch, error_status
if(error_status ne 0) then begin
   print, 'STATUS= Data cannot be listed.'
   print, 'ERROR=Error number: ',error_status,' in listing (dependn_search).'
   print, 'ERROR=Error Message: ', !ERR_STRING
   close, 1
   return, -1
endif

depn_values=''
tmp_stuff=''
dependn=''    
;
case d of
   1:begin
      q=where(tag_names(a.(i)) eq 'DEPEND_1')
      if (q[0] ne -1) then dependn=a.(i).depend_1
      ; RCJ 05/16/2013  If alt_cdaweb_depend_1 exists, use it instead:
      q=where(tag_names(a.(i)) eq 'ALT_CDAWEB_DEPEND_1')
      if (q[0] ne -1) then if (a.(i).alt_cdaweb_depend_1 ne '') then dependn=a.(i).alt_cdaweb_depend_1
     end
   2:begin
      q=where(tag_names(a.(i)) eq 'DEPEND_2')
      if (q[0] ne -1) then dependn=a.(i).depend_2
      ; RCJ 05/16/2013  If alt_cdaweb_depend_2 exists, use it instead:
      q=where(tag_names(a.(i)) eq 'ALT_CDAWEB_DEPEND_2')
      if (q[0] ne -1) then if (a.(i).alt_cdaweb_depend_2 ne '') then dependn=a.(i).alt_cdaweb_depend_2
     end 
   3:begin
      q=where(tag_names(a.(i)) eq 'DEPEND_3')
      if (q[0] ne -1) then dependn=a.(i).depend_3
      q=where(tag_names(a.(i)) eq 'ALT_CDAWEB_DEPEND_3')
      if (q[0] ne -1) then if (a.(i).alt_cdaweb_depend_3 ne '') then dependn=a.(i).alt_cdaweb_depend_3
     end 
endcase
if (dependn[0] ne '') then tmp_stuff= a.(dependn).DAT
if (dependn[0] ne '') then dep_fill= a.(dependn).FILLVAL
if string(tmp_stuff[0]) ne '' then begin      
   size_tmp=size(tmp_stuff)
   case size_tmp[0] of
      1: begin
            depn_values=strtrim(tmp_stuff,2)
         end
      2: begin
            ; RCJ 12/01  As far as I know, there are 2 types of 2D depend matrices.
            ; Taking, for example angles and a 3x3 matrix:
            ; a=[[90,180,270],[90,180,270],[90,180,270]] is one possible arrangement, but
            ; a=[[90,90,90],[180,180,180],[270,270,270]] is also an arrangement I've seen.
            ; So this code is checking for these 2 types. Taking the first and second
            ; rows, the first is compared to the second using 'match'. If the elements
            ; do not match (second case, count=0) our depend array is column 0 of 
            ; the original matrix. If all elements match (first case, 
            ; count=n_elements(one of the rows) then our depend array is row 0 of
            ; the original matrix. For a case other than these 2 listing the data
            ; becomes a more difficult task. I would have to think about it....
            ;ts1=tmp_stuff[*,0]
            ;ts2=tmp_stuff[*,1]
	    ; Above is the old ts1 and ts2. Now I'm trying to avoid
	    ; comparing arrays that contain fillval (hopefully not *all* of 
	    ; them do!) :  RCJ 02/21/02
	    ; The "if j lt size_tmp(2)" tests are used in case there are fillvals in
	    ; all of the rows and we don't want to run out of rows to test. RCJ 09/25/02
            j=0L
	    test_ts1:
	    q=where(tmp_stuff[*,j] eq dep_fill)
	    if q[0] ne -1 then begin
	       j=j+1L
	       if j lt size_tmp(2)-1 then goto, test_ts1
	    endif   
            ts1=tmp_stuff[*,j]
	    if j lt size_tmp(2)-1 then j=j+1L
	    test_ts2:
	    q=where(tmp_stuff[*,j] eq dep_fill)
	    if ((q[0] ne -1) and (j lt size_tmp(2)-1)) then begin
	       j=j+1L
	       goto, test_ts2
	    endif
            ts2=tmp_stuff[*,j]
	    ;
	    ; Test one array against the other:
              ; RCJ 06/16/2008  Moved and commented out what we had here to end of function.
	      ;  If this test doesn't work we can bring it back.
	    ; tolerance of 5 units ok?  testing only 3 first elements ok? can do better algorithm.
	    tol=5
	      ; RCJ 06/23/2011  Comparing only 2 first elements because of [2,4300], var:HETCNOFlux,
              ;                 dataset: sta_lb_impact
	    if (((ts1[0] le ts2[0]+tol) or (ts1[0] ge ts2[0]-tol)) or $
	       ((ts1[1] le ts2[1]+tol) or (ts1[1] ge ts2[1]-tol))) then begin
	       ;((ts1[3] le ts2[3]+tol) or (ts1[3] ge ts2[3]-tol))) then begin
	       tmp_stuff=tmp_stuff[*,0]  
	    endif else tmp_stuff=tmp_stuff[*,0]
            depn_values="~"+strtrim(tmp_stuff,2)
	    ;print,depn_values
         end
   endcase      
endif 
;
return, depn_values
            ; RCJ 06/16/2008  This is what was under case size_tmp[0] of 2 :
           ; ;
	   ; match,ts1,ts2,its1,its2,count=count
           ; ; recycling the variable:
           ; its1=n_elements(ts1)
           ; case count(0) of
           ;    0: begin
	   ;       tmp_stuff=transpose(tmp_stuff[0,*])
	   ;    end  
           ;    its1: begin
	   ;       tmp_stuff=tmp_stuff[*,0]
	   ;    end	  
           ;    else: begin
           ;       print,'WARNING: s/w does not recognize this 2D depend matrix. Too many fillvals?'
           ;       print,' Returning first row of array. In listing (dependn_search).'
           ;       ;return, depn_values ; oh well, it's better to return something:
           ;       tmp_stuff=tmp_stuff[*,0]
           ;    end
           ; endcase
           ; ; read only first line, but this is not generic enough... RCJ (10/01)
           ; ;tmp_stuff=tmp_stuff[*,0]
           ; depn_values=strtrim(tmp_stuff,2)
end


;-------------------------------------------------------------------------------------------------

FUNCTION label_search,a,sz,i,k

; RCJ 01/29/2003 We are no longer using label_search_max_width.
;
; Please pay attention to label_search_max_width
; if you make changes to label_search. The previous
; function is a copy of the latter with one specific
; modification, hence any changes may need to be made
; in both places
;
; JWJ 07/31/2000
;
;
;  INPUT: a - data structure
;	  sz - dimension of a(i) variable. First element of output of size().
;	  i - index of variable for which we want the label
;	  k - index of array element for which we want the label
;
;  OUTPUT: element k of label array for variable a.(i)
;
; Establish error handler
catch, error_status
if(error_status ne 0) then begin
   print, 'STATUS= Data cannot be listed.'
   print, 'ERROR=Error number: ',error_status,' in listing (label_search).'
   print, 'ERROR=Error Message: ', !ERR_STRING
   close, 1
   return, -1
endif

label=''
len=size(a.(i).dat)
lent=size(a.(0).dat)
length=lent(lent[0]+2)
if(sz le 1) then begin  
   if(length eq 1 and len[0] eq 1 and len(1) gt 1) then begin
      if(a.(i).lablaxis ne '') then label=strupcase(a.(i).lablaxis) else $ 
                   lab=strupcase(a.(i).labl_ptr_1)
      label=lab[k]
   endif else begin
      if(a.(i).lablaxis eq '') then label=strupcase(a.(i).fieldnam) else $
      label=strupcase(a.(i).lablaxis)
   endelse
endif

if(sz eq 2) then begin
   ;if(a.(i).var_notes eq 'ListImage') then begin     
   if(a.(i).var_notes eq 'ListImage' or a.(i).var_notes eq 'ListImage3D') then begin     
      if(a.(i).lablaxis ne '') then label=a.(i).lablaxis else $
                   label=a.(i).fieldnam
   endif
   if(a.(i).var_notes ne 'ListImage') then begin
      ;if(a.(i).lablaxis ne '') then label=strupcase(a.(i).lablaxis) ;else begin
      ;lab=strupcase(a.(i).labl_ptr_1)
      ;if(lab(0) ne '') then begin
      ;   label=lab[k]
      ;
      ; RCJ 03/28/01 Replaced the above with the code below. It is not
      ; guaranteed that we have labl_ptr_1, and k is sometimes out of range.
      ;
;TJK 9/2/2008 switch the order, want to use labl_ptr_1 if it isn't
;blank over lablaxis. In some cases we need both defined, one for
;plotting (stack_plots) but then the labl_ptr_1 for listings, example
;d.s. is sta/b_l1_let.
;      if(a.(i).lablaxis ne '') then begin
;         lab=strupcase(a.(i).lablaxis) 
;      endif else begin
;         lab=strupcase(a.(i).labl_ptr_1)
;      endelse   

;assign lab to lablaxis initially
      if (spd_cdawlib_tagindex('LABLAXIS',tag_names(a.(i))) ne -1) then begin
         lab=strupcase(a.(i).lablaxis)
      endif
;if labl_ptr_1 existing and isn't blank then use it instead
      if (spd_cdawlib_tagindex('LABL_PTR_1',tag_names(a.(i))) ne -1) then begin
       if(a.(i).labl_ptr_1(0) ne '') then lab=strupcase(a.(i).labl_ptr_1) 
      endif
    


      if(lab[0] ne '') then begin
         if (n_elements(lab) gt 1) then label=lab[k] else label=lab[0]
      endif else begin
         ;
         depend1=strupcase(a.(i).depend_1)
         ; RCJ 05/16/2013  If alt_cdaweb_depend_1 exists, use it instead:
         q=where(tag_names(a.(i)) eq 'ALT_CDAWEB_DEPEND_1')
         if (q[0] ne -1) then if (a.(i).alt_cdaweb_depend_1 ne '') then depend1=a.(i).alt_cdaweb_depend_1
	 ;
         ; RTB added code 3/98
         temp_names=tag_names(a)
         z=spd_cdawlib_tagindex(depend1,temp_names)
         if(z[0] ne -1) then begin
                lab=a.(z[0]).labl_ptr_1 
         endif else begin
                print, depend1, ' not found (ListImage section of spd_cdawlib_list_mystruct).'
         endelse
         if(lab[0] eq '') then begin
            ; RTB  3/98 
            ;lab_cmd='lab=string(a.'+depend1+'.dat[k])'

            ; JWJ 08/08/2000 - changed below ffo_string() call from a string() call
            lab=ffo_string(a.(z[0]).format, a.(z[0]).dat[k])

            label=strtrim(lab(0),2)
         endif else begin
            label=strtrim(lab[k],2)
         endelse
      endelse   
   endif
endif

if(sz eq 4) then begin
      if(a.(i).lablaxis ne '') then label=a.(i).lablaxis else $
                   label=a.(i).fieldnam

      ;assign lab to lablaxis initially
      if (spd_cdawlib_tagindex('LABLAXIS',tag_names(a.(i))) ne -1) then begin
         lab=strupcase(a.(i).lablaxis)
      endif
      ;if labl_ptr_1 existing and isn't blank then use it instead
      if (spd_cdawlib_tagindex('LABL_PTR_1',tag_names(a.(i))) ne -1) then begin
       if(a.(i).labl_ptr_1(0) ne '') then lab=strupcase(a.(i).labl_ptr_1) 
      endif
    
endif

;if(n_elements(label) eq 0) then label = ''

; Fill ' ' w/ '_'
;ii = strpos(label,' ')
;if(ii ne -1) then begin
; if(ii eq 0) then begin
;  label=strtrim(label,1)
;  ii = strpos(label,' ')
; endif

label=strjoin(strsplit(label,/extract),'_')

return, label
end

;-------------------------------------------------------------------------------------------------

FUNCTION unit_search,a,sz,i,k

;  INPUT: a - data structure
;	  sz - dimension of a(i) variable. First element of output of size().
;	  i - index of variable for which we want the unit
;	  k - index of array element for which we want the unit
;
;  OUTPUT: element k of label array for variable a.(i)
;
; Establish error handler
catch, error_status
if(error_status ne 0) then begin
   print, 'STATUS= Data cannot be listed.'
   print, 'ERROR=Error number: ',error_status,' in listing (unit_search).'
   print, 'ERROR=Error Message: ', !ERR_STRING
   close, 1
   return, -1
endif
;print,'stuff = ',sz,i,k
; RCJ 02/06/2003  Was going to call this var 'unit' but the name is already used: "printf, unit,.."
; so I'm calling it 'units':
units=''
len=size(a.(i).dat)
lent=size(a.(0).dat)
length=lent(lent[0]+2)
if(sz le 1) then begin  
   if(a.(i).units ne '') then units=a.(i).units else begin
      ; RCJ 04/18/2003 'units' or 'unit_ptr' are *required* var attributes according to the
      ; ISTP guidelines but some cdfs come w/ neither of them, so here's a test:
      z=spd_cdawlib_tagindex('unit_ptr',tag_names(a.(i))) 
      if z[0] ne -1 then unts=a.(i).unit_ptr else unts=''
      units=unts[k]
   endelse   
endif

if(sz eq 2) then begin
   ;if(a.(i).var_notes eq 'ListImage') then begin     
   if(a.(i).var_notes eq 'ListImage' or a.(i).var_notes eq 'ListImage3D') then begin     
      if(a.(i).units ne '') then units=a.(i).units
   endif
   ;if(a.(i).var_notes ne 'ListImage') then begin
   if(a.(i).var_notes ne 'ListImage' and a.(i).var_notes ne 'ListImage3D') then begin
      ;
      if(a.(i).units ne '') then begin
         unts=a.(i).units 
      endif else begin
         ; RCJ 02/25/2004 'units' or 'unit_ptr' are *required* var attributes according to the
         ; ISTP guidelines but some cdfs come w/ neither of them, so here's the same
         ; test as above:
         z=spd_cdawlib_tagindex('unit_ptr',tag_names(a.(i))) 
         if z[0] ne -1 then unts=a.(i).unit_ptr else unts=''
         ;unts=a.(i).unit_ptr
         ;print,'this is units = ',unts,' and k = ', k
      endelse   
      ;for ii=0,n_elements(unts)-1 do print,ii,'  &',unts(ii),'&'
      ;if(unts(0) ne '') then begin
         if (n_elements(unts) gt 1) then units=unts[k] else units=unts[0]
      ;endif
   endif
endif

if(sz eq 4) then begin

      if(a.(i).units ne '') then begin
         unts=a.(i).units 
      endif else begin
         ; RCJ 02/25/2004 'units' or 'unit_ptr' are *required* var attributes according to the
         ; ISTP guidelines but some cdfs come w/ neither of them, so here's the same
         ; test as above:
         z=spd_cdawlib_tagindex('unit_ptr',tag_names(a.(i))) 
         if z[0] ne -1 then unts=a.(i).unit_ptr else unts=''
      endelse 
      ;if (n_elements(unts) gt 1) then units=unts[k] else units=unts[0]
      units=unts
endif

;if(n_elements(units) eq 0) then units = ''

if strcmp('dd-mm-yyyy',units,10,/fold_case) eq 0 then $  ;  RCJ added this line at Bob's request. see email from 8/22/2011
units=strjoin(strsplit(units,/extract),'_')

return, units
end

;-----------------------------------------------------------------------------------
FUNCTION list_header, a, unit, ntags

; Establish error handler
catch, error_status
if(error_status ne 0) then begin
   print, 'STATUS= Data cannot be listed.'
   print, 'ERROR=Error number: ',error_status,' in listing (list_header).'
   print, 'ERROR=Error Message: ', !ERR_STRING
   close, 1
   return, -1 
endif
status=0
printf, unit, format='("#",14x,"************************************")'
printf, unit, format='("#",14x,"****  RECORD VARYING VARIABLES  ****")'
printf, unit, format='("#",14x,"************************************")'
printf, unit, format='("#",14x)'

ii=0
for i=0L, ntags-5 do begin
   ;if(a.(i).var_type eq 'data') or (a.(i).var_type eq 'support_data') then begin
   if (a.(i).var_type eq 'data') or ((a.(i).var_type eq 'support_data') and (a.(i).cdfrecvary ne 'NOVARY')) then begin
      ii=ii+1
      if(n_elements(a.(i).catdesc) eq 0) then begin
         printf,unit, format='("# ",i2,". ",a)', ii, a.(i).fieldnam
      endif else begin
         if(strlen(a.(i).catdesc) eq 0) then begin
            printf,unit, format='("# ",i2,". ",a)', ii, a.(i).fieldnam
         endif else begin
            printf,unit, format='("# ",i2,". ",a)', ii, a.(i).catdesc
         endelse
      endelse
      if ((a.(i).var_notes ne '') and (a.(i).var_notes ne ' ')) then printf,unit, format='("#       NOTES:  ",a)', a.(i).var_notes
   endif
   ;if(a.(i).var_notes eq 'ListImage') then begin 
   if(a.(i).var_notes eq 'ListImage' or a.(i).var_notes eq 'ListImage3D') and $
     ;((a.(i).var_type eq 'data') or (a.(i).var_type eq 'support_data')) then begin 
     ((a.(i).var_type eq 'data') or ((a.(i).var_type eq 'support_data') and (a.(i).cdfrecvary ne 'NOVARY'))) then begin 
      depend1=a.(i).depend_1
      depend2=a.(i).depend_2
      if (a.(i).var_notes eq 'ListImage3D') then depend3=a.(i).depend_3
      ; RCJ 05/16/2013  If alt_cdaweb_depend_1 and 2 exist, use those instead:
      q=where(tag_names(a.(i)) eq 'ALT_CDAWEB_DEPEND_1')
      if (q[0] ne -1) then if (a.(i).alt_cdaweb_depend_1 ne '') then depend1=a.(i).alt_cdaweb_depend_1 
      q=where(tag_names(a.(i)) eq 'ALT_CDAWEB_DEPEND_2')
      if (q[0] ne -1) then if (a.(i).alt_cdaweb_depend_2 ne '') then depend2=a.(i).alt_cdaweb_depend_2 
      if (a.(i).var_notes eq 'ListImage3D') then begin
         q=where(tag_names(a.(i)) eq 'ALT_CDAWEB_DEPEND_3')
         if (q[0] ne -1) then if (a.(i).alt_cdaweb_depend_3 ne '') then depend3=a.(i).alt_cdaweb_depend_3 
      endif
      ;
      temp_names=tag_names(a)
      ; RTB added code 3/98
      z=spd_cdawlib_tagindex(depend1,temp_names)
      ;
      ; RCJ 05/24/2012 If a.(z[0]).dat does not exist, the execute command
      ;   a few lines further down will fail and throw out an error.
      ;   Let's try to make dep?_cmd="" and same for frm?_cmd
      ;
      ;if(z[0] ne -1) then dep1_cmd='dep1=a.(z[0]).dat' else $
      ;         print, depend1, ' not found(ListImage section of spd_cdawlib_list_mystruct).'
      ;if(z[0] ne -1) then frm1_cmd='frm1=a.(z[0]).format' else $
      ;         print, depend1, ' not found (ListImage section of spd_cdawlib_list_mystruct).'
      if(z[0] ne -1) then dep1=a.(z[0]).dat else dep1=""
      if(z[0] ne -1) then frm1=a.(z[0]).format else frm1=""
      ; RTB added code 3/98
      ; RCJ 12/99 changed z -> zz, otherwise energy and angle will have 
      ;the same values when the commands are executed
      ;
      zz=spd_cdawlib_tagindex(depend2,temp_names)
      ;if(zz[0] ne -1) then dep2_cmd='dep2=a.(zz[0]).dat' else $
      ;         print, depend2, ' not found (ListImage section of spd_cdawlib_list_mystruct).'
      ;if(zz[0] ne -1) then frm2_cmd='frm2=a.(zz[0]).format' else $
      ;         print, depend2, ' not found (ListImage section of spd_cdawlib_list_mystruct).'
      if(zz[0] ne -1) then dep2=a.(zz[0]).dat else dep2=""
      if(zz[0] ne -1) then frm2=a.(zz[0]).format else frm2=""
      if (a.(i).var_notes eq 'ListImage3D') then begin
         zz=spd_cdawlib_tagindex(depend3,temp_names)
         if(zz[0] ne -1) then dep3=a.(zz[0]).dat else dep3=""
         if(zz[0] ne -1) then frm3=a.(zz[0]).format else  frm3=""
      endif
      len1=string(strlen(dep1[0])+1)
      len2=string(strlen(dep2[0])+1)
      sz1=size(dep1)
      sz2=size(dep2)
      ln1=strtrim(sz1(sz1[0]+2),2)
      ln2=strtrim(sz2(sz2[0]+2),2)
      if (a.(i).var_notes eq 'ListImage3D') then begin
         len3=string(strlen(dep3[0])+1)
         sz3=size(dep3)
         ln3=strtrim(sz3(sz3[0]+2),2)
      endif
      frm1=ln1+'a'+len1
      frm2=ln2+'a'+len2
      if (a.(i).var_notes eq 'ListImage3D') then frm3=ln3+'a'+len3
      form1='("# depend_1 is ",a,": [",'+frm1+',"]")'
      form2='("# depend_2 is ",a,": [",'+frm2+',"]")'
      if (a.(i).var_notes eq 'ListImage3D') then form3='("# depend_3 is ",a,": [",'+frm3+',"]")'
      printf, unit, format=form1, depend1,dep1
      printf, unit, format=form2, depend2,dep2
      if (a.(i).var_notes eq 'ListImage3D') then printf, unit, format=form3, depend3,dep3
      ;TJK changed this upon Bob's request since its not an accurate statement...
      ;      printf, unit, format='("Format: [1st depend_1 x M depend_2s, 2nd depend_1 x M depend_2s, ... Nth depend_1 x M depend_2s]")'
      if (a.(i).var_notes eq 'ListImage3D') then begin
           printf, unit, format='("# Order of values for this variable in each row:  values at each depend_1 for the 1st depend_2, for the 1st depend_3; values at each depend_1 for the 1st depend_2, for the 2nd depend_3, ..., values at each depend_1 for the each depend_2, for the last depend_3")'
      endif else begin
         printf, unit, format='("# Order of values for this variable in each row:  values at each depend_1 for the 1st depend_2, values at each depend_1 for the 2nd depend_2, ..., values at each depend_1 for the last depend_2")'
      endelse
      printf,unit,format='("#",14x)'
   endif
endfor   ; end i
printf,unit,format='("#",14x)'

return, status
end

;----------------------------------------------------------------------------------------------
FUNCTION ex_prt, unit, var, var2, slen, k 

; Establish error handler
catch, error_status
if(error_status ne 0) then begin
   print, 'STATUS = Data cannot be listed.'
   print, 'ERROR=Error number: ',error_status,' in listing (ex_prt).'
   print, 'ERROR=Error Message: ', !ERR_STRING
   close, 1
   return, -1 
endif

status=0
icnt=0
output='                                                                                                       '
;for i=0, slen-1 do begin
for i=0L, slen-1 do begin
   ch=strmid(var2,i,1)
   if(icnt lt 75) then begin
      strput,output,ch,icnt  
   endif else begin
      if(ch eq ' ') then begin
         if(k eq 0) then begin
            ;printf, unit, format='("#",5x,a,5x,a)', var, output
            printf, unit, format='("#",5x,a,2x,a)', var, output
         endif else begin
            ;printf, unit, format='("#",30x,a)', output 
            printf, unit, format='("#",37x,a)', output 
         endelse
         icnt=0
         output='                                                                                                       '
      endif else strput,output,ch,icnt
   endelse
   icnt=icnt+1 
endfor
;if(icnt gt 1) then printf, unit, format='("#",30x,a)', output 
if(icnt gt 1) then printf, unit, format='("#",37x,a)', output 

return, status
end

;------------------------------------------------------------------------------------------------
;+
; NAME: wrt_hybd_strct.pro
;
; PURPOSE: Prints ascii file of RV or NRV variables
;
FUNCTION wrt_hybd_strct, a, unit, convar, maxrecs, depend0, mega_num  

; Establish error handler
catch, error_status
if(error_status ne 0) then begin
   if(error_status eq -96) then $ 
          print, 'STATUS= This amount of data cannot be listed, please request a shorter time range' 
   if(error_status eq -133) then $ 
          print, 'STATUS= Incompatible variable types. Select variables separately' 
   if(error_status eq -124) then $ 
          print, 'STATUS= Temporary memory error. Please try again.'
   if(error_status eq -350) then $ ;  format has too many elements
          print, 'STATUS= Please select fewer variables.' $
          else print, 'STATUS= Data cannot be listed'
   print, 'ERROR=Error number: ',error_status,' in listing (wrt_hybd_strct).'
   print, 'ERROR=Error Message: ', !ERR_STRING
   return, -1 
endif
 
status=0
names=strupcase(tag_names(a))
ntags=n_tags(a)
blnk='# '


;print,'convar = ',convar
case convar of
   0 : begin
       ; Check MAXRECS
       if(n_elements(num_data) eq 0) then num_data=0 
       num_data=num_data+ntags
       if(num_data gt maxrecs) then begin
          dif_rec=num_data-maxrecs 
          text='# The maximum number of records allowed to be listed is '
          text1='# Your request has exceeded this maximum by '
          text2='# WARNING: Maxrecs exceeded in Global Attributes; No. Recs. = '
          printf, unit,text,maxrecs
          printf, unit, format='(a,i)',text1,dif_rec
          printf, unit, format='(a)',blnk
          status=1
       endif
       printf, unit, format='("#",14x,"************************************")'
       printf, unit, format='("#",14x,"*****    GLOBAL ATTRIBUTES    ******")'
       printf, unit, format='("#",14x,"************************************")'
       printf, unit, format='("#",14x)'
       for i=0L, ntags-1 do begin
          ;  RCJ 03/18/2014  Space below is arbitrarily defined so each global attr name will fit in that
	  ;       space, and could be chopped if too long.
	  ;       Needs to be increased if we find longer global attr name. You might need to make changes to ex_prt too.
          ;var='                    '
          var='                              '
          var1=strtrim(names[i],2)
          strput,var,var1,0
          tstsz=size(a.(i))
          if(tstsz[0] eq 0) then begin
             var2=strtrim(a.(i),2)
	     ; RCJ 03/18/2014  Clean var2 from carriage-returns, replace w/ blank space:
	     var2=strjoin(strsplit(var2,string(10B),/extract),' ')
             slen=strlen(var2)
	     ;print,'var2 = ',var2
	     ;print,'slen = ',slen
             if(slen gt 80) then begin
                status=ex_prt(unit,var,var2,slen,0) 
             endif else begin
                ;printf, unit, format='("#",5x,a,5x,a)', var, var2
                printf, unit, format='("#",5x,a,2x,a)', var, var2
             endelse
          endif else begin

             for k=0L, tstsz(1)-1 do begin
                var2=strtrim(a.(i)[k])
                slen=strlen(var2)
                if(slen gt 80) then begin
                   status=ex_prt(unit,var,var2,slen,k) 
                endif else begin
                   if(k eq 0) then begin
                      ;printf, unit, format='("#",5x,a,5x,a)', var, var2
                      printf, unit, format='("#",5x,a,2x,a)', var, var2
                   endif else begin
                      ;printf, unit, format='("#",30x,a)', var2
                      printf, unit, format='("#",37x,a)', var2
                   endelse
                endelse
             endfor   ; end k
          endelse
       endfor   ; end i
       ;
       if(num_data gt maxrecs) then begin                                       
          dif_rec=num_data-maxrecs
          text='# The maximum number of records allowed to be listed is '
          text1='# Your request has exceeded this maximum by '
          text2='# WARNING: Maxrecs exceeded in Global Attributes; No. Recs. = '
          printf, unit, format='(a)',blnk
          printf, unit, text,maxrecs
          printf, unit, format='(a,i)',text1,dif_rec
          status=1
       endif
       ;
       printf, unit, format='("#",14x)'   ;'(15x)'
       if mega_num gt 1 then printf, unit,'# **************************************************************************************'
       if mega_num gt 1 then printf, unit,'# *********    There is more than one Epoch for the variables selected    **************'
       if mega_num gt 1 then printf, unit,'# *********    Please scroll down                                         **************'
       if mega_num gt 1 then printf, unit,'# **************************************************************************************'
       if mega_num gt 1 then printf, unit, format='("#",14x)'    ;'(15x)'
   end  ; end case 0
   ;
   ; Record Varying Variables 
   ;
   1 : begin

       ; Check MAXRECS
       if(n_elements(num_data) eq 0) then num_data=0
       ; Put in appropriate record count
       len=size(a.(0).dat)
       length=len(len[0]+2)
       num_data=length
       ; Check for maxrecs begin exceeded
       num_data=num_data+4
       if(num_data gt maxrecs) then begin
          dif_rec=num_data-maxrecs
          text='# The maximum number of records allowed to be listed is '
          text1='# Your request has exceeded this maximum by '
          printf, unit, text,maxrecs
          printf, unit, format='(a,i6)',text1,dif_rec
          printf, unit, format='(a)',blnk
          status=1
          length=maxrecs
       endif
       status=list_header(a,unit,ntags)
       ;labels=strarr(ntags-3)
       ;units=strarr(ntags-3) 
       ; RCJ 05/12/2009   Append strings to 'labels' and 'units' instead of presetting the array sizes.
       ; Note that this first value is cut off the array after the array is populated. 
       labels=''
       units='' 
       ;
       inc=0
       for i=0L, ntags-5 do begin
          ;if (a.(i).var_type eq 'data') or (a.(i).var_type eq 'support_data') then begin
          if (a.(i).var_type eq 'data') or ((a.(i).var_type eq 'support_data') and (a.(i).cdfrecvary ne 'NOVARY')) then begin
             nvar=a.(i).fillval
             ;labels(i)=label_search(a,1,i,0)
	     labels=[labels,label_search(a,1,i,0)]
             ;units(i)=a.(i).units
             ;units(i)=unit_search(a,1,i,0)
	     units=[units,unit_search(a,1,i,0)]
             ; if 'EPOCH' or 'EPOCH92' etc.
             if(names[i] eq depend0) then begin
                temp=create_struct(names[i],a.(i).dateph[0])
             endif else begin
                if(nvar eq 0) then begin
                   temp=create_struct(names[i],a.(i).dat[0]) 
                endif else begin
                   temp=create_struct(names[i],a.(i).dat[0:nvar]) 
                endelse
             endelse
             if(inc eq 0) then begin
                b=temp
             endif else begin
                b=create_struct(b,temp)
             endelse
	     inc=inc+1
	  endif   
       endfor   ; end i
       labels=labels[1:*]
       units=units[1:*]
       ; Free Memory
       delete, temp
       printf,unit,format=a.lform,labels
       printf,unit,format=a.uform,units   ;  if too many vars are requested, a.uform could be too long for idl and an error is generated.
       ;
       for j=0L, length-1 do begin
          inc=0
          for i=0L,ntags-5 do begin
             ;if (a.(i).var_type eq 'data') or (a.(i).var_type eq 'support_data') then begin
             if (a.(i).var_type eq 'data') or ((a.(i).var_type eq 'support_data') and (a.(i).cdfrecvary ne 'NOVARY')) then begin
                ; temporary patch until nvar included as a new variable attribute
                nvar=a.(i).fillval[0]
                ;nvar=nvar(0)
                ; if(names(i) eq 'EPOCH' or names(i) eq 'EPOCH92') then begin
                if(names[i] eq depend0) then begin
                   b.(inc)=a.(i).dateph[j]
		   inc=inc+1
                endif else begin
                   if(nvar eq 0) then begin
                      b.(inc)=a.(i).dat[j] 
                   endif else begin
                      b.(inc)=a.(i).dat[0:nvar]
                   endelse
		   inc=inc+1
                endelse
             endif		
          endfor   ; end i
          printf,unit,format=a.dform,b 
       endfor   ; end j   
       if(num_data gt maxrecs) then begin
          dif_rec=num_data-maxrecs
          text='The maximum number of records allowed to be listed is '
          text1='Your request has exceeded this maximum by '
          printf, unit, format='(a)',blnk
          printf, unit, text,maxrecs
          printf, unit, format='(a,i6)',text1,dif_rec
          status=1                                  
       endif
       ; Free Memory
       delete, b
   end   ; end case 1
   ; 
   ; Non-Record Varying Variables 
   ;
   2 : begin
       ; Check MAXRECS
       if(n_elements(num_data) eq 0) then num_data=0
       ; Put in appropriate record count
       num_data=num_data+4    
       if(num_data gt maxrecs) then begin
          dif_rec=num_data-maxrecs
          text='The maximum number of records allowed to be listed is '
          text1='Your request has exceeded this maximum by '
          printf, unit, text,maxrecs
          printf, unit, format='(a,i6)',text1,dif_rec
          printf, unit, format='(a)',blnk
          status=1                                  
          length=maxrecs
       endif
       ;
       printf, unit, format='("#",14x,"************************************")'
       printf, unit, format='("#",14x,"**  NON-RECORD VARYING VARIABLES  **")'
       printf, unit, format='("#",14x,"************************************")'
       printf, unit, format='("#",14x)'
   end   ; end case 2
   ;
   ; 2-D Record Varying Variables 
   ;
   3 : begin
;Put in a loop to determine the data sizes for each variable's data array
;just once instead of doing this a million times below.  We can't
;trust what's set in a.*.idlsize (at least for virtual variables)
       idlsizes = lonarr(ntags-4,10)
       for i = 0, ntags-5 do begin
           t_size = size(a.(i).dat)
           for j = 0, n_elements(t_size)-1 do begin
               idlsizes[i,j] = t_size[j]
           endfor
       endfor

       ; Check MAXRECS
       if(n_elements(num_data) eq 0) then num_data=0
       ; Put in appropriate record count
;Use the computed sizes stored in idlsizes above
;       len=size(a.(0).dat)
       len=idlsizes[0,*]
       length=len(len[0]+2)
       ; Check for maxrecs begin exceeded                 
       num_data=length
       num_data=num_data+4
       if(num_data gt maxrecs) then begin
          dif_rec=num_data-maxrecs
          text='# The maximum number of records allowed to be listed is '
          text1='# Your request has exceeded this maximum by '
          printf, unit, text,maxrecs
          printf, unit, format='(a,i6)',text1,dif_rec
          printf, unit, format='(a)',blnk
          status=1                                  
          length=maxrecs
       endif
       status=list_header(a,unit,ntags)
       num=a.(0).fillval
       labels=strarr(num)
       units=strarr(num)
       dep1_values=''
       atags=tag_names(a)
       inc=0L 
       for i=0L, ntags-5 do begin
          ;if(a.(i).var_type eq 'data') or (a.(i).var_type eq 'support_data') then begin
          if (a.(i).var_type eq 'data') or ((a.(i).var_type eq 'support_data') and (a.(i).cdfrecvary ne 'NOVARY')) then begin
;TJK replace w/ computed size above to improve performance
;             st_sz=size(a.(i).dat)
              st_sz=idlsizes[i,*]
             if(st_sz[0] le 1) then begin
                ; Include condition where only 1 time selected w/ num_var 
                ;  length vector
                if(st_sz[0] eq 1 and st_sz[1] gt 1 and length eq 1) then begin
                   num_var=st_sz[1]
                   for k=0L, num_var-1 do begin
                      labels(inc)=label_search(a,st_sz[0],i,k)
                      ;units(inc)=a.(i).units
		      units(inc)=unit_search(a,st_sz[0],i,k)
                      ; temp=create_struct(labels(inc),a.(i).dat(k,0))
                      ; temp=create_struct(atags(i)+labels(inc),a.(i).dat(k,0))
		      unique = strtrim(string(inc), 2)
                      temp=create_struct(atags(i)+unique,a.(i).dat[k,0])
                      if(inc eq 0) then begin
                         b=temp
                      endif else begin
                         b=create_struct(b,temp)
                      endelse
                      inc=inc+1
                   endfor   ; end k
                endif else begin
                   ;print,'2', inc, size(labels)
                   labels(inc)=label_search(a,st_sz[0],i,0)
		   ;print,'labels(inc) 1 = ',labels(inc)
                   ;units(inc)=a.(i).units
		   units(inc)=unit_search(a,st_sz[0],i,0)
		   ;print,'units(inc) 1 = ',units(inc)
                   ; names(i) eq 'EPOCH' or 'EPOCH92' etc.
                   if(names(i) eq depend0) then begin
                      temp=create_struct(names(i),a.(i).dateph[0])
                   endif else begin
                      temp=create_struct(names(i),a.(i).dat[0])
                   endelse
                   if(inc eq 0) then begin
                      b=temp
                   endif else begin
                      b=create_struct(b,temp)
                   endelse
                   inc=inc+1
                endelse
             endif   ;  end st_sz[0] le 1
             ;
             if(st_sz[0] eq 2) then begin
                num_var=st_sz[1]
                   for k=0L, num_var-1 do begin
                      labels(inc)=label_search(a,st_sz[0],i,k)
                      ;units(inc)=a.(i).units
		      units(inc)=unit_search(a,st_sz[0],i,k)
                      ; temp=create_struct(labels(inc),a.(i).dat(k,0))
                      ;temp=create_struct(atags(i)+labels(inc),a.(i).dat(k,0))
		      unique = strtrim(string(inc), 2)
                      temp=create_struct(atags(i)+unique,a.(i).dat[k,0])
                      if(inc eq 0) then begin
                         b=temp
                      endif else begin
                         b=create_struct(b,temp)
		      endelse
		      ; RCJ 05/19/2003  Added the 'if endif else' above because
		      ; we got errors when inc=0: b was undefined.	 
                      ;b=create_struct(b,temp)
                      inc=inc+1
                   endfor
             endif   ; end if st_sz(0) eq 2
             dep1=dependn_search(a,i,1)
             if (dep1[0] ne '') then begin
                depend1=a.(i).depend_1
                ; RCJ 05/16/2013  If alt_cdaweb_depend_1 exists, use it instead:
                q=where(tag_names(a.(i)) eq 'ALT_CDAWEB_DEPEND_1')
                if (q[0] ne -1) then if (a.(i).alt_cdaweb_depend_1 ne '') then depend1=a.(i).alt_cdaweb_depend_1
                dep1_units=a.(strtrim(depend1,2)).units
                dep1=['(@_'+dep1+'_'+dep1_units+')']
             endif   
             dep1_values=[dep1_values,dep1]
          endif   ; end a.(i).var_type
       endfor   ; end i
       ; Free Memory
       delete, temp
       ;
       printf,unit,format=a.lform,labels
       ; listing depend_1 values if they exist. RCJ 04/01
       ;if (n_elements(dep1_values) gt 1) then begin
          dep1_values=dep1_values[1:*]
          q=where (dep1_values ne '') 
          if q[0] ne -1  then printf,unit,format=a.dpform,dep1_values
       ;endif 
       printf,unit,format=a.uform,units
       ;
;do this computation once, instead of for each record
i_ntags = ntags-5

       for j=0L, length-1 do begin
          inc=0L
          for i=0L,i_ntags do begin
             ;if(a.(i).var_type eq 'data') or (a.(i).var_type eq 'support_data') then begin
             if ((a.(i).var_type eq 'data') or (a.(i).var_type eq 'support_data') and (a.(i).cdfrecvary ne 'NOVARY'))  then begin
                ; 'EPOCH' or 'EPOCH92'
                if(names(i) eq depend0) then begin
                   b.(inc)=a.(i).dateph[j]
                   inc=inc+1
                endif else begin

;TJK 8/24/2009 EXTREMEMLY poor performance 
;                   st_sz=size(a.(i).dat)
;instead, compute the sizes once above this big loop and reference 
;the values here.  
                   st_sz = idlsizes[i,*]
                   if(st_sz[0] le 1) then begin
                     if(st_sz[0] eq 1 and st_sz[1] gt 1 and length eq 1) then begin
                         num_var=st_sz[1]
                         for k=0L,num_var-1 do begin
                            b.(inc)=a.(i).dat[k,j]
                            inc=inc+1
                         endfor
                      endif else begin
                         b.(inc)=a.(i).dat[j] 
                         inc=inc+1
                      endelse
                   endif   
                   if(st_sz[0] eq 2) then begin
                      num_var=st_sz[1]
		      ; RCJ 12/02/2003  Commented out this 'if num_var lt 20...'
		      ; It doesn't seem to make sense. Will test.
                      ;if(num_var lt 20) then begin
                         for k=0L,num_var-1 do begin
                            b.(inc)=a.(i).dat[k,j]
                            inc=inc+1
                         endfor
                      ;endif else begin
                         ;b.(inc)=a.(i).dat(*,j)
                         ;inc=inc+1  ; RTB added 1/21/99
                      ;endelse
                   endif
                endelse  ; end  (names(i) ne depend0)
             endif   ; end a.(i).var_type
          endfor   ; end i
          printf,unit,format=a.dform,b 
       endfor   ; end j
       ;
       if(num_data gt maxrecs) then begin
          dif_rec=num_data-maxrecs
          text='# The maximum number of records allowed to be listed is '
          text1='# Your request has exceeded this maximum by '
          printf, unit, format='(a)',blnk
          printf, unit, text,maxrecs
          printf, unit, format='(a,i6)',text1,dif_rec
          status=1                                  
          length=maxrecs
       endif
       ; Free Memory
       delete, b
   end   ;   end case 3
   ;
   ; 3-D Record Varying Variables 
   ;
   4 : begin
       ; Check MAXRECS
       if(n_elements(num_data) eq 0) then num_data=0
       ; Put in appropriate record count
       len=size(a.(0).dat)
       length=len(len[0]+2)
       ; Check for maxrecs begin exceeded                 
       num_data=length
       num_data=num_data+4
       if(num_data gt maxrecs) then begin
          dif_rec=num_data-maxrecs
          text='# The maximum number of records allowed to be listed is '
          text1='# Your request has exceeded this maximum by '
          printf, unit, text,maxrecs
          printf, unit, format='(a,i6)',text1,dif_rec
          printf, unit, format='(a)',blnk
          ; printf, unit, ' '                                                     
          status=1                                  
          length=maxrecs
       endif
       ;
       printf, unit, format='("#",14x,"************************************")'
       printf, unit, format='("#",14x,"****  RECORD VARYING VARIABLES  ****")'
       printf, unit, format='("#",14x,"************************************")'
       printf, unit, format='("#",14x)'
       printf,unit, format='("# 1. ",a)', a.epoch.fieldnam
       printf,unit, format='("# 2. ",a)', a.index.catdesc
       printf,unit, format='("# 3. ",a)', a.qflag.catdesc
       printf,unit, format='("# 4. ",a)', a.position.fieldnam
       printf,unit, format='("# 5. ",a)', a.vel.fieldnam
       printf,unit,format='("#",14x)'
       ;
       num=7
       labels=strarr(num)
       units=strarr(num)
       inc=0
       ; Epoch
       eplabel='                       ' 
       strput,eplabel,a.epoch.fieldnam,0
       labels(inc)=eplabel
       units(inc)=a.epoch.units
       temp=create_struct('EPOCH',a.epoch.dateph[0])
       b=temp
       inc=inc+1
       ; Index     
       labels(inc)="Index" 
       units(inc)=''
       inc=inc+1
       ; Qflag
       labels(inc)=a.qflag.lablaxis
       units(inc)=a.qflag.units
       inc=inc+1
       ; Position     
       for k=0, 1 do begin
          if(k eq 0) then labels(inc)=" geo latitude"
          if(k eq 1) then labels(inc)="geo longitude"
          units(inc)=a.position.units
          inc=inc+1
       endfor
       for k=0, 1 do begin
          if(k eq 0) then labels(inc)=" geo east vel"
          if(k eq 1) then labels(inc)="geo north vel"
          units(inc)=a.vel.units
          inc=inc+1
       endfor
       ;
       farr=fltarr(180)
       in=0
       for l=0,29 do begin
          farr(in)=a.index.dat[0]
          in=in+1
          farr(in)=a.qflag.dat[l,0]
          in=in+1
          for k=0, 1 do begin
             farr(in)= a.position.dat[k,l,0]
             in=in+1
          endfor
          for k=0, 1 do begin
             farr(in)= a.vel.dat[k,l,0]
             in=in+1
          endfor
       endfor
       temp=create_struct('DATREC',farr)
       b=create_struct(b,temp)
       ;
       ; Free Memory
       delete, temp 
       printf,unit,format=a.lform,labels
       printf,unit,format=a.uform,units
       ;
       for j=0L, length-1 do begin
          m=0
          b.epoch=a.epoch.dateph[j]
          for l=0,29 do begin
             b.datrec(m)=a.index.dat[l]
             m=m+1
             b.datrec(m)=a.qflag.dat[l,j]
             m=m+1
             for k=0,1 do begin
                b.datrec(m)=a.position.dat[k,l,j]
                m=m+1
             endfor
             for k=0,1 do begin
                b.datrec(m)=a.vel.dat[k,l,j]
                m=m+1
             endfor
          endfor   ; end l
          printf,unit,format=a.dform,b
       endfor   ; end j
       ;
       if(num_data gt maxrecs) then begin
          dif_rec=num_data-maxrecs
          text='# The maximum number of records allowed to be listed is '
          text1='# Your request has exceeded this maximum by '
          printf, unit, format='(a)',blnk
          printf, unit, text,maxrecs
          printf, unit, format='(a,i6)',text1,dif_rec
          status=1                                  
          length=maxrecs
       endif
       ; Free Memory
       delete, b
   end   ;  end case 4
   ;
   ; Image Data and 3D data (only difference is 3D data will have depend_3)
   ;
   5: begin
       ; Check MAXRECS
       if(n_elements(num_data) eq 0) then num_data=0
       ; Put in appropriate record count
       len=size(a.(0).dat)
       length=len(len[0]+2)
       ; Check for maxrecs begin exceeded                 
       num_data=length
       num_data=num_data+4
       if(num_data gt maxrecs) then begin
          dif_rec=num_data-maxrecs
          text='# The maximum number of records allowed to be listed is '
          text1='# Your request has exceeded this maximum by '
          printf, unit, text,maxrecs
          printf, unit, format='(a,i6)',text1,dif_rec
          printf, unit, format='(a)',blnk
          ; printf, unit, ' '                                                     
          status=1                                  
          length=maxrecs
       endif
       status=list_header(a,unit,ntags)
       num=a.(0).fillval
       final_labels=''
       final_units=''
       final_dep1_values=''
       final_dep2_values=''
       final_dep3_values=''
       atags=tag_names(a)
       inc=0L
       for i=0L, ntags-5 do begin
          if(a.(i).var_type eq 'data') or ((a.(i).var_type eq 'support_data') and (a.(i).cdfrecvary ne 'NOVARY')) then begin
             labels=''
             units=''
             dep1_values=''
             dep2_values=''
             dep3_values=''
             st_sz=size(a.(i).dat)
	     ;print,'name = ',a.(i).varname
	     ;print,'st_sz = ',st_sz
             if(st_sz[0] le 1) then begin
                ; get labels and units:
                labels=[labels,label_search(a,st_sz[0],i,0)]
                ;units=[units,a.(i).units]
                units=[units,unit_search(a,st_sz[0],i,0)]
                if(names(i) eq depend0) then begin
                   temp=create_struct(names(i),a.(i).dateph[0])
                endif else begin
                   temp=create_struct(names(i),a.(i).dat[0])
                endelse
                if(inc eq 0) then begin
                   b=temp
                endif else begin
                   b=create_struct(b,temp)
                endelse
                inc=inc+1L
             endif
             if(st_sz[0] eq 2) then begin
                ; get labels and units:
                num_var=st_sz[1]
                for k=0L, num_var-1 do begin
                   labels=[labels,label_search(a,st_sz[0],i,k)]
                   units=[units,unit_search(a,st_sz[0],i,k)]
		   unique = strtrim(string(inc), 2)
                   temp=create_struct(atags(i)+unique,a.(i).dat[k,0])
                   b=create_struct(b,temp)
                   inc=inc+1
                endfor
             endif   ; end st_sz(0) eq 2
             ; Free Memory
             delete, temp
             ;
             labels=labels[1:*]
             final_labels=[final_labels,labels]
	     ;help,final_labels
             units=units[1:*]
             final_units=[final_units,units]
             ;
             ; create array of depend_1 values, if they exist, to also be listed
             ; RCJ 07/2013
             ; exist test is done in dependn_search, if does not exist
             ; return ''
             dep1=dependn_search(a,i,1)
             if (dep1[0] ne '') then begin
                depend1=a.(i).depend_1
                ; RCJ 05/16/2013  If alt_cdaweb_depend_1 exists, use it instead:
                q=where(tag_names(a.(i)) eq 'ALT_CDAWEB_DEPEND_1')
                if (q[0] ne -1) then if (a.(i).alt_cdaweb_depend_1 ne '') then depend1=a.(i).alt_cdaweb_depend_1 
                dep1_units=a.(strtrim(depend1,2)).units
                dep1=['(@_'+dep1+'_'+dep1_units+')']
             endif 
             dep1_values=[dep1_values,dep1]
             ; create array of depend_2 and _3 values, if they exist, to also be listed
             ; RCJ 07/13
             ; exist test is done in dependn_search, if does not exist
             ; return ''
             dep2=dependn_search(a,i,2)
             if (dep2[0] ne '') then begin
                depend2=a.(i).depend_2
                ; RCJ 05/16/2013  If alt_cdaweb_depend_2 exists, use it instead:
                q=where(tag_names(a.(i)) eq 'ALT_CDAWEB_DEPEND_2')
                if (q[0] ne -1) then if (a.(i).alt_cdaweb_depend_2 ne '') then depend2=a.(i).alt_cdaweb_depend_2 
                dep2_units=a.(strtrim(depend2,2)).units
                dep2=['(@_'+dep2+'_'+dep2_units+')']
             endif 
             dep2_values=[dep2_values,dep2]
             dep3=dependn_search(a,i,3)
             if (dep3[0] ne '') then begin
                depend3=a.(i).depend_3
                q=where(tag_names(a.(i)) eq 'ALT_CDAWEB_DEPEND_3')
                if (q[0] ne -1) then if (a.(i).alt_cdaweb_depend_3 ne '') then depend3=a.(i).alt_cdaweb_depend_3 
                dep3_units=a.(strtrim(depend3,2)).units
                dep3=['(@_'+dep3+'_'+dep3_units+')']
             endif 
             dep3_values=[dep3_values,dep3]
             ;
             ; listing depend_1 values if they exist. RCJ 06/01
             if (n_elements(dep1_values) gt 1) then begin
                tmp_dep1_values=dep1_values[1:*]
                while n_elements(dep1_values)-1 le n_elements(labels)-n_elements(tmp_dep1_values) do begin
                   dep1_values=[dep1_values,tmp_dep1_values]
                endwhile
                dep1_values=dep1_values[1:*]
                final_dep1_values=[final_dep1_values,dep1_values]
             endif    
             ; listing depend_2 values if they exist. RCJ 06/01
             if (n_elements(dep2_values) gt 1) then begin
                tmp_dep2_values=dep2_values[1:*]
                if n_elements(tmp_dep2_values) eq n_elements(labels) then begin
                   ;print,'SAME NUMBER OF ELEMENTS!!!!!!'
                   ; RCJ 07/01 If the initial depend_2 is 2D (now stretched into 1D)
                   ; we don't need to do what goes below:
                endif else begin
                   k=0
                   dep2_values=''
                   while n_elements(dep2_values)-1 le n_elements(labels)-n_elements(tmp_dep1_values) do begin
                      for kk=0L,n_elements(tmp_dep1_values)-1 do begin
                         dep2_values=[dep2_values,tmp_dep2_values[k]]
                      endfor   
                      k=k+1
                      if k ge n_elements(tmp_dep2_values) then k=0
                   endwhile
                endelse   
                if n_elements(dep2_values) gt 1 then dep2_values=dep2_values[1:*]
                final_dep2_values=[final_dep2_values,dep2_values]
             endif  
             ; listing depend_3 values if they exist. 
             if (n_elements(dep3_values) gt 1) then begin
                tmp_dep3_values=dep3_values[1:*]
                if n_elements(tmp_dep3_values) eq n_elements(labels) then begin
                   ;print,'SAME NUMBER OF ELEMENTS!!!!!!'
                endif else begin
                   k=0
                   dep3_values=''
                   while n_elements(dep3_values)-1 le (n_elements(labels)-(n_elements(tmp_dep2_values)*n_elements(tmp_dep1_values))) do begin
                      for kk=0L,(n_elements(tmp_dep2_values)*n_elements(tmp_dep1_values))-1 do begin
                         dep3_values=[dep3_values,tmp_dep3_values[k]]
                      endfor   
                      k=k+1
                      if k ge n_elements(tmp_dep3_values) then k=0
                   endwhile
                endelse 
                if n_elements(dep3_values) gt 1 then dep3_values=dep3_values[1:*]
                final_dep3_values=[final_dep3_values,dep3_values]
             endif  
             ;
             ;
          endif   ; end a.(i).var_type
          ;
       endfor   ; end i
       ;
       final_labels=final_labels[1:*]
       printf,unit,format=a.lform,final_labels            ; <----------------------- print final labels
       final_units=final_units[1:*]  ;  but cannot printf the units right now
                                     ;  If there are depend_1/_2 they come first.
       ; If there are labels with no corresponding dep1 values,
       ; then add spaces before the first element of the array.
       ; This works as long as the labels which *do not have* corresponding dep1 
       ; values come before the labels which *have* corresponding dep1 values. 
       ; If that condition is not true, the logic has to be reworked.  RCJ 07/01
       if n_elements(final_dep1_values) gt 1 then begin
          final_dep1_values=final_dep1_values[1:*]
          diff=n_elements(final_labels)-n_elements(final_dep1_values)
          for k=1L,diff do begin
             formt = "('" + strtrim(strlen(final_labels[k])+1,2)+"'x,a)"
             space=string("",format=formt)
             ;cmd='space=string("",format="('+strtrim(strlen(final_labels[k])+1,2)+'x,a)")
             final_dep1_values=[space,final_dep1_values]
          endfor
       ;printf,unit,format=a.dpform,final_dep1_values
          q=where (final_dep1_values ne '') 
          if q[0] ne -1 then printf,unit,format=a.dpform,final_dep1_values; <----------------------- print final dep1
       endif   
       ; same for dep2 values:
       if n_elements(final_dep2_values) gt 1 then begin
          final_dep2_values=final_dep2_values[1:*]
          diff=n_elements(final_labels)-n_elements(final_dep2_values)
          for k=1L,diff do begin
             formt = "('" + strtrim(strlen(final_labels[k])+1,2)+"'x,a)"
             space=string("",format=formt)
             ;cmd='space=string("",format="('+strtrim(strlen(final_labels[k])+1,2)+'x,a)")
             final_dep2_values=[space,final_dep2_values]
          endfor
       ;printf,unit,format=a.dpform,final_dep2_values
          q=where (final_dep2_values ne '') 
          if q[0] ne -1 then printf,unit,format=a.dpform,final_dep2_values; <----------------------- print final dep2
       endif  
       ; 
       ; same for dep3 values:
       if n_elements(final_dep3_values) gt 1 then begin
          final_dep3_values=final_dep3_values[1:*]
          diff=n_elements(final_labels)-n_elements(final_dep3_values)
          for k=1L,diff do begin
             formt = "('" + strtrim(strlen(final_labels[k])+1,2)+"'x,a)"
             space=string("",format=formt)
             ;cmd='space=string("",format="('+strtrim(strlen(final_labels[k])+1,2)+'x,a)")
             final_dep3_values=[space,final_dep3_values]
          endfor
          q=where (final_dep3_values ne '') 
          if q[0] ne -1 then printf,unit,format=a.dpform,final_dep3_values; <----------------------- print final dep3
       endif  
       ; 
       printf,unit,format=a.uform,final_units      ; <----------------------- print final units
       ;
	     ;help,final_dep1_values,final_dep2_values,final_dep3_values,final_labels
	     ;print,'** ',final_dep1_values
	     ;print,'** ',final_dep2_values
	     ;print,'** ',final_dep3_values
	     ;print,'** ',final_labels
       for j=0L, length-1 do begin
          inc=0L
          for i=0L,ntags-5 do begin
             if (a.(i).var_type eq 'data') or ((a.(i).var_type eq 'support_data') and (a.(i).cdfrecvary ne 'NOVARY')) then begin
                ; if(names(i) eq 'EPOCH' or names(i) eq 'EPOCH92') then begin
                if(names(i) eq depend0) then begin
                   b.(inc)=a.(i).dateph[j]
                   inc=inc+1L
                endif else begin
                   st_sz=size(a.(i).dat)  
                   if(st_sz[0] eq 1) then begin
                      b.(inc)=a.(i).dat[j] 
                      inc=inc+1L
                   endif   
                   if(st_sz[0] eq 2) then begin
                      num_var=st_sz[1]
                      for k=0L,num_var-1 do begin
                         b.(inc)=a.(i).dat[k,j]
                         inc=inc+1L
                      endfor
                   endif
                endelse
             endif
          endfor   ; end i
          printf,unit,format=a.dform,b
       endfor   ; end j
       ; 
       if(num_data gt maxrecs) then begin
          dif_rec=num_data-maxrecs
          text='# The maximum number of records allowed to be listed is '
          text1='# Your request has exceeded this maximum by '
          printf, unit, format='(a)',blnk
          printf, unit,text,maxrecs
          printf, unit, format='(a,i6)',text1,dif_rec
          status=1                                  
          length=maxrecs
       endif
       ; Free Memory
       delete, b   
   end   ; end case 5
   ;
   ;
   else : begin
          print, 'STATUS= A listing of these data cannot be generated. '
          print, "ERROR=Error: Invalid control variable; convar= ",convar
          close,1
          return, -1
   end 
endcase   ; end case convar

return, status 
  
end

;----------------------------------------------------------------------------
;+
; NAME:  form_bld.pro
;
; PURPOSE: Builds format statements 
;
; shft - 0= left justified field; 1= right justified field
;
FUNCTION form_bld, col_sz, label, units, dat_len, dep_col_sz, depend1_labels, $
   dep2_col_sz, depend2_labels, dep3_col_sz, depend3_labels,form, shft
 
; Use column size and to build label, unit and data format statements
;
maxlength=max(strlen(depend1_labels)) > max(strlen(depend2_labels))  > max(strlen(depend3_labels)) > strlen(label) 
mintab=fix(dep_col_sz-max(strlen(depend1_labels))) < fix(dep2_col_sz-max(strlen(depend2_labels))) < fix(dep3_col_sz-max(strlen(depend3_labels)))<fix(col_sz-strlen(label))
;
; depend1 and depend2 use the same format (depv) :
; depend1, depend2 and depend3 use the same format (depv) :
ltab=strtrim(mintab,2)
lfld=strtrim(maxlength,2)
if(shft eq 0) then begin
   if(ltab ne '0') then depv='A'+lfld+','+ltab+'X,1X,' else depv='A'+lfld+',1X,'
endif else begin
   if(ltab ne '0') then depv=ltab+'X,A'+lfld+',1X,' else depv='A'+lfld+',1X,'
endelse
;
if(shft eq 0) then begin
   if(ltab ne '0') then labv='A'+lfld+','+ltab+'X,1X,' else labv='A'+lfld+',1X,'
endif else begin
   if(ltab ne '0') then labv=ltab+'X,A'+lfld+',1X,' else labv='A'+lfld+',1X,'
endelse
;
col_sz=maxlength > col_sz
utab=strtrim(fix(col_sz-strlen(units)),2)
ufld=strtrim(strlen(units),2)
if(shft eq 0) then begin
   if(utab ne '0') then untv='A'+ufld+','+utab+'X,1X,' else untv='A'+ufld+',1X,'
endif else begin
   if(utab ne '0') then untv=utab+'X,A'+ufld+',1X,' else untv='A'+ufld+',1X,'
endelse
;
dtab=strtrim(fix(col_sz-dat_len),2)
if(dtab ne '0') then datv=dtab+'X,'+form+',1X,' $
     else datv=form+',1X,'
sform=create_struct('labv',labv,'untv',untv,'datv',datv,'depv',depv)

return, sform
end

;----------------------------------------------------------------------------
;+ 
; NAME:  data_len.pro
;
; PURPOSE: Determines the length of the data field given FORMAT, FILLVAL 
;
;

FUNCTION data_len,format,fillval
                  
; Set input values if undefined 
;
status=0
;if(n_elements(format) eq 0) then form='null' else form=strmid(format,0,1)
;if(strlen(format) eq 0) then form='null' else begin
; RCJ 11/23/05   It has to be G format or fillvals will be ****          
if(strlen(format) eq 0) then format='G13.6' 
itrip=0
nc=0
new_form='        '
nvar=''
ivar=0
for i=0L, strlen(format)-1 do begin   
   ch=strupcase(strmid(format,i,1))
   if(ch ne '(') and (ch ne 'A') and (ch ne 'F') and (ch ne 'P') and $
      (ch ne 'I') and (ch ne 'Z') and (ch ne 'G') and (ch ne 'E') then begin
      if(ivar eq 0) then nvar=nvar+ch
   endif
   if(ch eq 'A') or (ch eq 'F') or (ch eq 'I') or (ch eq 'Z') or (ch eq 'G') $
      or (ch eq 'E') then begin
      form=ch
      itrip=1
      ivar=1
   endif 
   if(ch eq 'P') then ch=''
   if(ch eq ',') or (ch eq ')') then itrip=0
   if(itrip eq 1) then begin
      strput,new_form,ch,nc
      nc=nc+1
   endif
endfor   ; end i
format=strtrim(new_form,2)
formlen=strlen(format)-1
;endelse
;
case form of
   'null' : begin
            status=-1
            return, status
   end
   ; RCJ 11/23/05  We are setting formats F,E,G to G13.6 (or wider)
   ;   to accomodate possible fillvals in the data
   'F' : begin
         dat_len = 13.6 > strmid(format,1,formlen)
         ;dat_len = strmid(dat_len,6,4)
	 ; RCJ 10/29/2007  Generalizing line above. Same for E and G below.
         dat_len = strmid(dat_len,6,formlen > 4)
   end
   'E' : begin
         dat_len = 13.6 > strmid(format,1,formlen)
         ;dat_len = strmid(dat_len,6,4)
         dat_len = strmid(dat_len,6,formlen > 4)
   end
   'G' : begin
         dat_len = 13.6 > strmid(format,1,formlen)
         ;dat_len = strmid(dat_len,6,4)
         dat_len = strmid(dat_len,6,formlen > 4)
   end
   'I' : begin
         ;  Program caused arithmetic error: Floating illegal operand; where?
         if(n_elements(fillval) eq 0) then dat_len=strmid(format,1,formlen) else $
            dat_len=strlen(strtrim(string(fix(fillval)),2)) > strmid(format,1,3)
   end
   'A' : begin
         ;if(n_elements(fillval) eq 0) then dat_len=strmid(format,1,formlen) else $
         ;   dat_len=strlen(strtrim(fillval,2)) > strmid(format,1,3)       
         if(n_elements(fillval) eq 0) then dat_len=strmid(format,1,formlen) $
	 else begin
	    if size(fillval,/tname) eq 'DCOMPLEX' then $
	    ; RCJ 11/2006  This is the case of epoch for themis data
            dat_len=strlen(strtrim(real_part(fillval),2)) > strmid(format,1,3) else $
            dat_len=strlen(strtrim(fillval,2)) > strmid(format,1,3) 
	 endelse   
   end
   else : begin
          dat_len=0
   end
endcase
; RCJ 11/23/05  It has to be G format or fillvals will be ****:
if(form eq 'F') or (form eq 'E') then form='G' 
if(nvar ne '') then begin
   format=nvar+form+strtrim(dat_len,2)
   dat_len=fix(nvar)*fix(dat_len)
   nvar=fix(nvar)-1
endif else begin
   format=form+strtrim(dat_len,2)
   dat_len=fix(dat_len)
   nvar=0
endelse
frm_st=create_struct('status',status, 'form',format, 'dat_len',dat_len, $
                      'nvar',nvar) 
return, frm_st

end

function ep_conv, b, depd0, HANDLE=handle, sec_of_year=sec_of_year
; 
catch, error_status
if(error_status ne 0) then begin
   if(error_status eq -78) then $ 
      print, 'STATUS=Available memory exceeded. Re-select time interval.'
   print, 'ERROR=Error number: ',error_status,' in listing (ep_conv).'
   print, 'ERROR=Error Message: ', !ERR_STRING
   stop
endif
;
tagnames=tag_names(b)
v1=spd_cdawlib_tagindex(depd0,tagnames)
if(n_elements(handle) eq 0) then handle=0

if(handle eq 0) then begin
   dat=b.(v1[0]).dat
   datsz=size(dat)
   if(datsz[0] gt 0) then dat=reform(dat) 
endif else begin 
   tmp=b.(v1[0]).HANDLE
   handle_value, tmp, dat
   datsz=size(dat)
   if(datsz[0] gt 0) then dat=reform(dat) 
endelse
len=size(dat)
;TJK 10/1/2009 - put in code to check for Epoch 16 values (dcomplex)
;if found, then print the extra time fields (micro, nano and pico)

epoch_type = size(dat,/type)
case epoch_type of
 9: begin  ; complex
   ep16=1
   if keyword_set(sec_of_year) then b.(v1[0]).units="Year____Secs-of-year" else $  ;  e.g. 2001 4585746.000  <-  microsec precision
      b.(v1[0]).units="dd-mm-yyyy hh:mm:ss.mil.mic.nan.pic"
 end
 14: begin  ;  long64
   ep16=0
   if keyword_set(sec_of_year) then b.(v1[0]).units="Year____Secs-of-year" else $  ;  e.g. 2001 4585746.000  <-  microsec precision
      b.(v1[0]).units="dd-mm-yyyy hh:mm:ss.mil.mic" 
 end
 else: begin
    ep16=0
   if keyword_set(sec_of_year) then b.(v1[0]).units="Year____Secs-of-year" else $  ;  e.g. 2001 4585746.000  <-  microsec precision
       b.(v1[0]).units="dd-mm-yyyy hh:mm:ss.ms"
 end
endcase
;if (epoch_type eq 9) then begin ; if dcomplex
;    ep16 = 1 
;    b.(v1(0)).units="dd-mm-yyyy hh:mm:ss.mil.mic.nan.pic"
;endif else begin
;     ep16 = 0
;endelse

length=long(len(len(0)+2))
dat_eph=strarr(length)

for k=0L, length-1 do begin
   if keyword_set(sec_of_year) then begin
     CDF_EPOCH,dat[k], yr, mo, dy, hr, mn, sc, milli, micro, /break
     yr=long(yr) & mo=long(mo) & dy=long(dy) & hr=long(hr) & mn=long(mn)
     sc=long(sc) & hr=long(hr) 
     ical,yr,doy,mo,dy,/idoy
     doy=float(doy-1)  ;  if day=1 have to start from beginning of day, ie, not a whole day has passed at 00:05 of day 1, don't you agree?
     yrsec=double(sc)+double(mn)*60.+double(hr)*3600.+double(doy)*24.*3600.
     yrsec=yrsec+double(milli)/1000.+double(micro)/10^6.
     ;print,'date = ',yr, mo, dy, hr, mn,sc,milli, micro, yrmilli
   endif else begin
     if (ep16) then begin
      CDF_EPOCH16,dat[k], yr, mo, dy, hr, mn, sc, milli, micro, nano, pico, /break 
     endif else begin   
      if (size(dat[k],/type) eq 14) then begin
           CDF_EPOCH,dat[k], yr, mo, dy, hr, mn, sc, milli, micro, /break,/tointeger 
	 endif else begin
           CDF_EPOCH,dat[k], yr, mo, dy, hr, mn, sc, milli, /break
	 endelse
     endelse 
   endelse 
   if(dy lt 10) then dy= '0'+strtrim(dy,2) else dy=strtrim(dy,2)
   if(mo lt 10) then mo= '0'+strtrim(mo,2) else mo=strtrim(mo,2)
   if(hr lt 10) then hr= '0'+strtrim(hr,2) else hr=strtrim(hr,2)
   if(mn lt 10) then mn= '0'+strtrim(mn,2) else mn=strtrim(mn,2)
   if(sc lt 10) then sc= '0'+strtrim(sc,2) else sc=strtrim(sc,2)
   milli=strmid(strtrim(float(milli)/1000.,2),2,3)
   yr=strtrim(yr,2)
   if keyword_set(sec_of_year) then begin
     yrsec_str=string(yrsec,format='(f15.6)')
     dat_eph[k]=yr+' '+yrsec_str
   endif else begin
     if (ep16) then begin
       micro=strmid(strtrim(float(micro)/1000.,2),2,3)
       nano=strmid(strtrim(float(nano)/1000.,2),2,3)
       pico=strmid(strtrim(float(pico)/1000.,2),2,3)
       dat_eph[k]=dy+'-'+mo+'-'+yr+' '+hr+':'+mn+':'+sc+'.'+milli+'.'+micro+'.'+nano+'.'+pico   
     endif else begin
      if (size(dat[k],/type) eq 14) then begin
       micro=strmid(strtrim(float(micro)/1000.,2),2,3)
       dat_eph[k]=dy+'-'+mo+'-'+yr+' '+hr+':'+mn+':'+sc+'.'+milli +'.'+micro
      endif else begin   
       dat_eph[k]=dy+'-'+mo+'-'+yr+' '+hr+':'+mn+':'+sc+'.'+milli
      endelse   
     endelse
   endelse  
endfor
eptmp=create_struct('DATEPH',dat_eph)
return, eptmp
;
end 

;+ 
; NAME:  spd_cdawlib_list_mystruct.pro
;
; PURPOSE:  Generates a list output for CDAWweb
;
; CALLING SEQUENCE:
;
; FUNCTION spd_cdawlib_list_mystruct, a,NOGATT=nogatt,NOVATT=novatt,NORV=norv,$
;                         NONRV=nonrv,NO2DRV=no2drv,FILENAME=filename,$
;                         TSTART=TSTART,TSTOP=TSTOP,MAXRECS=maxrecs
;  
; VARIABLES:
;
; Input:
;
;  a        - an IDL structure
; 
; Keyword Parameters:
;
;  nogatt   - Global attributes output: =0 (print), =1 (no print)
;  novatt   - Variable attributes output: =0 (print), =1 (no print)
;  norv     - Record varying output: =0 (print), =1 (no print) 
;  nonrv    - Non record varying output: =0 (print), =1 (no print)
;  no2drv   - 2D record varying output: =0 (print), =1 (no print)
;  filename - Output filename 
;  maxrecs  - Maximum record output
;
; REQUIRED PROCEDURES:
;
; HISTORY
;
; Initial version: 
;
;         1.0  R. Baldwin  HSTX           2/9/96
;
;
;Copyright 1996-2013 United States Government as represented by the 
;Administrator of the National Aeronautics and Space Administration. 
;All Rights Reserved.
;
;------------------------------------------------------------------
;
FUNCTION spd_cdawlib_list_mystruct, a,NOGATT=nogatt,NOVATT=novatt,NORV=norv,$
                        NONRV=nonrv,NO2DRV=no2drv,FILENAME=filename,$
                        TSTART=TSTART,TSTOP=TSTOP, START_msec=start_msec, STOP_msec=stop_msec,$
			MAXRECS=maxrecs, SEC_OF_YEAR=sec_of_year, $
                        REPORT=REPORT,STATUS=STATUS,DEBUG=DEBUG
;
; Set input values if undefined 
;
;TJK 5/18/00 - Modified to allow 100,000 records to be listed - greatly
;increased from 30,000 - might have to back this off some should we start
;to see performance impacts.
;


compile_opt idl2


status=0
reportflag = 0
if(n_elements(nogatt) eq 0) then nogatt=0
if(n_elements(novatt) eq 0) then novatt=0
if(n_elements(norv) eq 0) then norv=1
if(n_elements(nonrv) eq 0) then nonrv=1
if(n_elements(no2drv) eq 0) then no2drv=1
if(n_elements(no3drv) eq 0) then no3drv=1
if(n_elements(no4drv) eq 0) then no4drv=1
if(n_elements(noimg) eq 0) then noimg=1
if(n_elements(filename) eq 0) then filename='cdaweb_listing.asc' 
;if(n_elements(maxrecs) eq 0) then maxrecs=150000 ;TJK changed from 30000
if(n_elements(maxrecs) eq 0) then maxrecs=15000000 ;TJK changed from 150000 for testing on new machine
;if(n_elements(maxrecs) eq 0) then maxrecs=100000 ;TJK changed from 30000
; REPORT and reportflag no longer used;
if(n_elements(REPORT) eq 0) then report=''
; statusflag not implemented yet!
if(n_elements(STATUS) eq 0) then statusflag=1L else statusflag=0L 
if(n_elements(DEBUG) eq 0) then debugflag=1L else debugflag=0L 

; Establish error handler
catch, error_status
if(error_status ne 0) then begin
   print, 'ERROR=Error number: ',error_status,' in listing (spd_cdawlib_list_mystruct).'
   print, 'ERROR=Error Message: ', !ERR_STRING
   if(error_status eq -98) then begin
      if reportflag then printf, 1, 'STATUS=Data space too large. Cannot currently list these data.'
      print, 'STATUS=Data space too large. Cannot currently list these data.'
   endif else begin
      if reportflag then printf, 1, 'STATUS= Data cannot be listed. '
      print, 'STATUS=Data cannot be listed. '
   endelse
   close,1
   return, -1 
endif
; Open report file
if(REPORT) then begin
   openw, 1, REPORT, error=err
   if(err ne 0) then begin
      print, "ERROR=",!ERR_STRING 
      close, 1 & return, -1
   endif
   reportFlag = 1
endif
if(keyword_set(DEBUG)) then print, 'Opening output file=', filename
;
; Open output file
;
openw, unit, filename, /get_lun,error=err,width=1000
if(n_elements(a) eq 0) then begin
   if reportflag then printf, 1, 'STATUS= Data cannot be listed.'
   print, 'STATUS=Data cannot be listed.'
   print, 'ERROR=Error: Undefined structure' 
   close, 1
   return, -1 
endif

; Add Code to trap a=-1 bad structures  RTB
str_tst=size(a)
if(str_tst[str_tst[0]+1] ne 8) then begin
   v_data='DATASET=UNDEFINED'
   v_err='ERROR=Input is not a stucture.'
   v_stat='STATUS=Cannot list this data'
   ; a=crate_struct('DATASET',v_data,'ERROR',v_err,'STATUS',v_stat)
   print, v_data
   print, v_err
   print, v_stat
   return, 0
endif else begin
   ; Test for errors trapped in spd_cdawlib_read_mycdf
   atags=tag_names(a)
   rflag=spd_cdawlib_tagindex('DATASET',atags)
   if(rflag[0] ne -1) then begin
      print, a.DATASET
      ;    print, a.ERROR    1/97 spd_cdawlib_read_mycdf change
      print, a.STATUS
      return, 0
   endif
   ;
   ; RCJ 06/09/2004. Testing number of columns. Large images
   ; yield more than 32767. columns and IDL will not print
   ; that much (and it will take a looong time to process). 
   ; This test had to be done here, before 'LISTING=' because parse.ph
   ; will register a 'system error' if there is a filename but nothing
   ; is listed.
   for i=0,n_elements(atags)-1 do begin
      if strupcase(a.(i).var_type) eq 'DATA' or $
         strupcase(a.(i).var_type) eq 'SUPPORT_DATA' then begin
	 aatags=tag_names(a.(i))
         q=where(aatags eq 'HANDLE')
	 if q[0] ne -1 then handle_value,a.(i).handle,testarr $
	    else testarr=a.(i).dat
	 sz=size(testarr)
	 if sz[0] eq 3 then begin
	    if sz[1]*sz[2] gt 32767. then begin
	       a.(i).var_type = 'ignore_data'
	       print,'STATUS=3D array too big. Will not list.'
	    endif  
	 endif   	
      endif	
   endfor
   ;
   ;
   ; There's nothing to list unless at least one of the variables is var_type=data 
   ; reuse variable rflag:    RCJ 09/16/02
   rflag=''
   for i=0,n_elements(atags)-1 do rflag=[rflag,a.(i).var_type]
   q=where(strupcase(rflag) eq 'DATA')
   if q[0] eq -1 then return,0 
endelse  

; Write DATASET=
data_set=''
if(data_set eq '') then begin 
   ; RCJ 03/13/2003 Some datasets are larger than 9 characters.
   ; Using strsplit to separate the string at the '_' and rejoin the dataset name only.
   ;data_set=strmid(a.(0).LOGICAL_FILE_ID,0,9)
   ; RCJ 06/27/2013 Logical_file_id is a required attribute but it may not be there
   ;    so I added this test:
   s=spd_cdawlib_tagindex('LOGICAL_FILE_ID',tag_names(a.(0)))
   if s[0] ne -1 then begin
      s=strsplit(a.(0).LOGICAL_FILE_ID,'_',/extract)
      if n_elements(s) gt 1 then begin  ; only continue if '_' exists in logical_file_id
         data_set=s[0]+'_'
         for i=1,n_elements(s)-4 do begin
            data_set=data_set+s[i]+'_'
         endfor	 
         data_set=strupcase(data_set+s[n_elements(s)-3]) 
         ;data_set=strupcase(data_set[0]+'_'+data_set[1]+'_'+data_set[2])
      endif
   endif
endif
if(data_set eq '') then begin
   data_set=strtrim(a.(0).LOGICAL_SOURCE,2)
   data_set=strupcase(data_set)
endif
if reportflag then printf, 1, 'DATASET=',data_set
print, 'DATASET=',data_set
; Write file name to REPORT file
if reportflag then printf, 1, 'LISTING=',filename
split=strsplit(filename,'/',/extract)
loutdir='/'
for t=0L,n_elements(split)-2 do loutdir=loutdir+split[t]+'/'
print, 'LIST_OUTDIR=',loutdir
fmt='(a10,a'+strtrim(strlen(split[t]),2)+')'
print, 'LONG_LIST=',split[t], format=fmt
;print, 'LISTING=',filename
;
; Reform dat arrays w/in structure.
;
if(keyword_set(DEBUG)) then print, 'Reform arrays w/in structure.'
a=reform_strc(a)
;
; Separate variables by their depend_0; build mega-structure
;
mega=parse_mydepend0(a)
depends=tag_names(mega)

for mega_loop=1, mega.num do begin
   a=mega.(mega_loop)
   depend0=depends[mega_loop]
   if(depend0 eq ' ') then continue
   ;
   ; Determine Global and variable attribute structures for listing
   ;
   ns_tags=n_tags(a)
   namest=strupcase(tag_names(a))
   ; Determine location of Epoch variable
   if(keyword_set(DEBUG)) then print, 'Find DEPEND_0'
   incep=-1
   incep=where(namest eq depend0,w)
   ; Remove any nasty variables
   v1=spd_cdawlib_tagindex(depend0,namest)
   if(v1[0] ne -1) then begin
      station=a.(v1[0]).source_name 
      station=strmid(station,0,4)
      v1=spd_cdawlib_tagindex('delay_time',namest)
      ;if((station eq "ISIS") and (v1[0] ne -1)) then a.DELAY_TIME.var_type="metadata"
      if (((station eq "ISIS")or(station eq "ALOU")) and (v1[0] ne -1)) then a.DELAY_TIME.var_type="metadata"
   endif else begin
      print, 'ERROR= Tag name not found'
      return, -1
   endelse

   ; No record varying attribute found
   incep=incep[0]
   if(incep eq -1) then begin
      if reportflag then printf, 1, 'STATUS= Data cannot be listed. '
      print, 'STATUS= Data cannot be listed. '
      print, 'ERROR=Error: No record varying data selected' 
      close, 1
      return, -1 
   endif

   ; Create new structure w/ data (w/o handle) and determine size of Data array
   ; Epoch or depend_0 will be the first variable processed

   if(keyword_set(DEBUG)) then print, 'Converting handles; Compute size;',$
         ' Build new structure.'
   names=tag_names(a.(incep))
   ntags=n_tags(a.(incep))
   ; Check to see if HANDLE a tag name
   wh=where(names eq 'HANDLE',whn)
   if(whn) then begin
      handle_value, a.(incep).HANDLE, dat
      datsz=size(dat)
      if(datsz[0] gt 0) then dat=reform(dat) 
      ; Convert Epoch info. to string
      ;  'EPOCH' or 'EPOCH92' etc.
      if(namest[incep] eq depend0) then begin
         eptmp=ep_conv(a,depend0,/handle,sec_of_year=sec_of_year)
         temp=create_struct('DAT',dat)
         temp1=create_struct(a.(incep),temp)
         temp2=create_struct(temp1,eptmp)
         b=create_struct(namest[incep],temp2)
      endif else begin
         temp=create_struct('DAT',dat)
         temp1=create_struct(a.(incep),temp)
         b=create_struct(namest[incep],temp1)
      endelse
      ;
   endif else begin
      ; Convert Epoch info. to string
      ; 'EPOCH' or 'EPOCH92' etc.
      if(namest[incep] eq depend0) then begin
         eptmp=ep_conv(a,depend0,sec_of_year=sec_of_year) 
         tmp=create_struct(a.(incep),eptmp)
         b=create_struct(namest[incep],tmp)
      endif else begin 
         b=create_struct(namest[incep],a.(incep))
      endelse
   endelse
   vorder=intarr(ns_tags)
   for k=0, ns_tags-1 do begin
      if(k ne incep) then begin
         names=tag_names(a.(k))
         ntags=n_tags(a.(k))
         whc=where(names eq 'HANDLE',whn)
         if(whn) then begin
            handle_value, a.(k).HANDLE, dat
            datsz=size(dat)
            if(datsz[0] gt 0) then dat=reform(dat)
            temp=create_struct('DAT',dat)
            temp1=create_struct(a.(k),temp)
            temp2=create_struct(namest[k],temp1)
            b=create_struct(b,temp2)
         endif else begin
            temp=create_struct(namest[k],a.(k))
            b=create_struct(b,temp)
         endelse
      endif
      st_sz=size(b.(k).DAT)
      vorder[k]=st_sz[0]
   endfor   ; end k
   ; Free Memory
   delete, a
   delete, temp
   delete, temp1
   delete, temp2
   delete, tmp
   ;
   if(keyword_set(DEBUG)) then print, 'Determine type of listing.'
   ; Determine type of listing
   plist=max(vorder)
   ;TJK change to 1st variable since not all CDF's have a time variable called
   ;"EPOCH"    if(plist eq 3) then station=strmid(b.epoch.source_name,0,4)
   if(plist eq 3) then station=strmid(b.(0).source_name,0,4)
   ;
   if(plist eq 0) then begin
      norv=1 & no2drv=1 & nonrv=1 & no3drv=1 & noimg=1
   endif
   if(plist eq 1) then begin
      norv=0 & no2drv=1 & nonrv=1 & no3drv=1 & noimg=1 
   endif
   if(plist eq 2) then begin
      norv=1 & no2drv=0 & nonrv=1 & no3drv=1 & noimg=1 
   endif
   if(plist eq 3) then begin
      if(station ne "DARN") then begin
         norv=1 & no2drv=1 & nonrv=1 & no3drv=1 & noimg=0
      endif else begin
         norv=1 & no2drv=1 & nonrv=1 & no3drv=0 & noimg=1
      endelse
   endif
   if(plist eq 4) then begin ; e.g.: Array[72, 16, 5, 3514]
       norv=1 & no2drv=1 & nonrv=1 & no3drv=1 & no4drv=0 & noimg=1
   endif
   if(plist gt 4) then begin 
      if reportflag then printf, 1, 'STATUS= Data of 4D or less can be listed. Re-select variables'
      print, 'STATUS= Data of 3D or less can be listed. Re-select variables'
      close, 1 
      return, -1 
   endif

   ; Reorder structue
   b_tagnames=tag_names(b)
   v1=spd_cdawlib_tagindex(depend0,b_tagnames)
   if(v1[0] eq -1) then begin
      print, 'ERROR= No tag found for DEPEND0'
      return, -1
   endif
   epsz=size(b.(v1[0]).dat)
   if(epsz[0] eq 0) then b=ord_mystruct(b,vorder,0) else $
                       b=ord_mystruct(b,vorder,1)

   ; Reform Image 3D data arrays
   if(noimg eq 0 and keyword_set(DEBUG)) then print, 'Reform 3D Image arrays.'
   if(noimg eq 0) then  b=reform_mystruct(b)
   
   ; Reform Image 4D data arrays
   ; This will make the 4D data into 2D, ie, one long line for each time element.
   ; Visually, we are going to stretch the 3D data cube into one looooong line of numbers.
   if(no4drv eq 0 and keyword_set(DEBUG)) then print, 'Reform 4D Image arrays.'
   if(no4drv eq 0) then  b=reform_mystruct(b)
   
   ; Set/Convert tstart and tstop 
   if(keyword_set(DEBUG)) then print, 'Set/Convert tstart and tstop.'
   tmpoch=b.(v1[0]).dat
   leng=n_elements(tmpoch)
   if((n_elements(TSTART) eq 0) or (n_elements(TSTOP) eq 0)) then begin
      if(leng gt 1) then begin
         TSTART=tmpoch[0]
         TSTOP=tmpoch[leng-1]
      endif else begin
         tmp=tmpoch
         tmpoch=fltarr(1)
         tmpoch[0]=tmp
         TSTART=tmpoch[0]
         TSTOP=tmpoch[0]
      endelse
   endif

   ; Set time constraints
   start_time = 0.0D0 ; initialize
   stop_time = 0.0D0 ; initialize
   if keyword_set(TSTART) then begin ; determine datatype and process if needed
      b1 = size(TSTART) & c1 = n_elements(b1)
      case (b1[c1-2]) of
         5: start_time=tstart  ; double float
	 9: start_time=tstart  ; dcomplex
	 7: begin  ; string
	    ;; if (size(tstart,/tname) eq 'DCOMPLEX') then $
	    ;if keyword_set(start_msec) then $
	    ;  ;start_time=encode_cdfepoch(tstart,msec=start_msec,/epoch16) else $
	    ;  start_time=encode_cdfepoch(tstart,msec=start_msec) else $
            ;  start_time=encode_cdfepoch(tstart)
	    case (size(tmpoch[0],/type)) of
	       '14': begin
	                start_time=encode_cdfepoch(tstart,/tt2000,msec=start_msec)
		     end
	       else: begin
	          if keyword_set(start_msec) then $
		  start_time=encode_cdfepoch(tstart,msec=start_msec) else $
	          start_time=encode_cdfepoch(tstart)
	       end  
	    endcase
            end
	 else: begin
	   print,'ERROR=TSTART parameter must be STRING, DOUBLE or DCOMPLEX' & close, 1
           return,-1 
	   end
      endcase
      ; RCJ 11/2006  Replaced w/ code above, extending capability to complex values
      ;if (b1(c1-2) eq 5) then start_time = TSTART $ ; double float already
      ;   else if (b1(c1-2) eq 7) then start_time = encode_cdfepoch(TSTART) $ ; string
      ;else begin
      ;   print,'ERROR=TSTART parameter must be STRING or DOUBLE' & close, 1
      ;   return,-1
      ;endelse 
   endif

   if keyword_set(TSTOP) then begin ; determine datatype and process if needed
      b1 = size(TSTOP) & c1 = n_elements(b1)
      case (b1[c1-2]) of
         5: stop_time=tstop  ; double float
	 9: stop_time=tstop  ; dcomplex
	 7: begin   ;string
	    ;if (size(tstop,/tname) eq 'DCOMPLEX') then $
	    ;if keyword_set(stop_msec) then $
	    ;   ;stop_time=encode_cdfepoch(tstop,msec=stop_msec,/epoch16) else $
	    ;   stop_time=encode_cdfepoch(tstop,msec=stop_msec) else $
	    ;   stop_time=encode_cdfepoch(tstop) 
	    case (size(tmpoch[0],/type)) of
	       '14': begin
	                stop_time=encode_cdfepoch(tstop,/tt2000,msec=stop_msec)
		     end
	       else: begin
	          if keyword_set(stop_msec) then $
		  stop_time=encode_cdfepoch(tstop,msec=stop_msec) else $
	          stop_time=encode_cdfepoch(tstop)
	       end  
	    endcase
            end
	 else: begin
	   print,'ERROR=TSTOP parameter must be STRING, DOUBLE or DCOMPLEX' & close, 1
           return,-1 
	   end
      endcase
      ; RCJ 11/2006  Replaced w/ code above, extending capability to complex values
      ;if (b1(c1-2) eq 5) then stop_time = TSTOP $ ; double float already
      ;   else if (b1(c1-2) eq 7) then stop_time = encode_cdfepoch(TSTOP) $ ; string
      ;else begin
      ;   print,'ERROR=TSTOP parameter must be STRING or DOUBLE' & close, 1
      ;   return,-1
      ;endelse
   endif

   ; Restrict long listings giving user some information to gage their
   ; work

   time_dif=stop_time-start_time
   time_dif=time_dif/(86400.*1000.)
   tnum=n_elements(tmpoch)-1
   ; Try a more accurate method for determining time interval
   ;dif_ep=tmpoch(1)-tmpoch[0]
   if(tnum gt 100) then begin
      idcs=findgen(99) 
      idct=findgen(99)+1
      difs=tmpoch[idct]-tmpoch[idcs] 
      mnval=min(difs)
      mxval=max(difs)
      if(mnval ne mxval) then begin
         dif_ep=moment(difs)
      endif else begin
         ;dif_ep=fltarr(1)
	 ; Input to cdf_epoch has to be double:
         dif_ep=dblarr(1)
         dif_ep[0]=difs[0]
      endelse
      if (size(tmpoch[0],/type) eq 14) then $
        cdf_epoch,dif_ep[0]*1.D0,y1,mo1,d1,h1,m1,s1,mi1,/break,/tointeger else $
        cdf_epoch,dif_ep[0],y1,mo1,d1,h1,m1,s1,mi1,/break
        ;  cdf_epoch,dif_ep,y1,mo1,d1,h1,m1,s1,mi1,/break
      deltime=strtrim(h1,2)+':'+strtrim(m1,2)+':'+strtrim(s1,2)+'.'+strtrim(mi1,2)
   endif
;TJK 8/30/2004 - add code to determine the number of columns of data being requested - 
;and kick out on that, in addition to the number of records (below).

;TJK 9/21/2004 - find the depend_1 and depend_2 variables and then look at their sizes
; in order to determine the actual number of columns of data requested

   for vars = 0, n_tags(b)-1 do begin
      dep1=dependn_search(b,vars,1)
      if (dep1[0] ne '') then begin
	depend1 = b.(vars).depend_1
        ; RCJ 05/16/2013  If alt_cdaweb_depend_1 exists, use it instead:
        q=where(tag_names(b.(vars)) eq 'ALT_CDAWEB_DEPEND_1')
        if (q[0] ne -1) then if (b.(vars).alt_cdaweb_depend_1 ne '') then depend1=b.(vars).alt_cdaweb_depend_1 
	if (n_elements(dep1_values) eq 0) then dep1_values = depend1 else $
	dep1_values=[dep1_values,depend1]
      endif
      dep2=dependn_search(b,vars,2)
      if (dep2[0] ne '') then begin
	depend2 = b.(vars).depend_2
        ; RCJ 05/16/2013  If alt_cdaweb_depend_2 exists, use it instead:
        q=where(tag_names(b.(vars)) eq 'ALT_CDAWEB_DEPEND_2')
        if (q[0] ne -1) then if (b.(vars).alt_cdaweb_depend_2 ne '') then depend2=b.(vars).alt_cdaweb_depend_2 
	if (n_elements(dep2_values) eq 0) then dep2_values = depend2 else $
	dep2_values=[dep2_values,depend2]
      endif
      dep3=dependn_search(b,vars,3)
      if (dep3[0] ne '') then begin
	depend3 = b.(vars).depend_3
        q=where(tag_names(b.(vars)) eq 'ALT_CDAWEB_DEPEND_3')
        if (q[0] ne -1) then if (b.(vars).alt_cdaweb_depend_3 ne '') then depend3=b.(vars).alt_cdaweb_depend_3 
	if (n_elements(dep3_values) eq 0) then dep3_values = depend3 else $
	dep3_values=[dep3_values,depend3]
      endif
   endfor

;sort and uniq the arrays to get rid of duplicates
   if (n_elements(dep1_values) gt 0) then begin
     dep1_idx = uniq(dep1_values,sort(dep1_values))
     dep1_values = dep1_values[dep1_idx]
   endif
   if (n_elements(dep2_values) gt 0) then begin
     dep2_idx = uniq(dep2_values,sort(dep2_values))  
     dep2_values = dep2_values[dep2_idx]
;     print, 'DEBUG - dep1_values = ',dep1_values, 'dep2_values = ',dep2_values
   endif
   if (n_elements(dep3_values) gt 0) then begin
     dep3_idx = uniq(dep3_values,sort(dep3_values))
     dep3_values = dep3_values[dep3_idx]
   endif
   cols = 0 & d1cols = 0 & d2cols = 0 & d3cols = 0
   b_tagnames=tag_names(b)
   ;Find the number of records
   idx = spd_cdawlib_tagindex(depend0,b_tagnames)
   var_size = size(b.(idx).dat)
   n_recs = var_size[1]

   for vars = 0, n_elements(dep1_values)-1 do begin
	var_idx = spd_cdawlib_tagindex(dep1_values[vars],b_tagnames)
        if (var_idx ge 0) then begin 
	  var_size = size(b.(var_idx).dat)
	  if (strupcase(b.(var_idx).var_type) eq 'SUPPORT_DATA') then begin
;	    print, 'support varname and size = ',b.(var_idx).varname, var_size
	    if (var_size[0] eq 1) then d1cols = d1cols + var_size[1] ; support data like rows and 
							       ; columns for an image variable
            if (var_size[0] eq 2) then d1cols = d1cols+ var_size[1] ;spectrogram type vars.
	  endif 
	endif
;	  print, 'DEBUG DEP1 Cols = ',d1cols
   endfor

   for vars = 0, n_elements(dep2_values)-1 do begin
	var_idx = spd_cdawlib_tagindex(dep2_values[vars],b_tagnames)
        if (var_idx ge 0) then begin 
	  var_size = size(b.(var_idx).dat)
	  if (strupcase(b.(var_idx).var_type) eq 'SUPPORT_DATA') then begin
;	    print, 'support varname and size = ',b.(var_idx).varname, var_size
	    if (var_size[0] eq 1) then d2cols = d2cols + var_size[1] ; support data like rows and 
							       ; columns for an image variable
            if (var_size[0] eq 2) then d2cols = d2cols+ var_size[1] ;spectrogram type vars.

	  endif
	endif
;	  print, 'DEBUG DEP2 Cols = ',d2cols
   endfor
   for vars = 0, n_elements(dep3_values)-1 do begin
	var_idx = spd_cdawlib_tagindex(dep3_values[vars],b_tagnames)
        if (var_idx ge 0) then begin 
	  var_size = size(b.(var_idx).dat)
	  if (strupcase(b.(var_idx).var_type) eq 'SUPPORT_DATA') then begin
	    if (var_size[0] eq 1) then d3cols = d3cols + var_size[1] ; support data like rows and 
							       ; columns for an image variable
            if (var_size[0] eq 2) then d3cols = d3cols+ var_size[1] ;spectrogram type vars.

	  endif
	endif
	  ;print, 'DEBUG DEP3 Cols = ',d3cols
   endfor
   cols = d1cols + d2cols + d3cols

   if (cols eq 0) then begin ;have to look at the data variables to decide # cols
;     print, 'TJK DEBUG - No depend1 or depend2 values, so looking at the data vars to determine cols'
     for vars = 0, n_elements(b_tagnames)-1 do begin
       if (strupcase(b.(vars).var_type) eq 'DATA') then begin
	 var_size = size(b.(vars).dat)
;	 print, 'data varname and size = ',b.(vars).varname, var_size
         if (var_size[0] eq 1) then cols = cols+ 1 ;regular DATA variable - scalar
         if (var_size[0] eq 2 and var_size[1] lt 10) then cols = cols+ var_size[1] ;vectors
       endif
;       print, 'DEBUG DATA Cols = ',cols
     endfor
   endif

   
;print, 'DEBUG - Number of columns requested = ',cols, 'number of records = ',n_recs

;TJK 9/2/2004 - change the logic to check for a large number of columns AND a large number of records
;print a different message, depending on whichever is too large for listing to handle
      stars = '#******************'
      if((n_recs gt 15000000 and cols gt 6) or n_recs gt 16000000) then begin ;larger than this takes 30+ min. to generate.
	status = '# WARNING: You have requested '+strtrim(string(n_recs),2)+' records of data, the limit is 15,000,000, please reduce the time range and resubmit.'
	 printf, unit, stars 
         printf, unit, format='(a)',status
	 printf, unit, stars
      ; Continue to get listing of Global Attributes
         nogatt=0 & norv=1  & nonrv=1 & no2drv=1 & no3drv=1 & no4drv=1 & noimg=1
;         print, 'STATUS= ',status
;         return, 0
      endif

;  RCJ  01/14/2013  Removed these conditions to see if/how we can stretch them.
;      if((cols gt 100 and n_recs gt 10000) or $
;	(d1cols gt 40 and d2cols gt 40))then begin
;	  status = '# WARNING: Cannot list this type of data, at least one of the variables that you have selected requires too many columns.'
; 	 printf, unit, stars
;         printf, unit, format='(a)',status
;	 printf, unit, stars
;        ; Continue to get listing of Global Attributes
;         nogatt=0 & norv=1  & nonrv=1 & no2drv=1 & no3drv=1 & noimg=1
;         print, 'STATUS= ',status
;         return, 0
;      endif

   ; Determine indices of epoch.dat that are within the tstart and tstop
   ;tind=where((b.epoch.dat ge start_time) and (b.epoch.dat le stop_time),w)
   ; RCJ 11/2006  Cannot do 'where' when complex numbers are introduced.
   ;    Have to use cdf_epoch_compare.
   ;tind=where((tmpoch ge start_time) and (tmpoch le stop_time),w)
   if (size(tmpoch,/tname) eq 'DCOMPLEX')then begin
      tind = lonarr(n_elements(tmpoch))
      for i = 0L, n_elements(tmpoch)-1 do begin
         tind[i] = ((cdf_epoch_compare(stop_time, tmpoch[i]) ge 0) and $
                   (cdf_epoch_compare(tmpoch[i], start_time) ge 0))
                    ;cdf_epoch_compare returns 0 for equal
                    ;value and 1 for greater than
      endfor
      tind = where(tind eq 1,w)
   endif else begin
      ;original code for regular tmpoch value
      tind=where((tmpoch ge start_time) and (tmpoch le stop_time),w)
   endelse   
   if(tind[0] eq -1) then begin
      ; Continue to get listing of Global Attributes
      warning='#  WARNING: No Data Selected for this Time Period. '
      printf, unit, format='(a)',warning
      ;  printf, unit, '  WARNING: No Data Selected for this Time Period. '
      nogatt=0 & norv=1  & nonrv=1 & no2drv=1 & no3drv=1 & no4drv=1 & noimg=1
      c=b
      ; print, 'ERROR= No Data Selected for this Time Period. '
      ; status=-1
      ; return, status
   endif
   ;
   ; temporary fix for 1 time choosen for a N dim arrays
   if(w eq 1) then begin
      warning='#  WARNING: Increase time period selected for listing. '
      printf, unit, '# ******************************************************* '    
      printf, unit, format='(a)',warning
      printf, unit, '# ******************************************************* '    
      printf, unit, '# '    
      w=0
      nogatt=0 & norv=1  & nonrv=1 & no2drv=1 & no3drv=1 & no4drv=1 &noimg=1
      c=b
   endif
   itrip=0
   irv=0
   inrv=0
   lab_for='('
   unt_for='('
   dat_for='('
   dep_for='('
   ns_tags=n_tags(b)
   namest=tag_names(b)
   ;
   ; Apply time constraints to data structure
   if keyword_set(DEBUG) then print,'Apply time constraints to data structure.'
   if(w gt 0) then begin
      for i=0, ns_tags-1 do begin
         ntags=n_tags(b.(i))
         names=tag_names(b.(i))
         st_sz=size(b.(i).dat)
         ; if(namest(i) eq "EPOCH" or namest(i) eq "EPOCH92") then begin
         if(namest[i] eq depend0) then begin
            temp_dat=b.(i).dateph[tind]
            temp_dat1=b.(i).dat[tind]
            tmp=create_struct('DATEPH',temp_dat)
            tmp1=create_struct('DAT',temp_dat1)
            for l=0, ntags-1 do begin
               if((names[l] eq "DAT") or (names[l] eq "DATEPH")) then begin
                  if(names[l] eq "DAT") then tmpt=create_struct(tmpt,tmp1)
                  if(names[l] eq "DATEPH") then tmpt=create_struct(tmpt,tmp)
               endif else begin        
                  if(l eq 0) then tmpt=create_struct(names[l],b.(i).(l)) else begin $
                      tmpt1=create_struct(names[l],b.(i).(l))
                      tmpt=create_struct(tmpt,tmpt1)
                  endelse
               endelse
            endfor
            ctmp=create_struct(namest[i],tmpt)
            if(i eq 0) then c=ctmp else c=create_struct(c,ctmp)
         endif else begin
            if(b.(i).var_type eq 'data') then begin
               if(st_sz[0] eq 1) then temp_dat1=b.(i).dat[tind]
               if(st_sz[0] eq 2) then temp_dat1=b.(i).dat[*,tind]
               if(st_sz[0] eq 3) then temp_dat1=b.(i).dat[*,*,tind]
               if(st_sz[0] eq 4) then temp_dat1=b.(i).dat[*,*,*,tind]
            endif else begin
               temp_dat1=b.(i).dat
            endelse
            tmp1=create_struct('DAT',temp_dat1)
            for l=0, ntags-1 do begin
               if(names[l] ne "DAT") then begin
                  if(l eq 0) then tmpt=create_struct(names[l],b.(i).(l)) else begin $
                     tmpt1=create_struct(names[l],b.(i).(l))
                     tmpt=create_struct(tmpt,tmpt1)
                  endelse 
               endif else begin
                  tmpt=create_struct(tmpt,tmp1)
               endelse
            endfor   ; end l
            ctmp=create_struct(namest[i],tmpt)
            if(i eq 0) then c=ctmp else c=create_struct(c,ctmp)
         endelse   ; end if (namest[i] ne depend0)
      endfor   ; end i
   endif   ; end if (w gt 0)
   ; Free Memory
   delete, ctmp
   delete, tmp1
   delete, tmpt
   delete, tmpt1
   delete, tmp
   delete, b
   ;
   nvar=0
   for i=0,ns_tags-1 do begin
      j=0
      ntags=n_tags(c.(i))    
      names=tag_names(c.(i))
      shft=1
      ; 'EPOCH' or 'EPOCH92' etc.
      if(namest[i] eq depend0) then shft=0
      ;if(c.(i).var_notes eq 'ListImage') then shft=0
       ; Build Global Structure
      if keyword_set(DEBUG) then print,'Build Global Structure.'
      while (itrip eq 0) and (j lt ntags) do begin
         j=j+1
         nc=j
         if(names[j] eq 'FIELDNAM') then begin
            itrip=1
         endif else begin
            pair=create_struct(names[j],c.(i).(j))
            if(j eq 1) then begin
               glbatt=create_struct(pair)
            endif else begin
               glbatt=create_struct(glbatt,pair)
            endelse
         endelse
      endwhile
      ; End Global Structure 
      ; Determine Format type and data width 
      if keyword_set(DEBUG) then print,'Determine Format type and data width.'
      form='' ; Default field 
      ; 'EPOCH' or 'EPOCH92' etc.

      if(namest[i] eq depend0) then begin
         if keyword_set(sec_of_year) then begin
	    ; RCJ 03/11/2014  When sec_of_year is set we need to redefine the fillval 
	    ;  which is, up to this point, based on a yyyy-mm-dd hh:mm:ss.msec format.
	    format='A20' 
	    c.(i).fillval='9999        0.000000'
	 endif else format='A23' 
      endif else format=c.(i).format
      ;TJK 10/1/2009 - need to allow for the more epoch fields w/ epoch16
      if (c.(i).cdftype eq 'CDF_EPOCH16') then begin
         if keyword_set(sec_of_year) then begin
	    format='A20' 
	    c.(i).fillval='9999        0.000000'
	 endif else format='A35' 
      endif
      if (c.(i).cdftype eq 'CDF_TIME_TT2000') then begin
         if keyword_set(sec_of_year) then begin
	    format='A20'
	    c.(i).fillval='9999        0.000000' 
	 endif else format='A27' 
      endif

      if(c.(i).var_type eq 'data') or $
         ; the line below will allow support_data that is not a depend_1 or 2 variable to be listed.
	 ; I'm assuming depend_1 or 2 variables do not have depend_0=Epoch
	 ; RCJ 10/28/2002
         ;((c.(i).var_type eq 'support_data') and (strupcase(c.(i).depend_0) eq depend0)) or $
         ;      (strupcase(c.(i).VARNAME) eq depend0) then begin 
	 ; RCJ 11/12/2003  Sometimes depend_1 or 2 do have depend_0=Epoch (see
	 ; i8_h0_gme var Proton_DIntn2.   This seems to be a better test:
         ((c.(i).var_type eq 'support_data') and $
	 (c.(i).cdfrecvary ne 'NOVARY')) then begin 

         ; RCJ 08/15/2013  Remove '%' if present in 'format'.
	 ;    We might run into different, more complex cases in the future. Will deal with
	 ;    them as they come up. This case is from bar118_1a_2_l2_ephm dataset.
	 format=strsplit(format,'%',/extract)
         frm_st=data_len(format[0],c.(i).fillval)
         status=frm_st.status
         if( status ne 0) then begin
            if reportflag then printf, 1, 'STATUS= Data cannot be listed. '
            print, 'STATUS= Data cannot be listed. '
            print, 'ERROR=Error: In function data_len'
            close, 1
            return, -1 
         endif
         dat_len=frm_st.dat_len
         form=frm_st.form 
         ; patch
         c.(i).fillval=frm_st.nvar
      endif
      ; For now replace fillval w/ nvar (number of elements of a variable)
      ; else rebuild the structure w/ nvar attributes appended to each variable
      ; RTB  3/96 
      ; Set record varying formats
      if(form ne '') then begin
      ;print,'^^^ ',nogatt,norv,nonrv,no2drv,no3drv,no4drv,noimg
         if(norv eq 0) then begin
            ; if(c.(i).lablaxis eq '') then label=c.(i).fieldnam else $
            ;   label=c.(i).lablaxis
            label=label_search(c,1,i,0)
            units=unit_search(c,1,i,0)
            ;col_sz=strlen(label) > strlen(c.(i).units) > dat_len
            col_sz=strlen(label) > strlen(units) > dat_len
            ; the second set of "col_sz, label" input will be used to define the format
            ; dep_for. This input changes when we have variables w/ depend_1 attribute.
            ; RCJ 04/01  
            ;sform=form_bld(col_sz, label, c.(i).units, dat_len, col_sz, label, col_sz, label,form, shft)
            sform=form_bld(col_sz, label, units, dat_len, col_sz, label, col_sz, label,col_sz, label,form, shft)
            lab_for=lab_for + sform.labv
            unt_for=unt_for + sform.untv
            dat_for=dat_for + sform.datv
            dep_for=dep_for + sform.depv
         endif

         ; Determine formats for 2D-RV
         if(no2drv eq 0) then begin
            if keyword_set(DEBUG) then print,'Determine formats for 2D-RV.'

            if(c.(i).var_type eq 'data') or $
                 ;(c.(i).var_type eq 'support_data') then begin
		 ; RCJ 11/12/2003 Same kind of test as above. Look for 11/12/2003.
                 ((c.(i).var_type eq 'support_data') and $
		  (c.(i).cdfrecvary ne 'NOVARY')) then begin
               st_sz=size(c.(i).dat)
               ; Compute depend_0 or Epoch
               if(st_sz[0] le 1) then begin
                  label=label_search(c,1,i,0)
		  units=unit_search(c,1,i,0)
                  num_var=1
                  if(w eq 1 and st_sz[1] gt 1 and st_sz[0] eq 1) then num_var=st_sz[1] 
                  for k=0, num_var-1 do begin
                     ;col_sz=strlen(label) > strlen(c.(i).units) > dat_len
                     col_sz=strlen(label) > strlen(units) > dat_len
                     ; the second set of "col_sz, label" input will be used to define the format
                     ; dep_for. This input changes when we have variables w/ depend_1 attribute.
                     ; RCJ 04/01  
                     ;sform=form_bld(col_sz, label, c.(i).units, dat_len, col_sz,label,col_sz,label,form, shft)
                     sform=form_bld(col_sz, label, units, dat_len, col_sz,label,col_sz,label,col_sz,label,form, shft)
                     lab_for=lab_for + sform.labv
                     unt_for=unt_for + sform.untv
                     dat_for=dat_for + sform.datv
                     dep_for=dep_for + sform.depv
                     nvar=nvar+1
                  endfor
               endif
               ; Compute all other 2D variables
               if(st_sz[0] eq 2) then begin
             
                  num_var=st_sz[1]
                        depend1_labels=dependn_search(c,i,1) ; st_sz(0)=2
                        if (depend1_labels[0] ne '') then begin
                              depend1=c.(i).depend_1
                              ; RCJ 05/16/2013  If alt_cdaweb_depend_1 exists, use it instead:
                              q=where(tag_names(c.(i)) eq 'ALT_CDAWEB_DEPEND_1')
                              if (q[0] ne -1) then if (c.(i).alt_cdaweb_depend_1 ne '') then depend1=c.(i).alt_cdaweb_depend_1
                              dep1_units=c.(strtrim(depend1,2)).units
                              depend1_labels=['(@_'+depend1_labels+'_'+dep1_units+')']
                              ;dep1_values=[dep1_values,dep1]
                        endif
                        depend2_labels=dependn_search(c,i,2) ; st_sz(0)=2
                        if (depend2_labels[0] ne '') then begin
                              depend2=c.(i).depend_2
                              ; RCJ 05/16/2013  If alt_cdaweb_depend_2 exists, use it instead:
                              q=where(tag_names(c.(i)) eq 'ALT_CDAWEB_DEPEND_2')
                              if (q[0] ne -1) then if (c.(i).alt_cdaweb_depend_2 ne '') then depend2=c.(i).alt_cdaweb_depend_2 
                              dep2_units=c.(strtrim(depend2,2)).units
                              depend2_labels=['(@_'+depend2_labels+'_'+dep2_units+')']
                        endif
                        ;dep_col_sz=max(strlen(depend1_labels)) > max(strlen(depend2_labels)) >strlen(c.(i).units) > dat_len
                        ; JWJ 07/31/2000 
                        ; changed below from label_search to label_search_max_width
                        ;label=label_search_max_width(c,st_sz[0],i,k)
			; RCJ 01/29/2003. Label_search_max_width no longer being used.
			;label=''
			;units=''
			for kk=0L,st_sz[1]-1 do begin
                           label0=label_search(c,st_sz[0],i,kk)
                           if strlen(label0) gt strlen(label) then label=label0
                           units0=unit_search(c,st_sz[0],i,kk)
                           if strlen(units0) gt strlen(units) then units=units0
			endfor 
			; label: this is only the longest of the labels, not a specific label.  
                        dep_col_sz=max(strlen(depend1_labels)) > max(strlen(depend2_labels)) >strlen(units) > dat_len
                        ;col_sz = strlen(label) > strlen(c.(i).units) > dat_len
                        col_sz = strlen(label) > strlen(units) > dat_len
                        ;sform=form_bld(col_sz, label, c.(i).units, dat_len, dep_col_sz, depend1_labels,dep_col_sz, depend2_labels,form, shft)
                        sform=form_bld(col_sz, label, units, dat_len, dep_col_sz, depend1_labels,dep_col_sz, depend2_labels,dep_col_sz, depend2_labels,form, shft)
                        ; Modify format 
                        labv=strtrim(num_var,2)+'('+sform.labv+' ' 
                        untv=strtrim(num_var,2)+'('+sform.untv+' '
                        datv=strtrim(num_var,2)+'('+sform.datv+' '
                        depv=strtrim(num_var,2)+'('+sform.depv+' ' 
                        lend=strlen(labv)-2
                        uend=strlen(untv)-2
                        dend=strlen(datv)-2
                        dpend=max(strlen(depv))-2
                        strput,labv,'),',lend
                        strput,untv,'),',uend
                        strput,datv,'),',dend
                        strput,depv,'),',dpend
                        lab_for=lab_for + labv
                        unt_for=unt_for + untv
                        dat_for=dat_for + datv
                        dep_for=dep_for + depv
                        nvar=nvar+num_var
                     ;endif
                  ;endelse
               endif   ; end  if (z[0] ne -1)
               c.(0).fillval=nvar
            endif   ; end if (c.(i).var_type eq 'data')
         endif ; format condition
      endif   ; end if (form ne '')
      ;
      ; Determine formats for 3D-RV images
      if ((noimg eq 0) or (no4drv eq 0)) then begin
         if keyword_set(DEBUG) then print,'Determine formats for 3D-RV or 4D-RV images.'
         if(i gt 0) then $
             if(c.(i).var_type eq 'support_data') then c.(i).var_type="metadata"
         ;if(c.(i).var_type eq 'data') or (c.(i).var_type eq 'support_data') then begin
         if (c.(i).var_type eq 'data') or ((c.(i).var_type eq 'support_data') and (c.(i).cdfrecvary ne 'NOVARY')) then begin
            st_sz=size(c.(i).dat)
	    ; RCJ 06/04/2004  If image causes list to have too many columns
	    ; IDL will not print. Get out.
	    ;if st_sz[1] gt 32767. then begin
	    ;   print, 'STATUS=Array has too many columns and cannot be listed.'
	    ;   ;print,'ERROR=Array has too many columns. Will not list.'
	    ;   return,-1
	    ;endif
            ; Compute depend_0 or Epoch 
            if(st_sz[0] le 1) then begin
               nvar=nvar+1
               label=label_search(c,st_sz[0],i,0)
               units=unit_search(c,st_sz[0],i,0)
               ;col_sz=strlen(label) > strlen(c.(i).units) > dat_len
               col_sz=strlen(label) > strlen(units) > dat_len
               ; the second set of "col_sz, label" input will be used to define the format
               ; dep_for. This input changes when we have variables w/ depend_1 attribute.
               ; RCJ 04/01  
               ;sform=form_bld(col_sz, label, c.(i).units, dat_len, col_sz, label, col_sz, label,form, shft)
               sform=form_bld(col_sz, label, units, dat_len, col_sz, label, col_sz, label,col_sz, label,form, shft)
               lab_for=lab_for + sform.labv
               unt_for=unt_for + sform.untv
               dat_for=dat_for + sform.datv
               dep_for=dep_for + sform.depv
            endif
            ; Compute all other 2D variables
            if(st_sz[0] eq 2) then begin
               ; Set labels
               ;num_var=st_sz(1)
               ;if(c.(i).var_notes eq 'ListImage') then num_var=1
               ;for k=0, num_var-1 do begin
               ;if(c.(i).var_type eq 'data') or $
                ;  (c.(i).var_type eq 'support_data') then begin
                  ; Determine labels
                  depend1_labels=dependn_search(c,i,1) ; st_sz(0)=2
                  if (depend1_labels[0] ne '') then begin
                     depend1=c.(i).depend_1
                     ; RCJ 05/16/2013  If alt_cdaweb_depend_1 exists, use it instead:
                     q=where(tag_names(c.(i)) eq 'ALT_CDAWEB_DEPEND_1')
                     if (q[0] ne -1) then if (c.(i).alt_cdaweb_depend_1 ne '') then depend1=c.(i).alt_cdaweb_depend_1
                     dep1_units=c.(strtrim(depend1,2)).units
                     depend1_labels=['(@_'+depend1_labels+'_'+dep1_units+')']
                  endif   
                  depend2_labels=dependn_search(c,i,2) ; st_sz[0]=2
                  if (depend2_labels[0] ne '') then begin
                     depend2=c.(i).depend_2
                     ; RCJ 05/16/2013  If alt_cdaweb_depend_2 exists, use it instead:
                     q=where(tag_names(c.(i)) eq 'ALT_CDAWEB_DEPEND_2')
                     if (q[0] ne -1) then if (c.(i).alt_cdaweb_depend_2 ne '') then depend2=c.(i).alt_cdaweb_depend_2 
                     dep2_units=c.(strtrim(depend2,2)).units
                     depend2_labels=['(@_'+depend2_labels+'_'+dep2_units+')']
                  endif   
		  ;if this is 2D image there will be no depend3. 
                     depend3_labels=dependn_search(c,i,3) ; st_sz[0]=3
                     if (depend3_labels[0] ne '') then begin
                       depend3=c.(i).depend_3
                       q=where(tag_names(c.(i)) eq 'ALT_CDAWEB_DEPEND_3')
                       if (q[0] ne -1) then if (c.(i).alt_cdaweb_depend_3 ne '') then depend3=c.(i).alt_cdaweb_depend_3 
                       dep3_units=c.(strtrim(depend3,2)).units
                       depend3_labels=['(@_'+depend3_labels+'_'+dep3_units+')']
                     endif 
                  label=''
		  units=''
                  for kk=0L,st_sz[1]-1 do begin
                     label0=label_search(c,st_sz[0],i,kk)
                     if strlen(label0) gt strlen(label) then label=label0
                     units0=unit_search(c,st_sz[0],i,kk)
                     if strlen(units0) gt strlen(units) then units=units0
                  endfor 
		  dep_col_sz=max(strlen(depend1_labels)) > max(strlen(depend2_labels))  > max(strlen(depend3_labels)) >strlen(units) > dat_len
                  col_sz = strlen(label) > strlen(units) > dat_len
                  sform=form_bld(col_sz, label, units, dat_len,dep_col_sz,depend1_labels,dep_col_sz,depend2_labels,dep_col_sz,depend3_labels,form, shft)
                  ;
               	  sform.labv=strmid(sform.labv,0,strlen(sform.labv)-1) ; remove comma
                  lab_for=lab_for + strtrim((st_sz[1]),2)+'('+sform.labv+'),'
                  ;
                  sform.untv=strmid(sform.untv,0,strlen(sform.untv)-1) ; remove comma
                  unt_for=unt_for + strtrim((st_sz[1]),2)+'('+sform.untv+'),'
                  ;
                  sform.depv=strmid(sform.depv,0,strlen(sform.depv)-1) ; remove comma
                  dep_for=dep_for + strtrim((st_sz[1]),2)+'('+sform.depv+'),'
                  ;
                  sform.datv=strmid(sform.datv,0,strlen(sform.datv)-1) ; remove comma
                  dat_for=dat_for + strtrim((st_sz[1]),2)+'('+sform.datv+'),'
                  nvar=nvar+1
            endif 
            c.(0).fillval=st_sz[1]
         endif   ; end if (c.(i).var_type eq 'data' or ...)
      endif   ; end if (noimg eq 0) 
   endfor   ; end i
   ; 
   ; Add ending parenthesis of formats
   lend=strlen(lab_for)-1
   uend=strlen(unt_for)-1
   dend=strlen(dat_for)-1
   dpend=max(strlen(dep_for))-1
   strput,lab_for,')',lend
   strput,unt_for,')',uend
   strput,dat_for,')',dend
   strput,dep_for,')',dpend
   ; 
   if(no3drv eq 0) then begin
      lab_for='(a23,1x,A5,1x,a9,2(1x,a13),2(1x,a13))'
      unt_for='(a23,1x,a5,1x,a9,2(7x,a7),2(11x,a3))'
      dat_for='(a23,4x,i2,7x,i3,2(1x,g13.5),2(1x,g13.5),/,29(27x,i2,7x,i3,2(1x,g13.5),2(1x,g13.5),/))'
   endif
   ;print,'dep_for = ', dep_for
   ;print,'lab_for = ', lab_for
   ;print,'unt_for = ', unt_for
   ;print,'dat_for = ', dat_for
   
   if(norv eq 0) or (no2drv eq 0) or (no3drv eq 0) or (no4drv eq 0) or (noimg eq 0) then $ 
          rvars=create_struct(c,'LFORM',lab_for,'UFORM',unt_for,'DFORM',dat_for,'DPFORM',dep_for)
   ; 
   ; Write out structure listing
   ; Turn off glbatt for mulitple depend_0's
   if(mega_loop gt 1) then begin
      nogatt=1
      printf, unit, format='("#  ")'   
   endif
   ; Free Memory
   delete, c
   if keyword_set(DEBUG) then print,'Write out variables.'
   if(nogatt eq 0) then  status=wrt_hybd_strct(glbatt,unit,0,maxrecs,depend0,mega.num)
   if(norv   eq 0) then  status=wrt_hybd_strct(rvars,unit,1,maxrecs,depend0,mega.num)  
   if(nonrv  eq 0) then  status=wrt_hybd_strct(nrvars,unit,2,maxrecs,depend0,mega.num)
   if(no2drv eq 0) then  status=wrt_hybd_strct(rvars,unit,3,maxrecs,depend0,mega.num)
   if(no3drv eq 0) then  status=wrt_hybd_strct(rvars,unit,4,maxrecs,depend0,mega.num)
   if(noimg  eq 0) then  status=wrt_hybd_strct(rvars,unit,5,maxrecs,depend0,mega.num)
   ; RCJ 07/19/2013  After no4drv data has been reformed, the call below is just like the 
   ;     call above, for 'noimg'.
   if(no4drv eq 0) then  status=wrt_hybd_strct(rvars,unit,5,maxrecs,depend0,mega.num)
   ; Free Memory
   delete, rvars
endfor ; end mega_loop

time_string=systime()
printf, unit, format='("#  ")'                                                  
printf, unit, format='("# Key Parameter and Survey data (labels K0,K1,K2) are preliminary browse data.")'
printf, unit, format='("# Generated by CDAWeb on: ",a)',time_string

close,unit
close,1
free_lun, unit

end
pro spd_cdawlib_list_mystruct
; do nothing
end

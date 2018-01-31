;Author: ryurow $
;Date: 2017/03/24 19:30:01 $
;Header: /home/cdaweb/dev/control/RCS/read_myCDF.pro,v 1.338 2017/03/24 19:30:01 ryurow Exp kovalick $
;Locker: kovalick $
;Revision: 1.338 $
;+------------------------------------------------------------------------
; This package of IDL functions facilitates reading data and metadata from
; Common Data Format (CDF) files.  While CDF provides all the benefits
; of a portable, self-documenting scientific data format, reading them is
; not always a simple matter.  To make it simple, I have created this IDL
; package so that all of the data and metadata from multiple variables can 
; be read from multiple CDF files ... in one single, simple command.  The 
; function is called 'spd_cdawlib_read_mycdf' and it returns an anonymous structure of
; the form:
;
;       structure_name.variable_name.attribute_name.attribute_value
;
; From this structure, all data and metadata for the requested variables
; is easily accessed.
;
; AUTHOR:
;       Richard Burley, NASA/GSFC/Code 632.0, Feb 13, 1996
;       burley@nssdca.gsfc.nasa.gov    (301)286-2864
; 
; NOTES:
;
; Three additional 'attributes' will be included in the sub-structure for 
; each variable.  The first is the 'VARNAME' field.  Because IDL structure
; tags are always uppercase, and because CDF variable names are case sen-
; sitive, a case sensitive copy of the variable name is created.  The second
; 'attribute' to be added is the 'CDFTYPE' field.  This field will hold a
; string value holding the cdf data type.  The last 'attribute' to be
; artificially added will be either the 'DAT' field or, if the keyword
; NODATASTRUCT is set, the 'HANDLE' field.  The 'DAT' field will contain
; the actual data values read from the CDF's for the variable.  The 'HANDLE'
; field will hold a handle_id where the data will reside.
;
; This package will look for and utilize certain special attributes required
; by the International Solar Terrestrial Physics Key Parameters Generation
; Software Standards and Guidelines.  The existance of these attributes is
; not required for the operation of this software, but will enhance its
; usefullness, primarily by reading variables that will be needed for proper
; utilization of the data, even though you may not have asked for them 
; explicitly.
;
; This package was tested under IDL version 4.0.1b.  This package was tested
; on CDF's up to version 2.5 and on both r-variables and z-variables.
;
; CDF variables defined as unsigned integers are, unfortunately, currently
; returned by the IDL CDF_VARGET procedure as signed integers.  This can
; cause sign flips.  This software detects and corrects for this defect for
; data values.  However, it cannot detect and correct for this defect for
; attribute values because the IDL procedure CDF_ATTINQ does not return the
; CDF data type of the attribute.  These problems have been reported to
; RSI.
;
;
; Modifications: 
;	As of October 2, 2000, this software can run on all of the following
;	IDL versions, 5.1, 5.2 and 5.3 (testing for 5.4 will commence soon).
;	Some fairly major changes were necessary in order for spd_cdawlib_read_mycdf
;	to work under 5.3.  IDL 5.3 enforces the variable naming rules for
;	structure tag names.  This change affects this s/w because we basically
;	had never checked our tag names, e.g. we used the CDF variable names
;	and label attribute values directly.  So in spd_cdawlib_read_mycdf the general
;	concept to fixing this problem was to set up a table (which is shared
;	in a common block - not my favorite way to go, but definitely the 
;	easiest), where there are two tags, equiv and varname.  varname 
;	contains the real CDF variable name, equiv contains the "cleaned up,
;	IDL acceptable" variable name that can be used as a structure tag
;	name... TJK 04/02/2000
;
; 1996, NASA/Goddard Space Flight Center
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.
;-------------------------------------------------------------------------
; NAME: spd_cdawlib_set_cdf_msg
; PURPOSE: 
;       Store message that can be read from anywhere in the module.
;       (equivalent to a global variable) 
; CALLING SEQUENCE:
;       spd_cdawlib_set_cdf_msg, msg
; INPUTS:
;       msg = input text string
; KEYWORD PARAMETERS:
;       None.
; OUTPUTS:
;       None.
; AUTHOR:
;       Ron Yurow  March 24, 2017
; MODIFICATION HISTORY:
;-------------------------------------------------------------------------
PRO spd_cdawlib_set_cdf_msg, msg
    COMMON spd_cdawlib_CDF_ERR_MSG, errmsg
    errmsg = msg
END
;-------------------------------------------------------------------------
; NAME: spd_cdawlib_get_cdf_msg
; PURPOSE: 
;       Retrieve a previously stored text message from anywhere in the module.
;       (equivalent to a global variable) 
; CALLING SEQUENCE:
;       msg = spd_cdawlib_get_cdf_msg ()
; INPUTS:
;       None.
; KEYWORD PARAMETERS:
;       None.
; OUTPUTS:
;       msg = a previously stored text string
; AUTHOR:
;       Ron Yurow  March 24, 2017
; MODIFICATION HISTORY:
;-------------------------------------------------------------------------
FUNCTION spd_cdawlib_get_cdf_msg
    COMMON spd_cdawlib_CDF_ERR_MSG, errmsg
    RETURN, errmsg
END

;+------------------------------------------------------------------------
; NAME: spd_cdawlib_amI_istpptr
; PURPOSE:
;       Return true(1) or false(0) depending on whether or not the
;       given attribute name qualifies as an ISTP pointer-class attribute.
; CALLING SEQUENCE:
;	out = spd_cdawlib_amI_istpptr(attribute_name)
; INPUTS:
;	attribute_name = name of a CDF attribute as a string
; KEYWORD PARAMETERS:
; OUTPUTS:
;       True(1) or False(0)
; AUTHOR:
;       Richard Burley, NASA/GSFC/Code 632.0, Feb 13, 1996
;       burley@nssdca.gsfc.nasa.gov    (301)286-2864
; MODIFICATION HISTORY:
;-------------------------------------------------------------------------
FUNCTION spd_cdawlib_amI_istpptr, aname
if (aname eq 'UNIT_PTR')        then return,1
if (aname eq 'FORM_PTR')        then return,1
;if (aname eq 'DELTA_PLUS_VAR')  then return,1
;if (aname eq 'DELTA_MINUS_VAR') then return,1
len = strlen(aname) & pos = strpos(aname,'LABL_PTR_')
if ((len gt 9) AND (pos eq 0)) then begin ; label pointer found
  ON_IOERROR,escape ; return false if non-digit found
  for j=0,(len-10) do begin ; check one character at a time
    r = strmid(aname,(9+j),1) & READS,r,v,FORMAT='(I1)'
  endfor
  return,1 ; remaining characters in label pointer are valid
endif
pos = strpos(aname,'OFFSET_')
if ((len gt 7) AND (pos eq 0)) then begin ; label pointer found
  ON_IOERROR,escape ; return false if non-digit found
  for j=0,(len-8) do begin ; check one character at a time
    r = strmid(aname,(7+j),1) & READS,r,v,FORMAT='(I1)'
  endfor
  return,1 ; remaining characters in offset pointer are valid
endif
escape: return,0
end

;+------------------------------------------------------------------------
; NAME: spd_cdawlib_ami_var
; PURPOSE:
;       Return true(1) or false(0) depending on whether or not the
;       given attribute name's value is assigned to a real CDF variable name.
; CALLING SEQUENCE:
;	out = spd_cdawlib_ami_var(attribute_name)
; INPUTS:
;	attribute_name = name of a CDF attribute as a string
; KEYWORD PARAMETERS:
; OUTPUTS:
;       True(1) or False(0)
; AUTHOR:
;	Tami Kovalick	March 6, 2000
;
; MODIFICATION HISTORY:
;-------------------------------------------------------------------------
FUNCTION spd_cdawlib_ami_var, aname
;TJK 8/11/2015 - do not include DEPEND_EPOCH0 which is a THEMIS specific attribute
if (strpos(aname, 'DEPEND') eq 0 and (aname ne 'DEPEND_EPOCH0')) then return,1
if (strpos(aname, 'COMPONENT') eq 0) then return,1
return,0
end

;+------------------------------------------------------------------------
; NAME: spd_cdawlib_parse_display_type
; PURPOSE: 
;	Parse and examine the input string.  It should be the value of the
;	CDF attribute 'DISPLAY_TYPE'.  Return an array of variable names
;       that it 'points' to.
; CALLING SEQUENCE:
;	out = spd_cdawlib_parse_display_type(instring)
; INPUTS:
;       instring = string, value of a CDF attribute called 'DISPLAY_TYPE'
; KEYWORD PARAMETERS:
; OUTPUTS:
;       out = string array, names of other variables required for display
; NOTES: This routine expects to find 'DISPLAY_TYPE' values looking like:
;        PLOT_TYPE>x=vname,y=vname ...
;        PLOT_TYPE>y=vname,z=vname(*,1),z=vname(*,2) ...
; AUTHOR:
;       Richard Burley, NASA/GSFC/Code 632.0, Feb 13, 1996
;       burley@nssdca.gsfc.nasa.gov    (301)286-2864
; MODIFICATION HISTORY:
;TJK modified 01/27/98 to not parse orbit display type here - the items
;specified for the orbit plot type aren't additional variables.
;TJK modified 09/25/2001 to not parse the "symsize" keyword because its
;value isn't a variable.
;
;-------------------------------------------------------------------------
FUNCTION spd_cdawlib_parse_display_type, instring
num_vnames = 0L & spos = 0L & i=0L ; initialize
a = spd_cdawlib_break_mystring(instring,DELIMITER='>') ; break string into components
if n_elements(a) le 1 then return,-1 ; no '>' following plot type
if a[1] eq '' then return,-1 ; no info past '>' to parse
if strlowcase(a[0]) eq 'orbit' then return,-1 ; dont want to parse orbit.

lastn=n_elements(a)-1  ; RTB added 3/98
b = spd_cdawlib_break_mystring(a[lastn],delimiter=',') ; Parse the string into substrings
for i=0,n_elements(b)-1 do begin ; examine each substring
   s = strpos(b[i],'=') & p = strpos(b[i],'(') ; find '=' and '(' signs
   if s ne -1 then begin ; probably a properly formated DISPLAY_TYPE vattr
      if (strlowcase(strmid(b[i],0,s)) ne 'symsize') then begin
        s = s + 1 ; point to first character past the '=' sign
        if p ne -1 then vname = strmid(b[i],s,[p-s]) $ ; extract vname
           else vname = strmid(b[i],s,(strlen(b[i])-s))   ; extract vname
        if num_vnames eq 0 then begin
           variable_names = vname & num_vnames = num_vnames + 1
        endif else begin
           index = where(variable_names eq vname,wc)
           if wc eq 0 then begin
              variable_names = [variable_names,vname] ; add to existing list
              num_vnames = num_vnames + 1 ; keep count of number of names
           endif
        endelse
      endif ;if the left side of the equal sign isn't equal to "symsize"
   endif
endfor

if num_vnames eq 0 then return,-1 else return,variable_names
end

;Function spd_cdawlib_correct_vnames(vnames)
;This function takes a list of variable names, checks to see if any of them
;are in the structure called "table" which has a mapping of the "real" variable names
;to those who've been "corrected" in order to run under IDL5.3.

Function spd_cdawlib_correct_vnames, vnames
common global_table, table

if (n_elements(table) gt 0) then begin
   for i = 0, n_elements(table.equiv)-1 do begin
      c_index = where(vnames eq table.equiv[i], c_count)
      if (c_count ge 1) then vnames[c_index[0]] = table.varname[i]
   endfor
endif

return, vnames
end

;+------------------------------------------------------------------------
; NAME: spd_cdawlib_follow_mydepends
; PURPOSE: 
;	Search the metadata anonymous structure for ISTP 'DEPEND' attributes.
;       If and when found, add the variable name that it points to to the
;       vnames array if it is not already present, and increase the size
;       of the dhids and mhids arrays.
; CALLING SEQUENCE:
;       spd_cdawlib_follow_mydepends, metadata, vnames, dhids, mhids
; INPUTS:
;       metadata = anonymous structure holding attribute values
;       vnames   = string array of the names of variables already processed
;       vvarys   = string array of the record variance for each variable
;       dhids    = array of data handle id's
;       mhids    = array of metadata handle id's
; KEYWORD PARAMETERS:
; OUTPUTS:
;       dhids    = array of data handle id's
;       mhids    = array of metadata handle id's
; AUTHOR:
;       Richard Burley, NASA/GSFC/Code 632.0, Feb 13, 1996
;       burley@nssdca.gsfc.nasa.gov    (301)286-2864
; MODIFICATION HISTORY:
;-------------------------------------------------------------------------
PRO spd_cdawlib_follow_mydepends, metadata, vnames, vvarys, ctypes, dhids, mhids

cdaw_tnames = tag_names(metadata)
for i=0,n_elements(cdaw_tnames)-1 do begin
   ; Determine if the current tagname is a legal ISTP-style DISPLAY_TYPE vattr
   if (cdaw_tnames[i] eq 'DISPLAY_TYPE') then begin
      dvnames = spd_cdawlib_parse_display_type(metadata.(i)) & dvs = size(dvnames)
      if (dvs[n_elements(dvs)-2] eq 7) then begin ; variable names found
         for j=0,n_elements(dvnames)-1 do begin
	    dvnames[j] = spd_cdawlib_correct_vnames(dvnames[j]) ;look for variable names that have
	    ;been corrected (no illegal characters)
	    ;replace them w/ their "real" names 
	    ;so that their associated data can be
	    ;retrieved from the cdf files.
            a = where(vnames eq dvnames[j],count) ; search vnames array so no duplicates.
            if ((dvnames[j] ne '') AND (count eq 0)) then begin
               ; add the display variable name all array parameters
               n = n_elements(vnames)
               newn = strarr(n+1) & newd = lonarr(n+1) & newm = lonarr(n+1)
               newv = strarr(n+1) & newr = lonarr(n+1) & newc = strarr(n+1)
               newn[0:[n-1]] = vnames[0:[n-1]]
               newv[0:[n-1]] = vvarys[0:[n-1]]
               newc[0:[n-1]] = ctypes[0:[n-1]]
               newd[0:[n-1]] = dhids[0:[n-1]]
               newm[0:[n-1]] = mhids[0:[n-1]]
               newn[n]=dvnames[j] & newv[n]='' & newc[n]='' & newd[n]=0 & newm[n]=0
               vnames=newn & vvarys=newv & ctypes=newc & dhids=newd & mhids=newm
            endif
         endfor
      endif
   endif

   ; Determine if the current tagname is a legal ISTP-style depend attribute
   ;TJK 8/11/2015 - do not include DEPEND_EPOCH0 which is a THEMIS specific attribute
   len = strlen(cdaw_tnames[i]) & pos = strpos(cdaw_tnames[i],'DEPEND_') & th_exclude = (cdaw_tnames[i] ne 'DEPEND_EPOCH0')
   if ((len gt 7) AND (pos eq 0) AND th_exclude) then begin ; DEPEND found, check remainder
      ON_IOERROR, escape ; return false if non-digit found
      for j=0,(len-8) do begin ; check one character at a time
         r = strmid(cdaw_tnames[i],(7+j),1) & READS,r,v,FORMAT='(I1)'
      endfor
      dvname = metadata.(i) ; depend attribute FOUND
      dvname = spd_cdawlib_correct_vnames(dvname) ;look for variable names that have
      ;been corrected (no illegal characters)
      ;replace them w/ their "real" names 
      ;so that their associated data can be
      ;retrieved from the cdf files.
      
      ; TJK 9/8/03 remove this because we can't touch these attribute values because they
      ;they need to be the real variables name.
      ; RCJ 08/11/03 in case we have " " where a "" should be.
;      dvname = strtrim(dvname,2)
;debug      help, dvname

      a = where(vnames eq dvname,count) ;search vnames array to make sure
				      ;there are no duplicates
      if ((dvname ne '') AND (count eq 0)) then begin
         ; add the depend variable name to all array parameters
         n = n_elements(vnames)
         newn = strarr(n+1) & newd = lonarr(n+1) & newm = lonarr(n+1)
         newv = strarr(n+1) & newr = lonarr(n+1) & newc = strarr(n+1)
         newn[0:[n-1]] = vnames[0:[n-1]]
         newv[0:[n-1]] = vvarys[0:[n-1]]
         newc[0:[n-1]] = ctypes[0:[n-1]]
         newd[0:[n-1]] = dhids[0:[n-1]]
         newm[0:[n-1]] = mhids[0:[n-1]]
         newn[n] = dvname & newv[n]='' & newc[n]='' & newd[n]=0 & newm[n]=0
         vnames = newn & vvarys=newv & ctypes=newc & dhids=newd & mhids=newm
      endif
   endif
   escape: ; Current tag name is not a depend attribute
endfor

end

;-------------------------------------------------------------------------
; NAME: spd_cdawlib_cdftype_to_myidltype
; PURPOSE: 
;	Convert from CDF type number to IDL type number
; CALLING SEQUENCE:
;       out = spd_cdawlib_cdftype_to_myidltype(in)
; INPUTS:
;       in = integer, CDF type number
; KEYWORD PARAMETERS:
; OUTPUTS:
;       out = integer, IDL type number
; AUTHOR:
;       Richard Burley, NASA/GSFC/Code 632.0, Feb 13, 1996
;       burley@nssdca.gsfc.nasa.gov    (301)286-2864
; MODIFICATION HISTORY:
;       TJK 6/27/2006 - added CDF_DCOMPLEX (double-precision complex)
;       for handling the new (IDL6.3/CDF3.1) Epoch16 values
;       The CDFTYPE values come from cdf.inc in the cdf/include directory
;-------------------------------------------------------------------------
FUNCTION spd_cdawlib_cdftype_to_myidltype,cdftype

case cdftype of
   22L : idltype = 5 ; CDF_REAL8
   45L : idltype = 5 ; CDF_DOUBLE
   31L : idltype = 5 ; CDF_EPOCH
   32L : idltype = 9 ; CDF_EPOCH16
   21L : idltype = 4 ; CDF_REAL4
   44L : idltype = 4 ; CDF_FLOAT
   4L  : idltype = 3 ; CDF_INT4
   14L : idltype = 3 ; CDF_UINT4
   2L  : idltype = 2 ; CDF_INT2
   12L : idltype = 2 ; CDF_UINT2
   51L : idltype = 7 ; CDF_CHAR
   52L : idltype = 1 ; CDF_UCHAR
   1L  : idltype = 1 ; CDF_INT1
   11L : idltype = 1 ; CDF_UINT1
   41L : idltype = 1 ; CDF_BYTE
   else: idltype = 0 ; undefined
endcase
return,idltype
end


;+------------------------------------------------------------------------
; NAME: spd_cdawlib_append_mydata
; PURPOSE: 
; 	Append the 'new' data to the 'old' data using array concatenation.
; CALLING SEQUENCE:
;       out = spd_cdawlib_append_mydata(new,old)
; INPUTS:
;       new = data to be appended to the old data
;       old = older data that new data is to be appended to
; KEYWORD PARAMETERS:
; OUTPUTS:
;       out = product of concatenating the old and new data arrays
; NOTES:
; 	Special case check: if old data was from either a skeleton CDF or from
; 	a CDF with only a single record, then the last dimension was dropped 
;	during the process of saving/retrieving the data from a handle.  
;	Must compare the dimensionality of the new and old data to determine 
;	if this drop has occured, and if so, reform the old data to include 
;       the extra dimension so that the data can be appended.
; AUTHOR:
;       Richard Burley, NASA/GSFC/Code 632.0, Feb 13, 1996
;       burley@nssdca.gsfc.nasa.gov    (301)286-2864
; MODIFICATION HISTORY:
;-------------------------------------------------------------------------
FUNCTION spd_cdawlib_append_mydata, new, old, dict_key=dict_key, vector=vector

; RCJ (11/21/01) Added this line because of problem w/ dataset wi_k0_sms:
; RCJ (02/01/02) Well, fixed problem for wi_k0_sms but broke for other datasets
; (wi_h1_wav for example) so I'm commenting this out.
;if n_elements(new) ne 1 then new=reform(new)

; RCJ 10/04/2012  Created this 'observe me' variable. This will be
; the 'size' of whatever array was *not* reformed. 
; Default is the size of the new array.
obsme=(a = size(new)) & b = size(old) & data=0L

if not keyword_set(dict_key) then dict_key=''

; RCJ 06/10/2003 Trying to fix dimension problem w/ interball dataset it_k0_wav
; but if it breaks anything I'll remove it.
;
; TJK 12/22/03 - the following if statements breaks the case where each cdf only 
; has one record in it, e.g. our new timed guvi files (timed_l1c*).  The case this
; was added for was for it_k0_wav and the Mf2 variable (which turns out to be all
; fill, so unless we have other cases that need this, this will be left commented out.
;if (a(0) eq 3) then begin
;   if ((a(1) eq 1) or (a(2) eq 1) or (a(3) eq 1)) then begin
;      new=reform(new)
;      a=size(new)
;   endif
;endif

; TJK 8/23/2007 dimensions match, but in the 
;    case of a single record of some size like a vector of 3 - 
;    need to reform old data.  If new happens to also be a single 
;    record of 3, will get reformed below.

;if ((a(0) eq b(0)) and (a(1) eq b(1))) then begin 
;    if (b(0) eq 1) then begin
;      print,'WARNING= First two dimensions are the same, attempting to reform...' ;DEBUG
;      old = reform(temporary(old),b(1),1)
;      b = size(old) ; recompute b after it has been reformed
;    endif
;endif

;TJK 9/29/2010 add code to remove the extra dimension on a 2-d "new"
;array - this was added specifically for the new isis_av_all dataset
;        which has a bunch of data variables that use the cdf "sparse
;        records" setting - which takes one value and fills it into
;                           all records.

; RCJ 05/23/2013 Cover also cases when a[1] eq 1 :
if (b[0] eq 1 and (a[0] eq 2 and ((a[2] eq 1) or (a[1] eq 1)))) then begin
;if (b[0] eq 1 and (a[0] eq 2 and a[2] eq 1)) then begin
   print,'WARNING= Single dimension found, attempting to reform...0' ;DEBUG
   new = reform(temporary(new))
   obsme=(a = size(new))
endif

if (a[0] gt b[0]) then begin ; dimension mismatch - reform old data
   print,'WARNING= Dimension mismatch detected, attempting to reform...1' ;DEBUG
   case b[0] of
      0    : ; no special actions needed
      1    : begin
               ;old = reform(temporary(old),b[1],1)
               if keyword_set(vector) then old = reform(temporary(old),b[1],1) $
                  else old = reform(temporary(old),1,b[1])
	       ; RCJ 04/19/2013  Making value=old[0] makes all values of a vector
	       ;  equal to that value.
               ;old = make_array(a[1],1,type=size(old,/type),value=old[0])
             end		
      2    : begin
               ;old = reform(temporary(old),b[1],b[2],1)
	       old = reform(temporary(old),a[1],b[2],1)
	     end	
      3    : begin
               ;old = reform(temporary(old),b[1],b[2],b[3],1)
	       old = reform(temporary(old),a[1],b[2],b[3],1)
	     end	
      else : print,'ERROR=Cannot reform single-record variable with > 3 dims'
   endcase
   b = size(old) ; recompute b after it has been reformed
   obsme = size(new)
endif
if (a[0] lt b[0]) then begin ; dimension mismatch - reform new data
   print,'WARNING= Dimension mismatch detected, attempting to reform...2' ;DEBUG
   case a[0] of
      0    : ; no special actions needed
      1    : begin
               ;new = reform(temporary(new),a[1],1)
               if keyword_set(vector) then new = reform(temporary(new),a[1],1) $
                  else new = reform(temporary(new),1,a[1])
	       ; RCJ 04/19/2013  Making value=new[0] makes all values of a vector
	       ;  equal to that value.
               ;new = make_array(b[1],1,type=size(new,/type),value=new[0])
	     end  
      2    : begin
               ;new = reform(temporary(new),a[1],a[2],1)
               new = reform(temporary(new),b[1],a[2],1)
	     end  
      3    : begin
               ;new = reform(temporary(new),a[1],a[2],a[3],1)
               new = reform(temporary(new),b[1],a[2],a[3],1)
	     end  
      else : print,'ERROR=Cannot reform single-record variable with > 3 dims'
   endcase
   a = size(new) ; recompute a after it has been reformed
   obsme= size(old)
endif

; append the new data to the old data
;case a[0] of
case obsme[0] of
   0:begin
       ; RCJ 02/09/2007  Problem reading po_k0_uvi_20020318 and 19.
       ; Day 18 generates an image array: [228,200,21]. Day 19 is a
       ; small cdf containing one (fill)value: -1.0000e+31 for the image. 
       ; New data cannot concatenate w/ old. Shouldn't test above fix this?
       data = [old,new]
    end
   1:begin
       ;data = [old,new]
       ; RCJ 09/20/2007  This is to resolve cases when the 
       ; var is a vector but the first cdf read contains an array[3]
       ; Best would be array[3,1], but that info is lost when we get
       ; to this point, so when we finally get array[3,*] the
       ; concatenation can be done properly.
       ; TJK 11/19/2007 Extend this to also look for spectrogram types
       ;TJK 6/25/2008 add this catch because sometimes the "vector"
       ;setting isn't correct.  So reset "vector" and try again.
       CATCH,error_status
          if (error_status ne 0) then begin
            if (vector) then begin
              vector= 0 ;try again w/ vector set to off
              !ERROR=0 ;and reset the error
              if (keyword_set(DEBUG)) then print, 'try no vector append'
          endif
      endif

       if ((strpos(strlowcase(dict_key),'vector') ne -1) or keyword_set(vector)) $
               then data = [[old],[new]] else data = [old,new]
    end
   2:begin
       data = [[old],[new]]
    end
   3:begin
       ;TJK 2/23/2009 add this check for vector set (it_k0_wav) and three dimensional
       ;array (which they are because the third dim. is added above - which
       ;is what you'd want to do if these were images, but they aren't
       ;so remove the last dimension from each array, and append the arrays.
       if (keyword_set(vector) and a[3] eq 1) then begin
           new = reform(temporary(new))
           old = reform(temporary(old))
           data = [[old],[new]]
       endif else begin   
        data = [[[old]],[[new]]]        
       endelse
    end
   4:begin
;can't do: IDL doesn't support more than 3 dimensions:
;  data = [[[[old]]],[[[new]]]]  so do this the old fashioned way
         a = size(new)
         b = size(old)
         data = make_array(a[1],a[2],a[3],a[4]+b[4],type=a[5])
         data[*,*,*,0:b[4]-1]=old[*,*,*,*]
         data[*,*,*,b[4]:*]=new[*,*,*,*]
     end
   else: print,'ERROR=Cannot append arrays with > 4 dimensions yet'
endcase
; TJK 10/21/2009 remove this line from here.  Plot_spectrogram uses
; spd_cdawlib_append_mydata to add fill values to the data array. The following line wipes
; out the fill values.  Let the calling routine take care of releasing memory.
;new = 0L & old = 0L ; free up unneeded memory

return,data
end

;+------------------------------------------------------------------------
; NAME: spd_cdawlib_add_mydepends
; PURPOSE: 
;	Search the metadata anonymous structure for ISTP 'DEPEND' 
;	attributes and add the variable name that it points to to the
;       vnames array if it is not already present.  If the DEPEND
;	variable is not present in the list, change the data_type so it
;	won't be plotted.
;
; CALLING SEQUENCE:
;       spd_cdawlib_add_mydepends, metadata, vnames
;
; INPUTS:
;       metadata = anonymous structure holding attribute values
;       vnames   = string array of virtual variables found
;
; OUTPUTS:
;       vnames    = modified variable name that includes component variable
;                   names
;
; NOTES - this is similar to spd_cdawlib_follow_mydepends, except it does less.
;
; AUTHOR:
; 	Tami Kovalick, QSS,   11/29/2006
;-------------------------------------------------------------------------
PRO spd_cdawlib_add_mydepends, metadata, vnames
common global_table, table

cdaw_tnames = tag_names(metadata)

for k=0,n_elements(cdaw_tnames)-1 do begin
   len = strlen(cdaw_tnames[k]) & pos = strpos(cdaw_tnames[k],'DEPEND_')
   if ((len gt 7) AND (pos eq 0)) then begin 
      ; DEPEND found, check remainder
      ON_IOERROR, escape ; return false if non-digit found
      for j=0,(len-11) do begin ; check one character at a time
         r = strmid(cdaw_tnames[k],(10+j),1) & READS,r,v,FORMAT='(I1)'
      endfor
      dvname = metadata.(k) ; depend attribute FOUND
      dvname = spd_cdawlib_correct_vnames(dvname) ;look for variable names that have
      a = where(vnames eq dvname,count)    ; search vnames array
      ;TJK 4/23/01 added extra check for the case where the depend_0 variable
      ; has an alternate name (its original name had invalid characters in it) - so
      ; check the table prior to including it.
      v_count = 0  
      e_index = where(dvname eq table.equiv, e_count)
      if (e_count gt 0) then begin 
         v_index = where(vnames eq table.varname[e_index], v_count)
      endif
      if ((dvname ne '') AND (count eq 0) AND (v_count eq 0)) then begin
         ;print, 'Adding ',dvname,' to vnames'
         ;  if DEPEND variable not already requested, add it to the vnames
         ;  array, but change data_type so it won't be plotted...
         vnames = [vnames,dvname] ;put the depend variable in place - TJK
      endif  ;  Added all depend variable names
   endif  ;  Finished reading all component variable names
   escape: ;Current tag name is not a depend attribute
endfor  ;  Finished looping through all metadata elements

end
;+------------------------------------------------------------------------
; NAME: spd_cdawlib_add_mycomponents
; PURPOSE: 
;	Search the metadata anonymous structure for ISTP 'COMPONENT' 
;	attributes and add the variable name that it points to to the
;       vnames array if it is not already present.  If the component
;	variable is not present in the list, change the data_type so it
;	won't be plotted.
;
; CALLING SEQUENCE:
;       spd_cdawlib_add_mycomponents, metadata, vnames
;
; INPUTS:
;       metadata = anonymous structure holding attribute values
;       vnames   = string array of virtual variables found
;
; OUTPUTS:
;       vnames    = modified variable name that includes component variable
;                   names
;
; AUTHOR:
; 	Carrie Gallap, Raytheon STX,   1/5/98
;-------------------------------------------------------------------------
PRO spd_cdawlib_add_mycomponents, metadata, vnames
common global_table, table

cdaw_tnames = tag_names(metadata)

;TJK changed the i to k since that's what's used below
;for i=0,n_elements(cdaw_tnames)-1 do begin

for k=0,n_elements(cdaw_tnames)-1 do begin
   len = strlen(cdaw_tnames[k]) & pos = strpos(cdaw_tnames[k],'COMPONENT_')
   if ((len gt 10) AND (pos eq 0)) then begin 
      ; COMPONENT found, check remainder
      ON_IOERROR, escape ; return false if non-digit found
      for j=0,(len-11) do begin ; check one character at a time
         r = strmid(cdaw_tnames[k],(10+j),1) & READS,r,v,FORMAT='(I1)'
      endfor
      dvname = metadata.(k) ; component attribute FOUND
      dvname = spd_cdawlib_correct_vnames(dvname) ;look for variable names that have
      a = where(vnames eq dvname,count)    ; search vnames array
      ;TJK 4/23/01 added extra check for the case where the component_0 variable
      ; has an alternate name (its original name had invalid characters in it) - so
      ; check the table prior to including it.
      v_count = 0  
      e_index = where(dvname eq table.equiv, e_count)
      if (e_count gt 0) then begin 
         v_index = where(vnames eq table.varname[e_index], v_count)
      endif
      if ((dvname ne '') AND (count eq 0) AND (v_count eq 0)) then begin
         ;print, 'Adding ',dvname,' to vnames'
         ;  if COMPONENT variable not already requested, add it to the vnames
         ;  array, but change data_type so it won't be plotted...
         n = n_elements(vnames)
         newn = strarr(n+1)
         newn[0:(n-1)] = vnames[0:(n-1)]
         vnames = newn
         vnames[n] = dvname ;put the component variable in place - TJK
      endif  ;  Added all component variable names
   endif  ;  Finished reading all component variable names
   escape: ;Current tag name is not a Component attribute
endfor  ;  Finished looping through all metadata elements

end
;-------------------------------------------------------------------------
PRO spd_cdawlib_add_mydeltas, metadata, vnames
common global_table, table

cdaw_tnames = tag_names(metadata)

for i=0,n_elements(cdaw_tnames)-1 do begin
   pos1 = strpos(cdaw_tnames[i],'DELTA_PLUS_VAR') $
          & pos2 = strpos(cdaw_tnames[i],'DELTA_MINUS_VAR')
   if ((pos1[0] ne -1) or (pos2[0] ne -1)) then begin ; DELTA found, 
      dvname = metadata.(i) 
      dvname = spd_cdawlib_correct_vnames(dvname) ;look for variable names that have
      q = where(vnames eq dvname,count) ;search vnames array to make sure
      ;TJK (from spd_cdawlib_add_mydeltas): added extra check for the case where 
      ; the delta variable
      ; has an alternate name (its original name had invalid characters in it) - so
      ; check the table prior to including it.
      v_count = 0  
      e_index = where(dvname eq table.equiv, e_count)
      if (e_count gt 0) then begin 
         v_index = where(vnames eq table.varname[e_index], v_count)
      endif
      if ((dvname ne '') AND (count eq 0) AND (v_count eq 0)) then begin
      ;if ((dvname ne '') AND (q[0] eq -1)) then begin
	 ;print,metadata.var_type
         ; add the delta variable name to all array parameters

         vnames=[vnames,dvname]

      endif
  endif
endfor
end

;
;
;+------------------------------------------------------------------------
; NAME: spd_cdawlib_read_myvariable
; PURPOSE: 
;	Return the data for the requested variable.
; CALLING SEQUENCE:
;       out = spd_cdawlib_read_myvariable(vname, CDFid, vary, dtype, recs)
; INPUTS:
;       vname = string, name of variable to be read from the CDF
;       CDFid = integer, id or already opened CDF file.
; KEYWORD PARAMETERS:
;	START_REC = first record to read.
;	REC_COUNT = number of records to read.
; OUTPUTS:
;       out = all data from the CDF for the variable being read
;       vary = True(1) or False(0) is variable record-varying
;       dtype= string, CDF data type
;       recs = integer, number of data records
; AUTHOR:
;       Richard Burley, NASA/GSFC/Code 632.0, Feb 13, 1996
;       burley@nssdca.gsfc.nasa.gov    (301)286-2864
; MODIFICATION HISTORY:
;       96/04/11 : R.Burley :zVar handling when MAXRECS = -1 changed to
;                            read REC_COUNT of MAXRECS + 2 & return,DAT
; 	96/12/20 ; T. Kovalick modified to take START_REC and REC_COUNT
;	keywords (see above).  If they aren't set you will get all of
; 	the records in a cdf.
;-------------------------------------------------------------------------
FUNCTION spd_cdawlib_read_myvariable, vname, CDFid, vary, $
	 dtype, recs, START_REC=START_REC, REC_COUNT=REC_COUNT,set_column_major=set_column_major,DEBUG=DEBUG

;
; Get needed information about the cdf and variable
;stop;
CDF_LIB_INFO, VERSION=V, RELEASE=R, COPYRIGHT=C, INCREMENT=I
cdfversion = string(V, R, I, FORMAT='(I0,".",I0,".",I0,A)')

cinfo = cdf_inquire(CDFid) ; inquire about the cdf
vinfo = cdf_varinq(CDFid,vname) ; inquire about the variable
cdf_control,CDFid,VAR=vname,GET_VAR_INFO=vinfo2 ; inquire more about the var

zflag = vinfo.is_zvar ; determine if r-variable or z-variable

if keyword_set(START_REC) then start_rec = START_REC else start_rec = 0L
;TJK changed this because the maxrec that comes back from cdf_inquire only
;applies to R variables under IDL v5.02, so if you don't have any R 
;variables in your CDF, maxrec will come back as -1...
;rcount = cinfo.maxrec+1 & if (vinfo.RECVAR eq 'NOVARY') then rcount=1L

rcount = vinfo2.maxrec+1 & if (vinfo.RECVAR eq 'NOVARY') then rcount=1L

;TJK changed this...maxrecs isn't documented by RSI.
;if keyword_set(REC_COUNT) then recs = REC_COUNT else recs = vinfo2.maxrecs+1
;So if the rec_count keyword is specified use it, else determine the
;the max recs depending on whether the variable is z or r.

if keyword_set(REC_COUNT) then recs = REC_COUNT else recs = vinfo2.maxrec+1
;So if the rec_count keyword is specified use it, else determine the
;the max recs depending on whether the variable is z or r.

;TJK w/ IDL 5.02 they have now defined maxrec and maxrecs, we want to
; use maxrec and this should work the same for both r and z variables.
;if keyword_set(REC_COUNT) then begin 
;  recs = REC_COUNT 
;endif else if (zflag eq 1) then begin ;set the z variable max recs
;  recs = vinfo2.maxrec+1
;endif else recs = vinfo2.maxrecs+1 ;set the r variable max recs

vary = vinfo.RECVAR & dtype = vinfo.DATATYPE
if keyword_set(DEBUG) then begin
  if keyword_set(set_column_major) then print, 'In spd_cdawlib_read_myvariable, to_column SET in varget' else print, 'In spd_cdawlib_read_myvariable, to_column NOT set in varget' 
endif
; Read the CDF for the data for the requested variable
if (zflag eq 1) then begin ; read the z-variable
   cdf_control,CDFid,VAR=vname,GET_VAR_INFO=zvinfo
   ; Add the condition that the variable is Record Variant before entering this branch.  According
   ; to the documentation, NRV variables should return a MAXREC = 0, however, at least in some cases,
   ; the structure returned in GET_VAR_INFOR when calling CDF_CONTROL on a NRV variable has MAXREC
   ; set to -1.
   ; Ron Yurow (October 6, 2015)
   if zvinfo.MAXREC eq -1  && vary eq "VARY" then begin  ; this means NO records have been written
      if keyword_set(DEBUG) then print,'WARNING=',vname,' has ZERO records!'
;TJK 11/17/2006 - instead of reading 1 record when maxrec = -1 (which
;                 indicates that no records for the variable were
;                 written), return the fill value for this variable
;print, 'WARNING, no records for variable ',vname
;print, 'attempting to get fillval and return that'
      anum = cdf_attnum(CDFid,'FILLVAL')
      if ((anum ne -1) and cdf_attexists(CDFid,'FILLVAL',vname))then begin
         cdf_attget,CDFid,'FILLVAL',vname,wfill
	 if (size(wfill,/tname) eq 'DCOMPLEX') then return,real_part(wfill) else $
         ;TJK 5/4/2007 - change from "return,wfill" to check if size should be
         ;               an array, if so the make the appropriate size array
         ;               and fill w/ the variables fill value.
         ; dim is array of longs. The value of each element corresponds to the dimension of the variable.
	 ;   This field is only included in the structure if the variable is a zVariable. (source: cdf_varinq in idl help)
	 ;  So this 'case' refers to the number of elements of dim.
         case (size(vinfo.dim, /n_elements)) of
             0: return, wfill
             1: begin
                 ;if (vinfo.dim le 0) then return, wfill $
                 ;else return, make_array(vinfo.dim,value=wfill)
                 if (vinfo.dim le 0) then begin
		    return, wfill 
		 endif else begin 
		   ; RCJ 02/07/2012 
		   ; if var and its depend_0 have no records (vinfo2.maxrecs=0) OR
		   ; if var has no records but its depend_0 does, then we need
		   ; to fill in the var array w/ as many records as depend_0 has. 
		   ; Ran into this problem w/ thb_l2_mom_20090929_v01.cdf 
                   ;if vinfo2.maxrecs eq 0 then begin
		   ; RCJ 03/23/2012   maxrecs could be -1 too, so changed to 'le'
                   ;TJK 4/11/2012, use maxrecs+1 instead of maxrecs
                   if (vinfo2.maxrecs le 0) then begin
		      return, make_array(vinfo.dim,value=wfill)
		   endif else begin 
 
;1/30/2014 TJK check the depend0 variable to see if its virtual, if so
;it will have a component_1 (THEMIS case) so the epoch values don't 
;exist yet... so need to get the depend_0's, component_1's data size 
;and compare w/ the current variables size - stored below in cinfo.maxrec
;3/18/2014 - call cdf_attexists for depend_0 and component_0 instead
;of cdf_attnum (attnum fails if the attribute doesn't exist)

                      dnum = cdf_attexists(CDFid,'DEPEND_0') ;returns true or false
                      if ((dnum) and cdf_attexists(CDFid,'DEPEND_0',vname))then begin
                         cdf_attget,CDFid,'DEPEND_0',vname, depend0 ;depend_0 of the data variable
                         if (depend0 ne ' ') then begin ;if depend_0 isn't blank get its component_0
                            cnum = cdf_attexists(CDFid,'COMPONENT_1') ;returns true or false
                            if ((cnum) and cdf_attexists(CDFid,'COMPONENT_1',depend0))then begin
                               cdf_attget,CDFid,'COMPONENT_1',depend0,component1 ;component_1 of the data variable
                               if (component1 ne ' ') then begin ; now get the data array sizes for the component_1 variable
                                  cdf_control,CDFid,VAR=component1,GET_VAR_INFO=cinfo
                                  if (cinfo.maxrec+1 gt 0) then make_records = cinfo.maxrec+1 else make_records = 1
                                  if keyword_set(DEBUG) then print,'WARNING, ',vname,' has no records but its component_1 ',component1,' does. Filling in array with ',make_records,' elements.'  
                                  return, make_array(vinfo.dim,make_records,value=wfill)
;                                 help, /struct, cinfo
                               endif 
                             endif else begin ; if component_1 isn't found, then use the maxrec for this variable
                                ;if (vinfo2.maxrec+1 gt 0) then make_records = vinfo2.maxrec+1 else make_records = 1
				; RCJ 10/09/2014  Recs seems to have the correct number of records to be read. 
                                ; if (recs gt 0) then make_records = recs else make_records = 1
                                ; It looks what is needed is maximum records of the depend_0 variable.  This is 
                                ; done in the following two lines.
                                ; Ron Yurow (Feb 12, 2016)
                                cdf_control,CDFid,VAR=depend0,GET_VAR_INFO=dinfo
                                if (dinfo.maxrec+1 gt 0) then make_records = dinfo.maxrec+1 else make_records = 1
                                if keyword_set(DEBUG) then print,'WARNING, ',vname,' has no records but its depend_0 ',depend0,' does. Filling in array with ',make_records,' elements.'  
                                return, make_array(vinfo.dim,make_records,value=wfill)
                             endelse
                         endif
                      endif else begin ; if depend_0 isn't found, then use the maxrec for this variable
                        ;if (vinfo2.maxrec+1 gt 0) then make_records = vinfo2.maxrec+1 else make_records = 1
			; RCJ 10/09/2014 Recs seems to have the correct number of records to be read.
                        if (recs gt 0) then make_records = recs else make_records = 1
                        if keyword_set(DEBUG) then print,'WARNING, ',vname,' has no records and no depend_0. Filling in array with ',make_records,' elements.'  
                        return, make_array(vinfo.dim,make_records,value=wfill)
                      endelse

                      ;1/30/2014 TJK vinfo2.maxrecs is the maximum record for all variables
                                ;in this cdf.  So we don't want
                                ;to use that, see above for new logic
;		      if keyword_set(DEBUG) then print,'WARNING, ',vname,' has no records but its depend_0 does. Filling in array with ',vinfo2.maxrecs+1,' elements.'  
;		      return, make_array(vinfo.dim,vinfo2.maxrecs+1,value=wfill)

		   endelse  
		 endelse   
                end
             2: begin
                  tmp_a = make_array(dimension=vinfo.dim, value=wfill)
                  tmp_a = reform(temporary(tmp_a),vinfo.dim[0],vinfo.dim[1],1)
                  return, tmp_a
                end
             3: begin
                  tmp_a = make_array(dimension=vinfo.dim, value=wfill)
                  tmp_a = reform(temporary(tmp_a),vinfo.dim[0],vinfo.dim[1],vinfo.dim[2],1)
                  return, tmp_a
                end
             else: print, "STATUS = array size too large"

         endcase
  
      endif else begin ;if don't have a fill value, go ahead and read 1 rec.
;        if keyword_set(DEBUG) then vtime = systime(1)
         if (cdfversion ge '3.5.0') then begin
           cdf_varget,CDFid,vname,dat,REC_COUNT=1,to_column_major=set_column_major & return,dat
        endif else begin
           cdf_varget,CDFid,vname,dat,REC_COUNT=1 & return,dat
        endelse
;        if keyword_set(DEBUG) then print, '1 Took ',systime(1)-vtime, ' seconds to do cdf_varget for ',vname
      endelse
   
   endif else begin

;     if keyword_set(DEBUG) then vtime = systime(1)
      if (cdfversion ge '3.5.0') then begin
        cdf_varget,CDFid,vname,dat,REC_START=start_rec,REC_COUNT=recs,to_column_major=set_column_major
     endif else cdf_varget,CDFid,vname,dat,REC_START=start_rec,REC_COUNT=recs

;     if keyword_set(DEBUG) then print, '2 Took ',systime(1)-vtime, ' seconds to do cdf_varget for ',vname

   endelse
   ;TJK - added the next two lines so that extraneous single dimensions
   ;will be taken out - this was already being done for r variables
   ;but wasn't for Z variables, so if we were loading a variable from
   ;both a z and r variable cdf there would be a mismatch and the
   ;append of the two data arrays would not be successful.
   ds = size(dat) ; get size info to determine if dat is scalar or not
   if (ds[0] ne 0) then dat = reform(temporary(dat)) ; eliminate extraneous dims
endif else begin ; read the r-variable
   dims = total(vinfo.dimvar) & dimc = vinfo.dimvar * cinfo.dim
   dimw = where(dimc eq 0,dcnt) & if (dcnt ne 0) then dimc[dimw]=1
   if rcount eq 0 then begin
      print,'WARNING=',vname,' has ZERO records!' & return,0
      ;TJK replaced this line w/ the following to accommodate start_rec and rec_count
      ;  endif else CDF_varget,CDFid,vname,dat,COUNT=dimc,REC_COUNT=rcount
   endif else begin
;     if keyword_set(DEBUG) then vtime = systime(1)
      if (cdfversion ge '3.5.0') then begin
       CDF_varget,CDFid,vname,dat,COUNT=dimc,REC_START=start_rec,REC_COUNT=recs, to_column_major=set_column_major
    endif else CDF_varget,CDFid,vname,dat,COUNT=dimc,REC_START=start_rec,REC_COUNT=recs
;     if keyword_set(DEBUG) then print, '3 Took ',systime(1)-vtime, ' seconds to do cdf_varget for ',vname
   endelse

   if keyword_set(DEBUG) then print, 'reading ',vname,' starting at record', start_rec,' ', recs, 'number of records'

   ds = size(dat) ; get size info to determine if dat is scalar or not
   if (ds[0] ne 0) then dat = reform(temporary(dat)) ; eliminate extraneous dims
endelse


; Correct for fact that IDL retrieves character data as bytes
;if vinfo.DATATYPE eq 'CDF_CHAR' then begin ; IDL retrieves as bytes

if ((vinfo.DATATYPE eq 'CDF_CHAR') or (vinfo.DATATYPE eq 'CDF_UCHAR')) then begin ; IDL retrieves as bytes
   ds = size(dat) ; get dimensions of dat for single char special case
   if (ds[0] gt 1) then begin 
      dat = string(dat)
      dat = reform(temporary(dat)); eliminate extraneous dims
   endif else begin 
     if ((ds[0] eq 1) and vinfo.dim eq 1) then begin 
;         print, 'converting one record of bytes '
        dat = string(dat)
     endif else begin  ; process each element of array
;         print, 'converting more than one record of bytes '
       d2=strarr(ds[1])
       for i=0,ds[1]-1 do d2[i]=string(dat[i])
       dat = d2
     endelse
  endelse
if keyword_set(DEBUG) then print, 'Converted ',vinfo.datatype,' to STRING ', dat
endif

; Check for sign loss for cdf unsigned integer data.  IDL (as of v4.0.1b)
; returns unsigned cdf variables as signed IDL variables with the same
; number of bytes.  This could cause a sign flip.  Detect and Correct.
if (vinfo.DATATYPE eq 'CDF_UINT1' and strupcase(vinfo.recvar) eq 'NOVARY') then begin
; RCJ 03/09/2016  Doing this for novary vars only at the moment.  There are 'vary' types
; that are of type byte but they list and plot properly, so I don't want to mess with them.
; The problem here was that novary vars that go on the header of a listing were not showing (mms fpi data,
; that are supposed to show as an index array). In LIST_mystruct, these byte arrays are turned to strings
; and become ''.
      dat = uint(dat)  & dtype='CDF_INT1'
      print,'WARNING=Converting BYTE to CDF_INT1.'
endif
if vinfo.DATATYPE eq 'CDF_UINT2' then begin
   w = where(dat lt 0,wc) ; search for negative values
   if (wc gt 0) then begin ; convert to long
      dat = long(dat) & dat[w] = dat[w]+(2L^16) & dtype='CDF_INT4'
      print,'WARNING=Converting CDF_UINT2 to CDF_INT4 to avoid sign switch.'
   endif
endif
if vinfo.DATATYPE eq 'CDF_UINT4' then begin
   w = where(dat lt 0,wc) ; search for negative values
   if (wc gt 0) then begin ; convert to float
      dat = float(dat) & dat[w] = dat[w]+(2.0d0^32) & dtype='CDF_REAL'
      print,'WARNING=Converting CDF_UINT4 to CDF_REAL4 to avoid sign switch.'
   endif
endif

; If this variable is a record-varying variable, but this CDF only happens
; to have one record, then we must add the extra dimension onto the end
; for proper appending to take place when other CDF's are read
if ((vinfo.RECVAR eq 'VARY') AND (rcount eq 1L)) then begin
   ; print,'WARNING=Reforming single-record variable' ;DEBUG
   ds = size(dat) ; get dimensions of dat
   case ds[0] of
      0    : rcount = 1L ; do nothing
      1    : dat = reform(temporary(dat),ds[1],1)
      2    : dat = reform(temporary(dat),ds[1],ds[2],1)
      3    : dat = reform(temporary(dat),ds[1],ds[2],ds[3],1)
      else : print,'ERROR=Cannot reform single-record variable with > 3 dims'
   endcase
endif
; Return the data read from the CDF
return,dat
end

function spd_cdawlib_majority_check, CDFid=CDFid, buf=buf
; If this is a row majority CDF and running at least IDL8.1 and have
; at least 3.5.0 of CDF then we can check for and we will want to read
; a row major cdf as column major. This will return the dimensions
; in IDL that will match the dimensions defined in the cdf.
; If buf is defined, check it 1st for the value of
; CDAWLIB_IDL_ROW_NOTRANSPOSE.  Otherwise, have to look in the
; currently opened CDF.
; Return the value of set_column_major
;
;TJK 10/2014 - decide whether to read cdfs w/ to_column switch
; also need to check for global attribute cdawlib_idl_row_notranspose
; existence or equal to FALSE then set "set_column_major" to "true"

set_column_major = 0

; Set up an error handler
CATCH, Error_status
if Error_status ne 0 then begin
   print,'Error in spd_cdawlib_majority_check ',!ERR_STRING
   return, set_column_major
endif


CDF_LIB_INFO, VERSION=V, RELEASE=R, COPYRIGHT=C, INCREMENT=I
cdfversion = string(V, R, I, FORMAT='(I0,".",I0,".",I0,A)')

if ((!version.release lt '8.1' and cdfversion lt '3.5.0')) then begin
  set_column_major = 0 ;w/o these two we can't use the to_column keyword to cdf_varget
endif

if ( cdfversion ge '3.5.0') then begin
  set_column_major = 1 ; default

   if (n_tags(buf) gt 0) then begin ;if buf defined then check it
     ;print, 'DEBUG in spd_cdawlib_majority_check, checking buffer'

     atags = tag_names(buf)
     q=spd_cdawlib_tagindex('CDAWLIB_IDL_ROW_NOTRANSPOSE',atags)
     m=spd_cdawlib_tagindex('CDFMAJOR',atags) 
     if (m[0] ne -1) then begin
         if (buf.cdfmajor eq 'COL_MAJOR') then begin
            set_column_major = 0 
         endif else begin
            if (buf.cdfmajor eq 'ROW_MAJOR') and (q[0] ne -1) then begin
               notranspose = buf.CDAWLIB_IDL_ROW_NOTRANSPOSE
               if (strupcase(notranspose) eq 'TRUE') then set_column_major = 0
            endif
         endelse
      endif else begin ;majority not in the buffer yet
            set_column_major = 0 
      endelse

     endif else begin            ; look into the cdf, if not given a buffer
      ;print, 'DEBUG in spd_cdawlib_majority_check, buffer isnt defined, checking the cdf for majority etc.'
      if keyword_set(CDFid) then begin
        cinfo = cdf_inquire(CDFid)
        if (cinfo.majority eq 'ROW_MAJOR') then begin
           if (cdf_attexists(CDFid,'CDAWLIB_IDL_ROW_NOTRANSPOSE'))then begin
              cdf_attget,CDFid,'CDAWLIB_IDL_ROW_NOTRANSPOSE', 0, notranspose   
              if (strupcase(notranspose) eq 'TRUE') then set_column_major = 0
           endif
           if (cdf_attexists(CDFid,'cdawlib_idl_row_notranspose'))then begin
              cdf_attget,CDFid,'cdawlib_idl_row_notranspose', 0, notranspose   
              if (strupcase(notranspose) eq 'TRUE') then set_column_major = 0
           endif
        endif else set_column_major = 0
     endif
   endelse
  endif

return, set_column_major

end

;+------------------------------------------------------------------------
; NAME: spd_cdawlib_read_myattribute
; PURPOSE: 
;	Return the value of the requested attribute for the requested variable.
; CALLING SEQUENCE:
;       out = spd_cdawlib_read_myattribute(vname,anum,CDFid)
; INPUTS:
;       vname = string, name of variable whose attribute is being read
;       anum = integer, number of attribute being read
;       CDFid = integer, id of already opened CDF file.
; KEYWORD PARAMETERS:
; OUTPUTS:
;       out = anonymous structure holding both the name of the attribute
;             and the value of the attribute
; AUTHOR:
;       Richard Burley, NASA/GSFC/Code 632.0, Feb 13, 1996
;       burley@nssdca.gsfc.nasa.gov    (301)286-2864
;
; MODIFICATION HISTORY:
;   	RCJ 11/2003 Added keyword isglobal
;-------------------------------------------------------------------------
FUNCTION spd_cdawlib_read_myattribute, vname, anum, CDFid, isglobal=isglobal
common global_table, table

cdf_attinq,CDFid,anum,aname,ascope,maxe,maxze ; inquire about the attribute
aname = strtrim(aname,2) ; trim any possible leading or trailing blanks
;TJK 2/28/2002 - call spd_cdawlib_replace_bad_chars to replace any "illegal" characters in
;the attribute name w/ a legal one.  This was necessary to go to IDL 5.3.

aname = spd_cdawlib_replace_bad_chars(aname,repchar="_",found)

attval='' & astruct=create_struct(aname,attval) ; initialize anonymous structure
;TJK modified this error catch to re-set the !error value since not finding
;all attributes is not a fatal error - w/o this SSWeb and the IDL server
;were getting stuck.
CATCH,error_status & if error_status ne 0 then begin !ERROR=0 & return,astruct & endif


   if (ascope eq 'GLOBAL_SCOPE') OR (ascope eq 'GLOBAL_SCOPE_ASSUMED') then begin
      isglobal=1
      cdf_attget,CDFid,anum,0,aval & attval = aval ; get the global attribute
      for entry=1,maxe do begin ; get remaining entrys if any
         if (entry eq 1) then begin ; create array to hold the data
            asize = size(aval) & dtype = asize[n_elements(asize)-2]
            attval = make_array((maxe+1),TYPE=dtype) & attval[0] = aval
         endif
         cdf_attget,CDFid,anum,entry,aval
         attval[entry] = aval
      endfor
      asize = size(attval) & nea = n_elements(asize)
      if (asize[nea-2] eq 7) then begin
         if asize[0] eq 0 then attval = strtrim(attval,2) $
         else for i=0,asize[1]-1 do attval[i] = strtrim(attval[i],2)
      endif
      astruct = create_struct(aname,attval)
   endif else begin ; 'VARIABLE_SCOPE' or 'VARIABLE_SCOPE_ASSUMED'
      isglobal=0
      cdf_attget,CDFid,anum,vname,aval & attval = aval ; read variable attribute 
      if (spd_cdawlib_amI_istpptr(aname) eq 1) then begin ; check for pointer-type attribute

        ; attval = spd_cdawlib_read_myvariable(attval,CDFid,vary,ctype,recs)

         if (n_tags(atmp) gt 0) then to_column = spd_cdawlib_majority_check(CDFid=CDFid,buf=atmp) else $
            to_column = spd_cdawlib_majority_check(CDFid=CDFid)
         attval = spd_cdawlib_read_myvariable(attval,CDFid,vary,ctype,recs,set_column_major=to_column)
      endif

      asize = size(attval) & nea = n_elements(asize)
      ;TJK, 3/2/2000, restrict the strtrim calls below because some attributes
      ;values are actually variable names which may need to have any leading/trailing
      ;blanks in order to be found in the cdf...  this is certainly the case for
      ;depend and component variable attributes...

      if ((asize[nea-2] eq 7) and NOT(spd_cdawlib_ami_var(aname))) then begin
         if asize[0] eq 0 then attval = strtrim(attval,2) $
         else for i=0,asize[1]-1 do attval[i] = strtrim(attval[i],2)
      endif else begin
         if (spd_cdawlib_ami_var(aname)) then begin
         ;replace "bad characters" w/ a "$"
         table_index = where(table.varname eq attval, tcount)
         ttable_index = where(table.equiv eq attval, ttcount)
         vcount = -1 ;initialize
         if (table_index[0] eq -1) and (ttable_index[0] eq -1)then begin ;add this variable to the table
            if keyword_set(debug) then print, 'found new attribute adding to table, ',attval
	    tfree = where(table.varname eq '',fcount)
	    if (fcount gt 0) then begin
	       table.varname[tfree[0]] = attval
	    endif else begin
	       print, '1, Number of variables exceeds the current size of the table structure, please increase it, current size is ' 
;	       help, table.varname
	       return, -1
	    endelse
            table_index = where(table.varname eq attval, vcount)
         endif 

         if (vcount ge 0) then begin
      	    attval = spd_cdawlib_replace_bad_chars(attval, diff)
	    table.equiv[table_index[0]] = attval ;set equiv to either the
	    ;new changed name or the original
	    ;if it doesn't contain any bad chars..
         endif else begin
	    if (vcount eq -1) then begin ;already set in the table, assign attval to what's in equiv.
	       attval = table.equiv[table_index[0]]
	    endif
         endelse
      endif
   endelse
   astruct = create_struct(aname,attval)
endelse

return,astruct
end ;spd_cdawlib_read_myattribute

;+------------------------------------------------------------------------
; NAME: spd_cdawlib_read_mymetadata
; PURPOSE: 
; To read all of the attribute values for the requested variable, and
;       to return this information as an anonymous structure.
; CALLING SEQUENCE:
;       metadata = spd_cdawlib_read_mymetadata(vname,CDFid)
; INPUTS:
;       vname = string, name of variable whose metadata is being read
;       CDFid = integer, id of already opened CDF file
; KEYWORD PARAMETERS:
; OUTPUTS:
;       metadata = anonymous structure whose tags are the attribute names
;                  and whose fields are the corresponding attribute values.
; AUTHOR:
;       Richard Burley, NASA/GSFC/Code 632.0, Feb 13, 1996
;       burley@nssdca.gsfc.nasa.gov    (301)286-2864
; MODIFICATION HISTORY:
;
;-------------------------------------------------------------------------
FUNCTION spd_cdawlib_read_mymetadata, vname, CDFid

cinfo = cdf_inquire(CDFid) ; inquire about the cdf to get #attributes
; Create initial data structure to hold all of the metadata information
METADATA = create_struct('varname',vname)
; Extract all metadata information for the all attributes
nglobal=0
for anum=0,cinfo.natts-1 do begin
   astruct = 0 ; initialize astruct
   ; Get the name and value of the next attribute for vname
   astruct = spd_cdawlib_read_myattribute(vname,anum,CDFid,isglobal=isglobal)
   new_attr = string(tag_names(astruct),/print) ;reform to take the value out of array
   existing_attrs = tag_names(metadata)
   dups = where(new_attr eq existing_attrs, nfound)
   if (nfound eq 0) then begin
     nglobal=[nglobal,isglobal]
     METADATA = create_struct(temporary(METADATA),astruct)
  endif else print, 'spd_cdawlib_read_mymetadata: duplicate attribute skipped ', new_attr
endfor ; for each attribute

;4/2/2015 add the cdf's majority - needed for use in the new
;                                  spd_cdawlib_majority_check routine.

mtags = tag_names(METADATA)
maj=spd_cdawlib_tagindex('CDFMAJOR',mtags) 
if (maj[0] eq -1) then begin
;print, 'DEBUG adding the cdfmajor structure element for ', metadata.varname
  METADATA= create_struct(temporary(METADATA),'cdfmajor',cinfo.majority) 
  nglobal=[nglobal,1]
endif


;11/20/2007 TJK after all attributes are read and put in metadata
;structure, add one more attribute that's needed for appending the 
;data arrays from file to file (for THEMIS especially).  Add a 
;dim_sizes element.

status = cdf_varnum(CDFid,vname) ;check to see if this named variable exists

; RCJ 01/31/2008 Need to check for the existence of dim_sizes
; In cdfs generated by cdaweb, for example, they already exist in the structure
q=where(tag_names(metadata) eq 'DIM_SIZES')

if (status ne -1) and (q[0] eq -1) then begin
  cdf_control, CDFid, SET_ZMODE=2 ;set zmode so that we'll always get a .dim (default for R variables
  ;is a value for .dimvar (which is different than .dim)...
  vinfo = cdf_varinq(CDFid,vname) ; get the dim_size info. on this var.
  METADATA = create_struct(temporary(METADATA),'DIM_SIZES',vinfo.dim)
  nglobal=[nglobal,0] ;add this as a variable attribute [0]
endif

;
; CDAWeb's listing and write_mycdf s/w rely on the fact that 'fieldnam' is 
; the first of the var attrs. Occasionally (see dataset po_k0_hyd) the data cdf
; is such that 'fieldnam' is not the first of the var attrs. Rewritting the 
; structure and moving 'fieldnam' to the top seems to fix that problem.
; RCJ 11/05/03
;
cdaw_tnames=tag_names(metadata)

q0=where(cdaw_tnames eq 'FIELDNAM')
if q0[0] ne -1 then begin
   n0=where(nglobal eq 0, var_cnt) ; variable scope
   n1=where(nglobal eq 1, global_cnt) ; global scope
;print, 'number of global attrs ', global_cnt
;print, 'number of variable attrs ', var_cnt

;   if q0[0] ne n0[1] then begin ; if fieldnam is not the second 'variable scope' var.
             ; we do not compare q0[0] and n0[0] because n0[0] is 'varname's
       ; position. 'Fieldnam' should be the next one, n0[1]

   reorder = where(n1 gt q0[0], globals_after_vars) ;TJK 1/14/2016 added to further determine when to reorder
   if (q0[0] ne n0[1] or globals_after_vars gt 0) then begin ; if fieldnam is not the second 'variable scope' var.
             ; we do not compare q0[0] and n0[0] because n0[0] is 'varname's
       ; position. 'Fieldnam' should be the next one, n0[1]
             ;added test to see if there are global attributes AFTER Fieldnam, if so,
             ;need to reorder the attributes

      si=strtrim(n1[0],2)
      comm = "tmpstr=create_struct('varname',vname," ; first global attr  
      tmpstr=create_struct('varname', vname)
      if (global_cnt gt 0) then begin ;TJK 11/27 check if there are global attributes
        for ii=0,n_elements(n1)-1 do begin  ;do global attr first
           si=strtrim(n1[ii],2)
           ;print,si,' g ',cdaw_tnames[si]
           comm = comm + "cdaw_tnames["+si+"],metadata.("+si+"),"           
           spd_cdawlib_str_element, tmpstr, cdaw_tnames[si], metadata.(si), /add_replace
        endfor 
      endif
      si=strtrim(q0[0],2)
      comm=comm + "'FIELDNAM',metadata.("+si+"),"
      spd_cdawlib_str_element, tmpstr, 'FIELDNAM', metadata.(si), /add_replace
      for ii=0,n_elements(n0)-2 do begin  ;do variable attr now
         si=strtrim(n0[ii],2)
         ;print,si,' v ',cdaw_tnames[si]
         if cdaw_tnames[si] ne 'FIELDNAM' and cdaw_tnames[si] ne 'VARNAME' then begin
            comm = comm + "cdaw_tnames["+si+"],metadata.("+si+"),"      
            spd_cdawlib_str_element, tmpstr, cdaw_tnames[si], metadata.(si), /add_replace
         endif 
      endfor
      si=strtrim(n0[n_elements(n0)-1],2)  ; last variable attr
      comm = comm + "cdaw_tnames["+si+"],metadata.("+si+"))"
      spd_cdawlib_str_element, tmpstr, cdaw_tnames[si], metadata.(si), /add_replace
      ;s=execute(comm)
      metadata=tmpstr

   endif
endif
;
return,METADATA
end

;+------------------------------------------------------------------------
; NAME: spd_cdawlib_getvar_attribute_names CDFid
; PURPOSE: 
;	To return all of the attribute names for the requested variable, as
;	an array.
; CALLING SEQUENCE:
;       att_array = spd_cdawlib_getvar_attribute_names(vname,CDFid, ALL=ALL)
; INPUTS:
;       CDFid = integer, id of already opened CDF file
; KEYWORD PARAMETERS:
;	ALL - all attributes are returned
;	      default is that just variable scoped attributes are returned
; OUTPUTS:
;       att_array = string array of attribute names
; AUTHOR:
;       Tami Kovalick
;       tami.kovalick@gsfc.nasa.gov    (301)286-9422
; MODIFICATION HISTORY:
;
;-------------------------------------------------------------------------
FUNCTION spd_cdawlib_getvar_attribute_names, CDFid, ALL=ALL

cinfo = cdf_inquire(CDFid) ; inquire about the cdf to get #attributes
; Create initial data structure to hold all of the metadata information

; get the names of the attributes

;TJK 1/28/2003 change size because this won't work when data cdfs don't have
;any global attributes att_array = make_array(cinfo.natts-1,/string, value="")
;TJK 3/21/2003 - added a check for when there are no attributes in the data
;cdfs at all...

if (keyword_set(ALL)) then all = 1 else all = 0 ;add a keyword to get all attributes

if (cinfo.natts gt 0) then begin
  att_array = make_array(cinfo.natts,/string, value="")
  i = 0
  for anum=0,cinfo.natts-1 do begin
    cdf_attinq,CDFid,anum,aname,ascope,maxe,maxze ; inquire about the attribute
    if (((all eq 0) and (ascope eq 'VARIABLE_SCOPE') OR (ascope eq 'VARIABLE_SCOPE_ASSUMED')) or (all eq 1)) then begin
      aname = strtrim(aname,2) ; trim any possible leading or trailing blanks
      ;call spd_cdawlib_replace_bad_chars to replace any "illegal" characters in
      ;the attribute name w/ a legal one.  This was necessary for IDL 5.3.

      aname = spd_cdawlib_replace_bad_chars(aname,repchar="_",found)

      att_array[i] = aname
      i = i +1
    endif
  endfor ; for each attribute
endif else att_array = make_array(1, /string, value="-1")

return,att_array
end

;+------------------------------------------------------------------------
; NAME: spd_cdawlib_get_numallvars
; PURPOSE: 
; 	To return the total number of variables in the cdf.
;
; CALLING SEQUENCE:
;       num_vars = spd_cdawlib_get_numallvars(CNAME=CNAME)
; INPUTS:
; KEYWORD PARAMETERS:
;	CNAME = string, name of a CDF file to be opened and read
;	CDFid = integer, id of an already opened CDF file
; OUTPUTS:
;       num_vars = number of variables in the CDF
; AUTHOR:
;       Tami Kovalick, RITSS, October 27, 2000
; MODIFICATION HISTORY:
;
;-------------------------------------------------------------------------
FUNCTION spd_cdawlib_get_numallvars, CNAME=CNAME, CDFid=CDFid

; validate keyword combination and open cdf if needed
if keyword_set(CNAME) AND keyword_set(CDFid) then return,0 ; invalid
if keyword_set(CNAME) then CDFindex = CDF_OPEN(CNAME, /readonly) ; open the cdf
if keyword_set(CDFid) then CDFindex = CDFid ; save the cdf file number

; determine the number of variables 
cinfo = CDF_INQUIRE(CDFindex) ; inquire about number of variables
num_vars = cinfo.nvars + cinfo.nzvars
if keyword_set(CNAME) then CDF_close,CDFindex ; close the cdf
return, num_vars
end

;+------------------------------------------------------------------------
; NAME: spd_cdawlib_get_allvarnames
; PURPOSE: 
; 	To return a string array containing the names of all of the
;	variables in the given CDF file.
; CALLING SEQUENCE:
;       vnames = spd_cdawlib_get_allvarnames()
; INPUTS:
; KEYWORD PARAMETERS:
;	CNAME = string, name of a CDF file to be opened and read
;	CDFid = integer, id of an already opened CDF file
;       VAR_TYPE = string, only return the names for variables who have an
;                  attribute called 'VAR_TYPE' and whose value matches the
;                  value given by this keyword.  (ex. VAR_TYPE='data')
; OUTPUTS:
;       vnames = string array of variable names
; AUTHOR:
;       Richard Burley, NASA/GSFC/Code 632.0, Feb 13, 1996
;       burley@nssdca.gsfc.nasa.gov    (301)286-2864
; MODIFICATION HISTORY:
;	4/9/1998 - TJK modified to include all variable when the "var_type"
;	keyword isn't used.  The original code only included variables
;	that vary by record so some important "support_data" variables
;	were being thrown out.
;-------------------------------------------------------------------------
FUNCTION spd_cdawlib_get_allvarnames, CNAME=CNAME, CDFid=CDFid, VAR_TYPE=VAR_TYPE

; validate keyword combination and open cdf if needed
if keyword_set(CNAME) AND keyword_set(CDFid) then return,0 ; invalid
if keyword_set(CNAME) then CDFindex = CDF_OPEN(CNAME, /readonly) ; open the cdf
if keyword_set(CDFid) then CDFindex = CDFid ; save the cdf file number

; determine the number of variables 
cinfo = CDF_INQUIRE(CDFindex) ; inquire about number of variables
numvars = cinfo.nvars + cinfo.nzvars 
;vnames=strarr(numvars)
vnames=''

; Set up an error handler
CATCH, Error_status
if Error_status ne 0 then begin
   if keyword_set(CNAME) then cdf_close,CDFindex
   print, "STATUS= Error reading CDF. "
   print,!ERR_STRING, "spd_cdawlib_get_allvarnames.pro" & return,-1
endif


; Get the name of every r variable
for i=0,cinfo.nvars-1 do begin
    ;TJK 5/9/2008 add code to determine the zmode, the call below 
    ;to read_myetadata changes the mode to 2, and you can't call
    ;cdf_varinq in zmode=2 w/o the /zvariable keyword set...
    ;This is only a problem w/ cdfs that have R variables, e.g. po_k0_uvi
    cdf_control, CDFindex, GET_ZMODE=mode ;get zmode

   if (mode gt 0) then  vinfo = CDF_VARINQ(CDFindex,i,/ZVARIABLE) else $
   vinfo = CDF_VARINQ(CDFindex,i)
   if keyword_set(VAR_TYPE) then begin ; only get VAR_TYPE='data', for example
      ; RCJ 01/14/2013  Mabye this approach works better? My experience is that,
      ; because mode changes when spd_cdawlib_read_mymetadata is called, I did not get all
      ; requested vars back when all=2 (all 'data' types) in the call to spd_cdawlib_read_mycdf.
      cdf_attget,CDFindex,'VAR_TYPE',vinfo.name,attgot
      if ((attgot eq VAR_TYPE) and (vinfo.recvar eq 'VARY')) then vnames=[vnames,vinfo.name]
      ;metadata = spd_cdawlib_read_mymetadata(vinfo.name,CDFindex)
      ;tags = tag_names(metadata) & temp = where(tags eq 'VAR_TYPE',count)
      ;if count ne 0 then begin
      ;   if metadata.VAR_TYPE eq VAR_TYPE then vnames[i] = vinfo.name
      ;endif
   endif else begin 
      ;vnames[i] = vinfo.name
      vnames=[vnames,vinfo.name]
   endelse
endfor


; Get the name of every z variable
for j=0,cinfo.nzvars-1 do begin
   vinfo = CDF_VARINQ(CDFindex,j,/ZVARIABLE)
   if keyword_set(VAR_TYPE) then begin ; only get VAR_TYPE='data'
      ; RCJ 01/14/2013  Same argument as above (see RCJ 01/14/2013)
      cdf_attget,CDFindex,'VAR_TYPE',vinfo.name,attgot
      if ((attgot eq VAR_TYPE) and (vinfo.recvar eq 'VARY')) then vnames=[vnames,vinfo.name]
      ;metadata = spd_cdawlib_read_mymetadata(vinfo.name,CDFindex)
      ;;tags = tag_names(metadata)  
      ;temp = where(tag_names(metadata) eq 'VAR_TYPE',count)
      ;if count ne 0 then begin
      ;   if metadata.VAR_TYPE eq VAR_TYPE then vnames[j+cinfo.nvars] = vinfo.name
      ;endif
   endif else begin
      ;vnames[j+cinfo.nvars] = vinfo.name 
      vnames=[vnames,vinfo.name] 
   endelse
endfor

if keyword_set(CNAME) then CDF_CLOSE,CDFindex
;  RCJ 01/14/2013  Not needed since we are appending values to the array.
; strip blank vnames from the array
;v = where(vnames ne "",vc)
;if vc gt 0 then begin
;   temp = strarr(vc) & temp = vnames[v] & vnames = temp
;endif

;return,vnames
;  RCJ 01/14/2013  Changed this because we are appending values to the array.
return,vnames[1:*]
end
;---------------------------------------------------------------------------
 
function spd_cdawlib_write_fill, vn_sdat, burley, tmp_str

;v_err='ERROR=Instrument off; fillval=dat'
v_stat='STATUS=Instrument off for variable '+vn_sdat+'.  Re-select variable or time. '
atags=tag_names(burley.(0))
b0 = spd_cdawlib_tagindex('LOGICAL_SOURCE',atags)
b1 = spd_cdawlib_tagindex('LOGICAL_FILE_ID',atags)
b2 = spd_cdawlib_tagindex('Logical_file_id',atags)
if (b0[0] ne -1) then  psrce = strupcase(burley.(0).LOGICAL_SOURCE)
if (b1[0] ne -1) then $ 
   psrce = strupcase(strmid(burley.(0).LOGICAL_FILE_ID,0,9))
if (b2[0] ne -1) then $     
   psrce = strupcase(strmid(burley.(0).Logical_file_id,0,9))
v_data='DATASET='+psrce
; Reduce the number of reported errors to the developers RTB 1/97
;tmp_str=create_struct('DATASET',v_data,'ERROR',v_err,'STATUS',v_stat)
tmp_str=create_struct('DATASET',v_data,'STATUS',v_stat)
ikill=1

return, ikill
end
;------------------------------------------------------------------------------------

;This function checks to make sure a given variables 'varname' attribute 
;actually matches its structure members name.
;
function spd_cdawlib_correct_varname, struct, varnames, index

;TJK 09/29/00 Put in a check to make the varname attribute value match
;its variables structure tag name - if it doesn't spd_cdawlib_list_mystruct won't work...
;This is all necessary for the upgrade to IDL5.3
str_index = strtrim(string(index),2) ;convert to string
;comm = execute('att_names = tag_names(struct.('+str_index+'))')
att_names = tag_names(struct.(str_index))
;if (comm eq 1) then begin
   att_v = where(att_names eq 'VARNAME', att_cnt)
   if (att_cnt gt 0) then begin
      ;assign the variable name to the "VARNAME" attribute for this variable...
      ;assign_string = 'struct.'+varnames(index)+'.('+strtrim(string((att_v[0])),2)+')='''+varnames(index)+'''
      assign_string = 'struct.('+str_index+').('+strtrim(string((att_v[0])),2)+')='''+varnames[index]+'''
      struct.(str_index).(strtrim(string((att_v[0])),2))=varnames[index]
      ;print, 'assign_string = ',assign_string
      ;comm = execute(assign_string)
      ;if (comm ne 1) then print, 'execute failed for ',assign_string 
   endif
;endif ;end TJK mod 09/29/00

return, struct
end
;------------------------------------------------------------------------------------

function spd_cdawlib_find_var, CDFid, variable
;Look in the current data cdf and return the actual correct spelling 
;of this variable (called only when one doesn't exist).
;This can occur when the master has a variable like "Epoch" (which many 
;of the datasets data files have, but then for whatever reason, some of the
;data files have the epoch variable spelled as "EPOCH"... which in CDF 
;land is not the same variable (variable names are case sensitive)!

cinfo = CDF_INQUIRE(CDFid) ; inquire about number of variables
numvars = cinfo.nvars + cinfo.nzvars
for j=0,numvars-1 do begin
   vinfo = CDF_VARINQ(CDFid,j,/ZVARIABLE)
   caps = strupcase(strtrim(vinfo.name,2)); trim blanks and capitalize
   in_caps = strupcase(strtrim(variable,2)); trim blanks and capitalize
   match = where(caps eq in_caps,match_cnt)
   if (match_cnt gt 0) then begin
	print, variable,' match found = ',vinfo.name, ' returning...'
	return, vinfo.name
   endif
endfor

return, -1 ;no match found
end

;------------------------------------------------------------------------------------

function spd_cdawlib_find_epochvar, CDFid
;Look in the current data cdf and return the actual correct spelling 
;of this epoch variable (called only when one doesn't exist).
;This occurs when the master has depend0 = "Epoch" (which many of the datasets
;data files have, but then for whatever reason, a data file has
;the epoch variable spelled as "EPOCH"... which in CDF land is not a match!

cinfo = CDF_INQUIRE(CDFid) ; inquire about number of variables
numvars = cinfo.nvars + cinfo.nzvars
for j=0,numvars-1 do begin
;print, 'in spd_cdawlib_find_epochvar'
   vinfo = CDF_VARINQ(CDFid,j,/ZVARIABLE)
   caps = strupcase(strtrim(vinfo.name,2)); trim blanks and capitalize
   match = where(caps eq 'EPOCH',match_cnt)
   if (match_cnt gt 0) then begin
	;print, 'epoch match found = ',vinfo.name, ' returning...'
	return, vinfo.name
   endif
endfor

return, -1 ;no match found
end
;----------------------------------------------------------

;Function spd_cdawlib_merge_metadata
;Merge the master and the 1st data cdf's attributes when some of the
;master's attribute values are intensionally left blank.
;This function was originally conceived to accommodate ACE's concerns
;about including the most appropriate metadata with our listings.
;But will likely be used for other datasets/projects.
;
;Written by Tami Kovalick, QSS, 4/8/2005
;
function spd_cdawlib_merge_metadata, cnames, base_struct, all=all
;
;Mods: 12/7/2005 by TJK
;Had to change how I dealt w/ multiple element attributes
;originally I just appended elements together so I didn't have to
;remake the variable structure.  But listing didn't like character
;strings that were so long.  So this routine basically re-builds the
;data structure for every variable just to include multi-element attributes.
;These changes were prompted by "blanking" out many of the global attributes
;in the cluster masters.

; Set up an error handler
CATCH, Error_status
if Error_status ne 0 then begin
   if keyword_set(CNAMES) then cdf_close,data_CDFid
   print,!ERR_STRING, " in spd_cdawlib_merge_metadata" 
   return, burley ;probably not a critical error, just return the buffer
endif

status = 0
;do this merge if we have more than two cdfs specified and the 1st one is a master
if ((n_elements(cnames) ge 2) and strpos(cnames[0],'00000000') ne -1) then begin  

      data_CDFid = cdf_open(cnames[1], /readonly) 
      ; RCJ 01/14/2013   spd_cdawlib_get_allvarnames needs to know the value of 'all'.
      ;data_vnames = spd_cdawlib_get_allvarnames(CDFid=data_CDFid)
      if keyword_set(ALL) then begin
         if all eq 1 then data_vnames = spd_cdawlib_get_allvarnames(CDFid=data_CDFid)
         if all eq 2 then data_vnames = spd_cdawlib_get_allvarnames(CDFid=data_CDFid,var_type='data')
      endif else data_vnames = spd_cdawlib_get_allvarnames(CDFid=data_CDFid)

      atmp = spd_cdawlib_read_mymetadata(data_vnames[0], data_CDFid)
      dnames=tag_names(atmp)
      data_attr=where(dnames eq 'FIELDNAM') ; this is the break between global and variable attributes

      bnames=tag_names(base_struct.(0))
      base_attr=where(bnames eq 'FIELDNAM') ; this is the break between global and variable attributes

      tpnames=tag_names(base_struct) 
      cpy_struct = 0 ; initialize a variable that will contain our new structure filled below

      ;compare atmp values w/ base_struct

      if (base_attr[0] gt 0 and data_attr[0] gt 0) then begin ;we have global attributes to look at
       for vars = 0, n_tags(base_struct) - 1 do begin

;	  for bnum = 0, base_attr[0]-1 do begin

	  for bnum = 0, n_elements(bnames)-1 do begin ;have to do all attributes now
;           ;if attributes are variable_scope
            if (bnum ge base_attr) then begin
		  ;1st in structure (highly unlikely)
		 if (bnum eq 0) then new_struct = create_struct(bnames[bnum],base_struct.(vars).(bnum)) else $
			 new_struct = create_struct(temporary(new_struct), bnames[bnum],base_struct.(vars).(bnum))
	   ;if attributes are global_scope 
	   endif else begin
		if (base_struct.(vars).(bnum)[0] ne '') then begin ;global attribute isn't blank in master...
              	;if 1st attribute 
              		if (bnum eq 0) then new_struct = create_struct(bnames[bnum],base_struct.(vars).(bnum)) else $
                	new_struct = create_struct(temporary(new_struct), bnames[bnum],base_struct.(vars).(bnum))		
	        endif else begin ;attribute IS blank in master get value for data cdf
	        ;**** have to match up the tag names so get the values in the right places.
	        s = where(dnames eq bnames[bnum], wc)
;	print, 'DEBUG1 current master attribute ',bnames[bnum]
	          if (wc gt 0) then begin
;	print, 'DEBUG2 found in data ',bnames[bnum]
		    if (atmp.(s[0])[0] ne '') then begin
;		      print, 'DEBUG Setting missing attribute value ', bnames[bnum], ' = ',atmp.(s[0]), ' from value found in 1st data cdf'
                        if (n_tags(new_struct) eq 0) then begin
                          new_struct = create_struct(bnames[bnum],atmp.(s[0]))
                        endif else begin
                          new_struct = create_struct(temporary(new_struct), bnames[bnum],atmp.(s[0]))
                        endelse
		    endif ;value is good in data cdf
		  endif ; found an attribute match between data and master
               endelse ;attribute value is blank
	     endelse ;attribute is global scope
	   endfor	

	   if (n_tags(cpy_struct) eq 0) then cpy_struct = create_struct(tpnames[vars],new_struct) else $
		cpy_struct = create_struct(temporary(cpy_struct),tpnames[vars],new_struct)
       endfor
       ; RCJ 12/13/05  wind 3dp data has no global or var attributes
       ; so data_attr(0) = -1 and we get here. We still want
       ; to return the structure so make cpy_struct=base_struct :
      endif else cpy_struct = temporary(base_struct)
      cdf_close,data_CDFid
  endif else cpy_struct = temporary(base_struct)
return, cpy_struct
end

;uniq_array takes two string arrays (like lists of variable names)
;and doesn't modify the 1st, but adds the second to the 1st w/o adding
;any duplicates.
function spd_cdawlib_unique_array, first, second
   x = where(second ne '',xcnt)
   if (xcnt gt 0) then begin
     second = second[x]
     u_s_index = uniq(second, sort(second))
     for s=0,n_elements(u_s_index)-1 do begin
        for u=0,n_elements(first)-1 do begin
          if (first[u] eq second[u_s_index[s]]) then  begin
             print, first[u], second[u_s_index[s]]
             second[u_s_index[s]] = ' '
          endif
        endfor
      endfor
      t = where(second ne ' ',tcnt)
      if (tcnt gt 0) then first = [first,second[t]] ;append sorted/uniqed
   endif
return, first
end

;+------------------------------------------------------------------------

; RCJ 03/30/2012  Commented out this function. It was called once and that
;  call is commented out too.
;;check the variables_comp array for existence of the variable name, for
;;the current cdf.
;function check_varcompare, variables_comp, cdf_index, variable_name
;;print,'**** ' & help,variables_comp
;;print, variable_name, cdf_index, variables_comp
;;stop;
;x = where(variable_name eq variables_comp(cdf_index,*), xcnt) 
;if (xcnt gt 0)then print, variable_name, ' found 1' else print, variable_name, ' not found 0'
;if (xcnt gt 0)then return, 1 else return, 0
;end

;+------------------------------------------------------------------------
; NAME: spd_cdawlib_read_mycdf
; PURPOSE: 
;	Read all data and metadata for given variables, from given CDF
;       files, and return all information in a single anonymous structure
;       of the form: 
;          structure_name.variable_name.attribute_name.attribute_value
;
; CALLING SEQUENCE:
;       out = spd_cdawlib_read_mycdf(vnames,cnames)
; INPUTS:
;       vnames = string, array of variable names or a single string of
;                names separated by a comma.  (ex. 'Epoch,Magfld,Bmax')
;       cnames = string, array of CDF filenames or a single string of
;                names separated by a comma.
; KEYWORD PARAMETERS:
;	ALL = 0: get data and metadata for requested variable(s) only.
;             1: get data and metadata for ALL variables in the CDFs.
;             2: get data and metadata for all var_type='data' variables.
;       NODATASTRUCT = If set, instead of returning the data for each variable
;                   in the 'DAT' attribute field, create a 'HANDLE' field
;                   and set it to the handle id of a data handle which
;                   holds the data for each variable.
;       NOQUIET = If set, do NOT set the !QUIET system variable before
;                 reading the cdf file(s).
;       DEBUG = If set, print out some progress information during reading.
;	TSTART = epoch starting value - YYYYMMDD etc. string.
;	TSTOP = epoch ending value - YYYYMMDD etc. string.
; OUTPUTS:
;       out = anonymous structure holding all data and metadata for the
;             requested variables. If an error occurs, that we know how
;             to deal w/, an alternate structure is returned, its structure
;	      is as follows: ('DATASET',d_set,'ERROR',v_err,'STATUS',v_stat)
;	      
; AUTHOR:
;       Richard Burley, NASA/GSFC/Code 632.0, Feb 13, 1996
;       burley@nssdca.gsfc.nasa.gov    (301)286-2864
; MODIFICATION HISTORY:
;	Tami Kovalick, HSTX, 12/16/96 modified to verify whether 
; variables requested in vnames array are actually in the "data" cdfs 
; prior to requesting the data from these variables.  If variables 
; aren't valid then they are removed from the vnames array and the 
; code continues on to create a valid structure.
;	Tami Kovalick, HSTX, 12/20/96 modified to allow the use of 
; TSTART and TSTOP keywords (see above).  Use of these keywords will
; force the code to only read the necessary records in the CDF, otherwise
; the code will read the entire CDF.  Could enhance the code to deal
; w/ one or the other keyword - right now they are only used if both
; are set.
;	Tami Kovalick, RSTX, 02/13/98, Carrie Gallap started modifications
; to spd_cdawlib_read_mycdf to accommodate "virtual variables" (VV) .  Tami finished 
; up the code and made corrections to several sections.  One new routine was
; written spd_cdawlib_add_mycomponents, this routine is called when a valid virtual
; variable is found in order to add any additional variables needed for
; actually generating the data for the VV.  The routine looks for variable
; attributes w/ the naming convention COMPONENT_n where n is a digit.  The
; basic methodology to the changes is to determine whether any of the
; variables selected are virtual variables, if so then the variable name
; and the source (where the VV was defined - master or data cdfs) are
; stored in a structure called vir_vars, then add the component variables
; to the vnames array.  Do the usual checking to see if the variables requested
; in vnames actually exist. Then continue on w/ getting the metadata for all
; variables (including VV), and continue on w/ the getting the data from
; the CDFs for all variables except the VV.  Population of the VV's data field
; in the "burley" structure are handled at the very end in a case statement 
; which looks for each VV's variable attribute FUNCTION to determine which 
; actual "IDL function" to call, ie. spd_cdawlib_conv_pos.
;-------------------------------------------------------------------------

FUNCTION spd_cdawlib_read_mycdf, vnames, cnames, ALL=ALL,NODATASTRUCT=NODATASTRUCT, $
                                     NOQUIET=NOQUIET,DEBUG=DEBUG, $
				     TSTART=TSTART, TSTOP=TSTOP, $
START_MSEC=START_MSEC, STOP_MSEC=STOP_MSEC, START_USEC=START_USEC, $ 
STOP_USEC=STOP_USEC, START_NSEC=START_NSEC, STOP_NSEC=STOP_NSEC, $
START_PSEC=START_PSEC, STOP_PSEC=STOP_PSEC, NOVIRTUAL=NOVIRTUAL


compile_opt idl2
if (!version.release ge '8.0') then CDF_SET_VALIDATE, /no  ;turn off CDF validation

; establish exception handler to trap errors from all sources.

CATCH,error_status
if (error_status ne 0) then begin
   print,!ERR_string ," Trapped in spd_cdawlib_read_mycdf."; output description of error
   print,'Error Index=',error_status
   ;also need to check for -123 for IDL 5.02, -98 is for IDL 4.01b - TJK 1/23/98
   ;added check for -134 out of memory in IDL5.3
   ; added check for the string "unable to allocate memory", since IDL seems
   ; to change the error number associated w/ this w/ each release
   if ((strpos(!ERR_string, "Unable to allocate memory") gt -1) or error_status eq -98 or error_status eq -123 or error_status eq -124 or error_status eq -134) then begin
      val_err="ERROR=Memory Exceeded; -98 or -123 or -124 or -134 or -151"
      val_stat="STATUS=Time range selected generates array which exceeds available system resources. Re-select a smaller time range."
      ;
      if (n_elements(mydata) ne 0) then begin
         atags=tag_names(mydata.(0))
         b0 = spd_cdawlib_tagindex('LOGICAL_SOURCE',atags)
         b1 = spd_cdawlib_tagindex('LOGICAL_FILE_ID',atags)
         b2 = spd_cdawlib_tagindex('Logical_file_id',atags)
         if (b0[0] ne -1) then  psrce = strupcase(mydata.(0).LOGICAL_SOURCE)
         if (b1[0] ne -1) then $
            psrce = strupcase(strmid(mydata.(0).LOGICAL_FILE_ID,0,9))
         if (b2[0] ne -1) then $
            psrce = strupcase(strmid(mydata.(0).Logical_file_id,0,9))
         v_data='DATASET='+psrce
      endif else begin
         parts=str_sep(cnames[cx],'/')
         piece=strupcase(str_sep(parts[n_elements(parts)-1],'_'))
         tempnm= piece[0]+'_'+piece[1]+'_'+piece[2]
         val_data="DATASET="+tempnm
      endelse
      tmpstr=create_struct('DATASET',val_data,'ERROR',val_err,'STATUS',val_stat)
      return, tmpstr
  endif 
  ; User Error.  MESSAGE trigered an error in another part of the program. 
  ; Uses !ERR_STRING as the text of the error message.
  ; Ron Yurow (Nov 10, 2016)
  IF  (error_status eq -5) THEN BEGIN
      ; Find the name of the data set.
      parts = STR_SEP (cnames[cx],'/')
      piece = STRUPCASE (STR_SEP (parts[n_elements(parts)-1], '_'))
      tempnm = piece[0] + '_' + piece [1] + '_' + piece [2]

      ; Get the error message
      msg = spd_cdawlib_get_cdf_msg ()
         
      ; Set up values we will used to populate the error structure.
      val_data= "DATASET=" + tempnm
      val_msg = "STATUS="  + msg

      ; Create an error structure to return.
      err_struct = CREATE_STRUCT ('DATASET', val_data, 'STATUS', val_msg)

      RETURN, err_struct
  ENDIF
  return,-1 ; return failure flag
endif

if keyword_set(DEBUG) then debug = 1 else debug=0

need_timeslice = 0L ;initialize

; Validate cnames parameter, remove .cdf extensions if present
s = size(cnames) & ns = n_elements(s)
if (s[ns-2] eq 7) then begin
   if (s[0] eq 0) then cnames = spd_cdawlib_break_mystring(cnames,DELIMITER=',')
   for i=0,n_elements(cnames)-1 do begin
      j=strpos(cnames[i],'.cdf') & if (j eq -1) then j=strpos(cnames[i],'.CDF')
      if (j ne -1) then cnames[i] = strmid(cnames[i],0,j)
   endfor
endif else begin
   print,'ERROR=CDF filenames must be given as strings.' & return,-1
endelse
if keyword_set(DEBUG) then print,'Number of CDFs to read=',n_elements(cnames)

quiet_flag = !quiet ; save current state of quiet flag
if not keyword_set(NOQUIET) then !quiet=1 ; turn off annoying cdf messages
;print, 'Announcement of annoying CDF messages = ', !quiet

;TJK setup a structure called table to hold the variable name as they are in
;the cdf and then an 'equivalent' name if the real variable name turned out to 
;contain "illegal characters", e.g. "!,@,#" etc..

common global_table, table
;TJK 03/15/2010 - check for the max number of variables between the
;                 master and a datacdf (if there is a
;                 master)... sometimes the master has fewer (like w/
;                 sta_l1_mag_rtn) which then causes a problem.
if (n_elements(cnames) gt 1) then num_vars = max([spd_cdawlib_get_numallvars(CNAME=cnames[0]), spd_cdawlib_get_numallvars(CNAME=cnames[1])]) else $
num_vars = spd_cdawlib_get_numallvars(CNAME=cnames[0])
var_names = strarr(num_vars)
total_storage_time = 0L
;varname will contain the real cdf variable name(s)
;equiv will contain the "fake" one(s)
table = create_struct('varname',var_names,'equiv',var_names)


; If the ALL keyword is set then get names of all data variables
; RCJ 11/21/2003  Added another option for 'all'. Now if all=0: read requested
;   var(s);  if all=1: read all vars;  if all=2: read all 'data' vars
if keyword_set(ALL) then begin
   if all eq 1 then vnames = spd_cdawlib_get_allvarnames(CNAME=cnames[0])
   if all eq 2 then vnames = spd_cdawlib_get_allvarnames(CNAME=cnames[0],var_type='data')
endif

variables_read = make_array(n_elements(cnames),num_vars,/string, value="")
;variables_comp = make_array(n_elements(cnames),num_vars,/string, value="")


;make a copy of the vnames in the orig_names array for use w/
;virtual variables and/or alternate views. TJK 2/4/98
orig_names = vnames

; RCJ 01/10/2005 Commented this part out. Call func
; spd_cdawlib_add_mydeltas instead.
;
;for cx=0,n_elements(cnames)-1 do begin
;   ; RCJ 08/25/2003 I was trying to save time with the 'if' below but the error
;   ; vars were not being read for cdfs created by write_mycdf since they don't
;   ; require a master cdf. 
;   ;if (strpos(cnames[cx],'00000000') ne -1) then begin  ;a master
;      CDFid = cdf_open(cnames[cx]) 
;        ;   
;	for nreq =0, n_elements(vnames)-1 do begin
;	    atmp = spd_cdawlib_read_mymetadata(vnames(nreq), CDFid)
;	    atags = tag_names(atmp)
;	    b0 = spd_cdawlib_tagindex('DELTA_PLUS_VAR', atags)
;	    if (b0(0) ne -1) then begin
;	       if (atmp.(b0(0)) ne '') then begin
;	          ; avoiding duplication:
;	          q=where(vnames eq atmp.(b0(0)))
;	          if q(0) eq -1 then vnames=[vnames,atmp.(b0(0))]
;	       endif	  
;	    endif
;	    b1 = spd_cdawlib_tagindex('DELTA_MINUS_VAR', atags)
;	    if (b1(0) ne -1) then begin
;	       if (atmp.(b1(0)) ne '') then begin
;	          ; avoiding duplication:
;	          q=where(vnames eq atmp.(b1(0)))
;	          if q(0) eq -1 then vnames=[vnames,atmp.(b1(0))]
;	       endif
;	    endif
;	 endfor 
;      cdf_close,CDFid	   
;   ;endif
;endfor
;
;
; Validate vnames parameter.  May be a strarr or single string
s = size(vnames) & ns = n_elements(s)
if (s[ns-2] eq 7) then begin
   if (s[0] eq 0) then vnames = spd_cdawlib_break_mystring(vnames,DELIMITER=',')
endif else begin
   print,'ERROR=variable names must be given as strings.' & return,-1
endelse

;TJK 10/8/2003 - move this initialization up on the code so that
;inadvertent variables don't get added to the list.
;make a copy of the vnames in the orig_names array for use w/
;virtual variables and/or alternate views. TJK 2/4/98
;orig_names = vnames


;TJK - 12/16/96
; added this section of code to check whether the requested variables
;are actually in the CDFs (other than the master CDFs).  If not, take them
;out... and continue building the structure w/ the resultant variables.
 
rcount = n_elements(vnames)
num_virs = -1 ; keep counter of number of virtual variables found
virs_found = 0L ;TJK 11/28/2006 set a flag, so that if virtual variables are found in the master, 
                ;don't check in the data cdf.
;create a structure to contain the virtual variable name and whether
;the variable was found in the master or in a data CDF, set to
;0 or 1 respectively.
; Added arbitrary # of 10 to structure; need space for vv depends  RTB  3/98
;TJK 11/16/2006 - increase the size of the vir_vars structure because
;                 we have some datasets (THEMIS all sky imagers) that
;                 define many virtual variable depends, so set array
;                 to the total number of variables in the cdf.
;n_tmp = strarr(n_elements(vnames)+10) ; initialize it
;m_tmp = make_array(n_elements(vnames)+10,/integer, value=-1)
n_tmp = strarr(num_vars) ; initialize it
m_tmp = make_array(num_vars,/integer, value=-1)
vir_vars= create_struct('name',n_tmp,'flag',m_tmp)
; RCJ 09/19/05  We are going to use the isis_flag for alouette-2 data too.
isis_flag = 0
for cx=0,n_elements(cnames)-1 do begin
   if (rcount gt 0) then begin
      ; Open the CDF and inquire about global information about file
      if (debug) then print,'Verifying variables in ',cnames[cx]
      CDFid = cdf_open(cnames[cx], /readonly) 
      cinfo = cdf_inquire(CDFid)
      ; if there is a master, look there for virtual variables that may not
      ; be defined in the actual cdfs...
      if (strpos(cnames[cx],'00000000') ne -1) then begin  ;a master
	 ;
	 if (debug) then print, 'checking ',cnames[cx], ' for Virtual variables';
         ;read the metadata for the variables requested from the master...	
         vdep_cnt=0;
	 ; RCJ 04/18/2003 Going to concatenate the strings instead of limiting
	 ; their number to 20. At the end we take: chkvv_dep=chkvv_dep[1:*]
         ;chkvv_dep=strarr(20)
         chkvv_dep=''

         ;  RCJ 08Nov2016  Added this for loop to look for vars not initially added to the structure atmp.
	 ;                 These are, for example, a comp0 of a VV which is the dep2 of a comp0 to the requested
	 ;                 var which, of course, is a VV.  These are too many levels past the requested var and 
	 ;                 not added to the vnames array by calls to spd_cdawlib_add_mycomponents, spd_cdawlib_add_mydepends or spd_cdawlib_add_mydeltas
	 ;                 in the main for loop a few lines below.
         for nreq =0, n_elements(vnames)-1 do begin
	    atmp = spd_cdawlib_read_mymetadata(vnames[nreq], CDFid)
	    spd_cdawlib_add_mycomponents,atmp,vnames
	    spd_cdawlib_add_mydepends,atmp,vnames
	    spd_cdawlib_add_mydeltas,atmp,vnames
	 endfor
         ;
         for nreq =0, n_elements(vnames)-1 do begin
	    atmp = spd_cdawlib_read_mymetadata(vnames[nreq], CDFid)
	    spd_cdawlib_add_mydeltas,atmp,vnames
	    atags = tag_names(atmp)
            ;TJK 09/28/2001 add code to flag whether we're looking at an ISIS mission, if so set
            ; a flag that's used lower down.  We need to check here in the master instead of in
            ; the data cdfs because lots of data cdf's don't have a mission_group global attribute.
	    b0 = spd_cdawlib_tagindex('MISSION_GROUP', atags)
	    if (b0[0] ne -1) then begin
	 	if ((strupcase(atmp.mission_group[0]) eq 'ISIS') or $
	           (strupcase(atmp.mission_group[0]) eq 'ALOUETTE')) $
		then isis_flag = 1
	 	;if (strupcase(atmp.mission_group(0)) eq 'ISIS') then isis_flag = 1
            endif
;TJK 11/23/2005 add logic to look for virtual depend variables related
;to "regular" variables... for some reason we haven't needed this till
;now!
            b1 = spd_cdawlib_tagindex('DEPEND_0', atags)
            if (b1[0] ne -1 ) then begin
	       if (atmp.depend_0 ne '') then begin
	           num = where(chkvv_dep eq atmp.depend_0, cnt)
	           if (cnt eq 0) then begin
		      chkvv_dep=[chkvv_dep,atmp.depend_0]
                      vdep_cnt=vdep_cnt+1
                   endif
	       endif
	    endif
            b1 = spd_cdawlib_tagindex('DEPEND_1', atags)
            if (b1[0] ne -1 ) then begin
	        atmp_dep1=atmp.depend_1
		; RCJ 05/16/2013 ok, but if alt_cdaweb_depend_1 exists, use it instead:
	        q=spd_cdawlib_tagindex('ALT_CDAWEB_DEPEND_1', atags)
		if q[0] ne -1 then if (atmp.alt_cdaweb_depend_1 ne '') then atmp_dep1=atmp.alt_cdaweb_depend_1
                ;if (atmp.depend_1 ne '') then begin
                if (atmp_dep1 ne '') then begin
	            if q[0] ne -1 then num = where(chkvv_dep eq atmp.alt_cdaweb_depend_1, cnt) else num = where(chkvv_dep eq atmp.depend_1, cnt)
	            if (cnt eq 0) then begin
                        if q[0] ne -1 then chkvv_dep=[chkvv_dep,atmp.alt_cdaweb_depend_1] else chkvv_dep=[chkvv_dep,atmp.depend_1]
                        vdep_cnt=vdep_cnt+1
                    endif
                endif
            endif
            b1 = spd_cdawlib_tagindex('DEPEND_2', atags)
	    if (b1[0] ne -1 ) then begin
	        atmp_dep2=atmp.depend_2
		; RCJ 05/16/2013 ok, but if alt_cdaweb_depend_1 exists, use it instead:
	        q=spd_cdawlib_tagindex('ALT_CDAWEB_DEPEND_2', atags)
	        if q[0] ne -1 then if (atmp.alt_cdaweb_depend_2 ne '') then atmp_dep2=atmp.alt_cdaweb_depend_2 
		;if (atmp.depend_2 ne '') then begin
		if (atmp_dep2 ne '') then begin
	            if q[0] ne -1 then num = where(chkvv_dep eq atmp.alt_cdaweb_depend_2, cnt) else num = where(chkvv_dep eq atmp.depend_2, cnt) 
                    if (cnt eq 0) then begin
 	               if q[0] ne -1 then chkvv_dep=[chkvv_dep,atmp.alt_cdaweb_depend_2] else chkvv_dep=[chkvv_dep,atmp.depend_2]
		       vdep_cnt=vdep_cnt+1
                    endif
	        endif
            endif
            b1 = spd_cdawlib_tagindex('DEPEND_3', atags)
	    if (b1[0] ne -1 ) then begin
	        atmp_dep3=atmp.depend_3
;		help,atmp_dep3
	        q=spd_cdawlib_tagindex('ALT_CDAWEB_DEPEND_3', atags)
	        if q[0] ne -1 then if (atmp.alt_cdaweb_depend_3 ne '') then atmp_dep3=atmp.alt_cdaweb_depend_3 
		if (atmp_dep3 ne '') then begin
	            if q[0] ne -1 then num = where(chkvv_dep eq atmp.alt_cdaweb_depend_3, cnt) else num = where(chkvv_dep eq atmp.depend_3, cnt) 
                    if (cnt eq 0) then begin
 	               if q[0] ne -1 then chkvv_dep=[chkvv_dep,atmp.alt_cdaweb_depend_3] else chkvv_dep=[chkvv_dep,atmp.depend_3]
		       vdep_cnt=vdep_cnt+1
                    endif
	        endif
            endif

;TJK 4/17/2008 adding check for deltas here otherwise those vars
;get thrown out below (needed this for voyager coho datasets
            b1 = spd_cdawlib_tagindex('DELTA_PLUS_VAR', atags)
	    if (b1[0] ne -1 ) then begin
	        if (atmp.delta_plus_var ne '') then begin
	            num = where(chkvv_dep eq atmp.delta_plus_var, cnt)
                    if (cnt eq 0) then begin
                        chkvv_dep=[chkvv_dep,atmp.delta_plus_var]
		        vdep_cnt=vdep_cnt+1
	            endif
	         endif
            endif
            b1 = spd_cdawlib_tagindex('DELTA_MINUS_VAR', atags)
	    if (b1[0] ne -1 ) then begin
	        if (atmp.delta_minus_var ne '') then begin
	             num = where(chkvv_dep eq atmp.delta_minus_var, cnt)
                     if (cnt eq 0) then begin
		         chkvv_dep=[chkvv_dep,atmp.delta_minus_var]
		         vdep_cnt=vdep_cnt+1
	             endif
	        endif
	    endif
;end of 4/17/2008 added check for deltas
;TJK 2/13/2015 remove extra blank element in index 0; leaving it in
;causes problems below w/ identifying virtual depends for virtual variables.
         if (vdep_cnt gt 0) then begin
            not_blank = where(chkvv_dep ne '', blank_cnt)
            if blank_cnt gt 0 then chkvv_dep = chkvv_dep[not_blank]
         endif
         
;help, chkvv_dep
;print, 'in between read variables and virtual section chkvv_dep array = ',chkvv_dep

;if (debug) then print, 'At bottom of new section = ',chkvv_dep

;TJK 11/23/2005 - end of new section, back to original section looking
;                 for virtual variables w/in virtual variables

	    b0 = spd_cdawlib_tagindex('VIRTUAL', atags)
            c0 = spd_cdawlib_tagindex('COMPONENT_0', atags) ;add check for component_0 value as well
            ;look through metadata and look for virtual variables...
            ; get components of the virtual variables and add them to the vnames  
            ; array...
;TJK 11/6/2009 add check for component_0 in order to determine if virtual
;variable definition is for real or not.
;               if (b0[0] ne -1 ) then begin
;                  if (strlowcase(atmp.VIRTUAL) eq 'true') then begin
            if ((b0[0] ne -1) and (c0[0] ne -1)) then begin
               if ((strlowcase(atmp.VIRTUAL) eq 'true') and (atmp.COMPONENT_0 ne '')) then begin
	          if (DEBUG) then print, 'Found a VV ',vnames[nreq],' in Master CDF.'
	          num_virs = num_virs + 1
                  vir_vars.name[num_virs] = vnames[nreq]
                  vir_vars.flag[num_virs] = 0 ;indicate this var found in master
	          if (DEBUG) then begin
                      print, 'found a VV ', vnames[nreq], ' in Master CDF.'
                      print, 'adding deltas and components next...'
                  endif

                  spd_cdawlib_add_mydeltas, atmp, vnames
	          spd_cdawlib_add_mycomponents, atmp, vnames

                  ; Check VV's depends for other VV's and add to list
                  ;TJK 11/98 added logic to only add the variable if it doesn't
                  ;already exist in the chkvv_dep list.
                  b1 = spd_cdawlib_tagindex('DEPEND_0', atags)
	          if (b1[0] ne -1 ) then begin
	             if (atmp.depend_0 ne '') then begin
	                num = where(chkvv_dep eq atmp.depend_0, cnt)
	                if (cnt eq 0) then begin
		           ;chkvv_dep(vdep_cnt)=atmp.depend_0
		           chkvv_dep=[chkvv_dep,atmp.depend_0]
		           vdep_cnt=vdep_cnt+1
	                endif
	             endif
	          endif
	          b1 = spd_cdawlib_tagindex('DEPEND_1', atags)
	          if (b1[0] ne -1 ) then begin
	             atmp_dep1=atmp.depend_1
		     ; RCJ 05/16/2013 ok, but if alt_cdaweb_depend_1 exists, use it instead:
	             q=spd_cdawlib_tagindex('ALT_CDAWEB_DEPEND_1', atags)
		     if (q[0] ne -1) then if (atmp.alt_cdaweb_depend_1 ne '') then atmp_dep1=atmp.alt_cdaweb_depend_1 
	             ;if (atmp.depend_1 ne '') then begin
                     if (atmp_dep1 ne '') then begin
			if (q[0] ne -1) then num = where(chkvv_dep eq atmp.alt_cdaweb_depend_1, cnt) else num = where(chkvv_dep eq atmp.depend_1, cnt)
	                if (cnt eq 0) then begin ;if not in the list already, add it
		           ;chkvv_dep[vdep_cnt]=atmp.depend_1
                           ;below still gets the value of alt_cdaweb_depehnd_1, even if it is blank, which we don't want.
                                ;if q[0] ne -1 then
                                ;chkvv_dep=[chkvv_dep,atmp.alt_cdaweb_depend_1]
                                ;else
                                ;chkvv_dep=[chkvv_dep,atmp.depend_1]
		           chkvv_dep=[chkvv_dep,atmp_dep1]
		           vdep_cnt=vdep_cnt+1
	                endif
	             endif
	          endif
	          b1 = spd_cdawlib_tagindex('DEPEND_2', atags)
	          if (b1[0] ne -1 ) then begin
	             atmp_dep2=atmp.depend_2
		     ; RCJ 05/16/2013 ok, but if alt_cdaweb_depend_2 exists, use it instead:
	             q=spd_cdawlib_tagindex('ALT_CDAWEB_DEPEND_2', atags)
		     if (q[0] ne -1) then if (atmp.alt_cdaweb_depend_2 ne '') then atmp_dep2=atmp.alt_cdaweb_depend_2 
	             ;if (atmp.depend_2 ne '') then begin
                     if (atmp_dep2 ne '') then begin
	                if (q[0] ne -1) then num = where(chkvv_dep eq atmp.alt_cdaweb_depend_2, cnt) else num = where(chkvv_dep eq atmp.depend_2, cnt)
                        if (cnt eq 0) then begin
		           ;chkvv_dep(vdep_cnt)=atmp.depend_2
                           ;below still gets the value of alt_cdaweb_depehnd_2, even if it is blank, which we don't want.
		           ;if q[0] ne -1 then chkvv_dep=[chkvv_dep,atmp.alt_cdaweb_depend_2] else chkvv_dep=[chkvv_dep,atmp.depend_2]
		           chkvv_dep=[chkvv_dep,atmp_dep2]
		           vdep_cnt=vdep_cnt+1
	                endif
	             endif
	          endif
	          b1 = spd_cdawlib_tagindex('DEPEND_3', atags)
	          if (b1[0] ne -1 ) then begin
	             atmp_dep3=atmp.depend_3
	             q=spd_cdawlib_tagindex('ALT_CDAWEB_DEPEND_3', atags)
		     if (q[0] ne -1) then if (atmp.alt_cdaweb_depend_3 ne '') then atmp_dep3=atmp.alt_cdaweb_depend_3 
                     if (atmp_dep3 ne '') then begin
	                if (q[0] ne -1) then num = where(chkvv_dep eq atmp.alt_cdaweb_depend_3, cnt) else num = where(chkvv_dep eq atmp.depend_3, cnt)
                        if (cnt eq 0) then begin
		           chkvv_dep=[chkvv_dep,atmp_dep3]
		           vdep_cnt=vdep_cnt+1
	                endif
	             endif
	          endif
                  ;TJK - 1/29/2001 add a check to see whether the component 
                  ; variables are virtual
	          b1 = spd_cdawlib_tagindex('COMPONENT_0', atags)
	          if (b1[0] ne -1 ) then begin
	             if (atmp.component_0 ne '') then begin
	                num = where(chkvv_dep eq atmp.component_0, cnt)
                        if (cnt eq 0) then begin
		           ;chkvv_dep(vdep_cnt)=atmp.component_0
		           chkvv_dep=[chkvv_dep,atmp.component_0]
		           vdep_cnt=vdep_cnt+1
	                endif
	             endif
	          endif
                  ;TJK - 1/27/2009 add a check to see whether the component_1
                  ; variables are virtual
	          b1 = spd_cdawlib_tagindex('COMPONENT_1', atags)
	          if (b1[0] ne -1 ) then begin
	             if (atmp.component_1 ne '') then begin
	                num = where(chkvv_dep eq atmp.component_1, cnt)
                        if (cnt eq 0) then begin
		           ;chkvv_dep(vdep_cnt)=atmp.component_1
		           chkvv_dep=[chkvv_dep,atmp.component_1]
		           vdep_cnt=vdep_cnt+1
	                endif
	             endif
	          endif
                  ;TJK - 1/27/2009 add a check to see whether the component_2 
                  ; variables are virtual
	          b1 = spd_cdawlib_tagindex('COMPONENT_2', atags)
	          if (b1[0] ne -1 ) then begin
	             if (atmp.component_2 ne '') then begin
	                num = where(chkvv_dep eq atmp.component_2, cnt)
                        if (cnt eq 0) then begin
		           ;chkvv_dep(vdep_cnt)=atmp.component_2
		           chkvv_dep=[chkvv_dep,atmp.component_2]
		           vdep_cnt=vdep_cnt+1
	                endif
	             endif
	          endif
	          b1 = spd_cdawlib_tagindex('DELTA_PLUS_VAR', atags)
	          if (b1[0] ne -1 ) then begin
	             if (atmp.delta_plus_var ne '') then begin
	                num = where(chkvv_dep eq atmp.delta_plus_var, cnt)
                        if (cnt eq 0) then begin
		           chkvv_dep=[chkvv_dep,atmp.delta_plus_var]
		           vdep_cnt=vdep_cnt+1
	                endif
	             endif
	          endif
	          b1 = spd_cdawlib_tagindex('DELTA_MINUS_VAR', atags)
	          if (b1[0] ne -1 ) then begin
	             if (atmp.delta_minus_var ne '') then begin
	                num = where(chkvv_dep eq atmp.delta_minus_var, cnt)
                        if (cnt eq 0) then begin
		           chkvv_dep=[chkvv_dep,atmp.delta_minus_var]
		           vdep_cnt=vdep_cnt+1
	                endif
	             endif
	          endif
               endif ; if atmp.virtual eq true
            endif ; if b0[0] ne -1
         endfor
         ; Now check the depend var's of the VV for VV

         if (vdep_cnt gt 0) then begin
            ;cwc=where(chkvv_dep ne '',cwcn)
            ;chkvv_dep=chkvv_dep(cwc)
            ;dont need to do this, extra blank removed up above chkvv_dep=chkvv_dep[1:*]

            for nvvq =0, n_elements(chkvv_dep)-1 do begin
               atmp = spd_cdawlib_read_mymetadata(chkvv_dep[nvvq], CDFid)
               atags = tag_names(atmp)
               spd_cdawlib_add_mydeltas, atmp, vnames ;TJK add this here because we have regular variables w/ delta
                                          ;not only virtual variables (3/20/2014)

               b0 = spd_cdawlib_tagindex('VIRTUAL', atags)
;TJK 11/6/2009 add check for component_0 in order to determine if virtual
;variable definition is for real or not.
;               if (b0[0] ne -1 ) then begin
;                  if (strlowcase(atmp.VIRTUAL) eq 'true') then begin

               c0 = spd_cdawlib_tagindex('COMPONENT_0', atags) ;add check for component_0 value as well
               if ((b0[0] ne -1) and (c0[0] ne -1)) then begin
                  if ((strlowcase(atmp.VIRTUAL) eq 'true') and (atmp.COMPONENT_0 ne '')) then begin

;TJK 11/28/2006 - need to check to see if this virtual variable is in
;                 the vnames array, if not add it.  This is the case
;                 for the THEMIS epoch variables since none of them
;                 are "real" variables".
                     v_index = where(vnames eq chkvv_dep[nvvq] , v_count)
                     if (v_count eq 0) then begin ;need to add to vnames
                       if (DEBUG) then print, 'Found a VV ',chkvv_dep[nvvq],' among Depends; adding to vnames.'
                       vnames = [vnames,chkvv_dep[nvvq]]
                     endif
;TJK 3/26/2009 add check for whether the variable name is in the
;vir_vars array
                     v_index = where(vir_vars.name eq chkvv_dep[nvvq] , v_count)
                     if (v_count eq 0) then begin ;need to add to vir_vars...
                       if (DEBUG) then print, 'Found a VV ',chkvv_dep[nvvq],' among Depends; adding to vir_vars.'
                       num_virs = num_virs + 1
                       vir_vars.name[num_virs] = chkvv_dep[nvvq]
                       vir_vars.flag[num_virs] = 0 ;indicate this var found in master
                       spd_cdawlib_add_mydeltas, atmp, vnames 
                       spd_cdawlib_add_mycomponents, atmp, vnames 
                     endif
                  endif
               endif
           endfor 
        endif ; if (vdep_cnt gt 0)

      if keyword_set(DEBUG) then print, 'end of master cdf section ',vnames
      endif  ;endif a master

;TJK 1/2/2007 - still have to determine how many virtual variables
;               there are for use lower down so can't set this for
;               keyword_set(ALL)
;      if (num_virs ge 0 or keyword_set(ALL)) then virs_found = 1L
      if (num_virs ge 0) then virs_found = 1L
 
      ; Continue to process vnames array...  
      ;  Possibly the virtual variable is defined in a data cdf, check for 
      ;  that...

      if (strpos(cnames[cx],'00000000') eq -1) then begin  ;not a master
         ; RCJ 02/02/2005 Added lines below. If we are not using a master cdf
	 ; or if we are using a cdf generated by write_myCDF
	 ; then the deltas and components are added to vnames here:
	 if cx eq 0 then begin ; first cdf only. This could
	    ; represent a problem but I'm trying to avoid cases
	    ; like the one described by TJK 8/27/2002 below.

	    for nreq =0, n_elements(vnames)-1 do begin
	       atmp = spd_cdawlib_read_mymetadata(vnames[nreq], CDFid)
               spd_cdawlib_add_mydeltas, atmp, vnames
               spd_cdawlib_add_mycomponents, atmp, vnames
            endfor
	 endif  

         ;if this is not a master cdf we want to check to make sure all of the
         ;variables that were requested (in vnames) actually exist in this cdf.
         ;If not, do not ask for them... doing so causing problems...
         ; look for the requested variable in the whole list of vars in this cdf
         all_cdf_vars = spd_cdawlib_get_allvarnames(CDFid = CDFid)
         ;  Look to see if a virtual variable is defined in the cdf file...

;	 if (debug) then print, 'checking the data cdf for virtual variables '

	att_names = spd_cdawlib_getvar_attribute_names(CDFid, /ALL) ;added all keyword, default 
							 ;is the variable attributes
	;TJK if no attributes are found, a -1 is returned above - which should
	;kick out below.
        ;TJK 11/28/2006 - add check for virs_found, if
        ;already found in master, don't check below

	afound = where(att_names eq 'VIRTUAL', acnt)
;TJK 3/12/2010 - add code to get component_0 info so it can be checked
;                below - otherwise we can't read themis cdfs (w/o
;                        masters) because they depend so heavily on
;                        virtual variables.
        bfound = where(att_names eq 'COMPONENT_0', bcnt)

	if (acnt eq 1 and not(virs_found)) then begin ; continue on w/ the checking otherwise get out
         for nvar = 0, (n_elements(all_cdf_vars)-1)  do begin
	   ;TJK 8/27/2002 replaced call to spd_cdawlib_read_mymetadata since we found at least
	   ; one case w/ c*_pp_whi where doing so severely hampered performance
	   ; because some attributes had many thousands of entries.
           ; atmp = spd_cdawlib_read_mymetadata(all_cdf_vars(nvar), CDFid) 
	   ; Replaced w/ call to spd_cdawlib_getvar_attribute_names and where statement, then
	   ; only get into this for loop if the VIRTUAL attribute actually exists...
           ; Now, just get the  value for the VIRTUAL attribute, not all
	   ; attributes
	   
           atmp = spd_cdawlib_read_myattribute(all_cdf_vars[nvar],afound[0],CDFid)
           ;this section finds all virtual variables in the data cdf
            atags = tag_names(atmp)
	    b0 = spd_cdawlib_tagindex('VIRTUAL', atags)
;TJK 3/12/2010 added the following because it was wrong before... atags only has 
;the virtual tag in it not all tags for the given variable (unlike way
;above)... so get the component_0 info. and store in btmp, btags and use t0 below

            btmp = spd_cdawlib_read_myattribute(all_cdf_vars[nvar],bfound[0],CDFid)
            btags = tag_names(btmp)
            t0 = spd_cdawlib_tagindex('COMPONENT_0', btags);add check for component_0 value as well


;TJK 11/6/2009 add check for component_0 in order to determine if virtual
;variable definition is for real or not.
;            if (b0[0] ne -1) then begin
;               if (strlowcase(atmp.VIRTUAL) eq 'true') then begin
;TJK 3/12/2010 - this check was wrong since atags only had "virtual"
;                in it - instead use t0 and btmp defined above
;            c0 = spd_cdawlib_tagindex('COMPONENT_0', atags) ;add check for component_0 value as well
;            if ((b0[0] ne -1) and (c0[0] ne -1)) then begin
;               if ((strlowcase(atmp.VIRTUAL) eq 'true') and (atmp.COMPONENT_0 ne '')) then begin

;print, 'DEBUG 3rd check for VIRTUAL and COMPONENT '
;print, ' tag indexes for virtual ',b0, 'for component ', t0
;
;TJK 3/12/2010 change to only check for virtuals in data cdfs if there 
;isn't a master cdf.  So if the data cdf has some virtuals defined
;they will be found... so they better be correct!  If the data cdfs
;virtual's aren't correct like in sta/b_l1_mag/b_rtn/sc, then use a
;master cdf w/ the virtuals turned off (set to false) and you'll be set.

          if (strpos(cnames[0],'00000000') eq -1) then begin
              ;print, 'DEBUG 1st cdf is not a master ', cnames[0]

            if ((b0[0] ne -1) and (t0[0] ne -1)) then begin
               if ((strlowcase(atmp.VIRTUAL) eq 'true') and (btmp.COMPONENT_0 ne '')) then begin

		   if (debug) then print, 'found a VIRTUAL tag for ',all_cdf_vars[nvar]

	          ;check to see if the vir_var is already in the array,
	          ; if so don't add it to the array.
 	          if (num_virs ge 1) then begin
	             c = where(vir_vars.name eq all_cdf_vars[nvar], cnt) 
	             ;compare this one with the vir_vars
	             if (cnt eq 0) then begin ;if this one isn't in vir_vars add it.
	                num_virs = num_virs+1
	                vir_vars.name[num_virs] = all_cdf_vars[nvar]
                        vir_vars.flag[num_virs] = 1 ;indicate this var found in data cdf
	                if (DEBUG) then print, 'Found a VV ',all_cdf_vars[nvar],' in data CDF'

                     endif
	          endif else begin
	             num_virs = num_virs+1
	             vir_vars.name[num_virs] = all_cdf_vars[nvar]
                     vir_vars.flag[num_virs] = 1 ;indicate this var found in data cdf
	             if (DEBUG) then print, 'Found a VV ',all_cdf_vars[nvar],' in data CDF'
                  endelse	

	       endif
             endif
           endif ; check for whether a master cdf has been defined
         endfor

;TJK 11/30/2006 - moved this endif down below the next section of code, since we
;      don't want to add more depends and components if a master was
;      present
;	endif ;TJK added on 8/27/2002 to match further checking for the VIRTUAL
	      ;attribute.

         ;  If virtual variables were found in the cdf, see if they were requested...

         dnames='' & cmpnames=''
         for req_vars=0, (n_elements(vnames)-1) do begin
            ;TJK 11/29/2006 - add code to get depends and components 
            ;for requested vnames - add to the vnames array a little 
            ;lower down.

            dtmp = spd_cdawlib_read_mymetadata(vnames[req_vars], CDFid)
            spd_cdawlib_add_mydepends, dtmp, dnames
            for delts = 0, n_elements(dnames)-1 do begin
              ctmp = spd_cdawlib_read_mymetadata(dnames[delts], CDFid)
              spd_cdawlib_add_mycomponents,ctmp, cmpnames
            endfor

            vcdf = where(vir_vars.name eq vnames[req_vars], v_cnt)
            ;virtual has been requested...

            if (vcdf[0] ne -1L)  then begin
	       ; found in data cdf (vs. Master cdf) so we need to add it
               if (vir_vars.flag[num_virs]) then begin
	          if (debug) then print, 'Reading metadata for VV, ',vnames[req_vars]
                  atmp = spd_cdawlib_read_mymetadata(vnames[req_vars], CDFid)
	          if (debug) then print, 'Add DELTAs for VV, ',vnames[req_vars]
	          spd_cdawlib_add_mydeltas, atmp, vnames
	          if (debug) then print, 'Add components for VV, ',vnames[req_vars]
	          spd_cdawlib_add_mycomponents, atmp, vnames
	       endif
           endif 
         endfor
         ;Concatenate depends and component variables to the vnames array
         ;Make sure not to add any blanks or variables that are already
         ;in vnames.

         ;TJK 6/23/2008 add code to add theunique list of depends and
         ;components, but don't want to use sort and uniq on the requested vnames
         ;array, because that messes up the ordering of the variables (we want to 
         ;plot them in the same order they're listed in the master cdf.


         vnames = spd_cdawlib_unique_array(vnames, dnames)
         cmpnames = spd_cdawlib_unique_array(vnames, cmpnames)

;old code below:
;         if (xcnt gt 0)then begin
;             vnames = [vnames,dnames(x)] ;append them and then sort out duplicates
;             vnames = vnames[uniq(vnames,sort(vnames))]
;         endif
;
;         if (ycnt gt 0)then begin
;             vnames = [vnames,cmpnames(y)]
;             vnames = vnames[uniq(vnames,sort(vnames))]
;         endif

	endif ;TJK added on 8/27/2002 to match further checking for the VIRTUAL
	      ;attribute.

         ;  Now check that all variables requested, and components of virtuals, are
         ;  found in the cdf file...
         for req_vars=0, (n_elements(vnames)-1) do begin
;            if (DEBUG) then print, 'Checking to see if variables are actually in this data cdf.'
            fcdf = where(all_cdf_vars eq vnames[req_vars], found_cnt)  
            if (fcdf[0] eq -1L) then begin      ;didn't find requested variable.
               ;Make sure you don't blank out a virtual variable that has 
               ;been defined in a master...
               vcdf = where (vir_vars.name eq vnames[req_vars], v_cnt)
               ;TJK added code to check whether vnames(req_vars) is a variable that has been altered
               ;because its original name had "invalid" characters in it - if it was altered, do
               ;not throw it out... 10/31/2000 
              table_index = where(table.equiv eq vnames[req_vars], tcount)
               if (tcount gt 0) then begin
	          ;before adding the table.varname to vnames, make sure it isn't already there...
	          already_there = where(table.varname[table_index[0]] eq vnames, already_cnt)
	          if (already_cnt eq 0) then begin
	             vnames[req_vars] = table.varname[table_index[0]] 
	             ;another name needs to be used in order to get 
	             ;the data out of the cdf
	          endif ;TJK removed this - this shouldn't be necessary 1/29/2001
	          ; else vnames(req_vars) = ' '     ; so blank it out
	       endif
               ;No, this is not a virtual variable
               ;TJK modified if (vcdf[0] eq -1L) then begin
	       if (vcdf[0] eq -1L and tcount eq 0) then begin
	          if (DEBUG) then print,'Variable ',vnames[req_vars],$
                     ' not found in this data cdf - throwing out.'
                  vnames[req_vars] = ' '     ; so blank it out
	       endif
            endif
         endfor ;for each requested variable
         if (DEBUG) then print, 'made it through SETUP for DATA cdfs'
      endif ; if not a master cdf

      real_vars = where(vnames ne ' ', rcount);
      if (rcount gt 0) then vnames = vnames[real_vars]
      cdf_close,CDFid ; close the open cdf
   endif 
endfor ; for each cdf

if keyword_set(DEBUG) then print, 'end of data cdf section ',vnames

;end TJK modifications


dhids = lonarr(n_elements(vnames)) ; create array of handle ids for data
mhids = lonarr(n_elements(vnames)) ; create array of handle ids for metadata
vvarys = strarr(n_elements(vnames)) ; initialize variable variance array
cdftyp = strarr(n_elements(vnames)) ; initialize cdftype array

if (rcount gt 0) then begin ; check whether there are any variables to retrieve
   ; get the data and metadata for all variables from all cdfs
   mastervary=''
   for cx=0,n_elements(cnames)-1 do begin
      ; Open the CDF and inquire about global information about file
      CDFid = cdf_open(cnames[cx], /readonly) & cinfo = cdf_inquire(CDFid)
      if keyword_set(DEBUG) then print, 'Opening CDF ',cnames[cx]
      ;TJK had to add the following two calls to cdf_control in order
      ;to get the proper number of maxrecs down below - this was needed
      ;for IDL v5.02
      cdf_control, CDFid, SET_ZMODE=2 ;set zmode so that i can always know that
      ;the variables are z variables for next line.
      cdf_control, CDFid,  VAR=0, /Zvariable, GET_VAR_INFO=vinfo2 ; inquire more about the var
      ; TJK - 12/20/96 - added this section plus some modifications below
      ; to only get the data for requested time range.  This should significantly
      ; help conserve memory usage in this s/w.
      start_rec = 0L ;initialize to read the whole cdf.
      ;TJK changed this since the maxrec coming back from cdf_inquire only
      ;applies to R variables under IDL v5.02, so if you don't have any R
      ;variables in your CDF, maxrec will come back as -1...
      ;  rec_count = cinfo.maxrec+1 ; initialize to read all records
      rec_count = vinfo2.maxrecs+1 ; initialize to read all records
      ;
      
;TJK 7/21/2006 initialize some arrays to hold the extra time resolution values
      msec = make_array(2, /integer, value=0)
      usec = make_array(2, /integer, value=0)
      nsec = make_array(2, /integer, value=0)
      psec = make_array(2, /integer, value=0)

      if (keyword_set(START_MSEC)) then msec[0] = START_MSEC 
      if (keyword_set(STOP_MSEC)) then msec[1] = STOP_MSEC 

      if (keyword_set(START_USEC)) then usec[0] = START_USEC 
      if (keyword_set(STOP_USEC)) then usec[1] = STOP_USEC 

      if (keyword_set(START_NSEC)) then nsec[0] = START_NSEC 
      if (keyword_set(STOP_NSEC)) then nsec[1] = STOP_NSEC 

      if (keyword_set(START_PSEC)) then psec[0] = START_PSEC 
      if (keyword_set(STOP_PSEC)) then psec[1] = STOP_PSEC 

      if (keyword_set(TSTART) and keyword_set(TSTOP))then begin 		
         ;convert the TSTART and TSTOP to double precision numbers.
	 ;Get the epoch variable data first, determine
	 ;which records fall within the TSTART and TSTOP range.
	 start_time = 0.0D0 ; initialize
         b = size(TSTART) & c = n_elements(b)
;TJK 7/20/2006 - original code.  New code gets epoch in original epoch
;                and in epoch16 so that either can be used lower down
;                in the code...

	 if (b[c-2] eq 5) then start_time = TSTART $ ; double float already
	 else if (b[c-2] eq 7) then begin
             start_time = encode_cdfepoch(TSTART, MSEC=msec[0]) ; string

             start_time16 = encode_cdfepoch(TSTART,/EPOCH16, MSEC=msec[0], $
                                            USEC=usec[0], NSEC=nsec[0], $
                                            PSEC=psec[0]) ;string
             start_timett = encode_cdfepoch(TSTART, /TT2000, MSEC=msec[0], $
                                            USEC=usec[0], NSEC=nsec[0], $
                                            PSEC=psec[0]) ;string
            endif
	 stop_time = 0.0D0 ; initialize
	 b = size(TSTOP) & c = n_elements(b)
	 if (b[c-2] eq 5) then stop_time = TSTOP $ ; double float already
	 else if (b[c-2] eq 7) then begin
             stop_time = encode_cdfepoch(TSTOP, MSEC=msec[1]) ; string
             stop_time16 = encode_cdfepoch(TSTOP,/EPOCH16, MSEC=msec[1], $
                                            USEC=usec[1], NSEC=nsec[1], $
                                            PSEC=psec[1]) ;string
             stop_timett = encode_cdfepoch(TSTOP, /TT2000, MSEC=msec[1], $
                                            USEC=usec[1], NSEC=nsec[1], $
                                            PSEC=psec[1]) ;string

             endif
         endif

      ;end TJK TSTART and TSTOP modifications.

      vnn=0
      vn_sdat=strarr(n_elements(vnames)+40)
      all_cdf_vars = spd_cdawlib_get_allvarnames(CDFid = CDFid)
      ;get the list of vars in the current CDF.
      ; Read all of the selected variables from the open CDF
      vx = 0 & REPEAT begin
         ;TJK check to see if the current variable exists in this CDF.
         ;if not go to the bottom of the repeat. 5/1/98
         found = where(all_cdf_vars eq vnames[vx], found_cnt)
	 ;if the variable isn't found try to find it w/ a different spelling - the
	 ;case that we know exists is w/ geotail orbit files, most data files and the
	 ; master cdf have the variable Epoch, some data cdfs have it spelled EPOCH...
	 if (found_cnt eq 0L) then begin
            new_name = spd_cdawlib_find_var(CDFid, vnames[vx]) ; return the actual 
						   ;correct spelling of the variable
	    if (strtrim(string(new_name),2) ne '-1') then begin
               print, 'replacing vnames ',vnames[vx], ' w/ ',new_name
	       vnames[vx] = new_name
	       found_cnt = 1L
	    endif
	 endif
         if (found_cnt gt 0L) then begin  ;did find requested variable.
            ;TJK added this next section so that the vvarys array is 
            ;actually set for all of the variables. 4/98
            ;TJK 10/5/2006 only initialize the vvarys and cdftyp to novary and ' '
            ;if this cdf is a master. Otherwise vvs info were being wiped out.
            if (strpos(cnames[cx],'00000000') ne -1) then begin  ;a master
              vvarys[vx] = 'NOVARY'
              cdftyp[vx] = ' '
            endif
            if (num_virs gt -1) then begin
               vv = where(vnames[vx] eq vir_vars.name, vv_cnt)
               ;if this var is not virtual or looking in a master CDF
               if ((vv_cnt le 0) or (cx eq 0)) then begin 
                  vinfo = cdf_varinq(CDFid,vnames[vx]) ; inquire about the variable
                  vvarys[vx] = vinfo.RECVAR
                  cdftyp[vx] = vinfo.DATATYPE
               endif
            endif else begin 
               vinfo = cdf_varinq(CDFid,vnames[vx]) ; inquire about the variable
               vvarys[vx] = vinfo.RECVAR
               cdftyp[vx] = vinfo.DATATYPE
            endelse

            ;end of TJK mods. 4/98
            ; Read the data for the variable unless it is known to be non varying
            if (vvarys[vx] ne 'NOVARY') then begin 
               ; Determine rec_count from depend_0 of current variable; check start & stop times RTB 9/30/97
               if (keyword_set(TSTART) and keyword_set(TSTOP))then begin 		
                  ; Need to find depend_0 for the current variable
                  ;TJK - 12/20/96 added the use of the start_rec and rec_count keywords.
                  if (cx eq 0) then begin ;TJK only get the metadata from the 1st cdf.
                     ;read this metadata from a master CDF only
                     atmp=spd_cdawlib_read_mymetadata(vnames[vx], CDFid)
                  endif else begin ;get the already retrieved data out of the handle
                     handle_value, mhids[vx], atmp
                  endelse
                  mnames=tag_names(atmp)
                  ; If a depend0 is not defined for a variable, read 
                  ;entire cdf (no time limits applied. RTB

                  nck=where(mnames eq 'DEPEND_0',dum)
                  if (nck[0] ne -1L) then depend0=atmp.depend_0 $
                  else begin 
                     if keyword_set(DEBUG) then print, "No depend_0 attribute, read entire cdf"
                     start_rec = 0L
                     goto, NO_VAR_ATT
                  endelse
                  nck=where(mnames eq 'VAR_TYPE',dum)
                  if (nck[0] ne -1L) then vartype=atmp.var_type $
                  else begin 
                     if keyword_set(DEBUG) then print, "No variable attribute, read entire cdf"
                     start_rec = 0L 
                     goto, NO_VAR_ATT 
                  endelse
                  ;RTB - 10/03/97 added code to distinguish b/w epoch and other data
                  ;read all epoch data then apply start and stop times

                  ;TJK Jan.17, 2003 - had to remove this section - found a case w/ equator s 
		  ;data that contain variable names including "%", that the following code won't work w/.
		  ;TJK - determine if there is a variable in this data cdf that matches the
		  ;depend0 - we have cases were this isn't the case, e.g. depend0 = Epoch,
		  ;the real data variable is named EPOCH... if not, this catch should detect this, and
		  ;then find the correct spelled epoch variable in this data cdf...
;		       tami = 0 ;TJK debugging...
;		       CATCH,error_status
;		       if ((error_status ne 0) and (depend0 ne '')) then begin
;			;found case where depend0 variable doesn't reallyexist  in the data cdf
;		 	;send depend0 to blank so we'll read the entire cdf
;		        print, 'variable ',depend0,' not found in this cdf, trying to correct spelling'
;			depend0 = spd_cdawlib_find_epochvar(CDFid) ; return the actual 
;						;correct spelling of the depend0 variable
;
;			if (strtrim(string(depend0),2) eq '-1') then begin
;			  v_err='ERROR=Depend0 variable for variable '+vnames[vx]+' not found in data cdf'
;			  v_stat='STATUS=Depend0 variable for variable '+vnames[vx]+$
;				' not found. CDAWeb support staff has been notified. '
;			  atags=tag_names(atmp)
;			  b0 = spd_cdawlib_tagindex('LOGICAL_SOURCE',atags)
;			  b1 = spd_cdawlib_tagindex('LOGICAL_FILE_ID',atags)
;			  b2 = spd_cdawlib_tagindex('Logical_file_id',atags)
;			  if (b0[0] ne -1) then  psrce = strupcase(atmp.LOGICAL_SOURCE)
;			  if (b1[0] ne -1) then psrce = strupcase(strmid(atmp.LOGICAL_FILE_ID,0,9))
;			  if (b2[0] ne -1) then psrce = strupcase(strmid(atmp.Logical_file_id,0,9))
;			  v_data='DATASET='+psrce
;			  ; Reduce the number of reported errors to the developers RTB 1/97
;			  tmp_str=create_struct('DATASET',v_data,'ERROR',v_err,'STATUS',v_stat)
;			  return, tmp_str
;			endif
;			print, '****depend0 successfully reset to ',depend0
;		  endif

;                  if (depend0 ne '') then vinfo = cdf_varinq(CDFid,depend0) ; inquire about the variable
		
                  if (depend0 ne '') then begin
                     table_index = where(table.equiv eq depend0, tcount)
                     if (tcount gt 0) then begin
                        depend0 = table.varname[table_index[0]] 
                        ;another name needs to be used 
                        ;in order to get the data out of the cdf
                     endif

;print, 'DEBUG, calling spd_cdawlib_majority_check and spd_cdawlib_read_myvariable to get depend0 epoch, line 2730' 
                     if (n_tags(atmp) gt 0) then to_column = spd_cdawlib_majority_check(CDFid=CDFid,buf=atmp) else $
                        to_column = spd_cdawlib_majority_check(CDFid=CDFid) 
                     epoch = spd_cdawlib_read_myvariable(depend0,CDFid,vary,dtype,recs,set_column_major=to_column)
                     epoch_varname = depend0

                  endif else begin ;assumes this is the epoch variable
                     if (vartype ne 'metadata') then begin
                        table_index = where(table.equiv eq vnames[vx], tcount)
                        if (tcount gt 0) then begin
                           depend0 = table.varname[table_index[0]]
                           ;another name needs to be used 
                           ;in order to get the data out of the cdf

                            if (n_tags(atmp) gt 0) then to_column = spd_cdawlib_majority_check(CDFid=CDFid,buf=atmp) else $
                              to_column = spd_cdawlib_majority_check(CDFid=CDFid) 
                           epoch = spd_cdawlib_read_myvariable(depend0,CDFid,vary,dtype,recs,set_column_major=to_column)
                           epoch_varname = depend0
;                           print, 'DEBUG looking for valid epoch recs'
;                           print, 'DEBUG ',stop_timett, start_timett, epoch[0]

                        endif else begin
                           if (n_tags(atmp) gt 0) then to_column = spd_cdawlib_majority_check(CDFid=CDFid,buf=atmp) else $
                              to_column = spd_cdawlib_majority_check(CDFid=CDFid) 
                           epoch = spd_cdawlib_read_myvariable(vnames[vx],CDFid,vary,dtype,recs,set_column_major=to_column)
                           epoch_varname = vnames[vx]
                        endelse
                     endif
                  endelse

                  ; fix for isis cdfs that have first element epoch = last time element epoch. RCJ 02/25/2009.
		  ; Who knows the isis data says this shouldn't have happened.  Don't know if the data providers
		  ; can fix it the data.  For now, this is the s/w fix.
                  if isis_flag then begin
                     if n_elements(epoch) gt 1 then begin
                        if epoch[0] eq epoch[n_elements(epoch)-1] then begin
                           if keyword_set(DEBUG) then print,'ISIS or ALOUETTE data. First and last elements of epoch are the same, deleting last....'
                           epoch=epoch[0:n_elements(epoch)-2]
                           recs=recs-1
                        endif
                     endif   
                  endif
		 
                  ; RCJ 11/21/2003  Added this test when tests using all=1 lead
		  ;   to error because recs was undefined.

                  ;TJK 9/15/2006 would like to check for whether epoch variable is a virtual
                  ;(which is the case for the THEMIS epochs), but don't have that info
                  ;here. So if THEMIS and no recs, read the whole cdf...
;print, 'THEMIS TEST and setting rec_count to 0 so all recs will read'
;stop;TJK
                  if ((n_elements(recs) gt 0) and strcmp('THEMIS',strupcase(atmp.project[0]),6)) then begin
                    rec_count = 0L   
                    if (keyword_set(TSTART) and keyword_set(TSTOP)) then need_timeslice = 1L
                    goto, NO_VAR_ATT 
                  endif

                  if (n_elements(recs) gt 0) then begin ; if recs is defined
                     if (recs gt 0) then begin ; we're looking at a cdf w/ data in it!
                        ;valid_recs = where(((epoch lt stop_time) and (epoch gt start_time)),$
		        ; RCJ 06/24/2003 Changed line above to line below.
		        ; Is there any reason to be exclusive instead of inclusive?
                        ;TJK 6/26/2006 - because of CDF_epoch16, if we're running 
                        ; w/ IDL6.3,use the new cdf_epoch_compare function to compare
                        ;epoch values (epoch16's are dcomplex - 2 double
                                ;values), so the usual comparison w/
                                ;the "where" function fails.

                        if (!version.release ge '6.2') then begin

                             ;4/27/2010 - also only look at this epoch variable if we haven't
                             ;            before - for this cdf - use check_varcompare function and the
                             ;            variables_comp array to keep track. 
			     ; RCJ 03/30/2012  check_varcompare didn't work on waltz. We tried to save_valid_recs
			     ;  but the vars may not be in order w/ their Epochs when there are 2 or more Epochs in the requested data.                               
                             ;if (not(check_varcompare(variables_comp, cx, epoch_varname)))then begin
                               if keyword_set(DEBUG) then etime = systime(1)
			       case size(epoch,/tname) of
			          'LONG64': begin  ;TT2000 case
				           valid_recs=where(cdf_epoch_compare(epoch, start_timett, stop_timett), rec_count)
                                           ;print, '1st rec = ',valid_recs[0], 'last rec = ',valid_recs(n_elements(valid_recs)-1)
                                           if keyword_set(DEBUG) then print, 'Took ',systime(1)-etime, ' seconds to do cdf_epoch_compare'
				    	   end
			          'DCOMPLEX': begin ;Epoch16 case
				           valid_recs=where(cdf_epoch_compare(epoch, start_time16, stop_time16), rec_count)
                                           ;print, '1st rec = ',valid_recs[0], 'last rec = ',valid_recs(n_elements(valid_recs)-1)
                                           if keyword_set(DEBUG) then print, 'Took ',systime(1)-etime, ' seconds to do cdf_epoch_compare'
				             end
				   else: begin
				         valid_recs = where(((epoch le stop_time) and (epoch ge start_time)), rec_count)
				        end	     
			       endcase
                               ;if (size(epoch,/tname) eq 'LONG64')then begin ;TT2000 case
                               ;  valid_recs=where(cdf_epoch_compare(epoch, start_timett, stop_timett), rec_count)
                               ;   ;print, '1st rec = ',valid_recs[0], 'last rec = ',valid_recs(n_elements(valid_recs)-1)
                               ;endif else if (size(epoch,/tname) eq 'DCOMPLEX')then begin ;Epoch16 case
                               ;   valid_recs=where(cdf_epoch_compare(epoch, start_time16, stop_time16), rec_count)
                               ;  ;print, '1st rec = ',valid_recs[0], 'last rec = ',valid_recs(n_elements(valid_recs)-1)
                               ;endif else $
                               ;   valid_recs = where(((epoch le stop_time) and (epoch ge start_time)), rec_count)
                               ;variables_comp(cx,vx) = epoch_varname
                               ;save_valid_recs = valid_recs ;save off the valid_recs for use below
                               ;save_rec_count = rec_count ; save off the rec_count for use below
			       
                             ;endif else begin
                             ;   valid_recs = save_valid_recs
                             ;   rec_count = save_rec_count
			     ;	;valid_recs = where(((epoch le stop_time) and (epoch ge start_time)), rec_count)
                             ;  ;rec_count = rec_count
                             ;endelse

                        endif else begin ;original code for regular epoch value and old versions of IDL
                          valid_recs = where(((epoch le stop_time) and (epoch ge start_time)),$
                          rec_count)
                        endelse

                        if (rec_count gt 0) then begin 
                           start_rec = valid_recs[0]
;                           print, 'DEBUG Setting start_rec to valid_recs[0] ', start_rec
                        endif else begin ;read one, only because if I set rec_count to zero
                           start_rec = 0L ;we'll get ALL of the records instead of none!
                           rec_count = 1L 
                        endelse
                     endif else start_rec = 0L ;read the whole cdf.
		  endif
               endif else begin ; if keyword set start and stop
                  start_rec = 0L ; else, get all records for this variable 
                  rec_count = 0L
               endelse
            endif else begin ;variables don't vary
               start_rec = 0L & rec_count = 1L
            endelse
            NO_VAR_ATT:
            ; RTB end 9/30/97

            ;TJK - 02/17/98 added check for virtual variables, if a
            ;virtual variable has been requested then there isn't any
            ;data to read from the CDF so set the data array to zero.
            ;The data will be filled in at the very bottom of this routine.
            read_flag = 1 ; set flag to true
            if (num_virs gt -1) then begin
               vv = where(vnames[vx] eq vir_vars.name, vv_cnt)
               if (vv_cnt ge 1) then begin
                  ;one exception to above
                  ; Check var_type for current variable  RTB 5/98
                  ;  if (tami eq 1) then begin
                  ; print, 'going to try to get attributes for ',vnames[vx]
                  ;  stop ;TJK debuggin
                  ; endif

                  cdf_attget,CDFid,'VAR_TYPE',vnames[vx],vartype
                  if ((vartype eq 'metadata') and(vvarys[vx] eq 'NOVARY') and $
                     (cx eq 0)) then begin ;vv,novary,metadata read from master
                     read_flag = 1
                     if (debug) then print, 'reading vv, novary,non-metadata from master, ',vnames[vx]
                  endif else begin
                     read_flag = 0 ;set read flag to false
                     data = 0 ;set the data array to nothing as a place holder.
                  endelse
               endif
            endif

         if (read_flag) then begin

;double check to see if we've read this variable already in this cdf,
;but if its the depend_0, read it again... (because the above reads of
;depend_0 aren't saved into the dhids structure below)


            if (n_tags(atmp) gt 0) then to_column = spd_cdawlib_majority_check(CDFid=CDFid,buf=atmp) else $
            to_column = spd_cdawlib_majority_check(CDFid=CDFid) 

            data = spd_cdawlib_read_myvariable(vnames[vx],CDFid,$
              vary,dtype,recs,start_rec=start_rec, $
              rec_count=rec_count, debug=debug,set_column_major=to_column) ; read the data

            if keyword_set(DEBUG) then begin
               print,'Read data for ',vnames[vx],'. Started at record ',start_rec,' and read ', rec_count, ' records.'
            endif

;TJK 5/28/2013 for the case where no valid time values are found, put
;the valid fill into the data variables array so that nothing will be
;listed/plotted - instead of using the first records data, which is
;definitely not correct. 

            if (n_elements(valid_recs) gt 0) then begin ;see if valid_recs is defined
               if (valid_recs[0] eq -1 and (recs gt 0)) then begin ; if recs is defined but no epoch data was found w/i the requested time range
                  if (cdf_attexists(CDFid,'FILLVAL',vnames[vx])) then begin
                     anum = cdf_attnum(CDFid,'FILLVAL') ; find the fill value for this variable and load the data array w/ it
                     cdf_attget,CDFid,'FILLVAL',vnames[vx],vfill
                     if keyword_set(DEBUG) then print, 'For ',cnames[cx],' setting ',vnames[vx],' values to fill ',vfill, ' because no data  w/in start/stop range'
                     data_size = size(data, /struc) ; use the size of the data returned in the 1st record to set up the new array
                     if (data_size.n_dimensions eq 0 and data_size.n_elements eq 1) then begin 
                        data = vfill
                     endif else begin
                        dsize_x = where(data_size.dimensions ne 0)
                        data = make_array(dimension=data_size.dimensions[dsize_x], type=data_size.type, value=vfill)
                     endelse
                  endif
               endif
            endif

          endif ;if read_flag

	  ; RCJ 10/22/2003 This is for cases when the variable is 'novary' in the master cdf
	  ; but 'vary' in the data cdfs. The type is then changed to 'novary'.
	  ; It doesn't seem to be a problem for plotting or listing in CDAWeb
	  ; but it is a problem for cdfs created by write_mycdf.  
	  ; This was found for dataset im_k0_lena (spinsector and polarzone)
	  if cx[0] eq 0 then begin
	     mastervary=[mastervary,vary] 
	  endif else begin
	     ; RCJ vx+1 is because mastervary already has a first element: ''
	     if vary eq 'VARY' and mastervary[vx+1] eq 'NOVARY' then $
	        vary=mastervary[vx+1]
	  endelse
	  
         ; Flag arrays of length 1; will check later to see if these have fillval's
         ; which indicates instrument is off  RTB 9/96
         sz=size(data)
         ;print,vnames(vx)
         ;print, sz
         ; Check if data is of 0, 1 or multi-dimension and set flag
         ;  if (sz(0) ge 1) then szck=sz(1)/(sz(sz(0)+2)) else szck=sz(sz(0)+2)
         ; RTB 10/29/97 
         if (sz[0] gt 1) then szck=sz[1]/(sz[sz[0]+2]) else szck=sz[sz[0]+2]
         if (sz[0] eq 3) then  szck=sz[sz[0]]
         ;TJK 3/17/98, added check for read_flag, if its set then this is
         ;NOT a virtual variable, so go ahead w/ the check for a single
         ;record containing fill (indicates instrument is off).
         ;TJK 10/25/99 added further check to see if this CDF is a master, if 
         ;it is then don't check for "instrument off" since most masters 
         ;don't contain any data.
         if (szck eq 1) and (vnames[vx] ne '') and (read_flag eq 1) and $
            (strpos(cnames[cx],'00000000') eq -1) then begin
            vn_sdat[vnn]=vnames[vx]
            vnn=vnn+1
            ;print, "Add to instrument off list:", vn_sdat
         endif
         ;     
         vvarys[vx] = vary  ; save the record variance flag
	 ;
	 ; RCJ 07/31/2003 commented out line below. If only 1 var is requested
	 ; and it's a vv it's cdftype is cdf_epoch!
         ;cdftyp(vx) = dtype ; save the cdf data type
	 ;
         ;TJK moved this up above No_VAR_ATT 4/16/98   endif
         ; Process the metadata of the current variable

         if (cx eq 0) then begin ; for only the first cdf on the list 
            vvarys[vx] = vary ; set value in variable variance array
            if keyword_set(DEBUG) then print,'Reading metadata for ',vnames[vx], ' and CDF #',cx
            metadata = spd_cdawlib_read_mymetadata(vnames[vx],CDFid) ; read variable metadata
            ;if (mhids[vx] ne 0) then HANDLE_FREE, mhids[vx]
            mhids[vx] = HANDLE_CREATE() & HANDLE_VALUE, mhids[vx], metadata, /SET
            ; Check metadata for ISTP depend attr's, modify other arrays accordingly
            spd_cdawlib_follow_mydepends, metadata, vnames, vvarys, cdftyp, dhids, mhids
         endif

         ; Process the data of the current variable
         ;if (strpos(cnames[cx],'00000000') eq -1) OR (vvarys(vx) eq 'NOVARY') then begin
         ; RCJ 09/01 Read the variable geo_coord (from satellite ISIS) even though it is 
         ; a 'novary' variable.
	 ;TJK modified this check for mission_group (moved that check up to where we're
	 ;reading the master) and just check the flag here since its quite possible a
	 ;data cdf wouldn't have a mission_group global attribute. 9/28/2001
         ; RCJ 11/01 Same for ISIS variable FH
	 ; RCJ 04/23/2003 Had to change the logic associated w/ isis variables.
	 ; We were getting arrays starting w/ a '0' because we had to force
	 ; these 'novary' variables to be read. Further down this first element
	 ; '0' is removed from the array.
         if (strpos(cnames[cx],'00000000') eq -1) OR (vvarys[vx] eq 'NOVARY') $
            then begin
            ; not a master skeleton or NRV data values from a master,
            ; (RCJ 09/01) but make an exception for variable geo_coord from ISIS satellite
	    if (dhids[vx] eq 0) then begin ; create handle to hold data
	       dhids[vx] = HANDLE_CREATE() 
	       if (isis_flag) then begin
		  if (vnames[vx] eq 'FH') or (vnames[vx] eq 'geo_coord') then begin
		     ; RCJ 09/04/2003 Problem when the user only asked for
		     ;'FH': at this point in the program valid_recs was undefined. 
	             ; If, for example, 'freq' and 'FH' were requested, then there was
		     ; no problem because valid_recs would have been calculated for
		     ; 'freq'. My solution was to (re)calculate valid_recs here:
		     ;
		     ; RCJ 10/21/2005  This if statement seems to be causing
		     ; problems now and I'm not getting all of the FH/geo_coord
		     ; points I need. I'm commenting it out so valid_recs will
		     ; *always* be recalculated. I did the same a few lines below,
		     ; same case.
	             ;if n_elements(valid_recs) eq 0 then begin 
                     if (n_tags(atmp) gt 0) then to_column = spd_cdawlib_majority_check(CDFid=CDFid,buf=atmp) else $
                           to_column = spd_cdawlib_majority_check(CDFid=CDFid) 
		        epoch = spd_cdawlib_read_myvariable('Epoch',CDFid,vary,dtype,recs,set_column_major=to_column)
		        ; Above, we know that for FH or geo_coord data time is 'Epoch'
		        valid_recs_isis = where((epoch le stop_time) and $
			      (epoch ge start_time), rec_count)
                        if keyword_set(DEBUG) then print, 'Recalculated - Reading ', rec_count, ' records.'
	             ;endif   
		     tmpdata=0
		     ;for i=0,(n_elements(valid_recs))-1 do tmpdata=[tmpdata,data]
		     if rec_count gt 0 then begin
		        for i=0,rec_count-1 do tmpdata=[tmpdata,data]
   		        data=tmpdata[1:*]
	             endif else data=tmpdata
 		  endif   
	       endif	  
	       HANDLE_VALUE, dhids[vx], data, /SET
            endif else begin ; only append record varying data
               ;if (vvarys(vx) eq 'VARY') then begin  ; append data to previous data
               ; RCJ 09/01 Again, read the varible geo_coord even though it is a 'novary' variable.
               ; RCJ 11/01 Same for ISIS variable FH
               if (vvarys[vx] eq 'VARY') or $
               (isis_flag and (vnames[vx] eq 'geo_coord')) or $
               (isis_flag and (vnames[vx] eq 'FH')) then begin  ; append data to previous data

                  HANDLE_VALUE, dhids[vx], olddata    ; get data from previous cdf's

                  ; Append only data when the instrument is on. RTB 10/29/97
                  ;print, "vnn=", vnn
                  ;print, vnames
                  ;print, "vn_sdat ",vn_sdat
                  ;if (vnn eq 0) then begin 
                  ;if (vn_sdat(vnn-1) ne vnames(vx)) then $ 
                  ;data = spd_cdawlib_append_mydata(data,olddata)  ; append new data to old data
                  ;endif else begin
                  ; print, vnames(vx),vnn
                  ;
                  ; RCJ 09/01 If satellite is ISIS and variable is the 3-element array geo_coord 
                  ; (one 3-element array per cdf) we have to replicate the array
                  ; based on the number of valid_recs (or time elements) in this cdf, so we can
                  ; have enough points to plot a graph. 
                  ; RCJ 11/01 Same for variable FH, but this is just a scalar.
                  if (isis_flag) then begin
		     if (vnames[vx] eq 'FH') or $
		        (vnames[vx] eq 'geo_coord') then begin
		        ; RCJ 09/04/2003 Problem when the user only asked for
		        ;'FH': at this point in the program valid_recs was undefined. 
	                ; If, for example, 'freq' and 'FH' were requested, then there was
		        ; no problem because valid_recs would have been calculated for
		        ; 'freq'. My solution was to (re)calculate valid_recs here:
			;
			; RCJ 10/21/2005 Commented out this if statement.
			; Reason is stated a few lines above, for the same case.
			;if n_elements(valid_recs) eq 0 then begin 

                        if (n_tags(atmp) gt 0) then to_column = spd_cdawlib_majority_check(CDFid=CDFid,buf=atmp) else $
                           to_column = spd_cdawlib_majority_check(CDFid=CDFid) 
		           epoch = spd_cdawlib_read_myvariable('Epoch',CDFid,vary,dtype,recs,set_column_major=to_column)
		           ; Above, we know that for FH or geo_coord data time is 'Epoch'
		           valid_recs_isis = where((epoch le stop_time) and $
			         (epoch ge start_time), rec_count)
                           if keyword_set(DEBUG) then print, 'Recalculated - Reading ', rec_count, ' records.'
			;endif   

		        tmpdata=0
		        ;for i=0,(n_elements(valid_recs))-1 do tmpdata=[tmpdata,data]
		        if rec_count gt 0 then begin
		           for i=0,rec_count-1 do tmpdata=[tmpdata,data]
   		           data=tmpdata[1:*]
	                endif else data=tmpdata
		     endif   
                  endif
;RCJ look for dict_key to help identify vector arrays
		  q = where(strlowcase(tag_names(atmp)) eq 'dict_key') 
		  if q[0] eq -1 then dk='' else dk=atmp.dict_key
;TJK more generic approach to this appending of single records problem
;because we have it for 3 elements vectors as well as spectrogram
;data, e.g. THEMIS L2 ESA
                  n_dims = size(data, /dimensions)
                  handle_value, mhids[vx], cur_var
                  vector=0L

;This was setting an array of just one value to vector, which was not intended.
;                  if (n_elements(cur_var.dim_sizes) eq 1) then begin
                  if (n_elements(cur_var.dim_sizes) eq 1 and cur_var.dim_sizes[0] gt 1) then begin
                      if (cur_var.dim_sizes[0] eq n_dims[0]) then begin
                        vector = 1L ;as in a 1-d array that is just one record
                                ; like 32 element record, all fill,
                                ; that needs to be appended as another
                                ; record, not appended as 32 records 
                    endif
                endif
if (keyword_set(DEBUG)) then begin
                  if (vector) then print, 'spd_cdawlib_append_mydata vector flag set' else print, 'spd_cdawlib_append_mydata vector flag not set'
endif
                  data = spd_cdawlib_append_mydata(data,olddata,dict_key=dk,vector=vector)  ; append new data to old data

                  HANDLE_VALUE, dhids[vx], data ,/SET ; save back into handle

               endif
            endelse
         endif
      endif else begin
          if (keyword_set(DEBUG)) then print, 'variable ',vnames[vx], ' not found in ',cnames[cx]
      endelse
      vx = vx + 1 ; increment variable name index
      ENDREP UNTIL (vx eq n_elements(vnames))
      cdf_close,CDFid ; close the open cdf
   endfor ; loop thru all cdfs
     


;   if keyword_set(DEBUG) then print,'Assembling Anonymous Structure'
   ; It is possible that some of the variable names may be padded with blanks
   ; This will likely cause problems later, so trim any blanks around vnames.
      
   ;TJK took out on 3/12/01 - because the spd_cdawlib_replace_bad_chars function now
   ;replaces any non-acceptable characters w/ dollars signs instead of just
   ;removing them.
   ;for i=0,n_elements(vnames)-1 do vnames[i] = strtrim(vnames[i],2)
      
   ; Retrieve the data and metadata from first handle, and append them
   ; together to create a data structure to be output from this function.
     
   HEAP_GC 
   HANDLE_VALUE, mhids[0], metadata, /NO_COPY 
  ; if (mhids[0] ne 0) then HANDLE_FREE, mhids[0]
   if (dhids[0] ne 0) then HANDLE_VALUE,dhids[0],data else data = ''
   ds = size(data) & if (ds[0] ne 0) then data = reform(temporary(data)) ; special case
   
   ;IDL 5.3 doesn't allow structure tag names that are not valid variable names,
   ;thus we need to check the vnames array for any CDF variable names that contain
   ;special characters, e.g. badChars=['\','/','.','%','!','@','#','^','&',
   ; '*','(',')','-','+','=', '`','~','|','?','<','>']  and replace them w/ a "$"
   ; character instead... not sure what other ramifications this will have 
   ; throughout the rest of the system. TJK 4/5/2000
   for t=0, n_elements(vnames)-1 do begin
;      if keyword_set(DEBUG) then print, 'Processing table variable, ',vnames[t]
      table_index = where(table.varname eq vnames[t], tcount)
      ttable_index = where(table.equiv eq vnames[t], ttcount)
      vcount = -1 ;initialize
      if (table_index[0] eq -1) and (ttable_index[0] eq -1) then begin 
         ;add this variable to the table
 ;        if keyword_set(DEBUG) then print, 'found new variable, adding to table, ',vnames(t)
         tfree = where(table.varname eq '' or table.varname eq ' ',fcount)
         if (fcount gt 0) then begin
            table.varname[tfree[0]] = vnames[t]
         endif else begin
            print, '2, Number of variables exceeds the current size ' + $
	        'of the table structure, please increase it, current size is ' 
;            help, table.varname
            return, -1
         endelse
         table_index = where(table.varname eq vnames[t], vcount)
      endif
      if (vcount ge 0) then begin
         vnames[t] = spd_cdawlib_replace_bad_chars(vnames[t], diff)
         table.equiv[table_index[0]] = vnames[t] 
         ;set equiv to either the new changed name or the original
         ;if it doesn't contain any bad chars..
      endif else begin
         if (vcount eq -1) then begin ;already set in the table, assign to what's in equiv.
            if table_index[0] ge 0 then idx = table_index[0]
            if ttable_index[0] ge 0 then idx = ttable_index[0]
            vnames[t] = table.equiv[idx]
         endif
      endelse
   endfor
      
   if keyword_set(NODATASTRUCT) then begin
      ; Rather than place the actual data into the megastructure, create
      ; a data handle structure field and put the data handle id in it.
      mytype = create_struct('cdftype',cdftyp[0])  ; create .cdftype structure
      myvary = create_struct('cdfrecvary',vvarys[0]) ; create .cdfrecvary structure - TJK added 8/1/2001
; don't need to add this here anymore, adding it as part of spd_cdawlib_read_mymetadata
;      mymajor= create_struct('cdfmajor',cinfo.majority)
      mydata = create_struct('handle',dhids[0])    ; create .handle structure
      mysize = create_struct('idlsize',size(data)) ; create .idlsize structure
      mytype = create_struct(mytype,myvary)        ; append the structures - TJK added 8/1/2001
;      mytype = create_struct(mytype,mymajor)        ; append the structures
      mytype = create_struct(mytype,mysize)        ; append the structures
      mydata = create_struct(mytype,mydata)        ; append the structures
      mydata = create_struct(metadata,mydata)      ; append the metadata
      burley = create_struct(vnames[0],mydata)     ; create initial structure
   endif else begin
      ; Place the actual data into the large data structure.  This requires
      ; moving data and can take a long time with large image data arrays.
     ; if dhids[0] ne 0 then HANDLE_FREE,dhids[0]
      ds = size(data) & if (ds[0] ne 0) then data = reform(data) ; special case
      mytype = create_struct('cdftype',cdftyp[0]) ; create .cdftype structure
      myvary = create_struct('cdfrecvary',vvarys[0]) ; create .cdfrecvary structure - TJK added 8/1/2001
; don't need to add this here anymore, adding it as part of spd_cdawlib_read_mymetadata
;      mymajor= create_struct('cdfmajor',cinfo.majority)
      mydata = create_struct('dat',data)          ; create .dat structure
      mytype = create_struct(mytype,myvary)       ; append the structures - TJK added 8/1/2001
;      mytype = create_struct(mytype,mymajor)        ; append the structures
      mydata = create_struct(mytype,mydata)       ; append the structures
      mydata = create_struct(metadata,mydata)     ; append the metadata
      burley = create_struct(vnames[0],mydata)    ; create initial structure
   endelse
      
   burley = spd_cdawlib_correct_varname(burley, vnames, 0)

   ; If more than one variable is being processed, then retrieve the data
   ; and metadata from the handles, and append them into an anonymous struct
   ; and append these structures into a single anonymous struct for output.

   for vx = 1,n_elements(vnames)-1 do begin ; retrieve and append
      HANDLE_VALUE, mhids[vx], metadata, /NO_COPY  
     ; if mhids[vx] ne 0 then HANDLE_FREE,mhids[vx]
      if dhids[vx] ne 0 then HANDLE_VALUE,dhids[vx],data else data = ''
      ds = size(data) & if (ds[0] ne 0) then data = reform(temporary(data)) ; special case
      if keyword_set(NODATASTRUCT) then begin
         ; Rather than place the actual data into the megastructure, create
         ; a data handle structure field and put the data handle id in it.
         mytype = create_struct('cdftype',cdftyp[vx]) ; create .cdftype structure
         myvary = create_struct('cdfrecvary',vvarys[vx]) ; create .cdfrecvary structure - TJK added 8/1/2001
; don't need to add this here anymore, adding it as part of spd_cdawlib_read_mymetadata
;	 mymajor= create_struct('cdfmajor',cinfo.majority)
         mysize = create_struct('idlsize',size(data)) ; create .idlsize structure
         mydata = create_struct('handle',dhids[vx])   ; create .handle structure
         mytype = create_struct(mytype,myvary)        ; append the structures - TJK added 8/1/2001
;         mytype = create_struct(mytype,mymajor)        ; append the structures
         mytype = create_struct(mytype,mysize)        ; append the structures
         mydata = create_struct(mytype,mydata)        ; append the structures
         mydata = create_struct(metadata,mydata)      ; append the metadata
         rick   = create_struct(vnames[vx],mydata)    ; create new structure
         burley = create_struct(burley,rick)          ; create initial structure
      endif else begin
        ; if (dhids[vx] ne 0) then HANDLE_FREE,dhids[vx]
         mytype = create_struct('cdftype',cdftyp[vx]) ; create .cdftype structure
         myvary = create_struct('cdfrecvary',vvarys[vx]) ; create .cdfrecvary structure - TJK added 8/1/2001
; don't need to add this here anymore, adding it as part of spd_cdawlib_read_mymetadata
;	 mymajor= create_struct('cdfmajor',cinfo.majority)
         mydata = create_struct('dat',data)           ; create .dat structure
         mytype = create_struct(mytype,myvary)        ; append the structures - TJK added 8/1/2001
;         mytype = create_struct(mytype,mymajor)        ; append the structures
         mydata = create_struct(mytype,mydata)        ; append the structures
         mydata = create_struct(metadata,mydata)      ; append the metadata
         rick   = create_struct(vnames[vx],mydata)    ; create new structure
         burley = create_struct(burley,rick)          ; append the structures
      endelse
      burley = spd_cdawlib_correct_varname(burley, vnames, vx)
   endfor


   ; Check for conditions where ISTP instrument may be off; data array length of
   ; 1 and equal to the fill value. If true set structure to -1 and return
   ; error and status messages
   ;TJK changed to ne 4/29/98  wvn=where(vn_sdat eq '',wcvn)
   ikill=0
   wvn=where(vn_sdat ne '',wcvn)
   if (wcvn ne 0) then begin
      for vi=0, wcvn-1 do begin
         if (vn_sdat[vi] ne '') then begin
            ;TJK - get the tag index in the burley structure for this variable name -
            ;can't use the variable names since they sometimes contain wierd 
            ;characters like "%" in equator-s
            ttags = tag_names(burley)
            ; RCJ 11/28/00 added line below. vn_sdat still had bad characters in
            ; the variable names and the search for var_type was failing.
           vn_sdat[vi] = spd_cdawlib_replace_bad_chars(vn_sdat[vi], diff)
            tindex = strtrim(string(spd_cdawlib_tagindex(vn_sdat[vi],ttags)),2) ;convert to string
            ;comm=execute('var_type=burley.('+tindex+').var_type')
            var_type=burley.(tindex).var_type
            if (var_type eq 'data') then begin
               ;comm=execute('vfill=burley.('+tindex+').fillval')
               vfill=burley.(tindex).fillval
               if (keyword_set(NODATASTRUCT)) then begin
                  ;comm=execute('temp=burley.('+tindex+').handle')
                  temp=burley.(tindex).handle
                  handle_value,temp,vdat 
               endif else begin 
                ;comm=execute('vdat=burley.('+tindex+').dat')
                vdat=burley.(tindex).dat
               endelse
               ;if (not comm) then print, 'ERROR=execute failed '
               ;TJK 4/17/98, added check for the datatype before doing
               ;the abs function test. If the data_type is byte, then the
               ;abs function cannot be applied, ie. under IDL 5.02 abs(255) is 1.
               data_size = size(vdat)
               data_type = data_size[n_elements(data_size)-2]
               ;TJK added logic to check if the data array size is still equal to
               ;just one value.  If so,then check the fill value, else get out.
               if (data_size[0] gt 1) then $
                  szck=data_size[1]/(data_size[data_size[0]+2]) else $
     	          szck=data_size[data_size[0]+2]
               if (data_size[0] eq 3) then  szck=data_size[data_size[0]]
               if (szck eq 1) then begin  ;data array has single value in it.
                  if (data_type eq 1) then begin
                                ;TJK - 3/9/2007 - comment this out, we
                                ;      really don't want to kick out
                                ;      entirely.
                     ;if (vfill eq vdat(0)) then $
   	             ;   ikill = spd_cdawlib_write_fill(vn_sdat(vi), burley, tmp_str)
                  endif else begin 
                     if (data_type gt 1) then begin
                        ; RCJ 06/06/01 Commented this part out. Maybe we have to rethink
                        ; the way we handle these situations.
                        ; RCJ 02/09/2007 Found case where images from po_k0_uvi were
                        ;   requested but cdf was small (po_k0_uvi_20070130), 
                        ;   had *one* (fill)value in place of image array.  
                        ;   Ended up here w/ a data_type of 4 (float) and 
                        ;   one (fill)value: -1.0000e+31
	                ;;print, 'detected a non byte value'
                        ;if (abs(vfill) eq abs(vdat(0))) then $
	                ;   ikill = spd_cdawlib_write_fill(vn_sdat(vi), burley, tmp_str)
                     endif ;datatype isn't byte (is gt 1)
                  endelse
               endif else begin
                     ; RCJ 05/01 commented this part out. We don't want to set ikill=1 if at least 
                     ; one of the variables has good data. 
	             ;if (data_size(0) eq 1) then begin
	             ;   fidx = where(vfill eq vdat, fcnt)
	             ;   if (fcnt eq n_elements(vdat)) then begin
                     ;     ;print, 'Found single record vector w/ all fill values'
                     ;     ;print, 'Setting fill message for variable',vn_sdat(vi)
	             ;     ikill = spd_cdawlib_write_fill(vn_sdat(vi), burley, tmp_str)
	             ;   endif
	             ;endif
               endelse
            endif
         endif
      endfor
   endif  
endif else begin ;TJK added check for no varibles to retrieve
   ;get some metadata out of the 1st CDF or Master CDF
   v_err = 'ERROR=Variable(s) not available for specified time range.'
   v_stat='STATUS=Variable(s) not available for specified time range. Re-select a different time range.'
   ; Changed method of getting the name of the data set.  The data set can be retrieved from
   ; the logical source global attribute.
   ; Ron Yurow  (March 18, 2016)
   ;slash = rstrpos(cnames[0],'/')
   ;d_set = strmid(cnames[0], slash+1, 9)
   d_set = atmp.logical_source
   d_set = 'DATASET='+strupcase(d_set)
   tmp_str=create_struct('DATASET',d_set,'ERROR',v_err,'STATUS',v_stat)
   ikill=1
endelse

if (ikill) then return, tmp_str
!quiet = quiet_flag ; restore
; Return successfull

if (keyword_set(DEBUG)) then begin
   print, 'num_virs',num_virs+1 
endif

;TJK add check in orig_names array for any variable name that might have
;bad characters in it.  Compare w/ what's been stored in the table structure.
;if (debug) then print, 'orig_names before checking ',orig_names
for i = 0, n_elements(orig_names)-1 do begin
   found = where(orig_names[i] eq table.varname, found_cnt)
   if (found_cnt eq 1) then orig_names[i] = table.equiv[found[0]]
endfor
;if (debug) then print, 'orig_names after checking ',orig_names

if not keyword_set(NOVIRTUAL) then begin
;TJK 3/26/2009 add this code to removed the un-used spots in the vir_vars
;structure arrays because I need to reverse the order of the variables
;so that in case there are virtual variables that depend on other v.v.s
;they'll likely be populated (this was specifically needed for
;wi_h4/m2_swe)

tids = where(vir_vars.flag ge 0, tcount)
if (tcount gt 0) then begin
  if keyword_set(debug) then print, 'Before ', vir_vars.name
  vir_vars2= create_struct('name',vir_vars.name[tids],'flag',vir_vars.flag[tids])
  vir_vars.name = vir_vars2.name
  vir_vars.flag = vir_vars2.flag
  if keyword_set(debug) then print, 'Remove extra virtual variables from list ', vir_vars.name
endif

;TJK add system time check to determine how long our virtual variables
;take to generate.

ttime = systime(1)

q=''  ; RCJ 03/04/2010  This test was triggered by a case where the only 'data' var 
; in the structure was 'thrown out' somewhere in the code above.
; var was thg_ask_nrsq, date was Nov/2007, for which we don't have data.
for i=0,n_tags(burley)-1 do q=[q,burley.(i).var_type]
;reuse q :
q=where(strlowcase(q) eq 'data')
if q[0] eq -1 then begin
   d_set='DATASET='+strupcase(atmp.logical_source)
   v_err="ERROR=No var type 'data' in structure" 
   v_stat='STATUS= Data not available'
   tmp_str=create_struct('DATASET',d_set,'ERROR',v_err,'STATUS',v_stat)
   return, tmp_str
endif

for i = 0, num_virs do begin
   vtags = tag_names(burley)
   ;vindex = spd_cdawlib_tagindex(vir_vars.name[i], vtags) ; find the VV index number
   vindex = spd_cdawlib_tagindex(spd_cdawlib_replace_bad_chars(vir_vars.name[i],diff), vtags) ; find the VV index number
   if (vindex[0] ge 0) then begin
      vartags = tag_names(burley.(vindex))
;      findex = spd_cdawlib_tagindex('FUNCTION', vartags) ; find the FUNCTION index number
      findex = spd_cdawlib_tagindex('FUNCT', vartags) ; find the FUNCT index number
      if (findex[0] ne -1) then begin ;found a virtual value w/ a function definition
         if keyword_set(DEBUG) then print,'VV function being called ',$
            strlowcase(burley.(vindex).(findex)), ' for variable ',vir_vars.name[i]

         case (strlowcase(burley.(vindex).(findex))) of
         'spd_cdawlib_crop_image': begin
                          burley=spd_cdawlib_crop_image(temporary(burley),orig_names,index=vindex)
   		       end   
         'spd_cdawlib_alternate_view': begin
                              burley = spd_cdawlib_alternate_view(temporary(burley),orig_names)
                           end
         'spd_cdawlib_clamp_to_zero': begin
                              burley = spd_cdawlib_clamp_to_zero(temporary(burley),orig_names,index=vindex)
                           end
         'spd_cdawlib_composite_tbl': begin
                              burley = spd_cdawlib_composite_tbl(temporary(burley),orig_names,index=vindex)
                           end
         'spd_cdawlib_arr_slice':  begin
                          burley = spd_cdawlib_arr_slice(temporary(burley), orig_names, index=vindex)
                       end
         'spd_cdawlib_conv_pos': begin
	                ; RCJ 11/21/2003  Added 'index=vindex'. It is necessary if all=1
                        burley = spd_cdawlib_conv_pos(temporary(burley),orig_names,$
                           tstart=start_time, tstop=stop_time,index=vindex)
                     end
         'spd_cdawlib_conv_pos_hungarian': begin
                        burley = spd_cdawlib_conv_pos_hungarian(temporary(burley),orig_names,index=vindex)
                     end
         'conv_pos1': begin
                         burley = conv_pos(temporary(burley),orig_names,$
                            tstart=start_time, tstop=stop_time, $
                            COORD="ANG-GSE",INDEX=vindex)
                      end
         'conv_pos2': begin
                         burley = conv_pos(temporary(burley),orig_names,$
                            tstart=start_time, tstop=stop_time, $
                            COORD="SYN-GEO",INDEX=vindex)
                      end
         'spd_cdawlib_conv_map_image': begin
                              burley = spd_cdawlib_conv_map_image(temporary(burley),orig_names)
                           end
         'spd_cdawlib_calc_p': begin
                      burley = spd_cdawlib_calc_p(temporary(burley),orig_names,INDEX=vindex)
                   end
         'create_vis': begin
                          burley = create_vis(temporary(burley),orig_names)
                       end
         'create_plain_vis': begin
                                burley = create_plain_vis(temporary(burley),orig_names)
                             end
         'create_plmap_vis': begin
                                burley = create_plmap_vis(temporary(burley),orig_names)
                             end
         'apply_qflag': begin
                           burley = apply_qflag(temporary(burley),orig_names,index=vindex)
                        end
         'spd_cdawlib_apply_rtn_qflag': begin
                           burley = spd_cdawlib_apply_rtn_qflag(temporary(burley),orig_names,index=vindex)
                        end
         'spd_cdawlib_apply_rtn_cadence': begin
                           burley = spd_cdawlib_apply_rtn_cadence(temporary(burley),orig_names,index=vindex)
                        end
         'region_filt': begin
                           burley = region_filt(temporary(burley),orig_names,index=vindex)
                        end
         'convert_log10': begin
                             burley = convert_log10(temporary(burley),orig_names)
                          end
         'spd_cdawlib_add_51s': begin ;for po_h2_uvi
                       burley = spd_cdawlib_add_seconds(temporary(burley),orig_names,index=vindex,seconds=51)
                    end
         'add_1800': begin ;for omni
                       burley = spd_cdawlib_add_seconds(temporary(burley),orig_names,index=vindex,seconds=1800)
                    end
         'spd_cdawlib_comp_themis_epoch': begin ;for computing THEMIS epoch
                       burley = spd_cdawlib_comp_themis_epoch(temporary(burley),orig_names,index=vindex)
                    end
         'comp_themis_epoch16': begin ;for computing THEMIS epoch
                       burley = spd_cdawlib_comp_themis_epoch(temporary(burley),orig_names,index=vindex,/sixteen)
                    end
         'spd_cdawlib_apply_filter_flag': begin ; filter out values based on COMPUTE_VAL and COMPUTE_OPERATOR
                       burley = spd_cdawlib_apply_filter_flag(temporary(burley),orig_names,index=vindex)
                    end
         'apply_esa_qflag': begin
                       burley = apply_esa_qflag(temporary(burley),orig_names,index=vindex)
                    end
         'apply_fgm_qflag': begin ;use the esa function
                       burley = apply_esa_qflag(temporary(burley),orig_names,index=vindex)
                    end
         'apply_gmom_qflag': begin ;use the esa function
                       burley = apply_esa_qflag(temporary(burley),orig_names,index=vindex)
                    end
         'spd_cdawlib_compute_magnitude': begin
                       burley = spd_cdawlib_compute_magnitude(temporary(burley),orig_names,index=vindex)
                    end
         'spd_cdawlib_height_isis': begin
                       burley = spd_cdawlib_height_isis(temporary(burley),orig_names,index=vindex)
                    end
         'spd_cdawlib_flip_image': begin
                       burley = spd_cdawlib_flip_image(temporary(burley),orig_names,index=vindex)
                    end
         'spd_cdawlib_wind_plot': begin
                         burley = spd_cdawlib_wind_plot(temporary(burley),orig_names,index=vindex)
                      end
         'spd_cdawlib_error_bar_array': begin
                           burley=spd_cdawlib_error_bar_array(temporary(burley), $
			                          index=vindex,value=0.02)
   		       end   
         'spd_cdawlib_convert_toev': begin
                           burley=spd_cdawlib_convert_toev(temporary(burley), orig_names, index=vindex)
                       end
         'spd_cdawlib_convert_ni': begin
                           burley=spd_cdawlib_convert_ni(temporary(burley), orig_names, index=vindex)
                        end
         'spd_cdawlib_correct_fast_by': begin
                           burley = spd_cdawlib_correct_fast_by(temporary(burley),orig_names,index=vindex)
                        end
         'spd_cdawlib_compute_cadence': begin
                           burley = spd_cdawlib_compute_cadence(temporary(burley),orig_names,index=vindex)
                        end
         'spd_cdawlib_extract_array': begin
                           burley = spd_cdawlib_extract_array(temporary(burley),orig_names,index=vindex)
                        end
         'spd_cdawlib_expand_wave_data': begin
                           burley = spd_cdawlib_expand_wave_data(temporary(burley),orig_names,index=vindex)
                        end
         'spd_cdawlib_make_stack_array': begin
                           burley = spd_cdawlib_make_stack_array(temporary(burley),orig_names,index=vindex)
                        end
         'spd_cdawlib_fix_sparse': begin
                           burley = spd_cdawlib_fix_sparse(temporary(burley),orig_names,index=vindex)
                        end

         else : print, 'WARNING= No function for:', vtags[vindex]
         endcase
      endif ;if function defined for this virtual variable    
   endif ;found the tag index for this virtual variable
endfor ; for number of virtual variables
 if keyword_set(DEBUG) then print, 'spd_cdawlib_read_mycdf took ',systime(1)-ttime, ' seconds to generate VVs.'
endif ;no virtual variable population 

;Add a check for variables that have var_type of data, but that the user didn't request.
;This has just recently become an issue because we want to allow plotting of variables
;that are defined as depends for other variables, e.g. ge_k0_epi.  TJK 11/22/2000
var_stat = 0

;TJK 1/26/01 - add if statement because if one of the virtual variable 
;functions has trouble running (doesn't find any data), burley will be
; equal to -1, then spd_cdawlib_check_myvartype fails...  so basically check to see
;if burley is a structure, by asking how many tags it has, if its not a
;structure, n_tags returns 0

if (n_tags(burley) ne 0) then begin
   var_stat = spd_cdawlib_check_myvartype(burley, orig_names)
   if (var_stat ne 0) then print, 'spd_cdawlib_read_mycdf, no data to plot/list.'
   ; RCJ 01/14/2013  Add keyword 'all' to call to spd_cdawlib_merge_metadata:
   ;burley = spd_cdawlib_merge_metadata(cnames, burley)
   burley = spd_cdawlib_merge_metadata(cnames, burley, all=all)
endif
;TJK 10/25/2006 - if THEMIS data then epoch values had to be computed
;                 (all virtual), thus time subsetting wasn't possible
;                 above, do it here by calling timeslice_mystruct
if (need_timeslice) then begin

    burley = timeslice_mystruct(temporary(burley), start_time16, stop_time16,$
       START_MSEC=START_MSEC, STOP_MSEC=STOP_MSEC, START_USEC=START_USEC, $ 
       STOP_USEC=STOP_USEC, START_NSEC=START_NSEC, STOP_NSEC=STOP_NSEC, $
       START_PSEC=START_PSEC, STOP_PSEC=STOP_PSEC)
endif

Return, burley
end


pro spd_cdawlib_read_mycdf
  compile_opt idl2
  ;do nothing
end

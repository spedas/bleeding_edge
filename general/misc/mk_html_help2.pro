; $Id: mk_html_help.pro,v 1.6 1995/07/20 15:52:59 griz Exp $
;+
; NAME:
;	MK_HTML_HELP2
;
; PURPOSE:
;       Creates a html document from a list of IDL procedures.
;	Given a list of IDL procedure files (.PRO), VMS text library 
;       files (.TLB), or directories that contain such files, this procedure 
;       generates a file in the HTML format that contains the documentation 
;       for those routines that contain a DOC_LIBRARY style documentation 
;       template.  The output file is compatible with World Wide Web browsers.
;       This version is enhanced over the routine supplied by IDL, It will
;       also cross reference, print the purpose, and add links to the source
;       code.
;
; CATEGORY:
;	Help, documentation.
;
; CALLING SEQUENCE:
;	MK_HTML_HELP, Sources, Outfile
;
; INPUTS:
;     Sources:  A string or string array containing the name(s) of the
;		.pro or .tlb files (or the names of directories containing 
;               such files) for which help is desired.  If a source file is 
;               a VMS text library, it must include the .TLB file extension.  
;               If a source file is an IDL procedure, it must include the .PRO
;               file extension.  All other source files are assumed to be
;               directories.  If not provided, searches down directory tree
;		from current directory for files.
;
;     Outfile:	The name of the output file which will be generated without
;		HTML extension.
;
;     If no inputs are given: All directories in the current directory tree
;               are used with the exception of: directories named: 'obsolete'
;               or 'SCCS.'  (UNIX only)
;
; KEYWORDS:
;     TITLE:	If present, a string which supplies the name that
;		should appear as the Document Title for the help.
;     FILENAME: Alternative method of specifying Outfile (see above)
;     VERBOSE:	Normally, MK_HTML_HELP does its work silently.
;		Setting this keyword to a non-zero value causes the procedure
;		to issue informational messages that indicate what it
;		is currently doing. !QUIET must be 0 for these messages
;               to appear.
;     STRICT:   If this keyword is set to a non-zero value, MK_HTML_HELP will 
;               adhere strictly to the HTML format by scanning the 
;               the document headers for characters that are reserved in 
;               HTML (",&,").  These are then converted to the appropriate 
;               HTML syntax in the output file. By default, this keyword
;               is set to zero (to allow for faster processing).
;     CROSSLINK:If this keyword is set MK_HTML_HELP will create a cross
;               reference between library files.
;     CLTURBO:  If this keyword is set to a single character string, then the 
;               cross reference procedure will only cross reference lines that
;               contain the character given in CLTURBO.  This greatly increases
;               the speed of the routine.  By default the double quote (") is 
;               used
;     PRINT_PURPOSE:  If this keyword is set then the first line after PURPOSE:
;               is printed in the output file.
;     MASTLIST:	If set, create master list only.  Do not create subdirectory
;		file listings.
;
; COMMON BLOCKS:
;	None.
;
; SIDE EFFECTS:
;	A help file with the name given by the Outfile argument is
;	created.
;
; RESTRICTIONS:
;	The following rules must be followed in formatting the .pro
;	files that are to be searched.
;		(a) The first line of the documentation block contains
;		    only the characters ";+", starting in column 1.
;               (b) There must be a line which contains the string "NAME:",
;                   which is immediately followed by a line containing the
;                   name of the procedure or function being described in
;                   that documentation block.  If this NAME field is not
;                   present, the name of the source file will be used.
;		(c) The last line of the documentation block contains
;		    only the characters ";-", starting in column 1.
;		(d) Every other line in the documentation block contains
;		    a ";" in column 1.
;
;       Note that a single .pro file can contain multiple procedures and/or
;       functions, each with their own documentation blocks. If it is desired
;       to have "invisible" routines in a file, i.e. routines which are only
;       for internal use and should not appear in the help file, simply leave
;       out the ";+" and ";-" lines in the documentation block for those
;       routines.
;
;	No reformatting of the documentation is done.
;
; MODIFICATION HISTORY:
;       July 5, 1995, DD, RSI. Original version.
;       July 13, 1995, Mark Rivers, University of Chicago. Added support for
;               multiple source directories and multiple documentation
;               headers per .pro file.
;       July 17, 1995, DD, RSI. Added code to alphabetize the subjects;
;               At the end of each description block in the HTML file,
;               added a reference to the source .pro file.
;       July 18, 1995, DD, RSI. Added STRICT keyword to handle angle brackets.
;       July 19, 1995, DD, RSI. Updated STRICT to handle & and ".
;               Changed calling sequence to accept .pro filenames, .tlb
;               text librarie names, and/or directory names.
;               Added code to set default subject to name of file if NAME
;               field is not present in the doc header.
;       September, 1995, D. Larson. SSL Berkeley. Added crosslink, print_purpose
;               clturbo.
;       October 4, 1995, D. Larson. SSL Berkeley. Added link to source file.
;       October 3, 1996, F. Marcoline. SSL Berkeley.  Added Alphabet Jumpline.
;       October 10, 1996, D. Larson. Added Listing by Directory.
;       October 1, 2007, J. McTiernan, allow to work with more than 28
;               directories, dropped obsolete /stream keywords from
;               openw calls.
;       
;FILE:  mk_html_help2.pro
;VERSION 1.26
;LAST MODIFICATION: 99/04/22
;-
;

forward_function setup_sources

function setup_sources,base

    compile_opt idl2

    sources = findfile(base+'*')
    i = where( strpos(sources,':') gt 0,cnt)
    if cnt gt 0 then sources = sources[i] else return,''
    i = where( strpos(sources,'SCCS') lt 0,cnt)   ; ignore all SCCS directories
    if cnt gt 0 then sources = sources[i] else return,''
    i = where( strpos(sources,'obsolete') lt 0,cnt) ; ignore all obsolete direcs
    if cnt gt 0 then sources = sources[i] else return,''
    on_ioerror,cantwrite
    indx = [-1]
    for i = 0,n_elements(sources)-1 do begin
	sepsource = str_sep(sources[i],':')
	sources[i] = sepsource[0]
	openw,lun,sources[i]+'/foo',/get_lun,/delete
	free_lun,lun
	indx = [indx,i]
	cantwrite:
    endfor
    if n_elements(indx) eq 1 then return,''
    sources = sources[indx[1:*]]
    for i = 0,n_elements(sources)-1 do $
    	sources = [sources,setup_sources(sources[i]+'/')]
    i = where(sources ne '',cnt)
    if cnt gt 0 then sources = sources[i] else return,''
    return,sources
end

;----------------------------------------------------------------------------
PRO alt_mhh_strict, txtlines
;
; Replaces any occurrence of HTML reserved characters (",&,") in the
; given text lines with the appropriate HTML counterpart.
;
; entry:
;       txtlines - String array containing the text line(s) to be altered.
; exit:
;	txtlines - Same as input except that reserved characters have been 
;                  replaced with the appropriate HTML syntax.
;
 compile_opt idl2

 count = N_ELEMENTS(txtlines)
 FOR i=0,count-1 DO BEGIN
  txt = txtlines[i] 

  ; Ampersands get replaced with &amp.  Must do ampersands first because
  ; they are used to replace other reserved characters in HTML.
  spos = STRPOS(txt,'&')
  WHILE (spos NE -1) DO BEGIN
   newtxt = STRMID(txt,0,spos)+'&amp;'+STRMID(txt,spos+1,STRLEN(txt)-spos+1)
   txt = newtxt
   spos = STRPOS(txt,'&',spos+1)
  ENDWHILE
  txtlines[i] = txt

  ; Left angle brackets get replaced with &lt;
  spos = STRPOS(txt,'<')
  WHILE (spos NE -1) DO BEGIN
   newtxt = STRMID(txt,0,spos)+'&lt;'+STRMID(txt,spos+1,STRLEN(txt)-spos+1)
   txt = newtxt
   spos = STRPOS(txt,'<',spos+1)
  ENDWHILE
  txtlines[i] = txt

  ; Right angle brackets get replaced with &gt;
  spos = STRPOS(txt,'>')
  WHILE (spos NE -1) DO BEGIN
   newtxt = STRMID(txt,0,spos)+'&gt;'+STRMID(txt,spos+1,STRLEN(txt)-spos+1)
   txt = newtxt
   spos = STRPOS(txt,'>',spos+1)
  ENDWHILE
  txtlines[i] = txt

  ; Double quotes get replaced with &quot;
  spos = STRPOS(txt,'"')
  WHILE (spos NE -1) DO BEGIN
   newtxt = STRMID(txt,0,spos)+'&quot;'+STRMID(txt,spos+1,STRLEN(txt)-spos+1)
   txt = newtxt
   spos = STRPOS(txt,'"',spos+1)
  ENDWHILE
  txtlines[i] = txt
 ENDFOR
END

;----------------------------------------------------------------------------
PRO  alt_mhh_grab_hdr,name,dict,infile_indx,libfile_indx,txt_file,verbose,$
     strict, print_purpose=print_purpose,allfiles=allfiles
;
; Searches an input file for all text between the ;+ and ;- comments, and
; updates the scratch text file appropriately. Note that this routine
; will extract multiple comment blocks from a single source file if they are
; present.
;
; entry:
;	name - Name of file containing documentation header(s).
;       dict[] - Dictionary entries for each documentation block in the .PRO
;               file.  Each dictionary entry is a structure with an index to 
;               the source filename, an index to the extracted library 
;               filename (useful only for VMS text libraries), a subject name,
;               scratch file offset, unique id (for duplicate names), and 
;               number of lines of documentation text.  
;               This parameter may be originally undefined at entry.
;       infile_indx - Index of the source .pro or .tlb filename.
;       libfile_indx - Index of extracted library filename.  If the source
;               filename was not a VMS text library, this value should be
;               set to -1L. 
;	txt_file - Scratch file to which the documentation header will
;               be written.
;	verbose - TRUE if the routine should output a descriptive message
;		when it finds the documentation header.
;       strict - If nonzero, the routine will adhere strictly to HTML format.
;                The document headers will be scanned for characters that are
;                reserved in HTML (",&,"), which are then converted to the 
;                appropriate HTML syntax in the output file.
;
; exit:
;	txt_file -  Updated as necessary. Positioned at EOF.
;       dict[] - Updated array of new dictionary entries.
;

 ; Under DOS, formatted output ends up with a carriage return linefeed
 ; pair at the end of every record. The resulting file would not be
 ; compatible with Unix. Therefore, we use unformatted output, and
 ; explicity add the linefeed, which has ASCII value 10.

 compile_opt idl2

 LF=10B
 on_ioerror,bad
 IF (libfile_indx NE -1L) THEN $
  OPENR, in_file, /GET, FILEPATH('mkhtmlhelp.scr',/TMP), /DELETE $
 ELSE $
  OPENR, in_file, /GET, name

 IF (verbose NE 0) THEN dprint, 'File = '+name,dlevel=2
; IF (verbose NE 0) THEN message,/info, 'File = '+name
 
if keyword_set(allfiles) then docum=0 else docum=1
 WHILE (1) DO BEGIN
  ; Find the opening line of the next header.
  tmp = ''
  found = 0
  num = 0
  header = ''
  ON_IOERROR, DONE
  WHILE (NOT found) DO BEGIN
   READF, in_file, tmp
   IF (STRMID(tmp,0,2) EQ ';+') THEN found = 1
if eof(in_file) and docum eq 0 then begin
  found=1
  docum=2
endif
  ENDWHILE


  IF (found) THEN BEGIN
   ; Find the matching closing line of the header.
if docum eq 2 then begin
 header = [header,'No Documentation for this routine.']
 num = num+1
endif else begin
   found = 0
   WHILE (NOT found) DO BEGIN
    READF,in_file,tmp
    IF (STRMID(tmp,0,2) EQ ';-') THEN BEGIN
     found =1
    ENDIF ELSE BEGIN
     tmp = strmid(tmp, 1, 1000)
     header = [header, tmp]
     num = num + 1
    ENDELSE
   ENDWHILE
endelse
docum=1
   IF (strict) THEN alt_mhh_strict,header
   ; Done with one block of header

   ; Keep track of current scratch file offset, then write doc text.
   POINT_LUN,-txt_file,pos
   FOR i=1, num DO BEGIN
    WRITEU, txt_file, header[i],LF
   ENDFOR

   ; Search for the subject. It is the line following name.
   index = WHERE(STRTRIM(header, 2) EQ 'NAME:', count)
   IF (count eq 1) THEN BEGIN
    sub = STRUPCASE(STRTRIM(header[index[0]+1], 2))
    IF (verbose NE 0) THEN dprint, 'Routine = '+sub

   ; If the NAME field was not present, set the subject to the name of the 
   ; source text file.
   ENDIF ELSE BEGIN
    IF (verbose NE 0) THEN dprint,'Properly formatted NAME entry not found...'
    ifname = name

    CASE !VERSION.OS_FAMILY OF
     'Windows': tok = '\'
     'MacOS': tok = ':'
     ELSE: tok = '/'
    ENDCASE

    ; Cut the path.
    sp0 = 0
    spos = STRPOS(ifname,tok,sp0)
    WHILE (spos NE -1) DO BEGIN
     sp0 = spos+1
     spos = STRPOS(ifname,tok,sp0)
    ENDWHILE
    ifname = STRMID(ifname,sp0,(STRLEN(ifname)-sp0))

    ; Cut the suffix.
    spos = STRPOS(ifname,'.')
    IF (spos NE -1) THEN ifname = STRMID(ifname,0,spos[0])
    IF (strict) THEN alt_mhh_strict, ifname
    sub = STRUPCASE(ifname)
    IF (verbose NE 0) THEN dprint,'  Setting subject to filename: '+sub+'.'
   ENDELSE

   ; Search for the Purpose. It is the line following purpose:
   index = WHERE(STRTRIM(header, 2) EQ 'PURPOSE:', count)
   IF keyword_set(print_purpose) and (count eq 1) THEN BEGIN
    purpose = STRTRIM(header[index[0]+1], 2)
    IF (verbose NE 0) THEN dprint, 'Purpose = '+purpose,dlevel=2
    ;IF (verbose NE 0) THEN message,/info, 'Purpose = '+purpose
   ENDIF ELSE purpose=''


   ; Calculate unique id in case of duplicate subject names.
   IF (N_ELEMENTS(dict) EQ 0) THEN $
    ndup=0 $
   ELSE BEGIN
    dpos = WHERE(dict.subject EQ sub,ndup)
    IF (ndup EQ 1) THEN BEGIN
     dict[dpos[0]].id = 1
     ndup = ndup + 1
    ENDIF
   ENDELSE

   ; Create a dictionary entry for the document header.
   entry = {DICT_STR,subject:sub,purpose:purpose,indx:infile_indx,lib:libfile_indx,$
            id:ndup,offset:pos,nline:num}
   IF (N_ELEMENTS(dict) EQ 0) THEN dict = [entry] ELSE dict = [dict,entry]
  ENDIF
 ENDWHILE

DONE: 
 FREE_LUN, in_file
BAD:
 ON_IOERROR, NULL


END

PRO alt_mhh_dum_file,outfile,title,verbose

 compile_opt idl2

 OPENW,final_file,outfile,/GET_LUN
 IF (verbose NE 0) THEN dprint,'Building '+outfile+'...',dlevel=2
 ;IF (verbose NE 0) THEN message,/info,'Building '+outfile+'...'
 ; Print a comment indicating how the file was generated.
 PRINTF,final_file,'<!-- This file was generated by mk_html_help.pro -->'

 ; Header stuff.
 PRINTF,final_file,'<html>'
 PRINTF,final_file,' '

 ; Title.
 PRINTF,final_file,'<head>'
 PRINTF,final_file,'<TITLE>',title,'</TITLE>
 PRINTF,final_file,'</head>'
 PRINTF,final_file,' '

 ; Title and intro info.
 PRINTF,final_file,'<body>'
 PRINTF,final_file,'<H2>',title,'</H2>'
 PRINTF,final_file,'<P>'
 PRINTF,final_file,'This page was created by the IDL library routine '
 PRINTF,final_file,'<CODE>mk_html_help2</CODE>.'
 PRINTF,final_file,'<br>'
; PRINTF,final_file,' For more information on '
; PRINTF,final_file,'this routine, refer to the IDL Online Help Navigator '
; PRINTF,final_file,'or type: <P>'
; PRINTF,final_file,'<PRE>     ? mk_html_help</PRE><P>'
; PRINTF,final_file,'at the IDL command line prompt.'
 PRINTF,final_file,'<P>'
 PRINTF,final_file,'<STRONG>Last modified: </STRONG>',SYSTIME(),'.<P>'
 PRINTF,final_file,' '
 PRINTF,final_file,'<HR>'
 PRINTF,final_file,' '

 PRINTF,final_file,'No Documented Routines'
 PRINTF,final_file,' '
 PRINTF,final_file,'</body>'
 PRINTF,final_file,'</html>'
 FREE_LUN,final_file
return
end

;----------------------------------------------------------------------------
PRO alt_mhh_gen_file,dict,txt_file,infiles,libfiles,outfile,verbose,title,strict $
   ,crosslink = crosslink,  clturbo = clturbo, no_dirlist=no_dirlist, $
   mastlist = mastlist, listname = listname, nolist = nolist
;
; Build a .HTML file with the constituent parts.
;
; entry:
;       dict - Array of dictionary entries. Each entry is a structure
;              with a subject name, scratch file offset, number of lines
;              of documentation text, etc.
;       infiles - String array containing the name(s) of .pro or .tlb files 
;              for which help is being generated.
;       libfiles - String array containing the name(s) of .pro files extracted
;              from any .tlb files in the infiles array. 
;	txt_file - Scratch file containing the documentation text.
;	outfile - NAME of final HELP file to be generated.
;	verbose - TRUE if the routine should output a descriptive message
;		when it finds the documentation header.
;	title - Scalar string containing the name to go at the top of the
;               HTML help page.
;       strict - If nonzero, the routine will adhere strictly to HTML format.
;                The document headers will be scanned for characters that are
;                reserved in HTML (",&,"), which are then converted to the 
;                appropriate HTML syntax in the output file.
;	no_alpha - Do not print the alphabetical listing of routines.
;
; exit:
;	outfile has been created.
;	txt_file has been closed via FREE_LUN.
;

 compile_opt idl2

  pathnames = strippath(infiles[dict.indx])
  dictpaths = pathnames.dir_name
  s = sort(pathnames.dir_name)
  pathnames = pathnames[s]
  u = uniq(pathnames.dir_name)
  dictwhdir = lonarr(n_elements(dictpaths))
  for i = 0, n_elements(dictpaths)-1 do begin
    whdir = where(pathnames[u].dir_name eq dictpaths[i])
    dictwhdir[i] = whdir[0]
  endfor
 ; Append unique numbers to any duplicate subject names.
  dpos = WHERE(dict.id GT 0, ndup) 
  FOR i = 0, ndup-1 DO BEGIN
    entry = dict[dpos[i]]
    dict[dpos[i]].subject = entry.subject+'['+STRTRIM(STRING(entry.id), 2)+']'
  ENDFOR

 ; Sort the subjects alphabetically.
  count = N_ELEMENTS(dict)
  indices = SORT(dict.subject)

 ; Open the final file.
  OPENW, final_file, outfile+'.html', /GET_LUN
  IF (verbose NE 0) THEN dprint, 'Building '+outfile+'...'

 ; Print a comment indicating how the file was generated.
  PRINTF, final_file, '<!-- This file was generated by mk_html_help.pro -->'

 ; Header stuff.
  PRINTF, final_file, '<html>'
  PRINTF, final_file, ' '

 ; Title.
  PRINTF, final_file, '<head>'
  PRINTF, final_file, '<TITLE>', title, '</TITLE>
  PRINTF, final_file, '</head>'
  PRINTF, final_file, ' '

 ; Title and intro info.
  PRINTF, final_file, '<body>'
  PRINTF, final_file, '<H2>', title, '</H2>'
  PRINTF, final_file, '<P>'
  PRINTF, final_file, 'This page was created by the IDL library routine '
  PRINTF, final_file, '<CODE>mk_html_help2</CODE>.'
  PRINTF, final_file, '<br>'
; PRINTF,final_file,' For more information on '
; PRINTF,final_file,'this routine, refer to the IDL Online Help Navigator '
; PRINTF,final_file,'or type: <P>'
; PRINTF,final_file,'<PRE>     ? mk_html_help</PRE><P>'
; PRINTF,final_file,'at the IDL command line prompt.'
  PRINTF, final_file, '<P>'
  PRINTF, final_file, '<STRONG>Last modified: </STRONG>', SYSTIME(), '.<P>'
  PRINTF, final_file, ' '
  PRINTF, final_file, '<HR>'
  PRINTF, final_file, ' '

  PRINTF, final_file, '<A NAME="ROUTINELIST">'

 ; Alphabetic jump list
  first_letter = strmid((dict[indices].subject), 0, 1)
  first_uniq = uniq(first_letter)
  if n_elements(first_uniq) gt 1 then $
    first_uniq = [0, first_uniq[0:n_elements(first_uniq)-2]+1] $
  else first_uniq = [0]
  nfu = n_elements(first_uniq)
  PRINTF, final_file, '<A NAME="JUMPLIST">'
  FOR i = 0, nfu-1 DO BEGIN 
    entry = dict[indices[first_uniq[i]]]
    letter = first_letter[first_uniq[i]]
    IF (entry.nline GT 0) THEN BEGIN 
      PRINTF, final_file, '<A HREF="#LIST_', letter, '">', letter, '</A>'
      IF i NE (nfu-1) THEN PRINTF, final_file, ','
    ENDIF 
  ENDFOR
  PRINTF, final_file, '<HR>'
  PRINTF, final_file, ' '

  purp_delim = '<br>'
  if keyword_set(print_purpose) then if print_purpose eq 2 then purp_delim = '  '


  PRINTF, final_file, '<P>'
  PRINTF, final_file, '<H1>Directories Searched:</H1></A>'
  PRINTF, final_file, '<UL>'
  pathnames = strippath(infiles[dict.indx])
  s = sort(pathnames.dir_name)
  pathnames = pathnames[s]
  u = uniq(pathnames.dir_name)
  suboutfile = pathnames[u].dir_name+listname
  for i = 0, n_elements(u)-1 do begin
    d = pathnames[u[i]].dir_name
    PRINTF, final_file, '<LI><A HREF="'+suboutfile[i]+'.html">', d, '</A>'
  endfor
  PRINTF, final_file, '</UL><P>'
  PRINTF, final_file, '<HR>'
  if not keyword_set(mastlist) then begin
    for i = 0, n_elements(u)-1 do begin
      openw, templun, suboutfile[i]+'.html', /get_lun
      PRINTF, templun, '<!-- This file was generated by mk_html_help.pro -->'
; Header stuff.
      PRINTF, templun, '<html>'
      PRINTF, templun, ' '
; Title.
      PRINTF, templun, '<head>'
      PRINTF, templun, '<TITLE>', pathnames[u[i]].dir_name, '</TITLE>'
      PRINTF, templun, '</head>'
      PRINTF, templun, ' '
                                ; Title and intro info.
      PRINTF, templun, '<body>'
      PRINTF, templun, '<P>'
      PRINTF, templun, 'This page was created by the IDL library routine '
      PRINTF, templun, '<CODE>mk_html_help2</CODE>.'
      PRINTF, templun, '<br>'
      PRINTF, templun, '<P>'
      PRINTF, templun, '<STRONG>Last modified: </STRONG>', SYSTIME(), '.<P>'
      PRINTF, templun, ' '
      PRINTF, templun, '<HR>'
      PRINTF, templun, ' '

      PRINTF, templun, '<A NAME="ROUTINELIST">'
      PRINTF, templun, '<H1>Directory Listing of Routines</H1></A>'
      PRINTF, templun, '<UL>'
      d = pathnames[u[i]].dir_name
      PRINTF, templun, '<H1>', d, '</H1>'
      w = where(d eq pathnames.dir_name, c)
      if c ne 0 then begin
        ws = sort(pathnames[w].file_name)
        w = w[ws]
        for j = 0, c-1 do begin
          entry = dict[s[w[j]]]
          IF (entry.nline GT 0) THEN begin
            PRINTF, templun, '<LI><A HREF="#', entry.subject, '">', entry.subject, '</A>'
            if strlen(entry.purpose) ne 0 then $
              printf, templun, purp_delim+entry.purpose
          endif
        endfor
      endif
      PRINTF, templun, '<br>'
;	    PRINTF,templun,'<HR>'
      PRINTF, templun, '</UL><P>'
      free_lun, templun         ;close this file now
    endfor
  endif
;stop

 ; Index.
  PRINTF, final_file, '<P>'
  PRINTF, final_file, '<H1>Alphabetical List of Routines</H1></A>'
  PRINTF, final_file, '<UL>'
  ifu = 0
  FOR i = 0, count-1 DO BEGIN
    entry = dict[indices[i]]
    whdir = dictwhdir[indices[i]]
    IF i EQ first_uniq[ifu] THEN BEGIN 
      PRINTF, final_file, '<A NAME="LIST_', first_letter[first_uniq[ifu]], '">'
      ifu = (ifu + 1) MOD nfu
    ENDIF 
    IF (entry.nline GT 0) THEN begin
      PRINTF, final_file, '<LI><A HREF="'+suboutfile[whdir]+'.html#', entry.subject, '">', $
        entry.subject, '</A>'
      if strlen(entry.purpose) ne 0 then $
        printf, final_file, purp_delim+entry.purpose
    endif
  ENDFOR
  PRINTF, final_file, '</UL><P>'
  PRINTF, final_file, ' '
  if not keyword_set(mastlist) then begin
    for i = 0, n_elements(u)-1 do begin
      openw, templun, suboutfile[i]+'.html', /get_lun, /append
      PRINTF, templun, '<HR>'
      PRINTF, templun, ' '
;print, crosslink,clturbo
      is_letter = bytarr(256)
      is_letter[65:90] = 1
      is_letter[97:122] = 1
      is_letter[48:57] = 1
      is_letter[95] = 1
                                ; Descriptions.
      PRINTF, templun, '<H1>Routine Descriptions</H1>'
      free_lun, templun
    endfor
    ON_IOERROR, TXT_DONE
    FOR i = 0, count-1 DO BEGIN
      entry = dict[indices[i]]
      whdir = dictwhdir[indices[i]]
      allwhdir = (dictwhdir eq whdir)
      IF(entry.nline GT 0) THEN BEGIN
        openw, templun, suboutfile[whdir]+'.html', /get_lun, /append
        PRINTF, templun, '<A NAME="', entry.subject, '">'
        PRINTF, templun, '<H2>', entry.subject, '</H2></A>'
        prev_i = i - 1
        IF (prev_i LT 0) THEN $
          dostep = 0 $ 
        ELSE BEGIN
          prev_ent = dict[indices[prev_i]]
          in_dir = allwhdir[indices[prev_i]]
          dostep = prev_ent.nline EQ 0 or in_dir eq 0
        ENDELSE
        WHILE dostep DO BEGIN
          prev_i = prev_i - 1
          IF (prev_i LT 0) THEN $
            dostep = 0 $
          ELSE BEGIN
            prev_ent = dict[indices[prev_i]]
            in_dir = allwhdir[indices[prev_i]]
            dostep = prev_ent.nline EQ 0 or in_dir eq 0
          ENDELSE
        ENDWHILE
        IF (prev_i GE 0) THEN $
          PRINTF, templun, '<A HREF="#', prev_ent.subject, '">[Previous Routine]</A>'
        next_i = i + 1
        IF (next_i GE count) THEN $
          dostep = 0 $
        ELSE BEGIN
          next_ent = dict[indices[next_i]]
          in_dir = allwhdir[indices[next_i]]
          dostep = next_ent.nline EQ 0 or in_dir eq 0
        ENDELSE
        WHILE dostep DO BEGIN
          next_i = next_i + 1
          IF (next_i GE count) THEN $
            dostep = 0 $
          ELSE BEGIN
            next_ent = dict[indices[next_i]]
            in_dir = allwhdir[indices[next_i]]
            dostep = next_ent.nline EQ 0 or in_dir eq 0
          ENDELSE
        ENDWHILE
        IF (next_i LT count) THEN $
          PRINTF, templun, '<A HREF="#', next_ent.subject, '">[Next Routine]</A>'
        PRINTF, templun, '<A HREF="#ROUTINELIST">[List of Routines]</A>'
        PRINTF, templun, '<PRE>'
        tmp = ''
        POINT_LUN, txt_file, entry.offset
        FOR j = 1, entry.nline DO BEGIN
          READF, txt_file, tmp
          if keyword_set(crosslink) then begin
            pos = 0
            if keyword_set(clturbo) then pos = strpos(tmp, clturbo)
            if pos lt 0 then goto, norefsatall
            for cross = 0, count-1 do begin
              reference = dict[cross].subject
              if entry.subject eq reference then goto, noreference
              refdir = dictwhdir[cross]
              pos = strpos(strupcase(tmp), reference)
              if pos lt 0 then goto, noreference
              reflen = strlen(reference)
              tmplen = strlen(tmp)
              refarr = bytarr(tmplen+2)
              refarr[1:tmplen] = byte(tmp)
              if is_letter[refarr[pos]] then goto, noreference
              if is_letter[refarr[pos+reflen+1]] then goto, noreference
              newref = '<A href="'+suboutfile[refdir]+'.html#'+reference+'">'+reference+'</A>'
              refarr = string(refarr[1:tmplen+1])
              tmp = strmid(refarr, 0, pos)+newref+strmid(refarr, pos+reflen, 300)
              IF (verbose NE 0) THEN $
                dprint, reference+' cross linked in '+entry.subject,dlevel=2
                ;message,/info, reference+' cross linked in '+entry.subject
noreference:
            endfor
norefsatall:
          endif 
          PRINTF, templun, tmp
        ENDFOR
        PRINTF, templun, '</PRE><P>'
        IF (entry.lib NE -1L) THEN BEGIN
          fname = libfiles[entry.lib]
          lname = infiles[entry.indx]
          IF (strict) THEN BEGIN
            alt_mhh_strict, fname
            alt_mhh_strict, lname
          ENDIF
          PRINTF, templun, '<STRONG>(See '+fname+' in '+lname+')</STRONG><P>'
        ENDIF ELSE BEGIN
          fname = strippath(infiles[entry.indx])
          dir = fname.dir_name
          reldir = strippath(fname.dir_name)
          reldir = reldir.file_name
          fname = fname.file_name
          IF (strict) THEN alt_mhh_strict, fname
          fname = '<A href="'+reldir+'/'+fname+'">'+dir+'/'+fname+'</A>'
          PRINTF, templun, '<STRONG>(See '+fname+')</STRONG><P>'
        ENDELSE
        PRINTF, templun, '<HR>'
        PRINTF, templun, ' '
        free_lun, templun
      ENDIF
    ENDFOR
TXT_DONE:
    ON_IOERROR, NULL
    FREE_LUN, txt_file
  endif

 ; Footer.
  PRINTF, final_file, '</body>'
  PRINTF, final_file, '</html>'
  FREE_LUN, final_file
END




;----------------------------------------------------------------------------
PRO mk_html_help2, sources, outfile, VERBOSE=verbose,TITLE=title,STRICT=strict $
  ,crosslink=crosslink,clturbo=clturbo,print_purpose=print_purpose $
  ,FILENAME= outfile2,allfiles=allfiles,no_dirlist=no_dirlist,mastlist=mastlist $
  ,listname= listname

 compile_opt idl2

 IF (NOT KEYWORD_SET(verbose)) THEN verbose=0
 IF (NOT KEYWORD_SET(title)) THEN title="Extended IDL Help" 
 IF (NOT KEYWORD_SET(strict)) THEN strict=0
 if n_elements(crosslink) eq 0 then crosslink = 1
 if n_elements(print_purpose) eq 0 then print_purpose = 1


 infiles = ''
 istlb = 0b

if not keyword_set(sources) then begin
	sources = setup_sources('')
	sources = ['./',sources]
endif

if keyword_set(outfile2) then outfile = outfile2
if not keyword_set(outfile) then outfile = 'help'
if not keyword_set(listname) then listname = outfile+'_list'
if n_elements(clturbo) eq 0 then clturbo = '"'

 count = N_ELEMENTS(sources)

 IF (count EQ 0) THEN BEGIN
  DPRINT,'No source IDL directories found.'
  RETURN
 ENDIF

 ; Open a temporary file for the documentation text.
 OPENW, txt_file, FILEPATH('userhtml.txt', /TMP), /GET_LUN, /DELETE

 ; Loop on sources. 
 FOR i=0, count-1 DO BEGIN
  src = sources[i]

  ; Strip any version numbers from the source so we can check for the
  ; VMS .tlb or .pro extension.
  vpos = STRPOS(src,';')
  IF (vpos NE -1) THEN vsource = STRMID(src,0,vpos) ELSE vsource = src

   ; Test if the source is a VMS text library.
  IF (!VERSION.OS EQ 'vms') AND (STRLEN(vsource) GT 4) AND $
     (STRUPCASE(STRMID(vsource, STRLEN(vsource)-4,4)) EQ '.TLB') THEN BEGIN 
   infiles = [infiles,src]
   istlb = [istlb, 1b]
  ENDIF ELSE BEGIN
   ; Test if the file is a .PRO file.
   IF (STRUPCASE(STRMID(vsource, STRLEN(vsource)-4,4)) EQ '.PRO') THEN BEGIN 
    infiles = [infiles,src]
    istlb = [istlb, 0b]

   ; If not a VMS text library or .PRO file, it must be a directory name.
   ENDIF ELSE BEGIN
    CASE !VERSION.OS_FAMILY OF
     'Windows': tok = '\'
     'MacOS': tok = ':'
     'unix': tok = '/'
     'vms': tok = ''
    ENDCASE

    ; Get a list of all .pro files in the directory.
    flist = FINDFILE(src+tok+'*.pro',COUNT=npro)
    IF (npro GT 0) THEN BEGIN
     infiles = [infiles,flist]
     istlb = [istlb, REPLICATE(0b,npro)]
    ENDIF

    ; Get a list of all .tlb files in the directory.
    flist = FINDFILE(src+tok+'*.tlb',COUNT=ntlb)
    IF (ntlb GT 0) THEN BEGIN
     infiles = [infiles,flist]
     istlb = [istlb, REPLICATE(1b,ntlb)]
    ENDIF
   ENDELSE
  ENDELSE
 ENDFOR

 count = N_ELEMENTS(infiles)
 IF (count EQ 1) THEN BEGIN
  DPRINT,'No IDL files found.'
  RETURN
 ENDIF 
 infiles = infiles[1:*]
 istlb = istlb[1:*]
 count = count-1
 
 ; Loop on all files.
 FOR i=0,count-1 DO BEGIN
  src = infiles[i]

  IF (istlb[i]) THEN BEGIN
   ; If it is a text library, get a list of routines by spawning
   ; a LIB/LIST command. 
   SPAWN,'LIBRARY/TEXT/LIST ' + src,files
   lib_count = N_ELEMENTS(files)
   j=0
   WHILE ((j LT lib_count) AND (STRLEN(files[j]) NE 0)) DO j = j + 1
   lib_count = lib_count - j - 1
   IF (count GT 0) THEN files = files[j+1:*]
   ; We do a separate extract for each potential routine. This is
   ; pretty slow, but easy to implement. This routine is generally
   ; run once in a long while, so I think it's OK.
   lib_total = N_ELEMENTS(libfiles)
   IF (lib_total EQ 0) THEN libfiles = files ELSE libfiles = [libfiles, files]
   FOR j=0, lib_count-1 DO BEGIN
    name = FILEPATH('mkhtmlhelp.scr',/TMP)
    SPAWN,'LIBRARY/TEXT/EXTRACT='+files[j]+'/OUT='+name+' '+src
    alt_mhh_grab_hdr,files[j],dict,i,lib_total+j,txt_file,verbose,strict $
       ,print_purpose = print_purpose
   ENDFOR
  ENDIF ELSE BEGIN
   name = infiles[i]
   alt_mhh_grab_hdr,name,dict,i,-1L,txt_file,verbose,strict,  $
        print_pu=print_purpose,allfile=allfiles
  ENDELSE
 ENDFOR

 ; Generate the HTML file.
 if keyword_set(dict) then $
 alt_mhh_gen_file,dict,txt_file,infiles,libfiles,outfile,verbose,title,strict $
   ,crosslink=crosslink,clturbo = clturbo,no_dirlist=no_dirlist, $
   mastlist=mastlist, listname=listname $
 else alt_mhh_dum_file,outfile,title,verbose

END

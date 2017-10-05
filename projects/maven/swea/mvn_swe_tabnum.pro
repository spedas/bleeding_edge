;+
;FUNCTION:   mvn_swe_tabnum
;PURPOSE:
;  Given a checksum, determines the corresponding table number.  Only returns
;  table numbers >= 3.  The first two tables are rarely or never used.
;
;  Six predefined tables are provided via keyword TABNUM.  These correspond to 
;  tables as loaded into flight software.
;
;        1 : Xmax = 6., Vrange = [0.75, 750.], V0scale = 1., /old_def
;            primary table for ATLO and Inner Cruise (first turnon)
;              -64 < Elev < +66 ; 7 < E < 4650
;               Chksum = 'CC'X
;
;        2 : Xmax = 6., Vrange = [0.75, 375.], V0scale = 1., /old_def
;            alternate table for ATLO and Inner Cruise (never used)
;              -64 < Elev < +66 ; 7 < E < 2340
;               Chksum = '1E'X
;
;        3 : Xmax = 5.5, Vrange = [3./Ka, 750.], V0scale = 0., /old_def
;            primary table for Outer Cruise
;              -59 < Elev < +61 ; 3 < E < 4630
;               Chksum = 'C0'X
;               GSEOS svn rev 8360
;
;        4 : Xmax = 5.5, Vrange = [2./Ka, 750.], V0scale = 1., /old_def
;            alternate table for Outer Cruise
;              -59 < Elev < +61 ; 3 < E < 4650
;               Chksum = 'DE'X
;               GSEOS svn rev 8361
;
;        5 : Xmax = 5.5, Vrange = [3./Ka, 750.], V0scale = 0.
;            primary table for Transition and Science
;              -59 < Elev < +61 ; 3 < E < 4630
;               Chksum = 'CC'X
;               GSEOS svn rev 8481
;
;        6 : Xmax = 5.5, Vrange = [2./Ka, 750.], V0scale = 1.
;            alternate table for Transition and Science
;              -59 < Elev < +61 ; 3 < E < 4650
;               Chksum = '82'X
;               GSEOS svn rev 8482
;
;USAGE:
;  tabnum = mvn_swe_tabnum(i)
;
;INPUTS:
;       i:            The checksum or table number.
;
;KEYWORDS:
;       INVERSE:      Given a table number, return its checksum.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2014-04-30 17:34:56 -0700 (Wed, 30 Apr 2014) $
; $LastChangedRevision: 14990 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_tabnum.pro $
;
;CREATED BY:	David L. Mitchell  2014-01-03
;FILE:  mvn_swe_tabnum.pro
;-
function mvn_swe_tabnum, i, inverse=inverse

  if keyword_set(inverse) then begin
    case i of
      3 : chksum = 'C0'XB
      4 : chksum = 'DE'XB
      5 : chksum = 'CC'XB
      6 : chksum = '82'XB
      else   : begin
                 print,'Tabnum ',i,' not recognized.',format='(a,i2.2,a)'
                 chksum = 0B
               end
    endcase

    return, chksum
  endif

  case byte(i) of
    'C0'XB : tabnum = 3
    'DE'XB : tabnum = 4
    'CC'XB : tabnum = 5
    '82'XB : tabnum = 6
    else   : begin
               print,'Checksum ',i,' not recognized.',format='(a,Z2.2,a)'
               tabnum = 0
             end
  endcase

  return, tabnum

end

;+
;FUNCTION:   mvn_swe_tabnum
;PURPOSE:
;  Given a checksum, determines the corresponding table number.  Only returns
;  table numbers >= 3.
;
;  Nine tables are defined.  Tables 1-4 are obsolete.  Tables 5 and 6 
;  correspond to tables as loaded into flight software during commissioning 
;  in October 2014.  Tables 7 and 8 (hires at 200 and 50 eV) were loaded in
;  2018.  Table 9 was loaded on 2022-04-22, overwriting table 6.
;
;  Table 5 and the three hires tables (7, 8, 9) are stored in non-volatile
;  memory in the PFDPU.  After a power cycle, the 4 tables are automatically
;  loaded into SWEA memory by the PFDPU, so there's no need to upload the
;  tables from the ground unless one of them becomes corrupted.
;
;  Tables 7, 8 and 9 all have a checksum of zero.  See mvn_swe_getlut for
;  the methods used to detect and distinguish these tables.
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
;            loaded into SWEA LUT 0
;
;        6 : Xmax = 5.5, Vrange = [2./Ka, 750.], V0scale = 1.
;            alternate table for Transition and Science
;              -59 < Elev < +61 ; 3 < E < 4650
;               Chksum = '82'X
;               GSEOS svn rev 8482
;            loaded into SWEA LUT 1
;            overwritten on 2022-04-22 (see table 9 below)
;
;        7 : Xmax = 5.5, Erange = [200.,200.], V0scale = 0.
;            Hires 32-Hz at 200 eV
;              -59 < Elev < +61 ; E = 200
;               Chksum = '00'X
;            loaded into SWEA LUT 2 on 2018-11-09
;
;        8 : Xmax = 5.5, Erange = [50.,50.], V0scale = 0.
;            Hires 32-Hz at 50 eV
;              -59 < Elev < +61 ; E = 50
;               Chksum = '00'X
;            loaded into SWEA LUT 3 on 2018-08-28
;
;        9 : Xmax = 5.5, Erange = [125.,125.], V0scale = 0.
;            Hires 32-Hz at 125 eV
;              -59 < Elev < +61 ; E = 125
;               Chksum = '00'X
;            loaded into SWEA LUT 1 on 2022-04-22
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
; $LastChangedDate: 2025-12-02 13:39:15 -0800 (Tue, 02 Dec 2025) $
; $LastChangedRevision: 33891 $
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
      7 : chksum = '00'XB
      8 : chksum = '00'XB
      9 : chksum = '00'XB
      else   : begin
                 print,'Tabnum ',i,' not recognized.',format='(a,i2.2,a)'
                 chksum = 'FF'XB
               end
    endcase

    return, chksum
  endif

  case byte(i) of
    'C0'XB : tabnum = 3
    'DE'XB : tabnum = 4
    'CC'XB : tabnum = 5
    '82'XB : tabnum = 6
    '00'XB : tabnum = 7  ; ambiguous, could be table 7, 8 or 9.
    else   : begin
               print,'Checksum ',i,' not recognized.',format='(a,Z2.2,a)'
               tabnum = 0
             end
  endcase

  return, tabnum
end

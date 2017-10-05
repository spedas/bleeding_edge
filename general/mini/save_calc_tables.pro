;+
;Procedure: save_calc_tables
;
;Purpose:  This simple routine calls the proper procedures to generate the files needed to run the mini language
;          You should run this routine if you've made a change to the mini_language descriptions and you want that change to
;          be reflected in the runtime behavior of calc.pro  This routine generates two files: grammar.sav and parse_tables.sav
;
;
; $LastChangedBy: pcruce $
; $LastChangedDate: 2012-07-12 15:26:32 -0700 (Thu, 12 Jul 2012) $
; $LastChangedRevision: 10700 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/mini/save_calc_tables.pro $
;-

pro save_calc_tables

  rt_info = routine_info('calc',/source)
  path = file_dirname(rt_info.path) + '/'
  
  grammar = productions()
  slr,grammar,parse_tables=parse_tables
  
  if parse_tables.type eq 'error' then begin
    message,'cannot save parse tables due to error in table generation'
  endif
  
  save,grammar,filename=path+'grammar.sav'
  save,parse_tables,filename=path+'parse_tables.sav'

end
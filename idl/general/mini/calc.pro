;+
; Procedure: calc
;
; Purpose:  This routine takes a string as input and interprets the string as a mini-language.
;    This language can manipulate normal idl variables and tplot variables.  The idl variables
;    that can be modified are non-system variables in the scope in which the procedure is called.
;    
;    
; Inputs: s : A string that will be interpreted as the mini language
;                    
; Keywords: error:
;              If an error occurs during processing this keyword will return a struct 
;              that contains information about the error.  If error is set at time of input
;              this routine will set it to undefined, before it interprets 's' to prevent internal errors.
;              
;              Note that setting this keyword will supress automatic printing of errors unless the verbose keyword is set.
;           
;           function_list: return an array of strings that lists of the names/syntax of
;                          available functions in the mini_language.  Return without processing 's'
;                          if an argument in the returned name is in brackets it is optional
;                          for example:  min(x[,dim]) 
;           operator_list:  return an array of strings that lists of the names of available
;                           operators in the mini_language. Return without processing 's'
;                           
;           verbose:  set this keyword if you want the routine to print errors to screen when you are using the error keyword.
;           
;           quiet: set this keyword to supress printing of errors to the screen at all times.
;                         
;           gui_data_obj: If 'calc' is being used inside the gui, then the loaded_data object will
;                         be passed in through this keyword.  NOTE: end users should not even set
;                         this argument. 
;                         
;           replay: if 'calc' is being used from the GUI, this keyword is set when the GUI is replaying a document. 
;                   Users shouldn't set this keyword manually
;           
;           overwrite_selections: tracking the user's selections to overwrite tplot variables that already exist. 
;                               Users shouldn't set this keyword manually
;           
;           statusbar: the status bar object will be passed through this keyword. Users shouldn't set this keyword manually
;           
;           historywin: the history window object will be passed through this keyword. Users shouldn't set this keyword manually
;           
;           gui_id: the top level GUI widget ID -- for prompting the user for overwrites in the GUI. Users shouldn't set this keyword manually
;                         
;           interpolate:  Set this to the name of the tplot variable that you'd like to interpolate data to.  If you set this keyword to 1(ex /interpolate), but 
;           don't name a specific variable, it will interpolate to the left-most variable in each binary operation.  This second way of using this keyword should be used carefully in complicated expressions, 
;           as it may not be obvious which interpolation operations are being performed  
;         
;           nan: Deprecated.  Use /nan keyword to functions
;         
;           cumulative_total: Deprecated.  Use /cumulative keyword to total function. 
;             
;              
; Outputs: none, but it will modify various variables in your environment
;              
; Examples:
;    calc,'a = 5'
;    calc,'"pos_re" = "tha_state_pos"/6371.2'
;    calc,'a += 7',/v ;abbreviated verbose keyword
;    calc,'"tvar" = "tvar" + var'
;    calc,'"tvar" = ln("tvar")'
;    calc,'"tvar" = total("tvar"+3,2)'
;    calc,'"tvar" = -a + 5.43e-7 ^ ("thb_fgs_dsl_x" / total("thb_fgs_dsl_x"))
;    calc,operator_list=o,function_list=f
;    calc,'"th?_state_pos_re" = "th?_state_pos"/6371.2' ;globbing
;
; Notes:
;    1. The language generally uses a fairly straightforward computational syntax.  The main
;       difference from idl is that quoted strings are treated as tplot variables in this language
;    2. A full specification of language syntax in backus-naur form can be found
;       in the file bnf_formal.txt, the programmatic specification of this syntax
;       can be found in productions.pro
;    3. The language is parsed using an slr parser.  The tables required to do this parsing
;       are generated and stored ahead of time in the file grammar.sav and parse_tables.sav
;    4. The routines that describe the evaluation rules for the language can be found in the file
;       mini_routines.pro
;    5. If you want to modify the way the language works you'll probably need to modify productions.pro,
;       regenerate the slr parse tables using save_calc_tables and modify/add routines to mini_routines.pro
;    6. Arrays must have the same dimensions to be combines, and tplot variables must also have the same times.
;    7. Procedures: min,max,mean,median,count,total  all take a second argument that allow you to select the
;       dimension over which the operation is performed
;    8. Calc supports globbing in tplot variable operands, but for it to work, the output variable also needs to be a tplot variable with the same number of glob characters.
;       Correct: calc,'"th?_state_pos_re" = "th?_state_pos"/6371.2'
;       Incorrect: calc,'tha_state_pos_re = "th?_state_pos"/6371.2'
;       Incorrect: calc,'"th?_state_pos_re" = "th?_state_*"/6371.2'
;       
; See Also:
;   All routines in the ssl_general/mini directory
;   The techniques used for this interpreter are based on two books:
;  
;   1. Compilers:Principles,Techniques,and Tools by Aho,Sethi,& Ullman 1986 (esp. Ch3(for lexical analysis) & Ch4(for SLR parser design))
;  
;   2. Structure & Interpretation of Computer Programs by Abelson & Sussman 1996 (esp. Ch4(evaluators & meta-circular evaluator))
;   
;   If you want to understand/modify this program it may help to use these books as
;   a reference.
;   
;   Also see:  thm_crib_calc.pro for examples of usage
;      
; ToDo: 1. Implement 0 argument functions
;       2. Implement keywords for functions
;       3. Implement procedures
;       4. Implement control statements
;
; $LastChangedBy: crussell $
; $LastChangedDate: 2020-12-04 12:40:48 -0800 (Fri, 04 Dec 2020) $
; $LastChangedRevision: 29436 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/mini/calc.pro $
;-

pro calc,s,error=error,function_list=function_list,operator_list=operator_list,verbose=verbose,gui_data_obj=gui_data_obj,interpolate=interpolate,quiet=quiet,$
    replay=replay,overwrite_selections=overwrite_selections,overwrite_count=overwrite_count,statusbar=statusbar,historywin=historywin,gui_id=gui_id,calc_prompt_obj=calc_prompt_obj,$ ; keywords used in the GUI for tracking overwrites of tvars
    nan=nan,cumulative_total=cumulative_total,$ ;depecated keywords, remain only to print warning messages
    _extra=ex

  compile_opt idl2
 
  if undefined(overwrite_selections) then overwrite_selections = ''

  ; check for GUI objects
  if ~keyword_set(calc_prompt_obj) then calc_prompt_obj = ''
  if ~keyword_set(statusbar) then statusbar = ''
  if ~keyword_set(historywin) then historywin = ''
  if ~keyword_set(gui_id) then gui_id = ''
  
  ;clear error if set at time of input
  if keyword_set(error) then begin
    t = temporary(error)
  endif
  
  ;if requested return list of functions
  if arg_present(function_list) then begin
    mini_routines
    
    function_list = (function_list()).name + (function_list()).syntax
   
  endif  
  
  if arg_present(operator_list) then begin
    mini_routines

    list = (operator_list()).name
    
    ;replace unary/binary minus codes with normal minus
    ;...this should probably be done in the operator_list routine
    list = [list[0:2],'-',list[5:*]]
    list = [list[0:3],'+',list[6:*]]
    list = [list[0:5],'/',list[8:*]]
    operator_list = list
    
  endif
  
  if arg_present(operator_list) || arg_present(function_list) then begin
    return
  endif

  
  ;get path of routine
  rt_info = routine_info('calc',/source)
  path = file_dirname(rt_info.path) + '/'
 
  ;read grammar and parse table information from file
  ;once read cache data for next time
  get_data, 'calc_grammar_cached', data=grammar
  get_data, 'calc_parse_tables_cached', data=parse_tables
  if ~is_struct(grammar) OR ~is_struct(parse_tables) then begin
    restore,path+'grammar.sav'
    restore,path+'parse_tables.sav'
    store_data, 'calc_grammar_cached',data=grammar
    store_data, 'calc_parse_tables_cached', data=parse_tables
  endif
 
 ; restore,path+'grammar.sav'
 ; restore,path+'parse_tables.sav'
  
  if ~keyword_set(gui_data_obj) || ~obj_valid(gui_data_obj) then begin
    gui_data_obj = obj_new()
  endif
  
  if ~is_string(interpolate) && ~keyword_set(interpolate) then begin
    interpolate = 0
  endif
  
  defsysv, '!mini_globals', exists=mini_globals_exists
  if mini_globals_exists eq 1 then begin
      overwrite_count = (*!mini_globals.replay_struct).overwrite_count
      overwrite_selections = (*!mini_globals.replay_struct).overwrite_selections
  endif else begin
      overwrite_count = 0
  endelse
  
  ; a structure for keeping track of replay details, user's overwrite selections
  replay_struct = {replay: byte(~undefined(replay)), overwrite_selections: overwrite_selections, overwrite_count: overwrite_count, gui_id: gui_id, statusBar: statusbar, historyWin: historywin, calc_prompt_obj: calc_prompt_obj}
  
  ;set global variables
  mini_globals = {scope_level:scope_level()-1,$ ;Top level scope must be known to look up variables in local environment
                  gui_data_obj:gui_data_obj,$ ;This object allows data I/O with the gui directly
                  interpolate:ptr_new(interpolate),$ ;This keyword specifies whether automatic interpolation should be used, and how (1=interpolate)
                  verbose:(keyword_set(verbose) || ~arg_present(error)) && ~keyword_set(quiet),$
                  extra:ptr_new(is_struct(ex)?ex:0),$
                  replay_struct: ptr_new(replay_struct)} ;extra arguments for the interpolate routine
  
  if undefined(replay) then begin
      ; Not replaying a document, need to check if the mini_globals system variable exists
      if mini_globals_exists eq 1 then begin
          ; mini_globals system variable exists, need to check if replay flag is set
          if (*!mini_globals.replay_struct).replay eq 1 then begin
              ; flag was set, need to reset it to 0
              ptr_free, !mini_globals.replay_struct
              replay_struct.replay = 0
              str_element, mini_globals, 'replay_struct', ptr_new(replay_struct), /add_rep
          endif
      endif
      defsysv,'!mini_globals',mini_globals
      
  endif
  

  if n_elements(nan) gt 0 then begin
    error = {type:'error',name:'NAN keyword is deprecated. Use /nan with calc function calls.',value:nan}
    if !mini_globals.verbose then begin
      dprint,error
    endif
    return
  endif
  
  if n_elements(cumulative_total) gt 0 then begin
    error = {type:'error',name:'cumulative_total keyword is deprecated. Use /cumulative with total function calls.',value:cumulative_total}
    if !mini_globals.verbose then begin
      dprint,error
    endif
    return
  endif
  
  ;check that arg is set
  if ~keyword_set(s) then begin
    error = {type:'error',name:'Input string not set',value:'s'}
    if !mini_globals.verbose then begin
      dprint,error
    endif
    ptr_free,!mini_globals.extra
    ptr_free,!mini_globals.interpolate
    return
  endif


  ;split the input string into a list of tokens
  lex,s,token_list=token_list,error=error  
  
  if keyword_set(error) then begin
  
    if  !mini_globals.verbose then begin
      if in_set('NAME',tag_names(error)) then begin
        dprint,error.name + ':'
      endif
      
      if in_set('VALUE',tag_names(error)) then begin
        for i = 0,n_elements(error.value)-1 do begin
          dprint,error.value[i]
        endfor
      endif else begin
        dprint,error
      endelse
    
    endif
    
    ptr_free,!mini_globals.extra
    ptr_free,!mini_globals.interpolate
    return
  endif

  if is_endline_type(token_list[0]) then begin
    ptr_free,!mini_globals.extra
    ptr_free,!mini_globals.interpolate
    return
  endif
  
  ;extra strings from variables in token list
  string_var_preprocess,token_list,var_token_list,error=error,verbose=!mini_globals.verbose
  
  if keyword_set(error) then begin
    ptr_free,!mini_globals.extra
    ptr_free,!mini_globals.interpolate
    return
  endif
  
  dim_var = dimen(var_token_list)
  
  for i = 0,dim_var[0]-1 do begin
    
    string_glob_preprocess,reform(var_token_list[i,*]),globbed_token_list,error=error,verbose=!mini_globals.verbose
  
    if keyword_set(error) then begin
      ptr_free,!mini_globals.extra
      ptr_free,!mini_globals.interpolate
      return
    endif
  
    dim_glob = dimen(globbed_token_list)
    
    for j = 0,dim_glob[0]-1 do begin
    
      ;evaluate the list of tokens using the parse table and grammar provided
      evaluate,reform(globbed_token_list[j,*]),grammar,parse_tables,error=error
    
      if keyword_set(error) then begin
    
        if !mini_globals.verbose then begin
      
          if in_set('VALUE',tag_names(error)) then begin
            for j = 0,n_elements(error.value)-1 do begin
              dprint,error.value[j]
            endfor
          endif else begin
            dprint,error
          endelse
       
        endif
    
       ;return
    
      endif
      
    endfor
  
  endfor
  
  ptr_free,!mini_globals.extra
  ptr_free,!mini_globals.interpolate
  return

end

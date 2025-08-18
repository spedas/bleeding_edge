;+
;Procedure: productions
;
;Purpose:  generates the grammar for the mini_language.  This file combined with the routines in mini_routines
;          describes most of the structure of the mini_language.  By changing these one should be able to change 
;          the language with relatively few modifications to other files. 
;
;Outputs: A structure that describes the grammar of the mini_language
;
;
; $LastChangedBy: pcruce $
; $LastChangedDate: 2016-06-16 16:20:59 -0700 (Thu, 16 Jun 2016) $
; $LastChangedRevision: 21331 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/mini/productions.pro $
;-



function productions

  nonterminals = ['sp','s','exp','args','keyword']
  terminals = ['var','asm','tvar','number','++',$
               '--','~','u-','b-','not','(',')',$
               'func','^','*','#','##','k/','b/',$
               'mod','u+','b+','<','>','eq','ne',$
               'le','lt','ge','gt','and',$
               'or','xor','&&','||',',','<cr>']
  
  
  ;operators list
  operators = reverse(['^','++','--',$
                       '*','#','##','k/','b/','mod',$
                       'u+','u-','b+','b-','<','>','not','~',$
                       'eq','ne','le','lt','ge','gt',$
                       'and','or','xor',$
                       '&&','||'])
    
  ;list of operator precedences, same number indicates same precedence, lower number indicates lower precedence.
  precedences = reverse([5,5,5,$
                         4,4,4,4,4,4,$
                         3,3,3,3,3,3,3,3,$
                         2,2,2,2,2,2,$
                         1,1,1,$
                         0,0])
  
  ;the number of rules in the grammar
  n = 47
  
  start = 's'
  augment = 'sp'
  endline = '<cr>'
  empty_sym = 'empty'
  
  production = {type:'production',$ ;Type is a field defined for most structs in the mini language
                left:'',$ ;left is the left side/nonterminal of a production
                right:strarr(6),$ ;right is the right side terminal/nonterminal list of a production
                op:'',$ ;op is the operator used in the production right side, if any...used in determining operator precedence conflicts
                fun:'',$ ;the name of a function that evaluates the production when called by the parser
                index:0,$ ;the index of the production, to save the trouble of constantly search for it 
                length:0 } ; the length of the production right side, to save from constantly counting it
  
  
  left = strarr(n)
  
  left[0] = 'sp'
  left[1:2] = 's'
  left[3:40] = 'exp'
  left[41:44] = 'args'
  left[45:46] = 'keyword' 
 
  plist = replicate(production,n)
  
  plist[*].left = left
  
  i = 0
  
  plist[i].right[0] = ['s']
  plist[i].length = 1
  plist[i].fun = 'mini_return'
  i++
  plist[i].right[0:2] = ['var','asm','exp']
  plist[i].length = 3
  plist[i].fun  = 'mini_assign'
  i++
  plist[i].right[0:2] = ['tvar','asm','exp']
  plist[i].length = 3
  plist[i].fun = 'mini_assign'
  i++
  plist[i].right[0] = ['number']
  plist[i].length = 1
  plist[i].fun = 'mini_number'
  i++
  plist[i].right[0] = ['var']
  plist[i].length = 1
  plist[i].fun = 'mini_var'
  i++
  plist[i].right[0] = ['tvar']
  plist[i].length = 1
  plist[i].fun = 'mini_var'
  i++
  plist[i].right[0:1] = ['++','var']
  plist[i].op = '++'
  plist[i].length = 2
  plist[i].fun = 'mini_incdec'
  i++
  plist[i].right[0:1] = ['++','tvar']
  plist[i].op = '++'
  plist[i].length = 2
  plist[i].fun = 'mini_incdec'
  i++
  plist[i].right[0:1] = ['--','var']
  plist[i].op = '--'
  plist[i].length = 2
  plist[i].fun = 'mini_incdec'
  i++
  plist[i].right[0:1] = ['--','tvar']
  plist[i].op = '--'
  plist[i].length = 2
  plist[i].fun = 'mini_incdec'
  i++
  plist[i].right[0:1] = ['var','++']
  plist[i].op = '++' 
  plist[i].length = 2
  plist[i].fun = 'mini_incdec'
  i++
  plist[i].right[0:1] = ['tvar','++']
  plist[i].op = '++'
  plist[i].length = 2
  plist[i].fun = 'mini_incdec'
  i++
  plist[i].right[0:1] = ['var','--']
  plist[i].op = '--'
  plist[i].length = 2
  plist[i].fun = 'mini_incdec'
  i++
  plist[i].right[0:1] = ['tvar','--']
  plist[i].op = '--'
  plist[i].length = 2
  plist[i].fun = 'mini_incdec'
  i++
  plist[i].right[0:1] = ['~','exp']
  plist[i].op = '~'
  plist[i].length = 2
  plist[i].fun = 'mini_uop'
  i++
  plist[i].right[0:1] = ['u+','exp']
  plist[i].op = 'u+'
  plist[i].length = 2
  plist[i].fun = 'mini_uop'
  i++
  plist[i].right[0:1] = ['u-','exp']
  plist[i].op = 'u-'
  plist[i].length = 2
  plist[i].fun = 'mini_uop'
  i++
  plist[i].right[0:1] = ['not','exp']
  plist[i].op = 'not'
  plist[i].length = 2
  plist[i].fun = 'mini_uop'
  i++
  plist[i].right[0:2] = ['(','exp',')']
  plist[i].length = 3
  plist[i].fun = 'mini_paren'
  i++
  plist[i].right[0:3] = ['func','(','args',')']
  plist[i].length = 4
  plist[i].fun = 'mini_func'
  i++
  plist[i].right[0:2] = ['exp','^','exp']
  plist[i].op = '^'
  plist[i].length = 3
  plist[i].fun = 'mini_bop'
  i++
  plist[i].right[0:2] = ['exp','*','exp']
  plist[i].op = '*'
  plist[i].length = 3
  plist[i].fun = 'mini_bop'
  i++
  plist[i].right[0:2] = ['exp','#','exp']
  plist[i].op = '#'
  plist[i].length = 3
  plist[i].fun = 'mini_bop'
  i++
  plist[i].right[0:2] = ['exp','##','exp']
  plist[i].op = '##'
  plist[i].length = 3
  plist[i].fun = 'mini_bop'
  i++
  plist[i].right[0:2] = ['exp','b/','exp']
  plist[i].op = 'b/'
  plist[i].length = 3
  plist[i].fun = 'mini_bop'
  i++
  plist[i].right[0:2] = ['exp','mod','exp']
  plist[i].op = 'mod'
  plist[i].length = 3
  plist[i].fun = 'mini_bop'
  i++
  plist[i].right[0:2] = ['exp','b+','exp']
  plist[i].op = 'b+'
  plist[i].length = 3
  plist[i].fun = 'mini_bop'
  i++
  plist[i].right[0:2] = ['exp','b-','exp']
  plist[i].op = 'b-'
  plist[i].length = 3
  plist[i].fun = 'mini_bop'
  i++
  plist[i].right[0:2] = ['exp','<','exp']
  plist[i].op = '<'
  plist[i].length = 3
  plist[i].fun = 'mini_bop'
  i++
  plist[i].right[0:2] = ['exp','>','exp']
  plist[i].op = '>'
  plist[i].length = 3
  plist[i].fun = 'mini_bop'
  i++
  plist[i].right[0:2] = ['exp','eq','exp']
  plist[i].op = 'eq'
  plist[i].length = 3
  plist[i].fun = 'mini_bop'
  i++
  plist[i].right[0:2] = ['exp','ne','exp']
  plist[i].op = 'ne'
  plist[i].length = 3
  plist[i].fun = 'mini_bop'
  i++
  plist[i].right[0:2] = ['exp','le','exp']
  plist[i].op = 'le'
  plist[i].length = 3
  plist[i].fun = 'mini_bop'
  i++
  plist[i].right[0:2] = ['exp','lt','exp']
  plist[i].op = 'lt'
  plist[i].length = 3
  plist[i].fun = 'mini_bop'
  i++
  plist[i].right[0:2] = ['exp','ge','exp']
  plist[i].op = 'ge'
  plist[i].length = 3
  plist[i].fun = 'mini_bop'
  i++
  plist[i].right[0:2] = ['exp','gt','exp']
  plist[i].op = 'gt'
  plist[i].length = 3
  plist[i].fun = 'mini_bop'
  i++
  plist[i].right[0:2] = ['exp','and','exp']
  plist[i].op = 'and'
  plist[i].length = 3
  plist[i].fun = 'mini_bop'
  i++
  plist[i].right[0:2] = ['exp','or','exp']
  plist[i].op = 'or'
  plist[i].length = 3
  plist[i].fun = 'mini_bop'
  i++
  plist[i].right[0:2] = ['exp','xor','exp']
  plist[i].op = 'xor'
  plist[i].length = 3
  plist[i].fun = 'mini_bop'
  i++
  plist[i].right[0:2] = ['exp','&&','exp']
  plist[i].op = '&&'
  plist[i].length = 3
  plist[i].fun = 'mini_bop'
  i++
  plist[i].right[0:2] = ['exp','||','exp']
  plist[i].op = '||'
  plist[i].length = 3
  plist[i].fun = 'mini_bop'
  i++
  plist[i].right[0] = ['exp']
  plist[i].length = 1
  plist[i].fun = 'mini_arg'
  i++
  plist[i].right[0] = ['keyword']
  plist[i].length = 1
  plist[i].fun = 'mini_arg'
  i++
  plist[i].right[0:2] = ['exp',',','args']
  plist[i].length = 3
  plist[i].fun = 'mini_args'
  i++
  plist[i].right[0:2] = ['keyword',',','args']
  plist[i].length = 3
  plist[i].fun = 'mini_args'
  i++
  plist[i].right[0:1] = ['k/','var']
  plist[i].length = 2
  plist[i].fun = 'mini_keyword'
  i++ 
  
  plist[i].right[0:3] = ['k/','var','asm','var']
  plist[i].length = 4
  plist[i].fun = 'mini_keyword'
  i++
  
  plist.index = lindgen(n_elements(plist))
  
  grammar = {type:'grammar',nonterminals:nonterminals,terminals:terminals,operators:operators,precedences:precedences,start:start,augment:augment,endline:endline,empty:empty_sym,production_list:plist}
  
  return,grammar

end

; $LastChangedBy: moka $
; $LastChangedDate: 2015-05-07 15:47:03 -0700 (Thu, 07 May 2015) $
; $LastChangedRevision: 17514 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/sitl/eva/source/cw_data/eva_data_load_thm.pro $

FUNCTION eva_data_load_thm, state
  compile_opt idl2

  catch, error_status
  if error_status ne 0 then begin
    eva_error_message, error_status, msg='filename= '
    catch, /cancel
    return, -1
  endif

  ;--- INITIALIZE ---
  dir       = state.PREF.EVA_CACHE_DIR
  ;duration  = state.duration
  duration  = (str2time(state.end_time)-str2time(state.start_time))/86400.d0; duration in unit of days.
  eventdate = state.eventdate
  paramlist = strlowcase(state.paramlist_thm); list of parameters read from parameterSet file
  probelist = state.probelist_thm
  ptype = size(probelist[0], /type)
  if ptype ne 7 then return, 'No'
  ;if probelist[0] eq -1 then return, 'No'

  imax      = n_elements(paramlist)
  pmax      = n_elements(probelist)
  cparam = imax*n_elements(probelist)
  if cparam ge 17 then begin
    rst = dialog_message('Total of '+strtrim(string(cparam),2)+' THEMIS parameters. Still plot?',/question,/center)
  endif else rst = 'Yes'
  if rst eq 'No' then return, 'No'

  ;--- LIST OF DATES ---
  loaddateList = ['dummy']
  start_date = strmid(state.start_time,0,10)
  end_time   = str2time(state.end_time)
  day = str2time(start_date)
  while day lt end_time do begin
    ; If end_time is 2014-03-02/00:24 and day = str2time(2014-03-02) then add the date
    ; If end_time is 2014-03-02/00:00 and day = str2time(2014-03-02) then don't add the date
    ; This is achieved by using "lt" rather than "le"
    loaddateList = [loaddateList,strmid(time_string(day),0,10)]
    day += 86400.d0
  endwhile
  loaddateList = loaddateList[1:n_elements(loaddateList)-1]
  dmax = n_elements(loaddateList)

  print,'EVA: paramlist_thm...'
  for i=0,imax-1 do begin
    print,'EVA:    '+strtrim(string(i),2)+': '+paramlist[i]
  endfor

  ;--- LIST OF REQUIRED FILES ---
  ; Based on the user input 'paramlist', the following code makes a list of files to be
  ; restored. The list is stored into the array 'refileList'
  refilelist = strarr(1)
  for i=0,imax-1 do begin; for each parameter

    ; remove suffix
    slen = strlen(paramlist[i])
    ;lencmb = 0
    ;pos = strpos(paramlist[i],'cmb')  & if pos eq slen-3 then lencmb = 3
    ;pos = strpos(paramlist[i],'comb') & if pos eq slen-4 then lencmb = 4
    ;sdif = slen-lencmb-2
    sdif = slen-2
    match  = (strpos(paramlist[i],'_m') eq sdif)
    match += (strpos(paramlist[i],'_x') ge sdif)
    match += (strpos(paramlist[i],'_y') ge sdif)
    match += (strpos(paramlist[i],'_z') ge sdif)
    match += (strpos(paramlist[i],'_p') ge sdif)
    match += (strpos(paramlist[i],'_t') ge sdif)
    if match gt 1 then begin
      message, 'ERROR: something is wrong with the parameter name:', paramlist[i]
      ;return,-1
    endif
    ;    if match then paramlist0 = strmid(paramlist[i],0,slen-lencmb-2) $
    ;             else paramlist0 = strmid(paramlist[i],0,slen-lencmb  )
    paramlist0 = strmid(paramlist[i],0,slen-match*2)

    ; add to refilelist
    if (strpos(paramlist0,'*') ne -1) and (strpos(paramlist0,'*') ne 2) then begin
      message, 'ERROR: '+paramlist[i]+' --> "*" was found in a wrong position.'
      ;return, -1
    endif
    if (strpos(paramlist0,'*') eq 2) or (strpos(paramlist0,'w') eq 2) then begin ; wildcard found
      for p=0,pmax-1 do begin; for each probe
        if strmatch(strmid(paramlist0,0,2),strmid(probelist[p],0,2))then begin
          fname = probelist[p]+strmid(paramlist0,3,100)
          refilelist = [refileList, fname]
        endif
      endfor
    endif else begin
      refilelist = [refileList, paramlist0]
    endelse
  endfor


  rmax = 0
  if n_elements(refileList) gt 1 then refileList = refileList[1:*]
  refilelist = refilelist[UNIQ(refilelist, SORT(refilelist))]; choose only unique elements

  rmax = n_elements(refilelist)

  print,'EVA: Required files...'
  for r=0,rmax-1 do begin
    print,'EVA:    '+strtrim(string(r),2)+': '+refilelist[r]
  endfor


  ;--- CHECK IF CACHE FILES EXIST ---

  nofileList = strarr(1)
  for dd=0,dmax-1 do begin; for each date
    for r=0,rmax-1 do begin; for each of refilelist


      yyyy = strmid(loaddateList[dd],0,4)
      mmdd = strmid(loaddateList[dd],5,5)
      svdir = dir+yyyy+'/'+mmdd+'/'
      filename = loaddateList[dd]+'_'+refilelist[r]+'.tplot'
      fullname = svdir + filename
      result = file_info(fullname)
      if result.exists then begin
        ; *socs* tplot_variables are frequently changed based on user settings of the tables.
        ; If a user changed the table and wanted to replot the tplot_variable, then
        ; the old tplot_variable should be deleted.
        if strmatch(filename,'*socs*') then begin
          file_delete, fullname, /ALLOW_NONEXISTENT
          del_data,'*socs*'
          nofileList = [nofileList, filename]
        endif
      endif else begin
        nofileList = [nofileList, filename]
      endelse
    endfor; for each of refilelist
  endfor; for each date
  count = 0
  if n_elements(nofileList) gt 1 then begin
    nofileList = nofileList[1:*]
    count = n_elements(nofileList)
  endif
  print,'EVA: number of missing files:'+ string(count)

  ;--- GENERATE MISSING CACHE FILES ---

  answer = 'Yes'
  if count gt 0 then begin
    print,'EVA: Files to be created are:
    for c=0,count-1 do begin
      print, 'EVA: '+nofileList[c]
    endfor
    answer = dialog_message(string(count)+' cache files will be created. Proceed?',$
      /question,title='LOAD DATA',/center)
    if(strcmp(answer,'Yes'))then begin
      progressbar = Obj_New('progressbar', background='white', Text='Generating cache files ..... 0 %')
      progressbar -> Start
      for c=0,count-1 do begin; for each of nofileList

        if progressbar->CheckCancel() then begin
          ok = Dialog_Message('User cancelled operation.',/center) ; Other cleanup, etc. here.
          answer = 'No'
          break
        endif
        if (strpos(nofileList[c],'.tplot') gt 0) then begin
          prg = 100.0*c*1.d/count
          sprg = 'Generating cache files ....... '+string(prg,format='(I2)')+' %'
          progressbar -> Update, prg, Text=sprg
          ;////////////////////////////////////////////////////

          answer = eva_data_load_daily(nofileList[c],dir)

          ;/////////////////////////////////////////////////////
        endif else begin
          anw = dialog_message(nofileList[c] + ' needs to be generated manually',/info,/center)
          answer = 'No'
          break
        endelse

      endfor; for each of nofileList
      progressbar -> Destroy
    endif
  endif


  ;--- RESTORE TPLOT CACHE FILES ---

  if(strcmp(answer,'Yes'))then begin
    progressbar = Obj_New('progressbar', color='blue', background='white', Text='Restoring cache files ..... 0 %')
    progressbar -> Start


    first = bytarr(rmax)
    first[0:rmax-1] = 1
    for dd=0,dmax-1 do begin; for each date
      for r=0,rmax-1 do begin; for each of refilelist
        ;............................................
        prg = 100.0*(rmax*dd*1.d + r)/(dmax*rmax)
        sprg = 'Restoring tplot data ....... '+string(prg,format='(I2)')+' %'
        progressbar -> Update, prg, Text=sprg
        ;.............................................
        yyyy = strmid(loaddateList[dd],0,4)
        mmdd = strmid(loaddateList[dd],5,5)
        svdir = dir+yyyy+'/'+mmdd+'/'
        filename = loaddateList[dd]+'_'+refilelist[r]+'.tplot'
        fullname = svdir + filename
        result = file_info(fullname)


        ;
        ; restore tplot file if file existed
        if result.exists then begin
          if result.size lt 20000.0 then begin
            print, 'EVA: !!!!!!!!!! WARNING !!!!!!!!!!'
            print, 'EVA: file ', filename, ' is skipped because it contains'
            print, 'EVA: no data or the file size is too small; ', result.size*0.001, ' KB'
            print, 'EVA: !!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
            file_delete, fullname, /ALLOW_NONEXISTENT; delete the file
          endif else begin
            if first[r] eq 1 then begin
              tplot_restore,filename=fullname
              first[r] = 0
            endif else begin; if the same tplot variable is loaded again (because of date update), then append.
              tplot_restore,filename=fullname,/append
            endelse

            ; POST DATA PROCESSING
            if strmatch(refilelist[r],'*_fg*'     ) then eva_cap, refilelist[r]
            ;if strmatch(refilelist[r],'*_density*') then eva_cap, refilelist[r], max=10.0

          endelse; result.size
        endif; result.exists

      endfor; for each of refilelist
    endfor; for each date
    progressbar -> Destroy
  endif; if answer='Yes'


  return, answer
END

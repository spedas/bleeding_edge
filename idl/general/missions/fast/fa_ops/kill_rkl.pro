;+------------------------------------------------------------------------------
;  KILL_RKL
;  Read a file of csh-style lines like:
;      set "RKL = `kill -9 12345`"
;  and execute the command inside the backticks using IDL's SPAWN.
;
;  Usage:
;      KILL_RKL, 'commands.txt'              ; executes
;      KILL_RKL, 'commands.txt', /DRYRUN     ; just prints what it would do
;      KILL_RKL, 'commands.txt', LOG=log     ; returns vector of log lines
;
;  Notes:
;  - Blank lines and lines starting with # are ignored.
;  - If a line has no backticks, it’s skipped.
;  - Captures shell output and exit status per command.
;------------------------------------------------------------------------------
PRO KILL_RKL, filename, DRYRUN=dryrun, LOG=log

  COMPILE_OPT strictarr

  IF N_PARAMS() EQ 0 THEN BEGIN
     MESSAGE, /info, 'Usage: KILL_RKL, filename'
     Return
  ENDIF

  ; Ensure file exists
  IF ~FILE_TEST(filename, /READ) THEN BEGIN
     MESSAGE, /info, 'File not found or not readable: ' + filename
     Return
  ENDIF

;open and read all lines
  OPENR, lun, filename, /GET_LUN
  ON_ERROR, 2                   ; return to caller on error
  line = ''
  log = ''
;Read all lines
  WHILE ~EOF(lun) DO BEGIN
     READF, lun, line
     print, line
    ; Normalize whitespace
    line = STRTRIM(line, 2)
    ; Skip blanks and comments
    IF (line EQ '') OR STRMATCH(line, '#*') THEN CONTINUE
    ; Find command inside backticks
    p1 = STRPOS(line, '`')
    p2 = (p1 GE 0) ? STRPOS(line, '`', p1+1) : -1
    IF (p1 LT 0) OR (p2 LE p1) THEN BEGIN
       ; No backticks -> ignore line
       log = [log, 'SKIP: no backticks -> ' + line]
       CONTINUE
    ENDIF

    cmd = STRMID(line, p1+1, p2-p1-1)
    cmd = STRTRIM(cmd, 2)

    ; Optional: guard against empty command
    IF cmd EQ '' THEN BEGIN
       log = [log, 'SKIP: empty command in -> ' + line]
       CONTINUE
    ENDIF

    ; Execute or dry-run
    IF KEYWORD_SET(dryrun) THEN BEGIN
       PRINT, 'DRYRUN:', cmd
       log = [log, 'DRYRUN: ' + cmd]
    ENDIF ELSE BEGIN
      result = ''
      exit_status = 0L
      ; Run via shell to support pipelines/expansions typical in kill wrappers
      ; (On UNIX, SPAWN uses /bin/sh -c by default.)
      SPAWN, cmd, result, EXIT_STATUS=exit_status
      ; Show what happened
      IF N_ELEMENTS(result) GT 0 THEN BEGIN
        FOR i=0, N_ELEMENTS(result)-1 DO PRINT, result[i]
      ENDIF
      PRINT, 'CMD:', cmd, ' -> EXIT_STATUS=', exit_status
      log = [log, 'RUN: ' + cmd + ' -> EXIT_STATUS=' + STRTRIM(STRING(exit_status),2)]
      IF N_ELEMENTS(result) GT 0 THEN log = [log, result]
    ENDELSE
  ENDWHILE
  If(n_elements(log) Gt 1) Then log = log[1:*]
  ; Cleanup
  FREE_LUN, lun
END

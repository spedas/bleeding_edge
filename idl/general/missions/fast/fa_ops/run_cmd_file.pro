;+------------------------------------------------------------------------------
;  RUN_CMD_FILE
;  Execute each non-empty, non-comment line in a file as a Unix shell command.
;
;  Format:
;    - One command per line.
;    - Lines starting with '#' (after trimming leading spaces) are ignored.
;    - A trailing backslash '\' at the end of a line joins with the next line.
;
;  Usage:
;    RUN_CMD_FILE, 'commands.txt'                       ; execute
;    RUN_CMD_FILE, 'commands.txt', /DRYRUN              ; print only
;    RUN_CMD_FILE, 'commands.txt', /HALT_ON_ERROR       ; stop on first failure
;    RUN_CMD_FILE, 'commands.txt', LOG=log              ; returns log lines
;    RUN_CMD_FILE, 'commands.txt', /QUIET               ; suppress PRINT output
;
;  Notes:
;    - Commands run under /bin/sh -c "<line>" to allow pipes, redirects, etc.
;    - Exit status is captured; 0 = success (per POSIX), nonzero = failure.
;------------------------------------------------------------------------------
PRO RUN_CMD_FILE, filename, DRYRUN=dryrun, HALT_ON_ERROR=halt_on_error, $
                  LOG=log, QUIET=quiet

  COMPILE_OPT strictarr

  IF N_PARAMS() LT 1 THEN MESSAGE, 'Usage: RUN_CMD_FILE, filename'

  IF ~FILE_TEST(filename, /READ) THEN $
    MESSAGE, 'File not found or not readable: ' + filename

  log = ''

  OPENR, lun, filename, /GET_LUN
  ON_ERROR, 2  ; return to caller on runtime error

  line = ''
  cmd  = ''
  lineno = 0L

  WHILE ~EOF(lun) DO BEGIN
    READF, lun, line
    lineno = lineno + 1
    line = STRTRIM(line, 2)

    ; Skip blanks and full-line comments
    IF (line EQ '') THEN CONTINUE
    IF (STRLEN(line) GT 0) THEN BEGIN
      first = STRMID(line, 0, 1)
      IF (first EQ '#') THEN CONTINUE
    ENDIF

    ; Handle simple backslash continuations:
    ; If a line ends with an unescaped '\' we join with the next line(s).
    tmp = line
    WHILE (STRLEN(tmp) GT 0) AND (STRMID(tmp, STRLEN(tmp)-1, 1) EQ '\') DO BEGIN
      ; remove the trailing backslash
      tmp = STRMID(tmp, 0, STRLEN(tmp)-1)
      ; read next physical line
      IF EOF(lun) THEN BREAK
      READF, lun, line
      lineno = lineno + 1
      line = STRTRIM(line, 2)
      tmp = tmp + ' ' + line
    ENDWHILE
    cmd = tmp

    ; Ignore if the assembled command is now blank
    IF (STRTRIM(cmd,2) EQ '') THEN CONTINUE

    ; Dry run?
    IF KEYWORD_SET(dryrun) THEN BEGIN
      IF ~KEYWORD_SET(quiet) THEN PRINT, 'DRYRUN: ', cmd
      log = [log, 'DRYRUN: ' + cmd]
      CONTINUE
    ENDIF

    ; Escape embedded double quotes for the sh -c "..." wrapper
    parts = STRSPLIT(cmd, '"', /EXTRACT)
    cmd_esc = STRJOIN(parts, '\"')

    ; Execute via /bin/sh to support pipes, redirects, expansions, etc.
    ; Using explicit /bin/sh avoids platform-dependent SPAWN behavior.
    result = ''
    status = 0L
    SPAWN, '/bin/sh -c "' + cmd_esc + '"', result, EXIT_STATUS=status

    ; Emit output lines (if any)
    IF (N_ELEMENTS(result) GT 0) AND (~KEYWORD_SET(quiet)) THEN BEGIN
      FOR i=0, N_ELEMENTS(result)-1 DO PRINT, result[i]
    ENDIF

    ; Log status
    msg = 'RUN: "' + cmd + '" -> EXIT_STATUS=' + STRTRIM(STRING(status),2)
    IF ~KEYWORD_SET(quiet) THEN PRINT, msg
    log = [log, msg]
    IF N_ELEMENTS(result) GT 0 THEN log = [log, result]

    ; Optionally stop on first nonzero exit
    IF KEYWORD_SET(halt_on_error) AND (status NE 0) THEN BEGIN
      IF ~KEYWORD_SET(quiet) THEN PRINT, 'HALTING on error.'
      FREE_LUN, lun
      RETURN
    ENDIF
  ENDWHILE

  If(n_elements(log) Gt 1) Then log = log[1:*]
  
  FREE_LUN, lun
END

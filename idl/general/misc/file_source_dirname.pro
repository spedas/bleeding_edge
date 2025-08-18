;+
;Function: file_source_dirname
;Purpose:  Returns the directory path of the source file which calls this function.
;   This is useful for determining the directory of associated data files.
;Warning:  May not work for a precompile version of code.
;Author:  D Larson  2008
;-


function file_source_dirname,mark_directory=mark_directory
    stack = scope_traceback(/structure)
    filename = stack[scope_level()-2 > 0].filename
    dir = file_dirname(filename,mark_directory=mark_directory)
    return,dir
end
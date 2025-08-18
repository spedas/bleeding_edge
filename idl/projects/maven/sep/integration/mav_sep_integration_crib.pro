
if not keyword_set(rinit) then begin
    recorder,host='128.32.98.66',port='7070',destination='APID30_YYYYMMDD_hhmmss.dat'
    recorder,host='128.32.98.66',port='4040',destination='RawTCP_YYYYMMDD_hhmmss.dat'
    rinit=1
endif
realtime=1

end



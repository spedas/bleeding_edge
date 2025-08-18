; PURPOSE:
;         This script obtain only xml header from das files. The xml header is 
;         parssed into orderedhash array using das_xml_to_orderhash class.
;         Some of the xml headers parresd normaly, but most often the parser 
;         retunrs an error: 
;         IDLFFXMLSAX::PARSEFILE: Parser SAX fatal error: File: IDL STRING, line: ..., column: ... :: The prefix '...' has not been mapped to any URI        
;
;$LastChangedBy: adrozdov $
;$LastChangedDate: 2019-08-19 13:48:54 -0700 (Mon, 19 Aug 2019) $
;$LastChangedRevision: 27621 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/external/das2pro/xml_parsing/das2pro_xml_test.pro $
;-

oUrl = IDLnetURL()

; Van_Allen_Probes example works
; sUrl = "https://emfisis.physics.uiowa.edu/das/server?server=dataset&dataset=Van_Allen_Probes/A/Ephemeris/Geomagnetic&start_time=2012-09-10&end_time=2012-09-15&interval=3600"

; Juno example retunrs the error
sUrl = "http://jupiter.physics.uiowa.edu/das/server?server=dataset&dataset=Juno/Ephemeris/Jupiter_Radial_SC&start_time=2017-02-02T12:58&end_time=2017-02-02T12:59&interval=0.5"

; Read the das file
buffer = oUrl.get(URL=sUrl, /buffer)

; Get two meta data recoreds as XMLs
nStreamHdrSz = long(string(buffer[4:9]))
xml_string_1 = string(buffer[10:10+nStreamHdrSz-1])

iBuf = 10 + nStreamHdrSz

nPktHdrSz = long(string(buffer[iBuf+4:iBuf+9]))

xml_string_2 = string(buffer[iBuf+10:iBuf+10+nPktHdrSz-1])

; Print record as xml
print, xml_string_1
; print, xml_string_2


t = obj_new('das_xml_to_orderhash', PARSER_URI="http://www-pw.physics.uiowa.edu/das2/das_dsid-0.2.xsd")

; Attement of using the schema according to https://das2.org/Das2.2.2-ICD_2017-05-09.pdf. However, the link is broken.
;t = obj_new('das_xml_to_orderhash', PARSER_URI="http://www-pw.physics.uiowa.edu/das2/das_dsid-0.2.xsd")

; Parsing the xml data. Returns the error if atributes with prefix are presented
t->ParseFile, xml_string_1, /xml_string

; Print the result of the parsing.
print, t->getHash()


end

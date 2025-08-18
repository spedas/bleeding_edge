;+
;
; FUNCTION:
;     spd_neturl_error2msg
;     
; PURPOSE:
;     returns a list, where the index is the cURL error code and the item is the status message that the code represents;
;     useful for finding meaningful download error messages
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2017-03-20 08:55:34 -0700 (Mon, 20 Mar 2017) $
; $LastChangedRevision: 22990 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/spedas_tools/spd_download/spd_neturl_error2msg.pro $
;-

function spd_neturl_error2msg
    out = strarr(75)

    out[1] = 'The URL you passed uses an unsupported protocol. The problem might be an unused compile-time option or a misspelled protocol string.'
    out[2] = 'Very early initialization code failed. This is likely an internal error or problem.'
    out[3] = 'The URL was not properly formatted.'
    out[4] = 'Boom goes the dynamite.'
    out[5] = 'The given proxy host could not be resolved.'
    out[6] = 'The given remote host was not resolved.'
    out[7] = 'Failed to connect to host or proxy.'
    out[8] = 'After connecting to an FTP server, the IDLnetURL object received a strange or bad reply. The remote server is probably not an OK FTP server.'
    out[9] = 'A service was denied by the FTP server due to lack of access. When a login fails, this is not returned.'
    out[10] = 'This is never returned.'
    out[11] = 'After sending the FTP password to the server, an unexpected code was received.'
    out[12] = 'After sending a user name to the FTP server, an unexpected code was received.'
    out[13] = 'The IDLnetURL object did not receive a sensible result from the server in response to either a PASV or EPSV command.'
    out[14] = 'FTP servers return a 227-line as a response to a PASV command. This code is returned if the IDLnetURL object fails to parse that line.'
    out[15] = 'Indicates an internal failure when looking up the host used for the new connection.'
    out[16] = 'A bad return code for either the PASV or EPSV command was sent by the FTP server, preventing the IDLnetURL object from continuing.'
    out[17] = 'An error was received when trying to set the transfer mode to binary.'
    out[18] = 'A file transfer was shorter or larger than expected. This happens when the server first reports an expected transfer size, and then delivers data that doesn''t match the previously-given size.'
    out[19] = 'Either the server returned a weird reply to a RETR command, or a zero-byte transfer was completed.'
    out[20] = 'After a completed file transfer, the FTP server did not send a proper "transfer successful" code.'
    out[21] = 'When sending custom QUOTE commands to the remote server, one of the commands returned an error code of 400 or higher.'
    out[22] = 'This is returned if CURLOPT_FAILONERROR is TRUE and the HTTP server returns an error code that is >= 400.
    out[23] = 'An error occurred when writing received data to a local file, or an error was returned from a write callback.
    out[24] = 'Not used
    out[25] = 'The server denied the STOR operation. The error buffer usually contains the server''s explanation.'
    out[26] = 'There was a problem reading a local file, or the read callback returned an error.'
    out[27] = 'A memory allocation request failed. This is not a good thing.'
    out[28] = 'The specified time-out period was exceeded.'
    out[29] = 'Failed to set ASCII transfer type (TYPE A).'
    out[30] = 'The FTP PORT command returned an error. This often happens when the address is improper.'
    out[31] = 'The FTP REST command failed.'
    out[32] = 'The FTP SIZE command failed. SIZE is not a fundamental FTP command; it is an extension and not all servers support it. This is not a surprising error.'
    out[33] = 'The HTTP server does not support or accept range requests.'
    out[34] = 'This is an odd error that mainly occurs due to internal confusion.'
    out[35] = 'A problem occurred somewhere in the SSL/TLS handshake. Check the error buffer for more information.'
    out[36] = 'An FTP resume was attempted beyond the file size.'
    out[37] = 'A file in the format of "FILE://" couldn''t be opened, most likely because the file path is invalid. File permissions may also be the culprit.'
    out[38] = 'The LDAP bind operation failed.'
    out[39] = 'LDAP search failed.'
    out[40] = 'The LDAP library was not found.'
    out[41] = 'A required LDAP function was not found.'
    out[42] = 'A callback returned an abort code.'
    out[43] = 'Internal error. A function was called with a bad parameter.'
    out[44] = 'Not used.'
    out[45] = 'A specified outgoing interface could not be used. Use CURLOPT_INTERFACE to set the interface for outgoing connections.'
    out[46] = 'Not used.'
    out[47] = 'Too many redirects. When following redirects, IDL hit the maximum amount. Set your limit with CURLOPT_MAXREDIRS.'
    out[48] = 'An option set with CURLOPT_TELNETOPTIONS was not recognized.'
    out[49] = 'A TELNET option string was malformed.'
    out[50] = 'Not used.'
    out[51] = 'The remote server''s SSL certificate is invalid.'
    out[52] = 'The server returned nothing. In certain circumstances, getting nothing is considered an error.'
    out[53] = 'The specified crypto engine wasn''t found.'
    out[54] = 'Can not set the selected SSL crypto engine as the default.'
    out[55] = 'Sending network data failed.'
    out[56] = 'Failure in receiving network data.'
    out[57] = 'Share is in use.'
    out[58] = 'There is a problem with the local certificate.'
    out[59] = 'Could not use the specified cipher.'
    out[60] = 'The peer certificate cannot be authenticated with known CA certificates.'
    out[61] = 'Unrecognized transfer encoding.'
    out[62] = 'Invalid LDAP URL.'
    out[63] = 'Maximum file size exceeded.'
    out[64] = 'Requested FTP SSL level failed.'
    out[65] = 'Sending the data required rewinding the data to retransmit, but the rewind operation failed.'
    out[66] = 'Failed to initialize the SSL engine.'
    out[67] = 'The user password (or similar) was not accepted and the login failed.'
    out[68] = 'File not found on TFTP server.'
    out[69] = 'There is a permission problem on the TFTP server.'
    out[70] = 'TFTP server is out of disk space.'
    out[71] = 'Illegal TFTP operation.'
    out[72] = 'Unknown TFTP transfer ID.'
    out[73] = 'TFTP file already exists.'
    out[74] = 'No such TFTP user.'
    return, out
end
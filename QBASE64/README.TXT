Please see LICENSE.TXT for legal information.

This contains my base64 encode/decode service program.
(Requires V7R2 or later)

PC Filename             Source File,Member on i5/OS
-----------------       -------------------------------
BASE64_H.RPGLE          QBASE64,BASE64_H
BASE64.BND              QBASE64,BASE64
BASE64R4.RPGLE          QBASE64,BASE64R4
EXAMPLE01.RPGLE         QBASE64,EXAMPLE01
EXAMPLE02.RPGLE         QBASE64,EXAMPLE02
EXAMPLE03.RPGLE         QBASE64,EXAMPLE03
EXAMPLE04.RPGLE         QBASE64,EXAMPLE04
EXAMPLE11.RPGLE         QBASE64,EXAMPLE11
EXAMPLE12.RPGLE         QBASE64,EXAMPLE12
EXAMPLE13.RPGLE         QBASE64,EXAMPLE13
EXAMPLE14.RPGLE         QBASE64,EXAMPLE14
IFSIO_H.RPGLE           QBASE64,IFSIO_H
LICENSE.TXT             QBASE64,LICENSE
README.TXT              QBASE64,README


Copying these members to the iSeries:

a) Import this i Project to RDi.

b) Assign a connection and a library to the i Project.

c) Push the project to the IBM i.

This Base64 encoder/decoder was initially developed by Scott Klement.
The following procedures have been added by Thomas Raddatz

 * base64_encodeBufferToStream()
 * base64_encodeStreamToStream()
 * base64_decodeBufferToStream()
 * base64_decodeStreamToStream()
 * base64_getUserData()()

 * EXAMPLE01
 * EXAMPLE02
 * EXAMPLE03
 * EXAMPLE04 (requires Scott Klements YAJLR4 service program)

 * EXAMPLE11
 * EXAMPLE12
 * EXAMPLE13
 * EXAMPLE14 (requires Scott Klements YAJLR4 service program)
 
**free
//=============================================================================
// Copyright (c) 2005-2023 Scott C. Klement, Thomas Raddatz
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions
// are met:
// 1. Redistributions of source code must retain the above copyright
//    notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright
//    notice, this list of conditions and the following disclaimer in the
//    documentation and/or other materials provided with the distribution.
//
// THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
// ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
// OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
// HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
// LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
// OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
// SUCH DAMAGE.
//=============================================================================
//  BASE64R4 -- Service Program to Encode/Decode data using the
//              base64 algorithm.
//                               Scott Klement, January 14, 2005
//  To Compile:
//        CHGCURLIB CURLIB(xxx)
//        ADDLIBLE LIB(xxx)
//        CRTRPGMOD BASE64R4 SRCFILE(QBASE64) DBGVIEW(*LIST)
//        CRTSRVPGM SRVPGM(BASE64R4) SRCFILE(QBASE64) SRCMBR(BASE64)
//        CRTBNDDIR BNDDIR(BASE64)
//        ADDBNDDIRE BNDDIR(BASE64) OBJ((BASE64R4 *SRVPGM))
//=============================================================================
//  History:
//
//  Date        Name          Description
//  ----------  ------------  ---------------------------------------
//  June 2009   Th.Raddatz    Downloaded from Scott's web page.
//
//  June 2011   Th.Raddatz    Changed original version to use
//                            encodeRaw().
//                            Added procedures:
//                               base64_encodeStream()
//
//  June 2011   Th.Raddatz    Changed original version to use
//                            decodeRaw().
//                            Renamed:
//                               base64_encodeStream() to
//                               base64_encodeStreamToStream()
//                            Added procedures:
//                               base64_encodeBufferToStream()
//                               base64_decodeStreamToStream()
//                               base64_decodeBufferToStream()
//
//  07.01.2012  Th.Raddatz    Fixed encodeRaw() and decodeRaw() to
//                            properly send an ESCAPE message in case
//                            not all data could be written to the
//                            output file descripter.
//
//  19.02.2013  Th.Raddatz    Converted to **free.
//                            Added procedure base64_getUserData().
//
//=============================================================================
//   >>PRE-COMPILER<<
//     >>CRTCMD<<  CRTRPGMOD   MODULE(&LI/&OB) +
//                             SRCFILE(&SL/&SF) +
//                             SRCMBR(&SM);
//     >>COMPILE<<
//       >>PARM<< TRUNCNBR(*NO);
//       >>PARM<< DBGVIEW(*LIST);
//       >>PARM<< TGTRLS(V7R3M0);
//     >>END-COMPILE<<
//     >>EXECUTE<<
//   >>END-PRE-COMPILER<<
//=============================================================================

ctl-opt nomain
  copyright('Copyright (c) 2005-2023 Scott C. Klement.  All rights H +
  reserved.  A member called "LICENSE" was included with this +
  H distribution, and contains important license +
  information.') bnddir('QC2LE');

/include qbase64,base64_h

// Reports an invalid input character.
dcl-pr invalidChar extproc('invalidChar');
  CharPos int(10) value;
  Char    uns(3) value;
end-pr;

// Reports a C-runtime error.
dcl-pr cRuntimeError extproc('cRuntimeError');
  cErrorNbr int(10) value;
  procName  varchar(256) const;
end-pr;

//  encodeRaw: Internally used Base64 encoding procedure.
dcl-pr encodeRaw uns(10) extproc('encodeRaw');
  readFD    int(10) value;
  pRead     pointer(*proc) value;
  writeFD   int(10) value;
  pWrite    pointer(*proc) value;
  pUserData pointer value;
end-pr;

//  decodeRaw: Internally used Base64 decoding procedure.
dcl-pr decodeRaw uns(10) extproc('decodeRaw');
  readFD    int(10) value;
  pRead     pointer(*proc) value;
  writeFD   int(10) value;
  pWrite    pointer(*proc) value;
  pUserData pointer value;
end-pr;

//  base64_inAlphabet(): check if a given character is in the
dcl-pr base64_inAlphabet ind extproc(*CL: 'base64_inAlphabet');
  Char char(1) value;
end-pr;

// cErrno():  Returns the value of the C errno variable.
dcl-pr cErrno int(10) extproc('cErrno');
end-pr;

dcl-pr killBase64 extproc('killBase64');
  message varchar(512) options(*varsize) const;
end-pr;

// memcpy() - Copy Bytes
dcl-pr memcpy pointer extproc('memcpy');
  pDest pointer value;
  pSrc  pointer value;
  count uns(10) value;
end-pr;

dcl-s g_pRead pointer(*proc);
dcl-pr cb_read int(10) extproc(g_pRead);
  fd    int(10) value;
  pData pointer value;
  size  uns(10) value;
end-pr;

dcl-s g_pWrite pointer(*proc);
dcl-pr cb_write int(10) extproc(g_pWrite);
  fd    int(10) value;
  pData pointer value;
  size  uns(10) value;
end-pr;

//  errno--Set Pointer to Runtime Error Code
dcl-pr errno pointer extproc('__errno');
end-pr;

dcl-ds g_b64_alphabet qualified;
  alphabet char(64) inz('ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/');
  base64f  char(1) dim(64) overlay(alphabet);
end-ds;

dcl-ds g_b64_reverse qualified;
  revalphabet  char(256) inz(x'FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF+
                               FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF+
                               FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF+
                               FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF+
                               FFFFFFFFFFFFFFFFFFFFFFFFFFFF3eFF+
                               FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF+
                               FF3fFFFFFFFFFFFFFFFFFFFFFFFFFFFF+
                               FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF+
                               FF1a1b1c1d1e1f202122FFFFFFFFFFFF+
                               FF232425262728292a2bFFFFFFFFFFFF+
                               FFFF2c2d2e2f30313233FFFFFFFFFFFF+
                               FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF+
                               FF000102030405060708FFFFFFFFFFFF+
                               FF090a0b0c0d0e0f1011FFFFFFFFFFFF+
                               FFFF1213141516171819FFFFFFFFFFFF+
                               3435363738393a3b3c3dFFFFFFFFFFFF+
                               ');
  base64r     uns(3) dim(255) overlay(revalphabet: 2);
end-ds;

// Handle of the internally used 'stringBufferReader'.
dcl-ds g_hReader qualified;
  offset int(10) inz;
  size   int(10) inz;
  pData  pointer;
end-ds;

// Handle of the internally used 'stringBufferWriter'.
dcl-ds g_hWriter qualified;
  offset int(10) inz;
  size   int(10) inz;
  pData  pointer;
end-ds;

//  Internally used reader.
dcl-pr stringBufferReader int(10) extproc('stringBufferReader');
  fd      int(10) value;
  pBuffer pointer value;
  size    uns(10) value;
end-pr;

//  Internally used writer.
dcl-pr stringBufferWriter int(10) extproc('stringBufferWriter');
  fd      int(10) value;
  pBuffer pointer value;
  size    uns(10) value;
end-pr;

dcl-s g_stackCounter int(10);
dcl-s g_pUserData pointer;

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//  base64_getUserData:  Returns the user data that were passed
//                       to the stream encode or decode
//                       procedures.
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
dcl-proc base64_getUserData export;
  dcl-pi *n pointer;
  end-pi;

  return g_pUserData;

end-proc;

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//  base64_encode:  Encode binary data using Base64 encoding
//
//       Input = (input) pointer to data to convert
//    InputLen = (input) length of data to convert
//      Output = (output) pointer to memory to receive output
//     OutSize = (input) size of area to store output in
//
//  Returns length of encoded data, or space needed to encode
//      data. If this value is greater than OutSize, then
//      output may have been truncated.
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
dcl-proc base64_encode export;
  dcl-pi *n uns(10);
    Input      pointer value;
    InputLen   uns(10) value;
    Output     pointer value;
    OutputSize uns(10) value;
  end-pi;

  dcl-s outLen uns(10);

  g_stackCounter = 1;

  clear g_hReader;
  g_hReader.offset= 0;
  g_hReader.size  = InputLen;
  g_hReader.pData = Input;

  clear g_hWriter;
  g_hWriter.offset= 0;
  g_hWriter.size  = OutputSize;
  g_hWriter.pData = Output;

  outLen = encodeRaw(0: %paddr('stringBufferReader')
                     : 0: %paddr('stringBufferWriter'): *null);

  g_stackCounter = 0;

  return OutLen;

end-proc;

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//  base64_encodeStream:  Encode binary data using Base64 encoding
//
//      readFD = (input)  file descriptor of input stream
//       pRead = (input)  procedure pointer of read procedure
//     writeFD = (output) file descriptor of input stream
//      pWrite = (input)  procedure pointer of read procedure
//   pUserData = (input)  user data that can be read with
//                        base64_getUserData()
//
//  Returns length of encoded data.
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
dcl-proc base64_encodeStreamToStream export;
  dcl-pi *n uns(10);
    readFD    int(10) value;
    pRead     pointer(*proc) value;
    writeFD   int(10) value;
    pWrite    pointer(*proc) value;
    pUserData pointer options(*nopass) value;
  end-pi;

  dcl-s outLen int(10);

  g_stackCounter = 1;

  outLen = encodeRaw(readFD: pRead: writeFD: pWrite: pUserData);

  g_stackCounter = 0;

  return outLen;

end-proc;

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//  base64_encodeBuffer:  Encode binary data using Base64 encoding
//
//     pBuffer = (input)  pointer to input data
//        size = (input)  size of input buffer
//     writeFD = (output) file descriptor of input stream
//      pWrite = (input)  procedure pointer of read procedure
//   pUserData = (input)  user data that can be read with
//                        base64_getUserData()
//
//  Returns length of encoded data.
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
dcl-proc base64_encodeBufferToStream export;
  dcl-pi *n uns(10);
    Input     pointer value;
    InputLen  uns(10) value;
    writeFD   int(10) value;
    pWrite    pointer(*proc) value;
    pUserData pointer options(*nopass) value;
  end-pi;

  dcl-s outLen int(10);

  g_stackCounter = 1;

  clear g_hReader;
  g_hReader.offset= 0;
  g_hReader.size  = InputLen;
  g_hReader.pData = Input;

  outLen = encodeRaw(0: %paddr('stringBufferReader')
                       : writeFD: pWrite: pUserData);

  g_stackCounter = 0;

  return outLen;

end-proc;

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//  base64_decode: Decode base64 encoded data back to binary
//
//       Input = (input) pointer to base64 data to decode
//    InputLen = (input) length of base64 data
//      Output = (output) pointer to memory to receive output
//     OutSize = (input) size of area to store output in
//
//  Returns length of decoded data, or space needed to decode
//      data. If this value is greater than OutSize, then
//      output may have been truncated.
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
dcl-proc base64_decode export;
  dcl-pi *n uns(10);
    Input      pointer value;
    InputLen   uns(10) value;
    Output     pointer value;
    OutputSize uns(10) value;
  end-pi;

  dcl-s outLen uns(10);

  g_stackCounter = 1;

  clear g_hReader;
  g_hReader.offset= 0;
  g_hReader.size  = InputLen;
  g_hReader.pData = Input;

  clear g_hWriter;
  g_hWriter.offset= 0;
  g_hWriter.size  = OutputSize;
  g_hWriter.pData = Output;

  outLen = decodeRaw(0: %paddr('stringBufferReader')
                     : 0: %paddr('stringBufferWriter'): *null);

  g_stackCounter = 0;

  return OutLen;

end-proc;

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//  base64_decodeStreamToStream:
//  Decode binary data using Base64 decoding
//
//      readFD = (input)  file descriptor of input stream
//       pRead = (input)  procedure pointer of read procedure
//     writeFD = (output) file descriptor of input stream
//      pWrite = (input)  procedure pointer of read procedure
//   pUserData = (input)  user data that can be read with
//                        base64_getUserData()
//
//  Returns length of decoded data.
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
dcl-proc base64_decodeStreamToStream export;
  dcl-pi *n uns(10);
    readFD    int(10) value;
    pRead     pointer(*proc) value;
    writeFD   int(10) value;
    pWrite    pointer(*proc) value;
    pUserData pointer options(*nopass) value;
  end-pi;

  dcl-s outLen uns(10);

  g_stackCounter = 1;

  outLen = decodeRaw(readFD: pRead: writeFD: pWrite: pUserData);

  g_stackCounter = 0;

  return outLen;

end-proc;

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//  base64_decodeBuffer:
//  Decode binary data using Base64 decoding
//
//     pBuffer = (input)  pointer to input data
//        size = (input)  size of input buffer
//     writeFD = (output) file descriptor of input stream
//      pWrite = (input)  procedure pointer of read procedure
//   pUserData = (input)  user data that can be read with
//                        base64_getUserData()
//
//  Returns length of decoded data.
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
dcl-proc base64_decodeBufferToStream export;
  dcl-pi *n uns(10);
    Input     pointer value;
    InputLen  uns(10) value;
    writeFD   int(10) value;
    pWrite    pointer(*proc) value;
    pUserData pointer options(*nopass) value;
  end-pi;

  dcl-s outLen uns(10);

  g_stackCounter = 1;

  clear g_hReader;
  g_hReader.offset= 0;
  g_hReader.size  = InputLen;
  g_hReader.pData = Input;

  outLen = decodeRaw(0: %paddr('stringBufferReader')
                       : writeFD: pWrite: pUserData);

  g_stackCounter = 0;

  return outLen;

end-proc;

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//  base64_inAlphabet(): Check if a given character is in the
//                       base64 alphabet
//
//        Char = (input) character to check
//
// Returns *ON if it's in the alphabet, *OFF otherwise
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
dcl-proc base64_inAlphabet;
  dcl-pi *n ind;
    Char char(1) value;
  end-pi;

  dcl-s Numb uns(3) based(p_Numb);

  p_Numb = %addr(char);
  if (g_b64_reverse.base64r(Numb) = x'FF');
    return *OFF;
  else;
    return *ON;
  endif;

end-proc;

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//  encodeRaw: Internally used Base64 encoding procedure.
//
//      readFD = (input)  file descriptor of input stream
//       pRead = (input)  procedure pointer of read procedure
//     writeFD = (output) file descriptor of input stream
//      pWrite = (input)  procedure pointer of read procedure
//
//  Returns length of encoded data.
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
dcl-proc encodeRaw;
  dcl-pi *n uns(10);
    readFD    int(10) value;
    pRead     pointer(*proc) value;
    writeFD   int(10) value;
    pWrite    pointer(*proc) value;
    pUserData pointer value;
  end-pi;

  dcl-ds *n;
    Numb uns(5) inz(0);
    Byte char(1) overlay(Numb: 2);
  end-ds;

  dcl-ds data based(pInput);
    B1 char(1);
    B2 char(1);
    B3 char(1);
  end-ds;

  dcl-s dataSize int(10);
  dcl-s outSize int(10);
  dcl-s remaining int(10);

  dcl-s OutData char(4) based(pOutput);
  dcl-s Temp char(4);
  dcl-s InpPos int(10);
  dcl-s OutLen int(10);
  dcl-s Save char(1);
  dcl-s TotalLen int(10);

  dcl-s Output char(32768);
  dcl-s InpLen int(10);
  dcl-s Input char(32768);

  dcl-s bytes int(10);

  g_stackCounter += 1;

  g_pRead = pRead;
  g_pWrite = pWrite;
  g_pUserData = pUserData;

  pOutput = %addr(Output);

  InpLen = cb_read(readFD: %addr(Input): %size(Input));
  if (InpLen = -1);
    cRuntimeError(cErrno(): 'read()');
  endif;

  dow (InpLen > 0);

    InpPos = 1;
    pInput = %addr(Input);

    dou (InpPos > InpLen - 2);

      // -------------------------------------------------
      // First output byte comes from bits 1-6 of input
      // -------------------------------------------------

      Byte = %bitand(B1: x'FC');
      Numb /= 4;
      %subst(Temp:1) = g_b64_alphabet.base64f(Numb+1);
      outSize = 1;

      // -------------------------------------------------
      // Second output byte comes from bits 7-8 of byte 1
      //                           and bits 1-4 of byte 2
      // -------------------------------------------------
      Byte = %bitand(B1: x'03');
      Numb *= 16;

      if (InpPos+1 <= InpLen);
        Save = Byte;
        Byte = %bitand(B2: x'F0');
        Numb /= 16;
        Byte = %bitor(Save: Byte);
      endif;

      %subst(Temp: 2) = g_b64_alphabet.base64f(Numb+1);
      outSize += 1;

      dataSize = 1;

      // -------------------------------------------------
      // Third output byte comes from bits 5-8 of byte 2
      //                          and bits 1-2 of byte 3
      // (or is set to '=' if there was only one byte)
      // -------------------------------------------------
      if (InpPos+1 > InpLen);
        %subst(Temp: 3) = '=';
        outSize += 1;
      else;
        Byte = %bitand(B2: x'0F');
        Numb *= 4;

        if (InpPos+2 <= InpLen);
          Save = Byte;
          Byte = %bitand(B3: x'C0');
          Numb /= 64;
          Byte = %bitor(Save: Byte);
        endif;

        %subst(Temp:3) = g_b64_alphabet.base64f(Numb+1);
        outSize += 1;

        dataSize += 1;
      endif;

      // -------------------------------------------------
      // Fourth output byte comes from bits 3-8 of byte 3
      // (or is set to '=' if there was only one/two bytes)
      // -------------------------------------------------

      if (InpPos+2 > InpLen);
        %subst(Temp:4:1) = '=';
        outSize += 1;
      else;
        Byte = %bitand(B3: x'3F');
        %subst(Temp:4) = g_b64_alphabet.base64f(Numb+1);
        outSize += 1;

        dataSize += 1;
      endif;

      // -------------------------------------------------
      //   Flush buffer.
      // -------------------------------------------------
      if (OutLen + %size(Temp) > %size(Output));
        pOutput = %addr(Output);
        bytes = cb_write(writeFD: pOutput: OutLen);
        select;
        when (bytes = -1);
          cRuntimeError(cErrno(): 'write()');
        when (bytes < OutLen);
          killBase64('encodeRaw(): +
                      Output buffer too small to hold result.');
        endsl;
        TotalLen += bytes;
        OutLen = 0;
      endif;

      // -------------------------------------------------
      //   Advance to next chunk of data.
      // -------------------------------------------------

      pInput += dataSize;
      InpPos += dataSize;

      OutData = %subst(Temp: 1: outSize);
      OutLen += outSize;
      pOutput += outSize;
    enddo;

    remaining = InpLen - InpPos + 1;
    %subst(Input: 1: remaining) = %subst(Input: InpPos: remaining);

    InpLen = cb_read(readFD: %addr(Input) + remaining
                        : %size(Input) - remaining);
    if (InpLen = -1);
      cRuntimeError(cErrno(): 'read()');
    endif;

    InpLen = InpLen + remaining;
  enddo;

  if (OutLen > 0);
    pOutput = %addr(Output);
    bytes = cb_write(writeFD: pOutput: OutLen);
    select;
    when (bytes = -1);
      cRuntimeError(cErrno(): 'write()');
    when (bytes < OutLen);
      killBase64('encodeRaw(): +
                  Output buffer too small to hold result.');
    endsl;
    TotalLen += bytes;
    OutLen = 0;
  endif;

  g_stackCounter -= 1;

  return TotalLen;

end-proc;

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//  decodeRaw: Internally used Base64 decoding procedure.
//
//      readFD = (input)  file descriptor of input stream
//       pRead = (input)  procedure pointer of read procedure
//     writeFD = (output) file descriptor of input stream
//      pWrite = (input)  procedure pointer of read procedure
//
//  Returns length of decoded data.
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
dcl-proc decodeRaw;
  dcl-pi *n uns(10);
    readFD    int(10) value;
    pRead     pointer(*proc) value;
    writeFD   int(10) value;
    pWrite    pointer(*proc) value;
    pUserData pointer value;
  end-pi;

  dcl-ds *n;
    Numb uns(5) inz(0);
    Byte char(1) overlay(Numb: 2);
  end-ds;

  dcl-ds data based(pInput);
    B1 uns(3);
    B2 uns(3);
    B3 uns(3);
    B4 uns(3);
  end-ds;

  dcl-s dataSize int(10);
  dcl-s remaining int(10);

  dcl-s OutData char(3) based(pOutput);
  dcl-s Temp varchar(3);
  dcl-s InpPos int(10);
  dcl-s OutLen int(10);
  dcl-s TotalLen int(10);

  dcl-s Output char(32768);
  dcl-s InpLen int(10);
  dcl-s Input char(32768);

  dcl-s bytes int(10);

  g_stackCounter += 1;

  g_pRead = pRead;
  g_pWrite = pWrite;
  g_pUserData = pUserData;

  pOutput = %addr(Output);

  InpLen = cb_read(readFD: %addr(Input): %size(Input));
  if (InpLen = -1);
    cRuntimeError(cErrno(): 'read()');
  endif;

  dow (InpLen > 0);

    InpPos = 1;
    pInput = %addr(Input);

    dou (InpPos > InpLen - 4);

      if (g_b64_reverse.base64r(B1)=x'FF');
        invalidChar(InpPos:B1);
      endif;
      if (g_b64_reverse.base64r(B2)=x'FF');
        invalidChar(InpPos+1:B2);
      endif;
      if (g_b64_reverse.base64r(B3)=x'FF' and B3<>126);
        invalidChar(InpPos+2:B3);
      endif;
      if (g_b64_reverse.base64r(B4)=x'FF' and B4<>126);
        invalidChar(InpPos+3:B4);
      endif;

      // -------------------------------------------------
      // First output byte comes from bits 3-8 of byte 1
      //                          and bits 3-4 of byte 2
      // -------------------------------------------------

      dataSize = 2;

      Numb = g_b64_reverse.base64r(B1) * 4
           + g_b64_reverse.base64r(B2) / 16;
      Temp = Byte;

      // -------------------------------------------------
      // Second output byte comes from bits 5-8 of byte 2
      //                           and bits 3-6 of byte 3
      // -------------------------------------------------
      dataSize += 1;

      if (%subst(data: 3: 1) <> '=');
        numb = %bitand(g_b64_reverse.base64r(B2):x'0f') * 16
             + g_b64_reverse.base64r(B3) / 4;
        Temp += Byte;
      endif;

      // -------------------------------------------------
      // Third output byte comes from bits 7-8 of byte 3
      //                          and bits 3-8 of byte 4
      // (or is set to '=' if there was only one byte)
      // -------------------------------------------------
      dataSize += 1;

      if (%subst(data: 4: 1) <> '=');
        numb = %bitand(g_b64_reverse.base64r(B3):x'03') * 64
             + g_b64_reverse.base64r(B4);
        Temp += Byte;
      endif;

      // -------------------------------------------------
      //   Flush buffer.
      // -------------------------------------------------
      if (OutLen + %len(Temp) > %size(Output));
        pOutput = %addr(Output);
        bytes = cb_write(writeFD: pOutput: OutLen);
        select;
        when (bytes = -1);
          cRuntimeError(cErrno(): 'write()');
        when (bytes < OutLen);
          killBase64('decodeRaw(): +
                      Output buffer too small to hold result.');
        endsl;
        TotalLen += bytes;
        OutLen = 0;
      endif;

      // -------------------------------------------------
      //   Advance to next chunk of data.
      // -------------------------------------------------

      pInput += dataSize;
      InpPos += dataSize;

      OutData = Temp;
      OutLen  += %len(Temp);
      pOutput += %len(Temp);

    enddo;

    remaining = InpLen - InpPos + 1;
    %subst(Input: 1: remaining) = %subst(Input: InpPos: remaining);

    InpLen = cb_read(readFD: %addr(Input) + remaining
                        : %size(Input) - remaining);
    if (InpLen = -1);
      cRuntimeError(cErrno(): 'read()');
    endif;

    InpLen = InpLen + remaining;
  enddo;

  if (OutLen > 0);
    pOutput = %addr(Output);
    bytes = cb_write(writeFD: pOutput: OutLen);
    select;
    when (bytes = -1);
      cRuntimeError(cErrno(): 'write()');
    when (bytes < OutLen);
      killBase64('decodeRaw(): +
                  Output buffer too small to hold result.');
    endsl;
    TotalLen += bytes;
    OutLen = 0;
  endif;

  g_stackCounter -= 1;

  return TotalLen;

end-proc;

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//  Internally used reader.
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
dcl-proc stringBufferReader;
  dcl-pi *n int(10);
    fd      int(10) value;
    pBuffer pointer value;
    size    uns(10) value;
  end-pi;

  dcl-s rtnSize int(10);

  if (g_hReader.offset + size < g_hReader.size);
    rtnSize = size;
  else;
    rtnSize = g_hReader.size - g_hReader.offset;
  endif;

  memcpy(pBuffer: g_hReader.pData + g_hReader.offset: rtnSize);
  g_hReader.offset = g_hReader.offset + rtnSize;

  return rtnSize;

end-proc;

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//  Internally used writer.
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
dcl-proc stringBufferWriter;
  dcl-pi *n int(10);
    fd      int(10) value;
    pBuffer pointer value;
    size    uns(10) value;
  end-pi;

  dcl-s rtnSize int(10);

  if (g_hWriter.offset + size < g_hWriter.size);
    rtnSize = size;
  else;
    rtnSize = g_hWriter.size - g_hWriter.offset;
  endif;

  memcpy(g_hWriter.pData + g_hWriter.offset: pBuffer: rtnSize);
  g_hWriter.offset = g_hWriter.offset + rtnSize;

  return rtnSize;

end-proc;

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// killBase64():  Sends an escape message to report an error.
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
dcl-proc killBase64;
  dcl-pi *n;
    message varchar(512) options(*varsize) const;
  end-pi;

  dcl-pr QMHSNDPM extpgm('QMHSNDPM');
    MessageID  char(7) const;
    QualMsgF   char(20) const;
    MsgData    char(32767) options(*varsize) const;
    MsgDtaLen  int(10) const;
    MsgType    char(10) const;
    CallStkEnt char(10) const;
    CallStkCnt int(10) const;
    MessageKey char(4);
    ErrorCode  char(32767) options(*varsize);
  end-pr;

  dcl-ds ErrorCode qualified;
    BytesProv  int(10) inz(0);
    BytesAvail int(10) inz(0);
  end-ds;

  dcl-ds qMsgFile qualified;
    name char(10) inz('QCPFMSG');
    lib  char(10) inz('*LIBL');
  end-ds;

  dcl-s stackEntry char(10) inz('*');
  dcl-s msgKey char(4);

  g_stackCounter += 1;

  QMHSNDPM( 'CPF9897': qMsgFile
          : message: %len(message): '*ESCAPE'
          : stackEntry: g_stackCounter
          : msgKey
          : errorCode);

end-proc;

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// invalidChar(): Report an invalid input character
//                in a fashion dramatic enough that people
//                won't blame me when they provide invalid
//                input characters!
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
dcl-proc invalidChar;
  dcl-pi *n;
    CharPos int(10) value;
    Char    uns(3) value;
  end-pi;

  dcl-s Message varchar(100);

  // Convert Hex to Character (CVTHC)
  dcl-pr cvthc extproc('cvthc');
    target     char(2) options(*varsize);
    src_bits   uns(3) const;
    tgt_length int(10) value;
  end-pr;

  dcl-s hex char(2);

  g_stackCounter += 1;

  cvthc(hex:char:%size(hex));

  Message = 'Unable to decode character at position '
          + %char(CharPos) + '. (Char=x''' + hex + ''')';

  killBase64(Message);

end-proc;

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// cRuntineError():  Reports a C-runtime error.
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
dcl-proc cRuntimeError;
  dcl-pi *n;
    cErrorNbr int(10) value;
    procName  varchar(256) const;
  end-pi;

  dcl-s cErrorText char(100);

  //  strerror -- Set Pointer to Runtime Error Message
  dcl-pr strerror pointer extproc('strerror');
    errno int(10) value;
  end-pr;

  g_stackCounter += 1;

  cErrorText = %str(strerror(cErrorNbr));

  killBase64(procName + ': (' + %char(cErrorNbr) + ') ' + cErrorText);

end-proc;

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// cErrno():  Returns the value of the C errno variable.
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
dcl-proc cErrno;
  dcl-pi *n int(10);
  end-pi;

  dcl-s cErrorNbr int(10) based(pCErrorNbr);

  pCErrorNbr = errno();

  return cErrorNbr;

end-proc;

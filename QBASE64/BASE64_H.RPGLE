**free
//=============================================================================
// Copyright (c) 2005-2023 Scott C. Klement
// All rights reserved.
//
// Copyright (c) 2023 Thomas Raddatz
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

/if defined(BASE64_H_DEFINED)
/eof
/endif
/define BASE64_H_DEFINED

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//  base64_getUserData:  Returns the user data that were passed
//                       to the stream encode or decode
//                       procedures.
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
dcl-pr base64_getUserData pointer extproc('base64_getUserData');
end-pr;

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
dcl-pr base64_encode uns(10) extproc('base64_encode');
  Input        pointer value;
  InputLen     uns(10) value;
  Output       pointer value;
  OutputSize   uns(10) value;
end-pr;

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//  base64_encodeStreamToStream:  Encodes a given byte stream.
//
//      readFD = (input) file descriptor of the input stream
//       pRead = (input) input stream read procedure
//     writeFD = (input) file descriptor of the output stream
//      pWrite = (input) output stream write procedure
//
//  Returns length of encoded data, or -1 on error.
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
dcl-pr base64_encodeStreamToStream uns(10) extproc('base64_encodeStreamToStream');
  readFD       int(10) value;
  pRead        pointer(*proc) value;
  writeFD      int(10) value;
  pWrite       pointer(*proc) value;
  pUserData    pointer value options(*nopass);
end-pr;
//
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//  base64_encodeBuffer:  Encode binary data using Base64 encoding
//
//     pBuffer = (input)  pointer to input data
//        size = (input)  size of input buffer
//     writeFD = (output) file descriptor of input stream
//      pWrite = (input)  procedure pointer of read procedure
//
//  Returns length of encoded data.
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
dcl-pr base64_encodeBufferToStream uns(10) extproc('base64_encodeBufferToStream');
  Input        pointer value;
  InputLen     uns(10) value;
  writeFD      int(10) value;
  pWrite       pointer(*proc) value;
  pUserData    pointer value options(*nopass);
end-pr;

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//  base64_decode: Decode base64 encoded data back to binary
//
//       Input = (input) pointer to base64 data to decodet
//    InputLen = (input) length of base64 data
//      Output = (output) pointer to memory to receive output
//     OutSize = (input) size of area to store output in
//
//  Returns length of decoded data, or space needed to decode
//      data. If this value is greater than OutSize, then
//      output may have been truncated.
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
dcl-pr base64_decode uns(10) extproc('base64_decode');
  Input        pointer value;
  InputLen     uns(10) value;
  Output       pointer value;
  OutputSize   uns(10) value;
end-pr;

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//  base64_decodeStreamToStream:
//  Decode binary data using Base64 decoding
//
//      readFD = (input)  file descriptor of input stream
//       pRead = (input)  procedure pointer of read procedure
//     writeFD = (output) file descriptor of input stream
//      pWrite = (input)  procedure pointer of read procedure
//
//  Returns length of decoded data.
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
dcl-pr base64_decodeStreamToStream uns(10) extproc('base64_decodeStreamToStream');
  readFD       int(10) value;
  pRead        pointer(*proc) value;
  writeFD      int(10) value;
  pWrite       pointer(*proc) value;
  pUserData    pointer value options(*nopass);
end-pr;

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//  base64_decodeBuffer:
//  Decode binary data using Base64 decoding
//
//     pBuffer = (input)  pointer to input data
//        size = (input)  size of input buffer
//     writeFD = (output) file descriptor of input stream
//      pWrite = (input)  procedure pointer of read procedure
//
//  Returns length of decoded data.
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
dcl-pr base64_decodeBufferToStream uns(10) extproc('base64_decodeBufferToStream');
  Input        pointer value;
  InputLen     uns(10) value;
  writeFD      int(10) value;
  pWrite       pointer(*proc) value;
  pUserData    pointer value options(*nopass);
end-pr;


**free
// ============================================================================
//  Decodes a Base64 buffer to a buffer.
//  This example demonstrates how to decode a given Base64 buffer. The
//  result is stored in a buffer.
//  The output buffer must match 'Hello World'.
// ============================================================================
//  To Compile:
//        CHGCURLIB CURLIB(xxx)
//        ADDLIBLE LIB(xxx)
//        CRTBNDRPG PGM(EXAMPLE11) SRCFILE(QBASE64) DBGVIEW(*LIST)
// ============================================================================
//   >>PRE-COMPILER<<
//     >>CRTCMD<<  CRTBNDRPG   PGM(&LI/&OB) SRCFILE(&SL/&SF) SRCMBR(&SM);
//     >>COMPILE<<
//       >>PARM<< TRUNCNBR(*NO);
//       >>PARM<< DBGVIEW(*LIST);
//       >>PARM<< OPTION(*EVENTF);
//       >>PARM<< TGTRLS(V7R2M0);
//     >>END-COMPILE<<
//     >>EXECUTE<<
//   >>END-PRE-COMPILER<<
//=============================================================================

ctl-opt debug option(*SRCSTMT : *NODEBUGIO)
        dftactgrp(*no) actgrp(*new) bnddir('BASE64')
        main(main);

/include qbase64,base64_h

dcl-pr main  extpgm('EXAMPLE11');
end-pr;

dcl-proc main;
  dcl-pi *n;
  end-pi;

  dcl-s input char(100);
  dcl-s output_utf8 char(100) ccsid(*utf8);
  dcl-s output char(100);
  dcl-s size uns(10);
  dcl-s msg char(52);

  input = 'SGVsbG8gV29ybGQ=';

  size = base64_decode(%addr(input): %len(%trimr(input)): %addr(output_utf8): %size(output_utf8));

  output = %subst(output_utf8: 1: size);
  msg = 'size=' + %char(size) + ': ' + %trimr(output);
  dsply msg;

  // Use one of the various Base64 online decoder pages for
  // decoding and validating the Base64 string:
  //   https://www.base64decode.org/
  //   https://www.utilities-online.info/base64
  //   https://www.base64decode.net/

end-proc;


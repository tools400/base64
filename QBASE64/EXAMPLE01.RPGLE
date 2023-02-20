**free
// ============================================================================
//  Encodes a buffer to a Base64 buffer.
//  This example demonstrates how to encode a given buffer to Base64. The
//  result is stored in a buffer.
// ============================================================================
//  To Compile:
//        CHGCURLIB CURLIB(xxx)
//        ADDLIBLE LIB(xxx)
//        CRTBNDRPG PGM(EXAMPLE01) SRCFILE(QBASE64) DBGVIEW(*LIST)
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

dcl-pr main  extpgm('EXAMPLE01');
end-pr;

dcl-proc main;
  dcl-pi *n;
  end-pi;

  dcl-s input char(100) ccsid(*utf8);
  dcl-s output char(100);
  dcl-s size uns(10);
  dcl-s msg char(52);

  input =  'Hello World';

  size = base64_encode(%addr(input): %len(%trimr(input)): %addr(output): %size(output));

  msg = 'size=' + %char(size) + ': ' + %subst(output: 1: size);
  dsply msg;

  // Use one of the various Base64 online decoder pages for
  // decoding and validating the Base64 string:
  //   https://www.base64decode.org/
  //   https://www.utilities-online.info/base64
  //   https://www.base64decode.net/

end-proc;


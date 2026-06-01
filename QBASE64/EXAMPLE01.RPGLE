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
//       >>PARM<< TGTRLS(V7R3M0);
//     >>END-COMPILE<<
//     >>EXECUTE<<
//   >>END-PRE-COMPILER<<
//=============================================================================

ctl-opt debug option(*srcstmt: *nodebugio) dftactgrp(*no) actgrp(*new) bnddir('BASE64') main(main);

/include qbase64,base64_h

dcl-pr main extpgm('EXAMPLE01');
end-pr;

dcl-proc main;
  dcl-pi *n;
  end-pi;

  dcl-s input char(100) ccsid(*utf8);
  dcl-s output char(100);
  dcl-s size uns(10);

  input =  'Hello World';

  size = base64_encode(%addr(input): %len(%trimr(input)): %addr(output): %size(output));

  println('size=' + %char(size) + ': ' + %subst(output: 1: size));

// Use one of the various Base64 online decoder pages for
// decoding and validating the Base64 string:
//   https://www.base64decode.org/
//   https://www.utilities-online.info/base64
//   https://www.base64decode.net/

end-proc;

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// Sends a message to the command line.
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
dcl-proc println;
  dcl-pi *n extproc(*dclcase);
    i_text varchar(128) value;
  end-pi;

  dcl-s msgKey char(4) inz;

  dcl-ds qMsgF qualified inz;
    name char(10);
    lib  char(10);
  end-ds;

  dcl-ds errCode qualified inz;
    bytPrv   int(10);
    bytAvl   int(10);
    excID    char(7);
    reserved char(1);
    excDta   char(256);
  end-ds;

  dcl-pr QMHSNDPM extpgm('QMHSNDPM');
    i_msgID    char(7) const;
    i_qMsgF    char(20) const;
    i_msgData  char(32767) options(*varsize) const;
    i_length   int(10) const;
    i_msgType  char(10) const;
    i_callStkE char(32767) options(*varsize) const;
    i_callStkC int(10) const;
    o_msgKey   char(4);
    io_ErrCode char(32767) options(*varsize);
  end-pr;

  clear qMsgF;
  qMsgF.name = 'QCPFMSG';
  qMsgF.lib  = '*LIBL';

  clear errCode;
  errCode.bytPrv = %size(errCode);

  QMHSNDPM('CPF9897': qMsgF: i_text: %len(i_text): '*INFO'
           : '*CTLBDY': 1: msgKey: errCode);

end-proc;


**free
// ============================================================================
//  Decodes a Base64 buffer to a stream file.
//  This example demonstrates how to decode a given Base64 buffer. The
//  result is stored in a stream file.
//  The output stream file must match 'Hello World'.
// ============================================================================
//  To Compile:
//        CHGCURLIB CURLIB(xxx)
//        ADDLIBLE LIB(xxx)
//        CRTBNDRPG PGM(EXAMPLE12) SRCFILE(QBASE64) DBGVIEW(*LIST)
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
/include qbase64,ifsio_h

dcl-pr main extpgm('EXAMPLE12');
end-pr;

dcl-proc main;
  dcl-pi *n;
  end-pi;

  dcl-s input char(100);
  dcl-s outputFile varchar(500) inz('/home/raddatz/base64/example12.txt');
  dcl-s fd int(10) inz(-1);
  dcl-s size uns(10);

  input = 'SGVsbG8gV29ybGQ=';

  // Write output to a stream file with the CCSID of then job.
  // Convert the data written to the file from utf-8 to the CCSID of the file.
  fd = open(outputFile: O_WRONLY + O_SHARE_RDONLY + O_CREAT + O_TRUNC
                        + O_TEXTDATA + O_TEXT_CREAT + O_CCSID
            : S_IRUSR + S_IWUSR + S_IRGRP + S_IWGRP + S_IROTH + S_IWOTH
            : 0: 1208);
  if (fd = -1);
    println(getSystemError());
    return;
  endif;

  size = base64_decodeBufferToStream (%addr(input): %len(%trimr(input)): fd: %paddr('write'));

  println('Bytes written to output file: ' + %char(size));

// Use one of the various Base64 online decoder pages for
// decoding and validating the Base64 string:
//   https://www.base64decode.org/
//   https://www.utilities-online.info/base64
//   https://www.base64decode.net/

on-exit;

  // Close output stream file
  if (fd <> -1);
    callp close(fd);
  endif;

end-proc;

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// Returns the last system error.
//
// returns error message
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
dcl-proc getSystemError;
  dcl-pi *n varchar(500) extproc(*dclcase);
  end-pi;

  dcl-s errMsg varchar(500);
  dcl-s err int(10) based(p_err);

  dcl-pr errno pointer extproc('__errno');
  end-pr;

  dcl-pr strerror pointer extproc('strerror');
    errnum int(10) value;
  end-pr;

  p_err = errno();
  errMsg = %str(strerror(err)) + ' (' + %char(err) + ')';

  return errMsg;

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


**free
// ============================================================================
//  Reads a Base64 stream file and decodes it.
//  This example demonstrates how to decode a given Base64 stream file. The
//  result is stored in a stream file.
//  The output file must match the file read and converted by EXAMPLE03.
// ============================================================================
//  To Compile:
//        CHGCURLIB CURLIB(xxx)
//        ADDLIBLE LIB(xxx)
//        CRTBNDRPG PGM(EXAMPLE13) SRCFILE(QBASE64) DBGVIEW(*LIST)
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
/include qbase64,ifsio_h

dcl-pr main  extpgm('EXAMPLE13');
end-pr;

dcl-proc main;
  dcl-pi *n;
  end-pi;

  dcl-s inputFile  varchar(500) inz('/home/raddatz/base64/example03.txt');
  dcl-s outputFile varchar(500) inz('/home/raddatz/base64/example13.pdf');
  dcl-s inFD  int(10) inz(-1);
  dcl-s outFD int(10) inz(-1);
  dcl-s size uns(10);
  dcl-s msg char(52);

  dcl-c ANY_MODE_FLAGS 0; // 'mode' is ignored, when O_CREAT is not set

  // Read utf-8 input data in text mode converting it from utf-8 to the
  // ccsid of the job. We need to do that, because the Base64 decoder
  // requires the Base64 string in EBCDIC.
  inFD = open(inputFile: O_RDONLY + O_SHARE_RDONLY + O_TEXTDATA + O_CCSID
             : ANY_MODE_FLAGS
             : 0);
  if (inFD = -1);
    msg = getSystemError();
    dsply msg;
    return;
  endif;

  // Write output data in binary mode.
  outFD = open(outputFile: O_WRONLY + O_SHARE_RDONLY + O_CREAT + O_TRUNC);
  if (outFD = -1);
    msg = getSystemError();
    dsply msg;
    return;
  endif;

  //size = base64_decodeStreamToStream (inFD: %paddr('utf8_read'): outFD: %paddr('write'));
  size = base64_decodeStreamToStream (inFD: %paddr('read'): outFD: %paddr('write'));

  msg = 'Bytes written to output file: ' + %char(size);
  dsply msg;

  // Use one of the various Base64 online decoder pages for
  // decoding and validating the Base64 string:
  //   https://www.base64decode.org/
  //   https://www.utilities-online.info/base64
  //   https://www.base64decode.net/

on-exit;

  // Close input stream file
  if (inFD <> -1);
    callp close(inFD);
  endif;

  // Close input stream file
  if (outFD <> -1);
    callp close(outFD);
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


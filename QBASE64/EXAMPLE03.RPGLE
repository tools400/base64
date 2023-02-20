**free
// ============================================================================
//  Reads a stream file and encodes it to Base64.
//  This example demonstrates how to read a stream file and encode it
//  to Base64. The output is stored as utf-8 in another stream file.
// ============================================================================
//  To Compile:
//        CHGCURLIB CURLIB(xxx)
//        ADDLIBLE LIB(xxx)
//        CRTBNDRPG PGM(EXAMPLE03) SRCFILE(QBASE64) DBGVIEW(*LIST)
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

dcl-pr main  extpgm('EXAMPLE03');
end-pr;

dcl-proc main;
  dcl-pi *n;
  end-pi;

  dcl-s inputFile varchar(500) inz('/home/raddatz/base64/BASE64 Encoder and Decoder.pdf');
  dcl-s outputFile varchar(500) inz('/home/raddatz/base64/example03.txt');
  dcl-s inFD int(10) inz(-1);
  dcl-s outFD int(10) inz(-1);
  dcl-s size uns(10);
  dcl-s msg char(52);

  // Read input data in binary mode.
  inFD = open(inputFile: O_RDONLY + O_SHARE_RDONLY);
  if (inFD = -1);
    msg = getSystemError();
    dsply msg;
    return;
  endif;

  // Write output to a UTF-8 stream file.
  outFD = open(outputFile: O_WRONLY + O_SHARE_RDONLY + O_CREAT + O_TRUNC
                         + O_TEXTDATA + O_TEXT_CREAT + O_CCSID
            : S_IRUSR + S_IWUSR + S_IRGRP + S_IWGRP + S_IROTH + S_IWOTH
            : 1208: 0);
  if (outFD = -1);
    msg = getSystemError();
    dsply msg;
    return;
  endif;

  size = base64_encodeStreamToStream (inFD: %paddr('read'): outFD: %paddr('write'));

  msg = 'Bytes written to output file: ' + %char(size);
  dsply msg;

  // Use one of the various Base64 online decoder pages for
  // decoding and validating the Base64 string:
  //   https://www.base64decode.org/
  //   https://www.utilities-online.info/base64
  //   https://www.base64decode.net/

on-exit;

  // Close output stream file
  if (inFD <> -1);
    callp close(inFD);
  endif;

  // Close output stream file
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


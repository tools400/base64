**free
// ============================================================================
//  Decodes data from a Json file to a stream file.
//  This example demonstrates how to read and decode data from a Json file. The
//  result is stored in a stream file.
// ============================================================================
//  To Compile:
//        CHGCURLIB CURLIB(xxx)
//        ADDLIBLE LIB(xxx)
//        ADDLIBLE LIB(LIBYAJL)
//        CRTBNDRPG PGM(EXAMPLE14) SRCFILE(QBASE64) DBGVIEW(*LIST)
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
        dftactgrp(*no) actgrp(*new) bnddir('BASE64': 'YAJL')
        main(main);

/include qbase64,base64_h
/include qbase64,ifsio_h
/include qrpglesrc,yajl_h

dcl-pr main  extpgm('EXAMPLE14');
end-pr;

dcl-proc main;
  dcl-pi *n;
  end-pi;

  dcl-s inputFile varchar(500) inz('/home/raddatz/base64/example04.json');
  dcl-s outputFile varchar(500) inz('/home/raddatz/base64/example14.pdf');
  dcl-s docNode like(yajl_val);
  dcl-s node like(yajl_val);
  dcl-s errMsg varchar(500);
  dcl-s msg char(52);
  dcl-s rc int(10);

  // Parse Json file.
  docNode = yajl_stmf_load_tree(inputFile: errMsg);

  // Find node and save it to a file.
  node = yajl_object_find(docNode: 'thePDFFile');
  rc = yajl_saveBase64Stmf(node: outputFile: errMsg);
  if (rc <> yajl_gen_status_ok);
    msg = errMsg;
    dsply msg;
    return;
  endif;

  msg = 'Finished writing the PDF file.';
  dsply msg;

  // Use one of the various Base64 online decoder pages for
  // decoding and validating the Base64 string:
  //   https://www.base64decode.org/
  //   https://www.utilities-online.info/base64
  //   https://www.base64decode.net/

on-exit;

  // Free Json tree
  if (docNode <> *null);
    yajl_tree_free(docNode);
  endif;

end-proc;

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// This procedure decodes the Base64 data that is associated
// to a Json key and stores it in the specified stream file.
//
//   node (input)  = YAJL tree node
//   stmf (input)  = pathname of stream file to store the data
// errMsg (output) = error message
//
// returns yajl_gen_status_ok upon success,
//         or generator status code upon failure.
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
dcl-proc yajl_saveBase64Stmf;
  dcl-pi *n int(10) extproc(*dclcase);
    node   like(yajl_val) const;
    stmf   varchar(5000)  options(*varsize) const;
    errMsg varchar(500);
  end-pi;

  dcl-s rc int(10);
  dcl-s tempFile varchar(500);
  dcl-s inFD  int(10) inz(-1);
  dcl-s outFD int(10) inz(-1);
  dcl-s size int(10);

  //_C_IFS_tmpnam -- Produce Temporary File Name for the IFS file system
  dcl-pr ifs_tmpnam pointer extproc('_C_IFS_tmpnam');
    string pointer value;
  end-pr;

  // If string is not NULL, it must point to an array of at least L_tmpnam bytes.
  // The value of L_tmpnam is defined in <stdio.h>.
  dcl-c L_tmpnam 39;

  dcl-c ANY_MODE_FLAGS 0; // 'mode' is ignored, when O_CREAT is not set

  errMsg = '';

  // Save Base64 string to a temporary file.
  tempFile = %str(ifs_tmpnam(*null));
  rc = yajl_save_string_stmf(node: tempFile: errMsg);
  if (rc <> yajl_gen_status_ok);
    return rc;
  endif;

  // Read utf-8 input data in text mode converting it from utf-8 to the
  // ccsid of the job. We need to do that, because the Base64 decoder
  // requires the Base64 string in EBCDIC.
  inFD = open(tempFile: O_RDONLY + O_SHARE_RDONLY + O_TEXTDATA + O_CCSID
             : ANY_MODE_FLAGS
             : 0);
  if (inFD = -1);
    errMsg = getSystemError();
    return yajl_gen_open_fail;
  endif;

  // Write output to a stream file in binary mode.
  outFD = open(stmf: O_WRONLY + O_SHARE_RDONLY + O_CREAT + O_TRUNC
            : S_IRUSR + S_IWUSR + S_IRGRP + S_IWGRP + S_IROTH + S_IWOTH);
  if (outFD = -1);
    errMsg = getSystemError();
    return yajl_gen_open_fail;
  endif;

  size = base64_decodeStreamToStream (inFD: %paddr('read'): outFD: %paddr('write'));

  return yajl_gen_status_ok;

on-exit;

  // Close input stream file and delete it.
  if (inFD <> -1);
    callp close(inFD);
    unlink(tempFile);
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


**free
// ============================================================================
//  Reads data from a stream file and adds it to Json.
//  This example demonstrates how to append a given PDF file to a Json file.
// ============================================================================
//  To Compile:
//        CHGCURLIB CURLIB(xxx)
//        ADDLIBLE LIB(xxx)
//        ADDLIBLE LIB(LIBYAJL)
//        CRTBNDRPG PGM(EXAMPLE04) SRCFILE(QBASE64) DBGVIEW(*LIST)
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

ctl-opt debug option(*srcstmt: *nodebugio) dftactgrp(*no) actgrp(*new) bnddir('BASE64': 'YAJL')
  main(main);

/include qbase64,base64_h
/include qbase64,ifsio_h
/include qrpglesrc,yajl_h

dcl-pr main extpgm('EXAMPLE04');
end-pr;

dcl-proc main;
  dcl-pi *n;
  end-pi;

  dcl-s inputFile varchar(500) inz('/home/raddatz/base64/BASE64 Encoder and Decoder.pdf');
  dcl-s errMsg varchar(500);
  dcl-s rc int(10);

  // Create Json object.
  yajl_genOpen(*ON);

  yajl_beginObj();
  rc = yajl_addBase64Stmf('thePDFFile': inputFile: errMsg);
  if (rc <> yajl_gen_status_ok);
    println(errMsg);
    return;
  endif;

  yajl_endObj();

  // Save Json string to file.
  yajl_saveBuf('/home/raddatz/base64/example04.json': errMsg);

on-exit;

  yajl_genClose();

  println('Finished writing the Json file.');

// Use one of the various Base64 online decoder pages for
// decoding and validating the Base64 string:
//   https://www.base64decode.org/
//   https://www.utilities-online.info/base64
//   https://www.base64decode.net/

end-proc;

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// This procedure reads data from an IFS stream file, translating it
// to Base64 and adds it to a given Json key.
//
//    key (input)  = key of property to add to object
//   stmf (input)  = pathname of stream file to read the data
// errMsg (output) = error message
//
// returns yajl_gen_status_ok upon success,
//         or generator status code upon failure.
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
dcl-proc yajl_addBase64Stmf;
  dcl-pi *n int(10) extproc(*dclcase);
    key    varchar(65535) options(*varsize) const;
    stmf   varchar(5000) options(*varsize) const;
    errMsg varchar(500);
  end-pi;

  dcl-s rc int(10);
  dcl-ds hExBuf likeds(yajl_exbuf_t);
  dcl-s fd int(10) inz(-1);
  dcl-s size int(10);

  errMsg = '';

  // Create YAJL expanding buffer, used as output stream
  hExBuf = yajl_exbuf_new(65536);

  // Open input stream file in binary mode
  fd = open(%trim(stmf): O_RDONLY + O_SHARE_RDONLY);
  if (fd = -1);
    errMsg = getSystemError();
    return yajl_gen_open_fail;
  endif;

  // Convert input stream to Base64. Pass 'hExBuf' as user data.
  size = base64_encodeStreamToStream(fd:%paddr('read'):0:%paddr('yajl_exbuf_write'):%addr(hExBuf));

  rc = yajl_addCharEx(key: hExBuf);

  return rc;

on-exit;

  // Close input stream
  if (fd <> -1);
    callp close(fd);
  endif;

  // Close output stream
  if (hExBuf.ptr <> *null);
    yajl_exbuf_free(hExBuf);
  endif;

end-proc;

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// This procedure appends data to a YAJL expanding buffer. It
// is used as a callback procedure from base64_encodeStreamToStream().
// The interface MUST match the interface of the IFS
// write() procedure.
//
//     fd (input) = descriptor of the file to which the data is to be written
//  pData (input) = pointer to a buffer containing the data to be written
//   size (input) = size in bytes of the data to be written
//
// returns the number of bytes actually written on success, else -1
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
dcl-proc yajl_exbuf_write;
  dcl-pi *n int(10) extproc(*dclcase);
    fd    int(10) value;
    pData pointer value;
    size  uns(10) value;
  end-pi;

  dcl-ds hExBuf likeds(yajl_exbuf_t) based(pHExBuf);

  // Get access to user data, here: hExBuf
  pHExBuf = base64_getUserData();

  // Add Base64 data to expandable buffer.
  yajl_exbuf_concat_ptr(hExBuf: pData: size);

  return size;

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


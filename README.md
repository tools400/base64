# BASE64 - Encoding/Decoding Utility

BASE64 is a service program providing Base64 encoding and decoding services.

The utility was first developed by Scott Clement. The version provided here
has been enhanced with additional services by Thomas Raddatz.

## Dependencies

- [YAJL](https://www.scottklement.com/yajl/) (Scott Klement)

## Installation

Compile members with the following PDM option:

   STRPREPRC USESRCFILE(&L/&F) USESRCMBR(&N) OPTION(*EVENTF) CHGOBJD(*NO)
     LIB(&O) OBJ(&N) SRCLIB(&L) SRCFILE(&F) SRCMBR(&N) USER0(&X)
     USER1(*LIST) USER2(*FULL)

Members of type MAKPGM or BND are used for linking programs (MAKPGM)
and service programs (BND).

The [STRPREPRC](https://github.com/tools400/strpreprc) utility is used for compiling the members. The utility retrieves object creation parameters from the source member that is compiled and building and executing the final object creation command.

---

2018, Thomas Raddatz

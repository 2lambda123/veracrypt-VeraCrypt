#ifndef TC_HEADER_Common_Token
#define TC_HEADER_Common_Token

#include "Platform/PlatformBase.h"

#if defined (TC_WINDOWS) && !defined (TC_PROTOTYPE)
#	include "Exception.h"
#else

#	include "Platform/Exception.h"

#endif

#include <string>


namespace VeraCrypt {

    struct TokenKeyfilePath {
        TokenKeyfilePath(const wstring& path): Path(path) { }

        operator wstring () const { return Path; }
        wstring Path;	//Complete path

    };
    struct TokenInfo {
        unsigned long int SlotId;
        wstring Label;	//Card name
    };

    struct TokenKeyfile {
        TokenKeyfile(): SlotId(UNAVAILABLE_SLOT) {};
        virtual operator TokenKeyfilePath () const = 0;
        unsigned long int SlotId;
        string IdUtf8;	                // Was used in SecurityToken to compare with the file name from a PKCS11 card, remove ?
    };

    class Token {
    public:
        static vector<unique_ptr<TokenKeyfile>> GetAvailableKeyfiles();
        static void GetKeyfileData(const TokenKeyfile& keyfile, vector <byte>& keyfileData);
        static bool IsKeyfilePathValid(const wstring& tokenKeyfilePath);
    };
}


#endif //TC_HEADER_Common_Token

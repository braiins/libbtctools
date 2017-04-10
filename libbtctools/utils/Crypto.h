#pragma once

#include <string>
#include <cryptopp/sha.h>
#include <cryptopp/md5.h>
#include <cryptopp/base64.h>

namespace btctools
{
	namespace utils
	{
        using string = std::string;

		class Crypto
		{
		public:
			static string md5(const string &str);

			static string sha1(const string &str);
			static string sha256(const string &str);

			static string base64Encode(const string &str);
			static string base64Decode(const string &encodedStr);

			static string bin2hex(const byte bArray[], int bArray_len);
		}; // class end

	} // namespace utils
} // namespace btctools
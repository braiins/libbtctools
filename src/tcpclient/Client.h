#pragma once

#include "common.h"

namespace btctools
{
    namespace tcpclient
    {
        class Client
        {
        public:
            Client();

			void addWork(Request *request, ResponseYield &yield);
			void addWork(Request *request);
            
			void run();
            void run(RequestSource &source, ResponseYield &yield);
			ResponseSource run(RequestSource &source);
            
			void stop();
			bool stopped();
            
        private:
            boost::asio::io_service io_service_;
			ResponseYield *yield_;
        };

    } // namespace tcpclient
} // namespace btctools
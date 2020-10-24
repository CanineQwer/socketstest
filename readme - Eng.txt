Serv is a simple Linux server. That waits for a client, transfers a large file, disconnects from the client and waits for the next one.
Cli is a simple Windows client. That connects to a server, accepts a file, and outputs its size.
CliAsyn is an asynchronous Windows client. That connects to the server, takes a file, and outputs its size.

The problem arises in the CliAsyn (windows) - Serv (linux) bundle.
Part of the data is lost, but the server does not see these losses.
If we transfer the server to Windows, then there will be no losses.
Also, there will be no losses if you use a synchronous client(Cli).
The MoonScript IRCd to rule them all

## Usage

```sh
Usage: ./moon.sh [OPTIONS]

 -c, --config <FILE>     | Specify configuration file
 -g, --gen-password-hash | Generate a password hash
```

## Configuration

Unless specified otherwise by command line flags, configuration should be
placed in `${XDG_CONFIG_HOME}/potatoircd.moon`. If the `$XDG_CONFIG_HOME`
variable is not set, `${HOME}/.config` will be used instead. Configuration
should use the MoonScript table format with the following fields:

```moon
{
	-- The server_name option will be sent to clients, to specify the name of
	-- the network. This should be kept the same through all linked servers.
	server_name: "PotatoNet"

	-- The vhost is how the server will display itself when sending numerics
	-- to the client. This should be set to the domain name of the server.
	vhost: "potatoircd.rocks"

	-- The server_pass option can optionally take a base16 encoded SHA512 hash
	-- of the server password. Comment out or remove the line for no password.
	--
	-- You can also generate a password using `./main.moon -g`
	server_pass: "optional_pass_hash"

	-- The hostname option specifies the IP the server will bind to. Using an
	-- IP of 0.0.0.0 on Linux means the server will listen on all addresses.
	hostname: "0.0.0.0"

	-- The port option - numeric - specifies the port the IRCd will listen to.
	-- Most IRC clients use 6667 for plaintext connections (not suggested) or
	-- 6697 for TLS connections.
	port: 6697

	-- The ssl_ctx option should be set to a table consisting of two values.
	-- The first value will be a relative or absolute path to the certificate
	-- the server will use; the second value will be a relative or absolute
	-- path to the key the server will use.
	ssl_ctx: {"ssl/cert.pem", "ssl/key.pem"} -- generate your own certificates!
}
```

#!/usr/bin/env moon
--- Utilities and monkeypatching module
-- @author ChickenNuggers
-- @module util

import compile from require "re"
digest = require "openssl.digest"

--- Check if type `name` exists in config
-- @lfunction check
-- @tparam table config Configuration to check and apply filter on
-- @tparam string name Name of configuration value
-- @tparam function filter Function to act as verification filter (can be nil)
check = (config, name, filter)->
	assert filter config[name], "Bad value for #{name}" if filter
	error "Missing field #{name}" if not config[name]

--- Set a value if it does not exist, then check with a filter
-- @lfunction default
-- @tparam table config see @{check}
-- @tparam string name see @{check}
-- @param value Default value
-- @tparam function filter see @{check}
default = (config, name, value, filter)->
	if not config[name]
		config[name] = value
	elseif filter
		assert filter config[name], "Bad value for #{name}"

--- Verifies if an input is a string (used in @{check_config})
-- @tparam string input Verifiable input
is_str = (input)-> type(input) == "string"

--- Check configuration values using appropriate filters
-- @lfunction check_config
-- @tparam table input Values to be verified
check_config = (input)->
	check input, "server_name", is_str
	check input, "server_pass", is_str
	default input, "hostname", "0.0.0.0", is_str -- all interfaces
	default input, "port", 6697, tonumber -- tls only
	default input, "ssl_ctx", {"ssl/cert.pem", "ssl/key.pem"}, ((a)-> #a == 2)
	default input, "server_pass", false, is_str

--- Check for "$XDG\_CONFIG\_HOME", default to $HOME/.config
-- @lfunction get_xdg_config_path
get_xdg_config_path = ()->
	os.getenv "XDG_CONFIG_HOME" or ("#{os.getenv 'HOME'}/.config")

--- Returns default configuration path
-- @lfunction get_default_config_path
get_default_config_path = ()-> "#{get_xdg_config_path!}/potatoircd.moon"

--- Load configuration from file
-- @tparam string file Location of configuration file
load_config = (file = get_default_config_path!)-> dofile file

--- Format strings using string.format with the modulo operator
-- @function string:__mod
-- @tparam table values Formattable values
-- @usage formatted_string = "%s: %q" % {"hello", "world"}
getmetatable''.__mod = (values)=> @format unpack values

--- Split strings into whitespace-split values
-- @function string:split
-- @usage values = input:split()
string.split = ()=> [value for value in @gmatch "%S+"]

--- Transform an escaped value in a tag to the value it represents
-- @lfunction transform_value
-- @param escaped_value String, first char being `\`, second being `[:s\rn]`
-- @usage print(transform_value("\s") == " ") --> true
transform_value = (escaped_value)->
	return ({
		"\\:": ";"
		"\\s": " "
		"\\\\": "\\"
		"\\r": "\r"
		"\\n": "\n"
	})[escaped_value]

--- Compile an IRCv3 message into a JSON tree
-- @function line_pattern:match
-- @tparam string input
-- @usage line_pattern\match "@potato.ircd/hello=world PRIVMSG #ircv3 :hi!"
line_pattern = compile [[
	line <- (tags SP)? command (SP arguments)?
	tags <- '@' {:tags: {| tag (';' SP tag)* |} :}
	tag <- {| key ('=' value)? |}
	key <- {:key: (vendor '/')? {:is_client: '+' -> true :} [A-Za-z0-9-]+ :}
	vendor <- {:vendor: [^/]+ :}
	value <- {:value: (('\' [:s\rn]) -> transform_value) / [^\ ]+ :}
	command <- {:command: %S+ :}
	arguments <- {:arguments: {|
		(argument SP)*
		trailing
	|} :}
	argument <- {%S+}
	trailing <- ':' {.+}
	SP <- ' '
]], :transform_value, "true": (()-> true), "false": (()-> false)

--- Create a base16 string from a binary string
-- @tparam string input Binary input
-- @treturn string Base16 output
base16 = (input)-> table.concat [("%02x")\format ch for ch in input\gmatch "."]

--- Generate a hash using OpenSSL
-- @tparam string input Hashable input
-- @tparam string algorithm Hashing algorithm to use, defaults to sha512
-- @treturn string @{base16} formatted hash of `input`
hash = (input, algorithm="sha512")-> base16 digest.new(algorithm):final(input)

{
	:line_pattern, :load_config, :base16, :hash
}

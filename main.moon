#!/usr/bin/env moon
--- Entry script for Potato IRCd.
-- @author ChickenNuggers
-- @script main
-- @license MIT
[[
MIT License

Copyright (c) 2016 Ryan "ChickenNuggers"

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
]]

cqueues = require "cqueues"
socket = require "socket"
log = require "log"
{util: {:load_config, :check_config, :hash}
:client
:init
:config
:state
tls: {:context_from_pair}} = require "potato"
getopt = require "getopt"

args = getopt {...}, "c:g", {
	config: "c"
	"gen-password-hash": "g"
}

if args.g
	os.execute "stty -echo echonl"
	io.write "Password: "
	print "Hash: #{hash io.read!}"
	os.execute "stty echo"
	os.exit!

print!
print line for line in io.lines "asciilogo"
print!
print "Version 0.1.0-alpha"
print!

init check_config load_config args.c

state.config = config
state.tls_ctx = context_from_pair unpack config.ssl_ctx

server = socket.listen config.hostname, config.port
loop = cqueues.new!

loop\wrap ->
	for client in server\clients do
		loop\wrap -> client(client)

while not loop\empty!
	with ok, err = pcall loop.step, loop
		if not ok
			log.error err

context = require "openssl.context"

context_from_pair = (cert, key)->
	ctx = context.new('TLS', true) -- server mode
	ctx\setCertificate cert
	ctx\setPrivateKey key
	return ctx

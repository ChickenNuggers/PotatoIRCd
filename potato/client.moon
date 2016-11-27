#!/usr/bin/env moon
--- Class for handling users.
-- @author ChickenNuggers
-- @classmod client

import line_pattern, hash from require "potato.util"
import context_from_pair from require "potato.tls"
state = require "potato.state"

class client
	--- Initiate a TLS handshake on a socket if available
	wrap_socket: (socket)->
		if state.tls_ctx
			-- ::TODO:: Alpn | SNI
			@socket\starttls state.tls_ctx

	--- Register client and establish IRCv3 capabilities
	-- @param socket Connection to client (cqueues.socket)
	-- @usage for socket in server\clients!
	-- 	loop\wrap ->
	-- 		potato.client socket
	new: (socket)=>
		@socket = socket
		@wrap_socket!
		@channels = {}
		@monitored_by = {}
		{@config} = require "potato"
		-- handle registration before iterating over lines
		-- check for NICK command or CAP command, then USER command
		line = socket\read!
		data = line_pattern\match line
		switch data.command
			when "PASS" -- PASS <password>
				if not @config.password
					@sent_password = hash data.arguments[1]
				else
					if hash data.arguments[1] != @config.password
						@fatal "Incorrect password."
			when "NICK" -- NICK <nickname>
				"pass"
			when "USER" -- USER <username> * * :<realname>
				"pass"
			when "CAP"  -- CAP {LS,LIST,REQ,ACK,NAK,END}
				"pass"
			else
				"pass"
				-- default case, do not handle line
		@loop!

	--- Send an `ERROR` message and signal `QUIT` messages
	-- @tparam string message Message to send to client
	fatal: (message)=>
		@socket\write "ERROR: #{message}\n"
		@quit message

	--- Send `QUIT` to every channel the user is in; terminate connection.
	-- @tparam string message Message to send to clients
	quit: (message)=>
		-- ::TODO:: remove channels if user is in last
		users_already_sent = {}
		for channel in *@channels
			channel.users[@nick] = nil
			for user in *channel.users
				if not users_already_sent[user]
					users_already_sent[user] = true
					user.socket\write "#{@prefix} QUIT :#{message}\n"
		for user in *@monitored_by -- MONITOR command
			user.monitors[@nick] = nil
			if not users_already_sent[user]
				users_already_sent[user] = true
				user.socket\write "#{@prefix} QUIT :#{message}\n"
		if @did_register
			state.users[@nick] = nil
		@socket\close! -- we don't dupe file descriptors, close also shuts down

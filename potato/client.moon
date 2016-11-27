#!/usr/bin/env moon
--- Class for handling users.
-- @author ChickenNuggers
-- @classmod client

import line_pattern, hash, serialize_tag_value from require "potato.util"
import context_from_pair from require "potato.tls"
state = require "potato.state"

wire_responses = {
	[401]: ":No suck nick/channel"
	[402]: ":No such server"
	[403]: ":No such channel"
	[404]: ":Cannot send to channel"
	[405]: ":You have joined too many channels"
	[406]: ":There was no such nickname"
	[407]: ":Duplicate recipients. No message delivered"
	[409]: ":No origin specified"
	[411]: ":No recipient given (%s)"
	[412]: ":No text to send"
	[413]: "%s :No toplevel domain specified"
	[414]: ":Wildcard in the top level domain"
	[421]: ":Unknown command"
	[422]: ":MOTD File is missing"
	[423]: "%s :No administrative info available"
	[424]: ":File error performing %s on %s"
	[431]: ":No nickname given"
	[432]: ":Erroneous nickname"
	[433]: ":Nickname is already in use"
	[436]: ":Nickname collision KILL"
	[441]: "%s %s :They aren't in that channel"
	[442]: "%s :You're not in that channel"
	[443]: "%s %s :is already in that channel"
	[444]: "%s :User not logged in"
	[445]: ":SUMMON has been disabled"
	[446]: ":USERS has been disabled"
	[451]: ":You have not registered"
	[461]: "%s :Not enough parameters"
	[462]: ":You may not reregister"
	[463]: ":Your host isn't among the privileged"
	[464]: ":Password incorrect"
	[465]: ":You are banned from this server"
	[467]: "%s :Channel key already set"
	[471]: "%s :Cannot join channel (+l)"
	[472]: "%s :is unknown mode char to me"
	[473]: "%s :Cannot join channel (+i)"
	[474]: "%s :Cannot join channel (+b)"
	[475]: "%s :Cannot join channel (+k)"
	[479]: "%s: Cannot join channel (%s)" -- CUSTOM new field ERR_NOJOINCHANNEL
	[481]: ":Permission denied- You're not an IRC operator"
	[482]: "%s :You're not a channel operator"
	[483]: ":You can't kill a server!"
	[491]: ":No O-lines for your host"
	[501]: ":Unknown MODE flag (%s)" -- CUSTOM modified
	[502]: ":Can't change mode for other users"
}

insert = table.insert
concat = table.concat

--- @table tag_format
-- @field vendor Optional field, contains vendor. Defaults to `default`
-- @field key Key for tag. Not optional.
-- @field value Value for tag. If left out, defaults to boolean true.
-- @field is_client Client-to-client identifier. Boolean, defaults to false

class client
	--- Initiate a TLS handshake on a socket if available.
	wrap_socket: (socket)->
		if state.tls_ctx
			-- ::TODO:: Alpn | SNI
			@socket\starttls state.tls_ctx

	--- Send a message to the client.
	-- @tparam string prefix Name, without space. May be nick!user@host.
	-- @tparam table arguments Command arguments. Will not be preceded by ':'
	-- @tparam table object_tags Optional IRCv3 tags array
	-- @see tag_format
	send: (prefix, arguments, object_tags)->
		tags = {}
		if object_tags and #object_tags > 0
			for tag in *object_tags
				current_tag = {}
				if tag.is_client
					insert current_tag, "+"
				if tag.vendor
					insert current_tag, "#{tag.vendor}/"
				insert current_tag, tag.key
				if tag.value
					insert current_tag, "=#{serialize_tag_value tag.value}"
			insert tags, " "
		if #tags != 0
			@socket\write "@#{concat tags, ';'} "
		@socket\write ":#{prefix} #{concat arguments, ' '}\n"

	--- Send a specific numeric to a user, optionally with a custom message.
	-- If a message isn't specified, one from wire_responses is used.
	-- @tparam number numeric Identifier for numeric command
	-- @tparam string description Description for command response
	-- @tparam table tags IRCv3 tags to send with message
	-- @see tag_format
	numeric: (numeric, description, tags)->
		if not description and @format == "wire"
			description = wire_responses[numeric]
		@send state.config.vhost, {numeric, description}, tags

	--- Register client and establish IRCv3 capabilities.
	-- @param socket Connection to client (cqueues.socket)
	-- @usage for socket in server\clients!
	-- 	loop\wrap ->
	-- 		potato.client socket
	new: (socket)=>
		@socket = socket
		@wrap_socket!
		@format = "wire"
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

	--- Send an `ERROR` message and signal `QUIT` messages.
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

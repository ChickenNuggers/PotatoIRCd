#!/usr/bin/env moon
--- IRCd state management module
-- @author ChickenNuggers
-- @module state

--- @table state
-- @field tls_ctx TLS context

users = {}
channels = {}

{
	:users
	:channels
}

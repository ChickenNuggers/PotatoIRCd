#!/usr/bin/env moon
--- Proxy library for Potato utility libraries
-- @author ChickenNuggers
-- @module potato

--- @table exports
-- @field init Function for initializing config.
-- @field config Placeholder table until initialized.
-- @field state Initialized class for managing state (@{state}).
-- @field client Class for handling users (@{client}). 
-- @field util Utilities and monkeypatching module (@{util}).
exports = {
	init: ((new_config)-> exports.config[k] = v for k, v in pairs(new_config))
	config: {} -- until `init` is called
	state: require "potato.state"
	client: require "potato.client"
	util: require "potato.util"
}

return exports

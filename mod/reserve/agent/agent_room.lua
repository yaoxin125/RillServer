local skynet = require "skynet"
local log = require "log"
local env = require "faci.env"

local libcenter = require "libcenter"
local libdbproxy = require "libdbproxy"

local runconf = require(skynet.getenv("runconfig"))
local games_common = runconf.games_common

local libmodules = {}

local function init_modules()
	setmetatable(libmodules, {
		__index = function(t, k)
			local mod = games_common[k]
			if not mod then
				return nil
			end
			local v = require(mod)
			t[k] = v
			return v
		end
	})
end
init_modules() -- local libmove = require "libmove"



local M = env.dispatch
local room_id = nil --房间id
local create_id = nil 
local lib = nil

local function cal_lib(game)
	return assert(libmodules[game])
end

function M.create_room(msg) 
	lib = cal_lib(msg.game)
	if not lib then
		ERROR("game not found: ", msg.game)
		msg.error = "game not found"
		return 
	end 
	create_id = 1000000--libdbproxy.inc_room()  
	local addr = lib.create(create_id)
end 

function M.enter_room(msg)
	if room_id then
		INFO("enter room fail, already in room")
		return msg
	end
	--暂时 这样处理
	-- if not msg.id and create_id then
	-- 	msg.id = create_id
	-- end 
	msg.id = 1000000
	local data = {
		uid = env.get_player().uid,
		agent = skynet.self(),
		node = node,
	}

	local isok, forward, data = lib.enter(msg.id, data)
	if isok then
		msg.result = 0
		room_id = msg.id
	else
		msg.result = 1
	end
	return msg
end

function M.leave_room(msg)
	if not room_id then
		return
	end

	local uid = env.get_player().uid
    if lib.leave(room_id, uid) then
		room_id = nil
	end
	return msg
end

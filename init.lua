
local spawn = require"coro-spawn";

local module = {};
local async = promise.async;
local proc = spawn("wmic",{args = {},stdio = {true,true,true}});
local stdinWrite = proc.stdin.write;
local insert = table.insert;
local wrap = coroutine.wrap;
local yield =  coroutine.yield;
local running =  coroutine.running;
local resume = coroutine.resume;
local events = {};
module.proc = proc;

local pack = table.pack;
-- local function unpack(t,n,p)
-- 	if not n then n = t.n or #t end
-- 	if (not n) or n == 0 then
-- 		return;
-- 	elseif not p then
-- 		if n == 1 then return t[1]; end
-- 		p = 1;
-- 		return t[1],unpack(t,n,p+1);
-- 	elseif n >= p then
-- 		return t[n];
-- 	end
-- 	return t[p],unpack(t,n,p+1);
-- end

wrap(function()
	for str in proc.stdout.read do
		if not str:match("wmic:.-cli>") then
			for pattern,waitters in pairs(events) do
				local patternType = type(pattern);
				local args;
				if patternType == "string" then
					args = pack(str:match(pattern));
                elseif patternType == "function" then
					args = pack(pattern(str));
				end
				local first = args[1];
				if first and first ~= "" then
					events[pattern] = {};
                    for _,waitting in ipairs(waitters) do
                        resume(waitting,unpack(args));
                    end
				end
                break;
			end
		end
	end
end)();

function module.addEventListener(event,cmd)
	local this = running();
	if not this then return nil,"This function can only called in coroutine"; end
	insert(events[event],this);
	stdinWrite(cmd);
	return yield();
end
local addEventListener = module.addEventListener;

local getCpuLoadpercentage = "LoadPercentage[ \t\n\r]*(%d+)";
local getCpuLoadpercentageCommand = "cpu get loadpercentage\n";
events[getCpuLoadpercentage] = {};
function module.getCpuLoadpercentage()
	return tonumber(addEventListener(getCpuLoadpercentage,getCpuLoadpercentageCommand));
end
module.getCpuLoadpercentageAsync = async(module.getCpuLoadpercentage);

local getFreePhysicalMemory = "FreePhysicalMemory[ \t\n\r]*(%d+)";
local getFreePhysicalMemoryCommand = "OS GET FreePhysicalMemory\n";
events[getFreePhysicalMemory] = {};
function module.getFreePhysicalMemory()
	return tonumber(addEventListener(getFreePhysicalMemory,getFreePhysicalMemoryCommand));
end
module.getFreePhysicalMemoryAsync = async(module.getFreePhysicalMemory);

local getTotalPhysicalMemory = "TotalPhysicalMemory[ \t\n\r]*(%d+)";
local getTotalPhysicalMemoryCommand = "ComputerSystem GET TotalPhysicalMemory\n";
events[getTotalPhysicalMemory] = {};
function module.getTotalPhysicalMemory()
	return tonumber(addEventListener(getTotalPhysicalMemory,getTotalPhysicalMemoryCommand));
end
module.getTotalPhysicalMemoryAsync = async(module.getTotalPhysicalMemory);

return module;


local spawn = require"coro-spawn";

local module = {};
local proc = spawn("wmic",{args = {},stdio = {true,true,true}});
local stdinWrite = proc.stdin.read;
local insert = table.insert;
local wrap = coroutine.wrap;
local yield =  coroutine.yield;
local running =  coroutine.running;
local resume = coroutine.resume;
local events = {};
module.proc = proc;

local pack = table.pack;
local function unpack(t,n,p)
	if not n then n = t.n or #t end
	if (not n) or n == 0 then return; end
	if n == p then
		return t[n];
	elseif not p then
		p = 1;
		if n == 1 then return t[1]; end
		return t[1],unpack(t,n,p+1);
	end
	return t[p],unpack(t,n,p+1);
end

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
				if args.n ~= 0 then
					events[pattern] = {};
                    for _,func in ipairs(waitters) do
                        resume(func,unpack(args));
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

local getCpuLoadpercentage = "LoadPercentage\n-(%d+)";
local getCPuLoadpercentageCommand = "cpu get loadpercentage";
events[getCpuLoadpercentage] = {};
function module.getCpuLoadpercentage()
	return addEventListener(getCpuLoadpercentage,getCPuLoadpercentageCommand);
end

return module;

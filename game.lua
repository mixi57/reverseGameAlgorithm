-- 输出内容 方便测试查看数据
local srep = string.rep
local tconcat = table.concat
local tinsert = table.insert
local printr = function (root, notPrint, params)
	local rootType = type(root)
	if rootType == "table" then
		local tag = params and params.tag or "Table detail:>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
		local cache = {  [root] = "." }
		local isHead = false
		local function _dump(t, space, name)
			local temp = {}
			if not isHead then
				temp = {tag}
				isHead = true
			end
			for k,v in pairs(t) do
				local key = tostring(k)
				if cache[v] then
					tinsert(temp, "+" .. key .. " {" .. cache[v] .. "}")
				elseif type(v) == "table" then
					local new_key = name .. "." .. key
					cache[v] = new_key
					tinsert(temp, "+" .. key .. _dump(v, space .. (next(t, k) and "|" or " " ) .. srep(" ", #key), new_key))
				else
					tinsert(temp, "+" .. key .. " [" .. tostring(v) .. "]")
				end
			end
			return tconcat(temp, "\n" .. space)
		end
		if not notPrint then
			print(_dump(root, "", ""))
			print("<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<")
		else
			return _dump(root, "", "")
		end
	elseif rootType == "userdata" then
		return printr(debug.getuservalue(root), notPrint, {tag = "Userdata's uservalue detail:"})
	else
		print("[printr error]: not support type")
	end
end
	
-- 游戏基础参数
local gameRowNum = 5
local gameLineNum = 5
-- 所有数据 要保证不重复
local dataGatherTable = {}
local dataCheckTable = {}
local dataCheckNum = 0
local transitionTable = {}

local function checkAnswer(data)
	local sum = 0;
	local oneTable = {}
	for i, v in ipairs(data) do
		sum = sum + v
		if v == 1 then
			table.insert(oneTable, i)
		end
		if sum > math.max(gameRowNum, gameLineNum) then
			break
		end
	end
	if sum == 0 then
		return true
	end
	return false;
end

-- 返回 false 是不存在
local function checkData(data)
	local dataTable = dataCheckTable
	for i, v in ipairs(data) do
		if dataTable[v] then
			dataTable = dataTable[v]
		else
			return false
		end
	end
	return true
end

local function addData(data, oldData, index)
	if checkData(data) then
		return
	end

	local dataTable = dataCheckTable
	local dataNum = #data
	for i, v in ipairs(data) do
		if not dataTable[v] then
			dataTable[v] = {}
		end
		dataTable = dataTable[v]
		if i == dataNum then
			if dataTable then
				dataTable["oldData"] = oldData
				dataTable["index"] = index
			end
		end
	end
	table.insert(dataGatherTable, data)
	dataCheckNum = dataCheckNum + 1
	print("dataCheckNum", dataCheckNum)
end

local function removeData(data)
	for i, v in ipairs(dataGatherTable) do
		local equil = true
		for index, value in ipairs(v) do
			if value ~= data[index] then
				equil = false
				break
			end
		end
		if equil then
			table.remove(dataGatherTable, i)
			break
		end
	end
end

local function transition(transitionType)
	if #transitionTable == 0 then
		for i = 1, gameLineNum do
			local indexTable = {}
			local index = (i - 1) * gameRowNum
			for no = 1, gameRowNum do
				table.insert(indexTable, index + no)
			end
			table.insert(transitionTable, indexTable)
		end
		for i = 1, gameRowNum do
			local indexTable = {}
			--local index = i - 1 --(i - 1) * gameLineNum
			for no = 1, gameLineNum do
				table.insert(indexTable, i + (no - 1) * gameRowNum )
			end
			table.insert(transitionTable, indexTable)
		end
		-- 斜
		local minNum = math.min(gameRowNum, gameLineNum) 
		local indexTable = {}
		for i = 1, minNum do
			local index = (gameLineNum - i) * gameRowNum + i
			table.insert(indexTable, index)		
		end
		table.insert(transitionTable, indexTable)
		--printr(transitionTable)
	end
	return transitionTable[transitionType]
end

local function clone(data)
	local newData = {}
	for i, v in pairs(data) do
		newData[i] = v
	end
	return newData
end

local function findData(data)
	if checkAnswer(data) then
		return true
	end
	removeData(data)
	transition(1)
	for i = 1, #transitionTable do
		local newData = clone(data)
		local transitionGirdNoTable = transition(i)
		for index, value in ipairs(transitionGirdNoTable) do
			newData[value] = bit32.bxor(newData[value], 1)
		end
		addData(newData, data, i)
	end
end

local function logAnwers(data)
	print("-----------")
	local str = ""
	local lastData = dataCheckTable
	for i, v in ipairs(data) do
		str = str.." "..v
		lastData = lastData[v]
	end
	print(str)
	print("+++++++++++")
	--printr(lastData)
	if lastData and lastData["oldData"] then
		print("按步数", lastData["index"])
		logAnwers(lastData["oldData"])
	else
		print("end")
	end
end

local function gameLoop()
	for i, data in ipairs(dataGatherTable) do
		if findData(data) then
			print("gameOver")
			-- 往回取数据链
			logAnwers(data)
			return true
		end
		if dataCheckNum > math.pow(2, gameRowNum * gameLineNum) then
			print("error no anwers")
			return true
		end
	end
	return false
end

local function gameStart()
	local data = {1,1,1,0,0, 1,1,1,1,1, 0,0,1,1,0, 0,1,0,1,0, 0,1,1,0,1}
	--{1,1,0,0,1, 0,0,1,0,1, 1,1,1,0,0, 0,1,1,1,1, 1,0,1,1,1}
	--{1,0,0,0,0, 0,1,1,0,0, 0,1,0,1,0, 0,0,1,1,0, 1,1,1,1,0}
	--{0,1,0,0,0, 0,1,0,1,1, 1,0,0,1,0, 1,1,1,1,0, 1,1,0,0,1}
	--{1,1,1,1,0, 0,0,0,1,0, 1,1,0,1,1, 0,1,0,0,0, 0,1,1,1,1}
	-- 
	--{
	--{0,1,1,0,0,1,1,1,1,0,1,1,1,1,0,1,1,1,1,0}
	--{0, 1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1}
	--{0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 1, 1, 0, 1, 1, 1, 0, 0, 0}
	--{0, 1, 1, 1, 1, 0, 1, 1, 0, 0, 1, 0, 0, 0, 0, 1}
	--{0, 1, 1, 0, 1, 0, 0, 1, 0, 1, 1, 0, 1, 0, 0, 1}
	--{1, 1, 1, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 1, 1, 1}
	--{0, 1, 1, 1, 0, 1, 0, 0, 1, 0, 0, 0}
	--{1, 0, 1, 1, 0, 1, 0, 1, 0, 0, 1, 0}
	--{0, 1, 1, 1, 1, 1, 1, 1, 0}--{0, 1, 0, 0, 0, 1, 0, 0, 0}--
	addData(data)
	while(1) do
		if gameLoop() then
			break
		end
	end
end
gameStart()
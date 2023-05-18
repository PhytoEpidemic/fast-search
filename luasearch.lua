local lfs = require('lfs')
local AppDataFolder = os.getenv('APPDATA')
local PowerSearchFolder = AppDataFolder .. "\\Power Search"
local SearchIndexFolder = PowerSearchFolder .. "\\IndexTrees"

local function showwindow()
	os.execute([[powershell -window normal -command ""]])
end

local function loadOptions(filename)
	local options = {}

	for line in io.lines(filename) do
		local label, value = line:match("^(.-)=(.-)$")
		
		if label then
			
			if value:lower() == "true" or value:lower() == "false" then
				value = value:lower() == "true"
			end
			
			options[label] = value
		end
		
	end
	
	return options
end

function split_by_spaces(input_string)
    local result = {}
    for word in string.gmatch(input_string, "%S+") do
        table.insert(result, word)
    end
    return result
end

function remove_enclosed_quotes(str)
    local matched = str:match('^"(.*)"$') or str:match("^'(.-)'$")
    
    if matched then
        return matched
    else
        return false
    end
end
function trim(s)
    return s:gsub("^%s*(.-)%s*$", "%1")
end
  
  
function windowsToLuaPattern(windowsPattern)
    -- Escape Lua magic characters
    local pattern = windowsPattern:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1")
    
    -- Convert Windows wildcards (*) and (?)
    pattern = pattern:gsub("%%%*", ".*")
    pattern = pattern:gsub("%%%?", ".")
    
    return pattern
end


function contains_all_words(input_string, words_table, negatives)
    for i, word in ipairs(words_table) do
        if not Config.CaseSensitive then
            input_string = input_string:lower()
        end
        local found_match = string.match(input_string, word)
		if negatives[i] and found_match then
			return false
		elseif not negatives[i] and (not found_match) and Config.ContainesAll then
			return false
        elseif found_match and (not Config.ContainesAll) then
            return true
		end
    end
    return Config.ContainesAll
end

local function addresults(driveletter, toadd, results)
	toadd = toadd:gsub([[\\]],[[\]])
	--if arg[1] then
    --    print()
    --    return
    --end
    if results then
        if not results[toadd] then
            results[toadd] = true
        else
            return results
        end
    end
    local resultsFile = io.open(driveletter .. "results.txt", "a")
	resultsFile:write(toadd)
	resultsFile:close()
    return results
end
local function save_file_tree(drive, filename)
    local file = io.open(filename, "w")

    local function write_file_tree(path, level)
        for entry in lfs.dir(path) do
            if entry ~= "." and entry ~= ".." then
                local fullPath = path .. "\\" .. entry
                local attr = lfs.attributes(fullPath)

                if attr then
                    if attr.mode == "directory" then
                        file:write(string.rep(" ", level) .. "d " .. entry .. "\n")
                        write_file_tree(fullPath, level + 1)
                    else
                        file:write(string.rep(" ", level) .. "f " .. entry .. "\n")
                    end
                end
            end
        end
    end

    write_file_tree(drive, 0)
    file:close()
end


local function search_saved_file_tree(filename, search_table, negatives, driveletter, results)
    results = results or {}
    local stack = {}
    local drive = driveletter..":"
    local function reconstruct_path(stack)
        local path = drive
        for _, part in ipairs(stack) do
            path = path .. "\\" .. part
        end
        return path
    end

    local function search_in_lines(content)
        for line in content:gmatch("[^\r\n]+") do
            local level, type, name = line:match("^(%s*)(%a)%s(.+)$")
            local indentation = #level

            while #stack > indentation do
                table.remove(stack)
            end
            local fullPath = reconstruct_path(stack) .. "\\" .. name
            if contains_all_words(name, search_table, negatives) then
                if lfs.attributes(fullPath) then
                    results = addresults(driveletter, fullPath .. "\n", results)
                end
            end
            if type == "d" then
                table.insert(stack, name)
            end
        end
    end
    if not lfs.attributes(filename) then
        return false
    end
    local file = io.open(filename, "r")
    local content = file:read("*all")
    file:close()

    search_in_lines(content)
    content = nil
    return results
end

function extract_lines(file_path, numlines)
    local extracted_lines = {}
    local remaining_lines = {}
    numlines = numlines or 1
    -- Read file content
    local i = 1
    for line in io.lines(file_path) do
        if i <= numlines then
            table.insert(extracted_lines, line)
        else
            table.insert(remaining_lines, line)
        end
        i = i + 1
    end

    -- Rewrite the file without the first two lines
    local file = io.open(file_path, "w")
    for _, line in ipairs(remaining_lines) do
        file:write(line .. "\n")
    end
    file:close()

    return extracted_lines
end





local function countDirItems(path)
	local itemcount = 0
	for file in lfs.dir(path) do
        if file ~= "." and file ~= ".." then
			itemcount = itemcount+1
		end
	end
	return itemcount
end
local ticktimer = os.time()
local function tick()
	local nowtime = os.time()
	if ticktimer ~= nowtime then
		ticktimer = nowtime
		return true
	end
	return false
end
local function space2quote(str)
	return str:gsub(" ",'" "')
end
local function updateStats(driveletter,searchcount)
	local stats = io.open(driveletter .. "stats.txt", "w")
	stats:write("searchcount="..tostring(searchcount))
	stats:close()
end

function search_files_and_folders(searchText, SearchPath)
    SearchPath = trim(SearchPath:gsub([["]],""):gsub([[']],""))
    local driveletter = SearchPath:sub(1,1)
	--if not arg[1] then
        os.remove(driveletter .. "results.txt")
	    os.remove(driveletter .. "stats.txt")
    --end
    
    local search_table = split_by_spaces(searchText)
	local negatives = {}
	for i,word in ipairs(search_table) do
		if word:sub(1,1) == "-" then
			search_table[i] = word:sub(2,#word)
			negatives[i] = true
		else
			negatives[i] = false
		end
		search_table[i] = windowsToLuaPattern(search_table[i])
		
        if not Config.CaseSensitive then
            search_table[i] = search_table[i]:lower()
        end
        
        local ExactMatch = remove_enclosed_quotes(search_table[i])
        if ExactMatch  then
            search_table[i] = "^" .. ExactMatch.. "$"
        end
        search_table[i] = string.gsub(search_table[i], ":", "%%s")
	end
    --local subProsesses = {}
    --local function checkSubprosess()
    --    if #subProsesses > 1 then
    --         for _,sprocess in ipairs(subProsesses) do
    --            local results = sprocess:read("*all")
    --            if #results > 1 then
    --            addresults(driveletter, results)
    --            end
    --             sprocess:close()
    --         end
    --         subProsesses = {}
    --     end
    --end
	local searchcount = 0
    
    local TempIndexFile = SearchIndexFolder.."\\"..driveletter.."indextree.tmp"
    local TempIndexFileHandle = false

	function search(path, level, results)
		level = level or 0
        for file in lfs.dir(path) do
            if file ~= "." and file ~= ".." then
                local ontick = tick()
				local fullPath = path..'\\'..file
                local attr = lfs.attributes(fullPath)
                
                if attr then
                    searchcount = searchcount+1
					if ontick then
						updateStats(driveletter,searchcount)
						
					end
					
					if attr.mode == 'directory' then
                        if contains_all_words(file, search_table, negatives) then
                            results = addresults(driveletter, fullPath .. "\n", results)
                        end
                        
                       
                        --table.insert(subProsesses, io.popen([[SearchAgent.exe luasearch.lua "]]..fullPath..[[" 2>&1]]))
                        --checkSubprosess()
                        if TempIndexFileHandle then
                            TempIndexFileHandle:write(string.rep(" ", level) .. "d " .. file .. "\n")
                        end
                        
                        search(fullPath, level + 1, results)
                    else
                        if contains_all_words(file, search_table, negatives) then
                            results = addresults(driveletter, fullPath .. "\n", results)
                        end
                        if TempIndexFileHandle then
                            TempIndexFileHandle:write(string.rep(" ", level) .. "f " .. file .. "\n")
                        end
                        
                    end
                end
            end
        end
    end
	
    local function save_file_tree(drive, filename)
        
    
        local function write_file_tree(path, level)
            for entry in lfs.dir(path) do
                if entry ~= "." and entry ~= ".." then
                    local fullPath = path .. "\\" .. entry
                    local attr = lfs.attributes(fullPath)
    
                    if attr then
                        if attr.mode == "directory" then
                            
                            write_file_tree(fullPath)
                        else
                            
                        end
                    end
                end
            end
        end
    
        write_file_tree(drive, 0)
        file:close()
    end

    
    if #(SearchPath:gsub([[\\]],[[\]])) == 3 then
        local oldIndexFile = SearchIndexFolder .. "\\" .. driveletter .. "indextree.txt"
        local OtherSearchNotRunning = (os.remove(TempIndexFile)) or (not lfs.attributes(TempIndexFile))
        
        if OtherSearchNotRunning then
            TempIndexFileHandle = io.open(TempIndexFile, "w")
        end
        
        local results = search_saved_file_tree(oldIndexFile, search_table, negatives, driveletter)
        
        
        search(SearchPath, 0, results)
        if TempIndexFileHandle then
            TempIndexFileHandle:close()
            os.remove(oldIndexFile)
            os.rename(TempIndexFile, oldIndexFile)
        end
        
        
    else
        search(SearchPath)
    end
    
    --checkSubprosess()
    updateStats(driveletter,searchcount)
end


--print(arg[1])
Config = loadOptions("SearchOptions.txt")
local SearchPath = extract_lines("GUIoutput.txt",1)[1] --arg[1] or 
--print(SearchPath)
os.remove("GUIoutput.txt")
local OK, errormsg = pcall( search_files_and_folders, Config.SearchText, SearchPath)
if not OK then
    print("Looks like you found an error!")
    print("Please report this error to https://github.com/PhytoEpidemic/fast-search/issues")
    print(errormsg)
    showwindow()
    os.execute("pause")
    
end
--os.execute("pause")
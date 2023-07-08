local lfs = require('lfs')
local AppDataFolder = os.getenv('APPDATA')
local PowerSearchFolder = AppDataFolder .. "\\Power Search"
local SearchIndexFolder = PowerSearchFolder .. "\\IndexTrees"

local function showwindow()
	os.execute([[powershell -window normal -command ""]])
end
local function pause()
    os.execute("pause")
end
local function updateStats(driveletter,searchcount)
	local stats = io.open(driveletter .. "stats.txt", "w")
	stats:write("searchcount="..tostring(searchcount))
	stats:close()
end




local function listFilesAndFolders(path, includeWords, excludeWords, search_table, originalInput)
    -- Temporary empty directory
    local tempDir = os.tmpname()
    --os.execute("mkdir " .. tempDir)
    local FilesOnly = Config.FilesOnly
    local FoldersOnly = Config.FoldersOnly
    -- Construct /IF arguments for robocopy
    local includeFilter = ""
    --print((#excludeWords+1),(#originalInput) )
    if not FoldersOnly then
        for i=1,(#originalInput) do
            local word = originalInput[i]
            if not excludeWords[i] then
                --print(word)
                local ExactMatch = remove_enclosed_quotes(word)
                --print(ExactMatch)
                if ExactMatch then
                    includeFilter = includeFilter .. [[ /IF "]] .. ExactMatch .. [["]]
                    --print(includeFilter)
                else
                    includeFilter = includeFilter .. [[ /IF "]] ..
    		    	    word .. [[*" /IF "*]] ..
    		    	    word .. [[*" /IF "]] ..
    		    	    word .. [[" /IF "*]] ..
    		    	    word .. [["]]
                end
            end
        end
    else
        includeFilter = " /NFL"
    end
    if FilesOnly then
        includeFilter = includeFilter.." /NDL"
    end
    local excludeFilter = ""
    for i, word in ipairs(originalInput) do
        if excludeWords[i] then

            excludeFilter = excludeFilter .. [[ /XF "]] ..
			word .. [[*" /XF "*]] ..
			word .. [[*" /XF "]] ..
			word .. [[" /XF "*]] ..
			word .. [["]]
        end
    end

    -- Run robocopy

    local FolderChangeQ = io.popen([[robocopy "]]..path..[[" "]]..tempDir..[[" /E /L /NJH /NJS /FP /NS]] .. includeFilter)--..excludeFilter)

    -- Return an iterator over the files and folders
    return function()
        local line = FolderChangeQ:read("*l")
        if line then
            -- Remove "New File" or "New Dir" prefix
            if line:find("^%s*New File%s+") then
                line = line:sub(18)
            elseif line:find("^%s*New Dir%s") then
                line = line:sub(11)
            end

            return line:match("^%s*(.-)%s*$") -- Remove leading and trailing whitespaces
        else
            -- Cleanup when no more lines
            FolderChangeQ:close()
            --os.execute("rmdir /S /Q " .. tempDir)
            return nil
        end
    end
end


function gsubFirst(s, pattern, repl)
    local start_pos, end_pos = string.find(s, pattern, 1, true)
    if start_pos == nil then
        return s
    end
    local first_part = string.sub(s, 1, start_pos - 1)
    local last_part = string.sub(s, end_pos + 1)
    return first_part .. repl .. last_part
end


local function listFilesAndFoldersMT(path, includeWords, excludeWords, search_table, originalInput, driveletter)
    -- Temporary empty directory
    local tempDir = os.tmpname()
    --os.execute("mkdir " .. tempDir)
    local FilesOnly = Config.FilesOnly
    local FoldersOnly = Config.FoldersOnly
    -- Construct /IF arguments for robocopy
    local includeFilter = ""
    --print((#excludeWords+1),(#originalInput) )
    for i=1,(#originalInput) do
        local word = originalInput[i]
        if not excludeWords[i] then
            --print(word)
            local ExactMatch = remove_enclosed_quotes(word)
            --print(ExactMatch)
            if ExactMatch then
                includeFilter = includeFilter .. [[ /IF "]] .. ExactMatch .. [["]]
                --print(includeFilter)
            else
                includeFilter = includeFilter .. [[ /IF "]] ..
		    	    word .. [[*" /IF "*]] ..
		    	    word .. [[*" /IF "]] ..
		    	    word .. [[" /IF "*]] ..
		    	    word .. [["]]
            end
        end
    end
    
    local excludeFilter = ""
    for i, word in ipairs(originalInput) do
        if excludeWords[i] then

            excludeFilter = excludeFilter .. [[ /XF "]] ..
			word .. [[*" /XF "*]] ..
			word .. [[*" /XF "]] ..
			word .. [[" /XF "*]] ..
			word .. [["]]
        end
    end
    local robologfile = driveletter..[[robolog.txt]]
    -- Run robocopy
    local roboprocess
    local numThreads = ""
    if Config.ThreadsPD > 1 then
        numThreads = " /MT:"..(tostring(Config.ThreadsPD))
    end
    if (not FoldersOnly) then
        roboprocess = io.popen([[robocopy "]]..path..[[" "]]..tempDir..[[" /E /L]]..numThreads..[[ /LOG:"]]..robologfile..[[" /NJH /NJS /FP /NS]] .. includeFilter)--..excludeFilter)
    end
    if roboprocess then
        roboprocess:read("*all")
        roboprocess:close()
        roboprocess = nil
    end
    local FolderChangeQ
    if (not FilesOnly) then
        FolderChangeQ = io.popen([[robocopy "]]..path..[[" "]]..tempDir..[[" /E /L /NFL /NJH /NJS /FP /NS]])--..excludeFilter)
    end
    
    local roboprocess2
    if (not FoldersOnly) then
        roboprocess2 = io.open(robologfile,"r")
    end

    -- Return an iterator over the files and folders
    return function()
        local line
        local Handle
        if roboprocess2 then
            Handle = roboprocess2
        elseif FolderChangeQ then
            Handle = FolderChangeQ
            
        end
        line = Handle:read("*l")
        if line then
            --line = line:sub(5)
            line = gsubFirst(line,"100%","")
            --print(line) pause()
            -- Remove "New File" or "New Dir" prefix
            if line:find("^%s*New File%s+") then
                line = line:sub(18)
                --print(line)
            elseif line:find("^%s*New Dir%s") then
                line = line:sub(11)
            end
            --print(line:match("^%s*(.-)%s*$"))
            return line:match("^%s*(.-)%s*$") -- Remove leading and trailing whitespaces
        else
            -- Cleanup when no more lines
            Handle:close()
            --os.execute("rmdir /S /Q " .. tempDir)
            if roboprocess2 then
                
                roboprocess2 = nil
                if FolderChangeQ then
                    return "dirs"
                else
                    return nil
                end
            end
            return nil
        end
    end
end


local function string_findlast(str,pat)
	local sspot,lspot = str:find(pat)
	local lastsspot, lastlspot = sspot, lspot
	while sspot do
		lastsspot, lastlspot = sspot, lspot
		sspot, lspot = str:find(pat,lastlspot+1)
	end
	return lastsspot, lastlspot
end
local function folderUP(path,num)
	num = num or 1
	local look = string_findlast(path,"\\")
	if look then
		local upafolder = path:sub(1,look-1)
		if num > 1 then
			return folderUP(upafolder,num-1)
		else
			return upafolder
		end

	else
		return ""
	end
end

local function endOfPath(f)
	local prevPath = folderUP(f)
	local cutspot = #prevPath
	if cutspot == 0 then
		cutspot = -1
	end
	return f:sub(cutspot+2,#f)
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


function removeSpecialCharsAndSplit(inputString)
    -- Replace all punctuation characters with spaces
    local stringWithSpaces = string.gsub(inputString, "%p", " ")

    -- Split string by spaces using gmatch and return the result
    local result = {}
    for word in stringWithSpaces:gmatch("%S+") do
        table.insert(result, word)
    end
    return result
end

function sortByDash(strings)
    table.sort(strings, function(a, b)
        local startsWithDashA = string.sub(a, 1, 1) == "-"
        local startsWithDashB = string.sub(b, 1, 1) == "-"
        
        if startsWithDashA and not startsWithDashB then
            return true
        elseif not startsWithDashA and startsWithDashB then
            return false
        else
            return a < b
        end
    end)

    return strings
end


function flatten(t)
    local result = {}

    local function helper(t)
        for k, v in pairs(t) do
            if type(v) == "table" then
                helper(v)
            else
                table.insert(result, v)
            end
        end
    end

    helper(t)
    return result
end
function hastrue(tab)
    for _,val in pairs(tab) do
        if val then return true end
    end
    return false
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

function contains_all_words_fast(input_string, words_table)
    for i, word in ipairs(words_table) do
		if string.match(input_string:lower(), word) then
            return true
		end
    end
    return false
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


local function search_saved_file_tree(filename, search_table, negatives, driveletter, results, quickSearchTable)
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
    local FilesOnly = Config.FilesOnly
    local FoldersOnly = Config.FoldersOnly
    local function search_in_lines(content)
        for line in content:gmatch("[^\r\n]+") do
            local level, type, name = line:match("^(%s*)(%a)%s(.+)$")
            local indentation = #level

            while #stack > indentation do
                table.remove(stack)
            end
            local fullPath = reconstruct_path(stack) .. "\\" .. name
            if contains_all_words_fast(name, quickSearchTable) and contains_all_words(name, search_table, negatives) then
                local fileInfo = lfs.attributes(fullPath)
                if fileInfo then
                    if (fileInfo.mode == "directory" and (not FilesOnly)) or (fileInfo.mode == "file" and (not FoldersOnly)) then
                        results = addresults(driveletter, fullPath .. "\n", results)
                    end
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

local function robo_search(folderPath, search_table, negatives, driveletter, results, quickSearchTable, originalInput,ifiles)
    results = results or {}
    local drive = driveletter..":"
    local folderCount = 0
    local FilesOnly = Config.FilesOnly
    local FoldersOnly = Config.FoldersOnly
    for file in ifiles do
        local fileName = endOfPath( file)
        if file:sub(#file) == "\\" then
            file = file:sub(1,#file-1)
        end
        local fileInfo = lfs.attributes(file)
        if fileInfo then
            local isDirectory = fileInfo.mode == "directory"
            if isDirectory then
                folderCount = folderCount+1
                if folderCount%197 == 1 then
                    updateStats(driveletter,folderCount)
                    --if lfs.attributes("StopSearch.txt") then
                        --os.exit()
                        --return results
                    --end
                end
            else
                --print(fileName)
            end
            
            fileName = endOfPath((file))
            --print((fileName))
            if (isDirectory and (not FilesOnly)) or (fileInfo.mode == "file" and (not FoldersOnly)) then
                if contains_all_words_fast(fileName, quickSearchTable) and contains_all_words(fileName, search_table, negatives) then
                    results = addresults(driveletter, file .. "\n", results)
                end
            end
        end
            
    end
    updateStats(driveletter,folderCount)
    return results
end


local function isFolderEmpty(path)
    if lfs.attributes(path) then
        for file in lfs.dir(path) do
            if file ~= "." and file ~= ".." then
                return false
            end
        end
    end
    return true
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


function DeepCopy(orig)
    local origType = type(orig)
    local copy
    if origType == 'table' then
        copy = {}
        for origKey, origValue in next, orig, nil do
            copy[DeepCopy(origKey)] = DeepCopy(origValue)
        end
        setmetatable(copy, DeepCopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
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

function search_files_and_folders(searchText, SearchPath)
    SearchPath = trim(SearchPath:gsub([["]],""):gsub([[']],""))
    local driveletter = SearchPath:sub(1,1)
	--if not arg[1] then
        os.remove(driveletter .. "results.txt")
	    os.remove(driveletter .. "stats.txt")
    --end
    
    local search_table = split_by_spaces(searchText)
    search_table = sortByDash(search_table)
    local originalInput = {}
	local negatives = {}
	for i,word in ipairs(search_table) do
		if word:sub(1,1) == "-" then
			search_table[i] = word:sub(2,#word)
			negatives[i] = true
		else
			negatives[i] = false
		end
		originalInput[i] = search_table[i]
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
    local quickSearchTable = {}
    for key,word in ipairs(search_table) do
        if not negatives[key] then
            table.insert(quickSearchTable, removeSpecialCharsAndSplit(word))
        end
    end
    quickSearchTable = flatten(quickSearchTable)
    for key,word in ipairs(quickSearchTable) do
        quickSearchTable[key] = word:lower()
    end
    local TempIndexFile = SearchIndexFolder.."\\"..driveletter.."indextree.tmp"
    local TempIndexFileHandle = false
    local FoldersToSearch = {}
    local FilesOnly = Config.FilesOnly
    local FoldersOnly = Config.FoldersOnly
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
                        if (not FilesOnly) and contains_all_words_fast(file, quickSearchTable) and contains_all_words(file, search_table, negatives) then
                            results = addresults(driveletter, fullPath .. "\n", results)
                        end
                        
                        
                        --table.insert(subProsesses, io.popen([[SearchAgent.exe luasearch.lua "]]..fullPath..[[" 2>&1]]))
                        --checkSubprosess()
                        if TempIndexFileHandle then
                            TempIndexFileHandle:write(string.rep(" ", level) .. "d " .. file .. "\n")
                        end
                        if Config.SearchMethod ~= "Normal FIFO" then
                            search(fullPath, level + 1, results)
                        else
                            table.insert(FoldersToSearch,fullPath)
                        end
                    elseif not FoldersOnly then
                        if contains_all_words_fast(file, quickSearchTable) and  contains_all_words(file, search_table, negatives) then
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
    local hasShortWord = false
    local hasManyWords = #quickSearchTable >= 5
    for i,word in ipairs(quickSearchTable) do
        if #word <= 3 then
            if hasShortWord then
                hasShortWord = math.min(hasShortWord,#word)
            else
                hasShortWord = #word
            end
        end
    end
    if (hasManyWords and hasShortWord) or ((hasShortWord or math.huge) <= 2) then
        --Config.SearchMethod = false
    end
    SearchPath = SearchPath:gsub([[\\]],[[\]])
    if #(SearchPath) ~= 3 then
        if Config.SearchMethod == "Normal Index" then
            Config.SearchMethod = "Normal FIFO"
        end
    end
    local oldIndexFile = SearchIndexFolder .. "\\" .. driveletter .. "indextree.txt"
    local OtherSearchNotRunning = (os.remove(TempIndexFile)) or (not lfs.attributes(TempIndexFile))
    
    if OtherSearchNotRunning and Config.SearchMethod == "Normal Index" then
        TempIndexFileHandle = io.open(TempIndexFile, "w")
    end
    
    print(Config.SearchMethod)
    
    --pause()
    if Config.SearchMethod == "RoboSearch" then
        if (#SearchPath < 4) then 
            SearchPath = SearchPath.."\\" 
        end
        local results = false
        if not isFolderEmpty(SearchPath) then
            local ifiles = listFilesAndFolders(SearchPath, quickSearchTable, negatives, search_table, originalInput)
            results = robo_search(SearchPath, search_table, negatives, driveletter, results, quickSearchTable, originalInput, ifiles)
        end
        SearchPath = SearchPath:sub(1,#SearchPath-1)
        
    elseif Config.SearchMethod == "RoboSearchMT" then
        if (#SearchPath < 4) then 
            SearchPath = SearchPath.."\\" 
        end
        local results = false
        if not isFolderEmpty(SearchPath) then
            local ifiles = listFilesAndFoldersMT(SearchPath, quickSearchTable, negatives, search_table, originalInput, driveletter)
            results = robo_search(SearchPath, search_table, negatives, driveletter, results, quickSearchTable, originalInput, ifiles)
        end
        SearchPath = SearchPath:sub(1,#SearchPath-1)
    elseif Config.SearchMethod == "Normal Index" then
        local results = false
        results = search_saved_file_tree(oldIndexFile, search_table, negatives, driveletter, results, quickSearchTable)
        search(SearchPath, 0, results)
        updateStats(driveletter,searchcount)
    elseif Config.SearchMethod == "Normal FIFO" then
        table.insert(FoldersToSearch,SearchPath)
        local indexspot = 0
        while true do
            indexspot = indexspot+1
            local thepath = FoldersToSearch[indexspot]
            if thepath then
                search(thepath)
            else
                break
            end
        end
        updateStats(driveletter,searchcount)
    elseif Config.SearchMethod == "Normal" then
        search(SearchPath)
        updateStats(driveletter,searchcount)
    end
        
        
        
        
        
    if TempIndexFileHandle then
        TempIndexFileHandle:close()
        os.remove(oldIndexFile)
        os.rename(TempIndexFile, oldIndexFile)
    end
        
    
    --checkSubprosess()
    
end


--print(arg[1])
Config = loadOptions("SearchOptions.txt")
Config.ThreadsPD = tonumber(Config.ThreadsPD)
local SearchPath = extract_lines("GUIoutput.txt",1)[1] --arg[1] or
os.execute([[title SearchAgent - ]]..SearchPath)
--print(SearchPath)
local donesignal = (SearchPath:sub(1,1)).."done.txt"
os.remove(donesignal)
os.remove((SearchPath:sub(1,1)).."stats.txt")
os.remove("GUIoutput.txt")
local OK, errormsg = pcall( search_files_and_folders, Config.SearchText, SearchPath)
if not OK then
    print("Looks like you found an error!")
    print("Please report this error to https://github.com/PhytoEpidemic/fast-search/issues")
    print(errormsg)
    showwindow()
    os.execute("pause")
    
end
--pause()
io.open(donesignal,"w"):close()
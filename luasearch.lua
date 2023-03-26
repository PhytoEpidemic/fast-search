local lfs = require('lfs')
local st = os.time()

function split_by_spaces(input_string)
    local result = {}
    for word in string.gmatch(input_string, "%S+") do
        table.insert(result, word)
    end
    return result
end

function contains_all_words(input_string, words_table, negatives)
    for i, word in ipairs(words_table) do
        local found_match = string.match(input_string, word)
		if negatives[i] and found_match then
			return false
		elseif not negatives[i] and not found_match then
			return false
		end
    end
    return true
end


function extract_first_two_lines(file_path)
    local extracted_lines = {}
    local remaining_lines = {}

    -- Read file content
    local i = 1
    for line in io.lines(file_path) do
        if i <= 2 then
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


local function addresults(driveletter, toadd)
	
	local resultsFile = io.open(driveletter .. "results.txt", "a")
	resultsFile:write((toadd:gsub([[\\]],[[\]])))
	resultsFile:close()
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
function search_files_and_folders(searchText, drive)
    local driveletter = drive:sub(1,1)
	os.remove(driveletter .. "results.txt")
	os.remove(driveletter .. "stats.txt")
    local search_table = split_by_spaces(searchText)
	local negatives = {}
	for i,word in ipairs(search_table) do
		if word:sub(1,1) == "-" then
			search_table[i] = word:sub(2,#word)
			negatives[i] = true
		else
			negatives[i] = false
		end
	end
	local searchcount = 0
	function search(path)
        
		for file in lfs.dir(path) do
            if file ~= "." and file ~= ".." then
                local ontick = tick()
				local fullPath = path..'\\'..file
                local attr = lfs.attributes(fullPath)
                if attr then
                    searchcount = searchcount+1
					if ontick then
						local stats = io.open(driveletter .. "stats.txt", "w")
						stats:write("searchcount="..tostring(searchcount))
						stats:close()
					end
					
					if attr.mode == 'directory' then
                        if contains_all_words(file, search_table, negatives) then
                            addresults(driveletter, fullPath .. "\n")
                        end
                        search(fullPath)
                    else
                        if contains_all_words(file, search_table, negatives) then
                            addresults(driveletter, fullPath .. "\n")
                        end
                    end
                end
            end
        end
    end
	
    search(drive)
    
end
args = extract_first_two_lines("GUIoutput.txt")
os.remove("GUIoutput.txt")
local searchText = args[1]
local drive = args[2]

search_files_and_folders(searchText, drive)
print(os.time()-st)
print((os.time()-st)/60)
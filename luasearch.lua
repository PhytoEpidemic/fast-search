local lfs = require('lfs')
local st = os.time()

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
function search_files_and_folders(searchText, drive)
    local driveletter = drive:sub(1,1)
	os.remove(driveletter .. "results.txt")
    function search(path, searchText)
        for file in lfs.dir(path) do
            if file ~= "." and file ~= ".." then
                local fullPath = path..'\\'..file
                local attr = lfs.attributes(fullPath)
                if attr then
                    if attr.mode == 'directory' then
                        if string.match(file, searchText) then
                            addresults(driveletter, fullPath .. "\n")
                        end
                        search(fullPath, searchText)
                    else
                        if string.match(file, searchText) then
                            addresults(driveletter, fullPath .. "\n")
                        end
                    end
                end
            end
        end
    end

    search(drive, searchText)
    
end
args = extract_first_two_lines("GUIoutput.txt")
os.remove("GUIoutput.txt")
local searchText = args[1]
local drive = args[2]

search_files_and_folders(searchText, drive)
print(os.time()-st)
print((os.time()-st)/60)
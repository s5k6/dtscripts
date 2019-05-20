
--[[ This is a more complicated version of `scrubMetadataOnExport`,
    it's the one I actually use.
    
    Function `initialize` should collect data from the gui to the
    `extraData` table.

    Function `process` is where you define the shell commands that
    sould be run on each exported file.  This function also copies the
    file to a final destination.

    Function `finalize` is called after all images were exported.

    This implementation uses the tool `exiv2` [8], and may use other
    scripts not publicly available.
    
    See [5] for the example this was derived from.

    Author: Stefan Klinger (www.stefan-klinger.de)
    License: GNU General Public License Version 3
]]



-- See [7] for how to use a relative path in `require`.
local dirOfThisFile = (...):match('^(.*)/[^/]*$')

local dt = require "darktable"
local h = require(dirOfThisFile .. "/helpers")



-- my default export path

local defaultExportPath = table.concat{
    os.getenv("HOME"), '/tmp/dt/export'
}



--[[ A GUI field to enter the export target path.  If your export
    script needs more input, you'll need to put all widgets into a
    box-widget.  See [6]. ]]

local exportPathEntry = dt.new_widget("entry"){
    text = defaultExportPath,   -- my default export path
    placeholder = '(export path)',
    editable = true,
    tooltip = 'export path'
}



--[[ Called once before the exports happen.  Collects data from the
    GUI and saves them to the `extraData` table.  Does sanity checks.
    Creates export directory.  See [2]. ]]

local initialize = function(storage, format, images, highQuality, extraData)

    --[[ Make copy of all GUI fields, in case they are changed by the
        user while exporting. ]]    
    extraData.exportPath = exportPathEntry.text
    
    -- check whether an export path is specified
    if extraData.exportPath == '' then
        print("No export path")
        return {} -- do nothing
    end

    -- create export path
    if not h.mkDir(extraData.exportPath) then
        print("Failed to create: " .. extraData.exportPath)
        return {} -- do nothing
    end

    return nil -- use unchanged list of files to export
end



--[[ Called once all store calls have finished, see [11].  Launches
    shell in export directory. ]]

local finalize = function(
	storage, -- : types.dt_imageio_module_storage_t
	imageTable, -- : table
	extraData -- : table
)
    -- open terminal in folder containing exported images
    h.runCmd{'openFolder', extraData.exportPath}
end



--[[ This function will be called once for each exported image (see
    [3]).  This function's parameter `filename` contains the path to
    file that was exported by darktable, a temporary location.  We
    work on that, and if all commands are successful the file is
    copied to the export path. ]]

local process = function(
        storage, image, format, filename, number, total, highQuality,
        extraData
)

    -- Debug
    --h.printAllFields('image', image)

    
    --[[ Run some external tools.  In general: Test your commands
        on the command line before adding them here.  Don't forget to
        restart darktable after changes to this script. ]]

    
    
    --[[ Clear all metadata: $ exiv2 rm "$filename" ]]
    if not h.runCmd{ 'exiv2', 'rm', filename } then return false end



    --[[ Add some metadata.  Only available fields will be added to
        the argument list of the command.  See [10] for a list of
        lists of available metadata tags. ]]
    
    local cmd = { 'exiv2' } -- Add arguments below.
    local run = false -- Don't run if nothing is added.
    
    -- for the easy cases (only one non-empty string argument)
    local easy = function(dst, src)
        if src and src ~= '' then
            run = true
            h.append(cmd, '-Mset ' .. dst .. ' "' .. src .. '"')
        end
    end

    -- the easy cases
    easy('Xmp.dc.creator', image.creator)
    easy('Xmp.dc.publisher', image.publisher)
    easy('Xmp.dc.title', image.title)
    easy('Xmp.dc.description', image.description)

    -- Xmp.dc.rights, fallback to "all rights reserved"
    if image.rights and image.rights ~= '' then
        h.append(cmd, '-Mset Xmp.dc.rights "' .. image.rights .. '"')
    else
        h.append(cmd, '-Mset Xmp.dc.rights "all rights reserved"')
    end
    
    -- In `Xmp.dc.source` store path to raw file.
    if (image.path or image.filename) then
        h.append(cmd, '-Mset Xmp.dc.source "' .. (image.path or '')
                     .. '/' ..  (image.filename or '') .. '"')
    end
    
    -- Only run if anything was added
    if run then
        h.append(cmd, filename) -- Don't forget filename argument
        if not h.runCmd(cmd) then return false end
    end



    -- Debug: Print all metadata to stdout.
    --h.runCmd{'exiv2', '-pa', filename}

    

    -- On success, copy the file to the target path
    return h.copyToDir(extraData.exportPath, filename)
end



-- Add all this to the list of export options.  See [1].

dt.register_storage(
    "my_export",
    "my export",
    process, -- : function
    finalize, -- finalize : function] 
    nil, -- supported : function
    initialize, -- : function
    exportPathEntry
)



--[[ Notes
    [1] https://www.darktable.org/lua-api/index.html#darktable_register_storage
    [2] https://www.darktable.org/lua-api/index.html#darktable_register_storage_initialize
    [3] https://www.darktable.org/lua-api/index.html#darktable_register_storage_store
    [4] https://darktable.gitlab.io/doc/en/lua_chapter.html
    [5] https://darktable.gitlab.io/doc/en/lua_chapter.html#lua_storage_example
    [6] https://www.darktable.org/lua-api/index.html#darktable_new_widget
    [7] https://stackoverflow.com/questions/9145432/load-lua-files-by-relative-path
    [8] http://www.exiv2.org
    [9] https://metacpan.org/pod/exiftool
    [10] https://www.exiv2.org/metadata.html
    [11] https://www.darktable.org/lua-api/index.html#darktable_register_storage_finalize
]]

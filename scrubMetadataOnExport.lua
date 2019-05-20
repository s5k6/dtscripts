--[[ If you load this file into darktable [4], the "export selected"
    module in lighttable will offer a "target storage" called "scrub
    metadata".  Enter an export path in the field below that.

    Function `initialize` should collect data from the gui to the
    `extraData` table.

    Function `process` is where you define the shell commands that
    sould be run on each exported file.  This function also copies the
    file to a final destination.

    This implementation uses the tool `exiv2` [8].  Get it if you
    don't have it, or rewrite this script to use maybe `exiftool` [9].

    Darktables's Lua API is poorly documented.  I've put links to the
    docs into this script where I find appropriate, but if that does
    not help you, ask the darktable devs on the mailing list.  See [5]
    for the example this was derived from.

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



--[[ This function will be called once for each exported image (see
    [3]).  One could invoke all kinds of external tools here.  The
    following implements three calls to `exiv2`, but you might just
    call your own script and do the coding there.  This function's
    parameter `filename` contains the path to file that was exported
    by darktable, a temporary location.  We work on that, and if all
    commands are successful the file is copied to the export path. ]]

local process = function(
        storage, image, format, filename, number, total, highQuality,
        extraData
)
    --print(filename)
    --[[ Uncomment the next line to see a list of all fields in
        `image` printed to stdout. ]]
    --for k, v in pairs(image) do print('image.' .. k, type(v), v) end

    --[[ A list of commands to run. In general: Test your commands on
        the command line before adding them here.  Don't forget to
        restart darktable after changes to this script. ]]
    local commands = {

        -- clear all metadata: $ exiv2 rm "$filename"
        { 'exiv2', 'rm', filename },

        --[[ explicitly set some metadata, takes data from `image`,
            see above how to print what's available.  The following
            produces a command akin to:

                $ exiv2 '-Mset Xmp.dc.creator "a creator"' \
                        '-Mset Xmp.dc.publisher "a publisher"' \
                        '-Mset Xmp.dc.rights "rights statement"' \
                        image.jpg

            See [10] for a list of lists of available metadata
            tags. ]]
        { 'exiv2',
          '-Mset Xmp.dc.creator "' .. image.creator .. '"',
          '-Mset Xmp.dc.publisher "' .. image.publisher .. '"',
          '-Mset Xmp.dc.rights "' .. image.rights .. '"',
          filename
        },

        -- print all metadata to stdout: $ exiv2 -pa "$filename"
        --{ 'exiv2', '-pa', filename },

    }

    -- run all commands, abort on first error
    for _, v in pairs(commands) do
        if not h.runCmd(v) then return false end
    end

    -- On success, copy the file to the target path
    return h.copyToDir(extraData.exportPath, filename)
end



-- Add all this to the list of export options.  See [1].

dt.register_storage(
    "scrub_metadata_export",
    "scrub metadata",
    process, -- : function
    nil, -- finalize : function]
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
]]

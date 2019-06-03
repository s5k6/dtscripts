
--[[ I use this script to auto-apply a default style: The style
    "minimal" only contains a switched-off basecurve.  This script is
    loaded from `luarc` by:

        require('dtscripts/applyStyleOnImport').use('minimal')

    Note: This is a workaround until basecurve is disabled by default.
    Also, You'll have to define the style "minimal", it's not included
    here.
]]



-- See [1] for how to use a relative path in `require`.
local dirOfThisFile = (...):match('^(.*)/[^/]*$')

local dt = require('darktable')
local h = require(dirOfThisFile .. '/helpers')



local m = {} -- module export



--[[ Auto-apply style named `styleName` on import of every image.

    Missing: Clear history stack first.  Compress history stack
    afterwards.  Remove unused modules.  ]]

m.use = function(styleName)

    -- find style of this name 
    local style = nil
    for k, v in ipairs(dt.styles) do
        if v.name == styleName then
            style = v
        end
    end

    if not style then
        dt.print_error('applyStyleOnImport: Style not found: ' .. styleName)
        return false
    end

    dt.register_event(
        'post-import-image',
        function(_, img)
            dt.print('Applying `' .. styleName .. '` to ' .. img.filename)
            dt.styles.apply(style, img)
        end
    )

end



return m



--[[ Notes
    [1] https://stackoverflow.com/questions/9145432/load-lua-files-by-relative-path
]]

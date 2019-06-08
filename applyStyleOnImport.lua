
--[[ I use this script to disable "base curve" on imported images.  It
    should be able to auto-apply any style on import.

    To use, import the style `minimal.dtstyle` (switches off the
    basecurve).  Then "require" this script from `luarc` by something
    like

        require('dtscripts/applyStyleOnImport').use('minimal')

    but read `README` to get the path right.  Then restart darktable.

    This is a workaround until basecurve is disabled by default.
]]



local dt = require('darktable')



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

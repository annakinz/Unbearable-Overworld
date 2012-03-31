local t = {}

-- Load a texture at most once
-- Pass:
--   filename	A texture to load
--
local s_loaded_textures = {}

function t.get_texture(png)
	local tex = s_loaded_textures[png]
	if tex then return tex end
	tex = MOAITexture.new()
	tex:load(png)
	s_loaded_textures[png] = tex
	print ('loaded',tex)
	return tex
end

-- Create a sprite from png.
-- By default, worldspace size == texel size
function t.load_single(png, scale)
	if not scale then scale = 1 end
    local deck = MOAIGfxQuad2D.new()
	local tex = t.get_texture(png)
    deck:setTexture(tex)
    local w,h = tex:getSize()
    deck:setRect(0,0,w*scale,h*scale)

    return deck
end


-- Load a sprite sheet
-- It's assumed that there is some sort of custom logic in here
-- that sets the geometry scale appropriately
--
function t.load_sheet(lua, png)
    local frames = dofile ( lua ).frames

    local tex = MOAITexture.new ()
    tex:load ( png )
    local xtex, ytex = tex:getSize ()

    -- Annotate the frame array with uv quads and geometry rects
    for i, frame in ipairs ( frames ) do
        -- convert frame.uvRect to frame.uvQuad to handle rotation
        local uv = frame.uvRect
        local q = {}
        if not frame.textureRotated then
            -- From Moai docs: "Vertex order is clockwise from upper left (xMin, yMax)"
            q.x0, q.y0 = uv.u0, uv.v0
            q.x1, q.y1 = uv.u1, uv.v0
            q.x2, q.y2 = uv.u1, uv.v1
            q.x3, q.y3 = uv.u0, uv.v1
        else
            -- Sprite data is rotated 90 degrees CW on the texture
            -- u0v0 is still the upper-left
            q.x3, q.y3 = uv.u0, uv.v0
            q.x0, q.y0 = uv.u1, uv.v0
            q.x1, q.y1 = uv.u1, uv.v1
            q.x2, q.y2 = uv.u0, uv.v1
        end
        frame.uvQuad = q

        -- convert frame.spriteColorRect and frame.spriteSourceSize
        -- to frame.geomRect.  Origin is at x0,y0 of original sprite
        local cr = frame.spriteColorRect
        local r = {}
        r.x0 = cr.x
        r.y0 = cr.y
        r.x1 = cr.x + cr.width
        r.y1 = cr.y + cr.height
        frame.geomRect = r
    end

    -- Construct the deck
    local deck = MOAIGfxQuadDeck2D.new ()
    deck:setTexture ( tex )
    deck:reserve ( #frames )
    local names = {}
    for i, frame in ipairs ( frames ) do
        local q = frame.uvQuad
        local r = frame.geomRect
        names[frame.name] = i
        deck:setUVQuad ( i, q.x0,q.y0, q.x1,q.y1, q.x2,q.y2, q.x3,q.y3 )
        deck:setRect ( i, r.x0,r.y0, r.x1,r.y1 )
    end

    return deck, names
end

return t
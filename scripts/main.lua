---@type love.Canvas
local generatedCanvas

local function readImage(fileName)
   if not fileName:match('%.png$') then
      return
   end
   local imageData = love.image.newImageData('mcblocks/'..fileName)
   local sx, sy = imageData:getDimensions()
   if sx ~= 16 or sy ~= 16 then
      return
   end
   local opaque = true
   for x = 0, sx - 1 do
      for y = 0, sy - 1 do
         local r, g, b, a = imageData:getPixel(x, y)
         if a < 0.99 then
            opaque = false
            break
         end
      end
      if not opaque then
         break
      end
   end
   if fileName:match('leaves') then
      opaque = true
   end
   if not opaque then
      return
   end
   print(fileName)
   imageData:encode('png', 'goodblocks/'..fileName)
end

local function generateImage()
   generatedCanvas = love.graphics.newCanvas(4096, 4096)
   local blocks = {}
   for _, fileName in pairs(love.filesystem.getDirectoryItems('goodblocks')) do
      local imageData = love.image.newImageData('goodblocks/'..fileName)
      local R, G, B = 0, 0, 0
      local sx, sy = imageData:getDimensions()
      for x = 0, sx - 1 do
         for y = 0, sy - 1 do
            local r, g, b, a = imageData:getPixel(x, y)
            R = R + r
            G = G + g
            B = B + b
         end
      end
      R = R / sx / sy
      G = G / sx / sy
      B = B / sx / sy
      table.insert(blocks, {
         r = R,
         g = G,
         b = B,
         imageData = imageData
      })
   end
   love.graphics.setCanvas(generatedCanvas)
   for X = 0, 4096 - 16, 16 do
      for Y = 0, 4096 - 16, 16 do
         local x = X / 4080.01
         local y = Y / 4080.01
         local r = (x * 8) % 1
         local b = (y * 8) % 1
         local g = (math.floor(y * 7.999) + math.floor(x * 7.999) / 8) / 8
         local bestBlock = {}
         local bestDist = math.huge
         for _, blockData in pairs(blocks) do
            local dist = (blockData.r ^ 2 - r ^ 2) ^ 2 + (blockData.g ^ 2 - g ^ 2) ^ 2 + (blockData.b ^ 2 - b ^ 2) ^ 2
            if dist < bestDist then
               bestBlock = blockData
               bestDist = dist
            end
         end
         if not bestBlock.image then
            bestBlock.image = love.graphics.newImage(bestBlock.imageData)
         end
         local image = bestBlock.image
         -- love.graphics.setColor(r, g, b)
         love.graphics.draw(image, X, Y)
         -- love.graphics.rectangle("fill", X, Y, 16, 16)
      end
   end
   -- love.graphics.setColor(1, 1, 1)
   love.graphics.setCanvas()
end

function love.keypressed(key)
   if key == 'o' then
      local files = love.filesystem.getDirectoryItems('mcblocks')
      love.filesystem.createDirectory('goodblocks')
      for _, fileName in pairs(files) do
         readImage(fileName)
      end
      love.event.quit()
   elseif key == 's' then
      generateImage()
      generatedCanvas:newImageData():encode('png', 'blocks.png')
      -- love.event.quit()
   end
end

function love.draw()
   love.graphics.print('o - filter blocks in mcblocks/\ns - read from goodblocks/ and generate blocks.png')
   if generatedCanvas then
      local sx, sy = love.window.getMode()
      local size = math.min(sx, sy) / 4096
      love.graphics.draw(generatedCanvas, 0, 0, 0, size, size)
   end
end
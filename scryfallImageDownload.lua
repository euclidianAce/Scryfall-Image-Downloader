#!/bin/env lua

local coroutine = require "coroutine"
local https = require "ssl.https"
local json = require "cjson.safe"

local scryfallAPI = "https://api.scryfall.com/%s"
local function getURL(str)
	return scryfallAPI:format(str)
end


------------------------------------------------------------------
------------                PRODUCERS                 ------------
------------------------------------------------------------------

local getCardData = coroutine.wrap(function(searchTerm)
	while true do
		-- format the search term
		searchTerm = searchTerm:gsub(" ", "+")
		-- make GET request
		print("Making GET request for search: ".. searchTerm)
		local jsonString, err = https.request( 
			getURL("/cards/named?fuzzy=" .. searchTerm)
		)
		-- return jsonString
		searchTerm = coroutine.yield( jsonString or nil, err )
	end
end)

local getImageData = coroutine.wrap(function(imageURI)
	local imageData
	while true do
		if imageURI ~= "error" then
			print("Making GET request for image uri...")
			imageData, err = https.request(imageURI)
		end
		imageURI = coroutine.yield(imageData or nil, err)
	end
end)
------------------------------------------------------------------
------------                 FILTER                   ------------
------------------------------------------------------------------

local decodeCardData = coroutine.wrap(function(jsonData)
	while true do
		-- decode json
		local jsonTable, err = json.decode(jsonData)
		print("Decoding search data...")
		-- return it or an error if it couldnt be fetched
		if jsonTable.object == "error" then
			print( "         Search failed: " .. jsonTable.details )
		end
		jsonData = coroutine.yield(
			(jsonTable and (jsonTable.object ~= "error")) and jsonTable.image_uris.large or "error", jsonTable.name
		)
	end
end)

------------------------------------------------------------------
------------                CONSUMERS                 ------------
------------------------------------------------------------------

local makeImage = coroutine.wrap(function(imageData, fileName)
	local outputFile
	while true do
		if imageData and fileName then
			fileName = "Images/" .. fileName:gsub("[, ]", {[","] = "", [" "] = "+"}) .. ".jpg"
			outputFile = io.open(fileName, "w")
		end
		if outputFile then
			outputFile:write(imageData)
			outputFile:close()
			print("Output written to ".. fileName)
			outputFile = nil
		end
		imageData, fileName = coroutine.yield(outputFile and true)
	end
end)

------------------------------------------------------------------
------------               SCHEDULER                  ------------
------------------------------------------------------------------
local cards = {...}

local data = {}
local uris = {}
local imageData = {}
while #cards > 0 do
	local cardData, err = getCardData( table.remove(cards) )
	if not cardData then
		print(err)
	end
	table.insert(data, cardData)
end
while #data > 0 do
	local uri, cardName = decodeCardData( table.remove(data) )
	table.insert(uris, 
		{
			uri = uri, 
			cardName = cardName
		}
	)
end
while #uris > 0 do
	local uriData = table.remove(uris)
	table.insert(imageData, 
		{
			data = getImageData(uriData.uri), 
			cardName = uriData.cardName
		}
	)
end
while #imageData > 0 do
	local image = table.remove(imageData)
	makeImage(image.data, image.cardName)
end

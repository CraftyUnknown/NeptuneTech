local ms = game:GetService("MarketplaceService")
local http = game:GetService("HttpService")
local ts = game:GetService("TweenService")
local players = game.Players

local config = require(game.ServerScriptService.Configuration)

local s, loadingErr = pcall(function()
	warn("Requesting UI...")
	local UILoader = require(129619868289742)

	if config.Theme then
		if config.Theme == "round" then
			UILoader.load()
		elseif config.Theme == "flat" then
			UILoader.loadNoRound()
		else
			UILoader.load()
		end
	else
		UILoader.load()
	end
end)

if loadingErr then
	warn("Failed to load UI: " .. loadingErr)
end

repeat
	task.wait()
until game.StarterGui:FindFirstChild("HubUI")

warn("UI has been insterted")

for _, v in pairs(game.Players:GetChildren()) do
	if v:IsA("Player") then
		repeat
			task.wait()
		until v.PlayerGui:FindFirstChild("HubUI")
	end
end

local functions = require(126248524293032)

local ui = game.StarterGui.HubUI
local ui1 = game.StarterGui.HubUI
local mainFrame = ui.main
local nameLabel = ui.side.groupName
local pList = mainFrame.products
local format = pList.Frame
local side = ui.side
local img = side.player
local plrname = side.user
local hId = mainFrame.id
local aboutLabel = ui.about.about

local gridCopy = ui.main.products:WaitForChild("UIGridLayout"):Clone()

local linkFrame = ui.link
local codeLabel = linkFrame.code

local url = config.URL

local valid_chars = {}

local groupService = game:GetService("GroupService")

local ReplicatedFirst = game:GetService("ReplicatedFirst")
ReplicatedFirst:RemoveDefaultLoadingScreen()

local ownedProducts = {}
local productCount = 0

wait()

local function checkApiKey()
	local success, response = pcall(function()
		return http:PostAsync(
			config.URL .. "/checkapikey",
			http:JSONEncode({
				hubID = config.HubID,
				apiKey = config.APIkey
			}),
			Enum.HttpContentType.ApplicationJson
		)
	end)

	if success then
		if response == "true" then
			-- valid API key, do nothing
			warn("API key correct")
			return
		else
			-- invalid response
			print("Invalid API key or hub ID")

			for _, v in pairs(game.Players:GetChildren()) do
				if v:IsA("Player") then
					v:Kick("Invalid API Key or Hub ID! Please contact an Administrator or neptuneTech Support.")
				end
			end
		end
	else
		warn("Request failed:", response)

		for _, v in pairs(game.Players:GetChildren()) do
			if v:IsA("Player") then
				v:Kick("Error while validating API key! Please contact an Administrator or neptuneTech Support.")
			end
		end
	end
end

function setGroupName(text) 
	for _, v in pairs(game.Players:GetChildren()) do
		v.PlayerGui.HubUI.side.groupName.Text = text
	end
end

function setAbout(text) 
	for _, v in pairs(game.Players:GetChildren()) do
		v.PlayerGui.HubUI.about.about.Text = text
	end
end

function updateStats(hub) 
	for _, v in pairs(game.Players:GetChildren()) do
		if v:FindFirstChild("PlayerGui") and 
			v.PlayerGui:FindFirstChild("HubUI") and 
			v.PlayerGui.HubUI:FindFirstChild("home") and 
			v.PlayerGui.HubUI.home:FindFirstChild("ownedProducts") then

			local home = v.PlayerGui.HubUI.home

			home.ownedProducts.Text = #ownedProducts
			home.totalProducts.Text = productCount
			home.totalSales.Text = hub.totalSales

			local dcName = "Unable to get name"
			local success, result = pcall(function()
				return functions.getDcName(tostring(v.UserId))
			end)

			if success then
				dcName = result
			end

			home.dcname.Text = "<b>".. dcName .."</b>\n(".. functions.getDcID(tostring(v.UserId)) .. ")"
		end
	end
end


function getGroupIcon(id)
	local res

	local s, e = pcall(function()
		res = groupService:GetGroupInfoAsync(id).EmblemUrl
	end)

	if s then
		return res
	end

	if e then
		return "error"
	end
end

local function set_valid(x, y)
	for i = string.byte(x), string.byte(y) do
		table.insert(valid_chars, string.char(i))
	end
end

local function random_string(length)
	local s = {}

	for i = 1, length do s[i] = valid_chars[math.random(1, #valid_chars)] end

	return table.concat(s)
end

function testConnection()
	local success, response = pcall(function()
		return http:GetAsync(url)
	end)

	if success and response and response ~= "" then
		return true
	else
		warn("Connection failed:", response)
		for _, v in pairs(game.Players:GetChildren()) do
			if v:IsA("Player") then
				v:Kick("Seems like nHub Servers are down! Please contact neptuneTech Support if you think that there has been an error.")
			end
		end
		return false
	end
end

set_valid('a', 'z')
set_valid('A', 'Z')
set_valid('0', '9')

checkApiKey()

wait(3)

for _, player in pairs(game.Players:GetChildren()) do
	if player:IsA("Player") then
		local s1, e1 = pcall(function()
			local data1 = http:GetAsync(url.. "/public/users/get?roblox_id=".. tostring(player.UserId))
			local a1 = http:JSONDecode(data1)

			warn("Player ID: ".. tostring(player.UserId))

			local dcId = functions.getDcID(tostring(player.UserId))

			for _, v1 in pairs(a1.data.ownedProducts[config.HubID]) do
				table.insert(ownedProducts, v1)
			end
		end)

		if e1 then
			warn("Getting Owned Products Error: ".. e1)
		end

		wait()
	end
end

for _, player in pairs(game.Players:GetChildren()) do
	if player:IsA("Player") then
		local status = testConnection()

		print("Status: ".. tostring(status))

		if status == false then
			player:Kick("Server is down. Please rejoin if you think this was an error, if not, please contact us via https://neptunetech.xyz/contact !")
			return
		end

		wait(.5)

		local data = http:GetAsync(url.. "/public/hubs/info?id="..config.HubID)
		data = http:JSONDecode(data)

		ui = player.PlayerGui.HubUI

		if data.success == false then
			player:Kick("Unable to load hub: Hub ID incorrect! Please contact an administrator if this keeps happening.")
		end

		local linked = functions.isLinked(tostring(player.UserId))

		warn("Is linked: ".. tostring(linked))

		local linkedString = tostring(linked)

		local s, e = pcall(function()
			if linkedString == "false" or linkedString == false then
				player.PlayerGui.HubUI.link.Visible = true
				local code = random_string(6)
				player.PlayerGui.HubUI.link.code.Text = "/link "..code
				functions.createLinkCode(player.Name, player.UserId, code)
			else
				player.PlayerGui.HubUI.link.Visible = false
			end
		end)

		if s then
			print("Success (Linking frame)")
		end

		if e then
			player:Kick("Linking error: "..e)
			print("Linking error: "..e)
		end
	end
end

local hub = functions.GetHub(config.HubID)

repeat
	task.wait()
until hub

if hub == false or not hub then for _, v in pairs(game.Players:GetChildren()) do v:Kick("Hub has not been set up yet. Please contact owner.") end end

local hubName = hub.name
local groupId = hub.groupID
local hubID = config.HubID

pcall(function()
	local ownerid = hub.ownerId

	if (tonumber(ownerid)) then
		local data1 = http:GetAsync(url.. "/public/users/get?discord_id=".. ownerid)
		local a1 = http:JSONDecode(data1)

		local owner = a1[ownerid]

		if owner then
			if owner.data.banned and owner.data.banned == true or owner.data.banned == "true" then
				for _, v in pairs(game.Players:GetChildren()) do v:Kick("Hub owner is banned from using nHub.") end
			end
		end
	end
end)

ui.home.id.Text = "Hub ID: ".. hubID
ui.main.id.Text = "Hub ID: ".. hubID

nameLabel.Text = hubName
setGroupName(hubName)

aboutLabel.Text = hub.about
setAbout(hub.about)

local groupIcon = getGroupIcon(hub.groupID)

ui.side.groupName.group.Image = groupIcon

print("About: ", hub.about)

local musicSuccess, musicErr = pcall(function()
	game.SoundService.Music.SoundId = "rbxassetid://".. tonumber(hub.music_id)
end)

for _, player in pairs(game.Players:GetChildren()) do
	if player:IsA("Player") then
		local ui2 = player.PlayerGui:FindFirstChild("HubUI")

		if ui2 then
			ui2.side.groupName.group.Image = groupIcon
		end
	end
end

print("Products: ", hub.products)

wait(.5)

for i, v in pairs(hub.products) do
	task.spawn(function()
		local success, err = pcall(function()
			if not v.offsale or v.offsale == false or v.offsale == "false" then
				productCount += 1

				local c = format:Clone()
				local desc = c.productDescription
				local name = c.productName
				local price = c.b.productPrice
				local image = c.image
				local reviews = c.reviews
				local convImg = 0

				if tonumber(v.image_id) > 0 then
					image.Image = "rbxassetid://"..v.image_id
				end

				local p = ms:GetProductInfo(v.devproduct, Enum.InfoType.Product)

				desc.Text = v.description
				name.Text = v.name
				c.id.Value = v.devproduct

				if table.find(ownedProducts, v.name) then
					price.Text = "Owned"
				else
					if v.stock < 0 then
						price.Text = p.PriceInRobux.. " R$ - Stock: ∞"
					else
						price.Text = p.PriceInRobux.. " R$ - Stock: ".. (v.stock or "∞")
					end
				end

				c.Name = v.name

				if v.reviewsAmount < 1 then
					reviews.Text = '<font color="#AAAAAA" size="27">(no reviews yet)</font>'
				else
					local num = math.floor(tonumber(v.reviewsTotal / v.reviewsAmount))
					local totalStars = 5

					reviews.RichText = true
					reviews.Text = ""

					for i = 1, num do
						reviews.Text = reviews.Text .. '<font color="#FFD700" size="20">⭐</font>'
					end

					for i = num + 1, totalStars do
						reviews.Text = reviews.Text .. '<font color="#AAAAAA" size="27">☆</font>'
					end

					reviews.Text = reviews.Text .. '<font color="#AAAAAA" size="20"> (' .. v.reviewsAmount .. ')</font>'
				end

				for _, plr in pairs(game.Players:GetChildren()) do
					if plr:IsA("Player") then
						if plr.PlayerGui.HubUI.main.products:FindFirstChild("Frame") then
							plr.PlayerGui.HubUI.main.products.Frame:Destroy()
						end

						if not plr.PlayerGui.HubUI.main.products:FindFirstChild("UIGridLayout") then
							gridCopy.Parent = plr.PlayerGui.HubUI.main.products
						end

						c:Clone().Parent = plr.PlayerGui.HubUI.main.products
					end
				end

				ui.side.groupName.group.Image = getGroupIcon(hub.groupID)

				task.wait()
			end
		end)

		if success then
			print("Successfully added product ", v.name)
		end

		if err then
			print("Error while listing product; ", err)
		end
	end)
end

updateStats(hub)

print("Done!")

for _, plr in pairs(game.Players:GetChildren()) do
	if plr:IsA("Player") then
		if plr.PlayerGui.HubUI.main.products:FindFirstChild("Frame") then
			plr.PlayerGui.HubUI.main.products:ClearAllChildren()

			for _, v in pairs(ui.main.products:GetChildren()) do
				print("Cloning "..v.Name.."...")

				if plr.PlayerGui.HubUI.main.products:FindFirstChild(v.Name) then
					plr.PlayerGui.HubUI.main.products:WaitForChild(v.Name):Destroy()
				end

				v:Clone().Parent = plr.PlayerGui.HubUI.main.products

				wait()
			end
		end
	end
end

if ui.main.products:FindFirstChild("Frame") then
	ui.main.products.Frame:Destroy()
end

local function onPromptPurchaseFinished(player, assetId, isPurchased)
	if isPurchased then
		print(player.Name, "bought an item with AssetID:", assetId)
	else
		print(player.Name, "didn't buy an item with AssetID:", assetId)
	end
end

function grant(receipt, discordId, plr)
	local plr = game.Players:GetPlayerByUserId(receipt.PlayerId)

	local pName = functions.FindProductByID(plr, receipt.ProductId)

	local Data = {
		["username"] = plr.Name,
		["userID"] = receipt.PlayerId,
		["productName"] = pName,
		["devProductID"] = receipt.ProductId,
		["hubID"] = config.HubID,
		["apiKey"] = config.APIkey,
		["dcName"] = discordId,
		["purchaseID"] = receipt.PurchaseId 
	}

	Data = http:JSONEncode(Data)

	local res = http:PostAsync(url.. "/giveproduct", Data)
	local resData = http:JSONDecode(res)

	return resData.success, (resData.message or "-")
end

ms.ProcessReceipt = function(receipt)
	local plr = game.Players:GetPlayerByUserId(receipt.PlayerId)

	print('Sending data to server')

	local did = functions.getDcID(receipt.PlayerId)

	local status, msg = grant(receipt, did, plr)

	local pName = functions.FindProductByID(plr, receipt.ProductId)

	print('Purchase complete')

	warn("STATUS:")
	warn(status)
	warn("MSG: ")
	warn(msg)

	if status == true or status == "true" then
		task.spawn(function()
			local s, e = pcall(function()
				task.wait(2)

				if game.SoundService:FindFirstChild("Money") then
					game.SoundService.Money:Play()
				end

				if game.SoundService:FindFirstChild("PurchaseCompleted") then
					game.SoundService.PurchaseCompleted:Play()
				end

				for _, v in pairs(plr.PlayerGui:GetChildren()) do
					if v.Name == "HubUI" then
						v.purchased.aboutBg.desc.Text = "Your purchase of <b>".. pName .."</b> went through!\n\nThe download instructions have been sent to you via discord."

						v.purchased.Visible = true

						local aboutBg = v.purchased.aboutBg

						local originalSize = UDim2.new(0.278, 0, 0.713, 0)
						local originalPosition = UDim2.new(0.361, 0, 0.143, 0)

						aboutBg.AnchorPoint = Vector2.new(0, 0)
						aboutBg.Position = UDim2.new(0.5, 0, 0.5, 0)
						aboutBg.Size = UDim2.new(0, 0, 0, 0)
						aboutBg.Visible = true
						aboutBg.BackgroundTransparency = 1 

						local tweenInfo = TweenInfo.new(
							0.35,
							Enum.EasingStyle.Back,
							Enum.EasingDirection.Out
						)

						local goal = {
							Size = originalSize,
							Position = originalPosition,
							BackgroundTransparency = 0
						}

						local tween = ts:Create(aboutBg, tweenInfo, goal)
						tween:Play()
					end
				end
			end)

			if e then
				warn(e)
			end
		end)
	else
		plr:Kick("Error while giving product: ".. msg .. "; please contact nHub Support!")
	end

	return Enum.ProductPurchaseDecision.PurchaseGranted
end

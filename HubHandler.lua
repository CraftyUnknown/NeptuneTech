local ms = game:GetService("MarketplaceService")
local http = game:GetService("HttpService")
local ts = game:GetService("TweenService")
local players = game.Players

local s, e = pcall(function()
	warn("Requesting UI...")
	local UILoader = require(129619868289742)
	UILoader.load()
end)

repeat
	task.wait()
until game.StarterGui:FindFirstChild("HubUI")

warn("UI has been insterted")

local config = require(game.ServerScriptService.Configuration)
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

local linkFrame = ui.link
local codeLabel = linkFrame.code

local url = config.URL

local valid_chars = {}

local groupService = game:GetService("GroupService")

local ReplicatedFirst = game:GetService("ReplicatedFirst")
ReplicatedFirst:RemoveDefaultLoadingScreen()

local ownedProducts = {}

wait()

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
		if v.PlayerGui.HubUI.home.ownedProducts then
			v.PlayerGui.HubUI.home.ownedProducts.Text = #ownedProducts
			v.PlayerGui.HubUI.home.totalProducts.Text = #hub.products
			v.PlayerGui.HubUI.home.totalSales.Text = hub.totalSales
			v.PlayerGui.HubUI.home.dcname.Text = "<b>".. functions.getDcName(tostring(v.UserId)) .."</b>\n(".. functions.getDcID(tostring(v.UserId)).. ")"
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
	local s, e = pcall(function()
		http:GetAsync(url)
	end)

	if s then
		return true
	else
		print(e)
		return false
	end
end

set_valid('a', 'z')
set_valid('A', 'Z')
set_valid('0', '9')

game.Players.PlayerAdded:Connect(function(player)
	local status = testConnection()

	if status == false then
		player:Kick("Server is down. Please rejoin if you think this was an error, if not, please contact us via https://neptunetech.xyz/contact !")
		return
	end

	player.CharacterAdded:Wait()

	wait(.5)

	local data = http:GetAsync(url.. "/servers")

	local a = http:JSONDecode(data)

	ui = player.PlayerGui.HubUI

	if not a[config.HubID] then
		player:Kick("Unable to load hub: Hub ID incorrect! Please contact an administrator if this keeps happening.")
	end

	local linked = functions.isLinked(tostring(player.UserId))

	print("Is linked: ".. tostring(linked))

	local linkedString = tostring(linked)

	local s, e = pcall(function()
		if linkedString == "false" or linkedString == false then
			ui.link.Visible = true
			local code = random_string(6)
			ui.link.code.Text = "/link "..code
			functions.createLinkCode(player.Name, player.UserId, code)
		else
			linkFrame.Visible = false
		end
	end)

	if s then
		print("Success (Linking frame)")
	end

	if e then
		player:Kick("Linking error: "..e)
		print("Linking error: "..e)
	end
end)

wait(3)

for _, player in pairs(game.Players:GetChildren()) do
	if player:IsA("Player") then
		local s1, e1 = pcall(function()
			local data1 = http:GetAsync(url.. "/users")

			local a1 = http:JSONDecode(data1)

			warn("Player ID: ".. tostring(player.UserId))

			local dcId = functions.getDcID(tostring(player.UserId))

			for _, v1 in pairs(a1[dcId].ownedProducts[config.HubID]) do
				table.insert(ownedProducts, v1)
			end
		end)

		if e1 then
			warn("Getting Owned Products Error: ".. e1)
		end

		wait()
	end
end

local hub = functions.GetHub(config.HubID)

if hub == false then for _, v in pairs(game.Players:GetChildren()) do v:Kick("Hub has not been set up yet. Please contact owner.") end end

local hubName = hub.name
local groupId = hub.groupID
local hubID = config.HubID

ui.home.id.Text = "Hub ID: ".. hubID
ui.main.id.Text = "Hub ID: ".. hubID

nameLabel.Text = hubName
setGroupName(hubName)

aboutLabel.Text = hub.about
setAbout(hub.about)
updateStats(hub)

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
			local c = format:Clone()
			local desc = c.productDescription
			local name = c.productName
			local price = c.b.productPrice
			local image = c.image
			local reviews = c.reviews
			local convImg = 0

			if tonumber(v.image_id) > 0 then
				local imgSucess, imgErr = pcall(function()
					convImg = http:GetAsync("https://rbxdecal.glitch.me/".. v.image_id)
					image.Image = "rbxassetid://".. convImg
				end)

				if imgErr then
					warn("Error while converting image: ".. imgErr)

					image.Image = "rbxassetid://"..v.image_id
				end
			end

			local p = ms:GetProductInfo(v.devproduct, Enum.InfoType.Product)

			desc.Text = v.description
			name.Text = v.name
			c.id.Value = v.devproduct

			if table.find(ownedProducts, v.name) then
				price.Text = "Owned"
			else
				price.Text = p.PriceInRobux.. " R$"
			end

			c.Name = v.name

			if v.reviewsAmount < 1 then
				reviews.Text = "(no reviews yet)"
			else
				reviews.Text = v.reviewsTotal/v.reviewsAmount .."/5 ⭐"
			end
			
			for _, plr in pairs(game.Players:GetChildren()) do
				if plr:IsA("Player") then
					c:Clone().Parent = plr.PlayerGui.HubUI.main.products
				end
			end

			ui.side.groupName.group.Image = getGroupIcon(hub.groupID)

			task.wait()
		end)

		if success then
			print("Successfully added product ", v.name)
		end

		if err then
			print("Error while listing product; ", err)
		end
	end)
end

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

ui.main.products.Frame:Destroy()

game.ReplicatedStorage.Loaded.Value = true

local function onPromptPurchaseFinished(player, assetId, isPurchased)
	if isPurchased then
		print(player.Name, "bought an item with AssetID:", assetId)
	else
		print(player.Name, "didn't buy an item with AssetID:", assetId)
	end
end

function grant(reciept, d, plr)
	local success, err = pcall(function()
		local plr = game.Players:GetPlayerByUserId(reciept.PlayerId)

		local pName = functions.FindProductByID(plr, reciept.ProductId)

		local Data = {
			["username"] = plr.Name,
			["userID"] = reciept.PlayerId,
			["productName"] = pName,
			["devProductID"] = reciept.ProductId,
			["hubID"] = config.HubID,
			["apiKey"] = config.APIkey,
			["dcName"] = d["".. reciept.PlayerId .. ""].discordId,
		}

		print("Player Data: ", Data)

		Data = http:JSONEncode(Data)

		local res = http:PostAsync(url.. "/giveproduct", Data)

		print(res)

		return res
	end)

	if err then
		print(err)
	end
end

ms.ProcessReceipt = function(reciept)
	local plr = game.Players:GetPlayerByUserId(reciept.PlayerId)

	local d = http:JSONDecode(http:GetAsync(url.. "/robloxusers"))
	local d1 = http:JSONDecode(http:GetAsync(url.. "/users"))

	print("Users: ", d)

	--local pName = functions.FindProductByID(reciept.ProductId)
	--local pId = d["".. reciept.PlayerId .. ""].discordId

	--if table.find(d1[pId].products[hubID], pName) then
	--	print("User already owns ".. pName.. "!")

	--	return Enum.ProductPurchaseDecision.NotProcessedYet
	--end

	print('httpget success')
	print('sending data to server')

	local givePrct = grant(reciept, d, plr)

	local pName = functions.FindProductByID(plr, reciept.ProductId)

	print(givePrct)

	print('purchase complete')

	task.spawn(function()
		task.wait(2)

		if game.SoundService:FindFirstChild("Money") then
			game.SoundService.Money:Play()
		end

		plr.PlayerGui.HubUI.purchased.aboutBg.desc.Text = "Your purchase of <b>".. pName .."</b> went through!\n\nYou have been sent the download link via discord."

		plr.PlayerGui.HubUI.purchased.Visible = true

		local aboutBg = plr.PlayerGui.HubUI.purchased.aboutBg

		local originalSize = UDim2.new(0.278, 0, 0.713, 0)
		local originalPosition = UDim2.new(0.361, 0, 0.143, 0)

		-- Setup for animation
		aboutBg.AnchorPoint = Vector2.new(0, 0)
		aboutBg.Position = UDim2.new(0.5, 0, 0.5, 0)
		aboutBg.Size = UDim2.new(0, 0, 0, 0)
		aboutBg.Visible = true
		aboutBg.BackgroundTransparency = 1 -- optional, fade in effect

		-- Tween to target
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
	end)

	return Enum.ProductPurchaseDecision.PurchaseGranted
end

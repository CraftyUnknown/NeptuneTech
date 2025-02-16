local Parent = script.Parent
local Settings = require(script:WaitForChild("Settings"))

local TS = game:GetService("TweenService")
local IS = game:GetService("InsertService")
local HTTP = game:GetService("HttpService")
local MS = game:GetService("MarketplaceService")

local Parcel = require(9428572121)

local ReceiptInsert = script.Receipt
ReceiptInsert.Parent = game.ReplicatedStorage

local POS = Parent.POS

local Prefix = "neptunePOS || "

local function SetStatus(CustomerUI, statusText)
	CustomerUI.Main.Top.Status.Text = statusText
end

local function ToggleCashierStatus(CashierUI)
	CashierUI.Main.Status.Visible = not CashierUI.Main.Status.Visible
end

local function SetCashierStatus(CashierUI, statusText)
	CashierUI.Main.Status.Text.Text = statusText
end

local function APIOrderComplete(Addons, Player, Items)
	for _, module in pairs(Addons:GetChildren()) do
		if module:IsA("ModuleScript") then
			local s, e = pcall(function()
				require(module).OrderComplete(true, Player, Items)
			end)
		end
	end
end

local function APIItemScanned(Addons, Player, Item, Price)
	for _, module in pairs(Addons:GetChildren()) do
		if module:IsA("ModuleScript") then
			local s, e = pcall(function()
				require(module).ItemScanned(true, Player, Item, Price)
			end)
		end
	end
end

local function APILogIn(Addons, Player)
	for _, module in pairs(Addons:GetChildren()) do
		if module:IsA("ModuleScript") then
			local s, e = pcall(function()
				require(module).Login(true, Player)
			end)
		end
	end
end

local function APILogOut(Addons, Player)
	for _, module in pairs(Addons:GetChildren()) do
		if module:IsA("ModuleScript") then
			local s, e = pcall(function()
				require(module).Logout(true, Player)
			end)
		end
	end
end

local function GiveItems(Player, FolderName)
	local Folder = game.ReplicatedStorage:FindFirstChild(FolderName)

	if Folder then
		for _, v in pairs(Folder:GetChildren()) do
			if v:IsA("Tool") then
				if v.Handle:FindFirstChild("EAS_Active") then
					v.Handle:WaitForChild("EAS_ACtive").Value = false
				end

				if v:FindFirstChild("EAS_Active") then
					v:WaitForChild("EAS_ACtive").Value = false
				end

				v:Clone().Parent = Player.Backpack
			end

			task.wait()
		end
	end
end

local function ClearItems(FolderName)
	local Folder = game.ReplicatedStorage:FindFirstChild(FolderName)

	if Folder then
		Folder:ClearAllChildren()
	end
end

local function RemoveCartItem(CustomerCart, CashierCart)
	for _, v in pairs(CustomerCart:GetChildren()) do
		if v:IsA("Frame") then
			v:Destroy()
		end

		task.wait()
	end

	task.wait()

	for _, v in pairs(CashierCart:GetChildren()) do
		if v:IsA("Frame") then
			v:Destroy()
		end

		task.wait()
	end
end

local function PrintReceipt(SystemName ,ReceiptPrinter, PlayerWhoPaid, Total)
	local Products = Settings.Products
	local Receipt = ReceiptPrinter:WaitForChild("Receipt")

	Receipt.Transparency = 0

	if Receipt then
		Receipt.Transparency = 0
		Receipt.Position = ReceiptPrinter.ReceiptStart.Position

		wait(.25)

		local T1 = TS:Create(Receipt, TweenInfo.new(1.5), { Position = ReceiptPrinter.ReceiptEnd.Position })
		Receipt.Sound:Play()
		T1:Play()

		wait(1.5)

		local Items = game.ReplicatedStorage:WaitForChild("ITEMS_".. SystemName):GetChildren()

		local ReceiptClone = ReceiptInsert:Clone()

		ReceiptClone.Handle.SurfaceGui.Frame.total.Text = "Total: ".. Settings.FormatCurrency(Total)

		for _, Item in pairs(Items) do
			if Item:IsA("Tool") then
				local ItmLabel = script.ItemLbl:Clone()

				ItmLabel.Text = Item.Name.. ":\n".. Settings.FormatCurrency(Products[Item.Name].Price)

				ItmLabel.Parent = ReceiptClone.Handle.SurfaceGui.Frame.items
			end

			task.wait()
		end

		ReceiptClone.Parent = PlayerWhoPaid.Backpack

		Receipt.Transparency = 1
		--Receipt.Position = ReceiptPrinter.ReceiptStart.Position

		ClearItems("ITEMS_".. SystemName)
	end
end

local function Payment(Reader, ReaderUI, Total)
	local Status, Player = false, nil
	
	task.wait(1.5)
	
	if ReaderUI:FindFirstChild("Idle") then
		ReaderUI.Idle.Visible = false
	end
	
	if Reader.Screen:FindFirstChild("Beep") then
		Reader.Screen.Beep:Play()
	end
	
	ReaderUI.Main.Payment.Status.Visible = true
	ReaderUI.Main.Payment.Status.Text = Settings.FormatCurrency(Total)
	Reader.Screen.Pay.Enabled = true
	Reader.Screen.Pay.ObjectText = "Total: ".. Settings.FormatCurrency(Total)

	Reader.Screen.Pay.Triggered:Connect(function(Player1)
		Status = true
		Player = Player1
	end)

	repeat 
		task.wait()
	until Status == true

	Reader.Screen.Contactless:Play()
	Reader.Screen.Pay.Enabled = false
	ReaderUI.Main.Payment.Status.Visible = false
	
	if ReaderUI:FindFirstChild("Idle") then
		task.spawn(function()
			task.wait(3)
			ReaderUI.Idle.Visible = true
		end)
	end

	return true, Player
end

print(Prefix.. "Checking licence...")

if game.PlaceId == 0 then warn(Prefix.."Please publish the game first!") return end

local s, e = pcall(function()
	if Parcel:Whitelist("62d91b088d9869cb89c2472f", "gnrnyaesnp110tadyyg38dm8kaf8") or Parcel:Whitelist("62d91b088d9869cb89c2472f", "v6x4l3jcj00l0a6xloeolb9mjcjw") or Parcel:Whitelist("668b3ca39c2ff2291e8210c0", "w63jz1tl5i2w2hx50ck970fj7pn1") then
		print(Prefix.. "Loading neptunePOS. Thanks for using our system!")
	else
		warn(Prefix.. "Please purchase a valid licence in order to use this product!")
		script.Parent:Destroy()
	end
end)

if e then
	print(e)
	warn(Prefix.."An error occured while checking the licence! Did you enable HTTP Services?")

	return
end

for _, System in pairs(POS:GetChildren()) do
	System.Name = "NeptunePOS_".. math.random(1,9999999)

	local Folder = Instance.new("Folder")
	Folder.Name = "ITEMS_".. System.Name

	task.spawn(function()
		if System:IsA("Model") then
			local d = false

			local paying = false

			local Scanned = {}

			local Total = 0

			Folder.Parent = game.ReplicatedStorage

			local CashierScreen = System.Screens:FindFirstChild("Cashier")
			local CustomerScreen = System.Screens:FindFirstChild("Customer")
			local CardReader = System.Reader
			local CardReaderScreen = System.Reader.Screen

			local CashierUI = CashierScreen.Display:FindFirstChild("GUI")
			local CustomerUI = CustomerScreen.Display:FindFirstChild("GUI")
			local CardReaderUI = CardReaderScreen:WaitForChild("GUI")
			
			local s, e = pcall(function()
				if CardReaderUI:FindFirstChild("Idle") then
					print("Chaning reader logo...")
					CardReaderUI.Idle.Logo = Settings.Logo
				end
			end)
			
			if e then
				warn(e)
			end

			local Addons = Parent.Addons

			CashierUI.Name = "CASHIER_GUI_".. System.Name
			CashierUI.Parent = game.StarterGui
			CashierUI.Adornee = CashierScreen.Display

			CustomerUI.Main.Background.ImageColor3 = Settings.BackgroundColor
			CustomerUI.Main.Staticbackground.BackgroundColor3 = Settings.BackgroundColor

			if Settings.UseLegacyBackground == true then
				CustomerUI.Main.Background.Visible = false
				CustomerUI.Main.LegacyBackground.Visible = true
			end

			if Settings.UseStaticBackground == true then
				CustomerUI.Main.Background.Visible = false
				CustomerUI.Main.LegacyBackground.Visible = false
				CustomerUI.Main.Staticbackground.Visible = true
			end

			for _, Plr in pairs(game.Players:GetChildren()) do
				if Plr:IsA("Player") then
					if not Plr.PlayerGui:FindFirstChild(CashierUI.Name) then
						local CLONE = CashierUI:Clone()

						CashierUI.Parent = Plr.PlayerGui
						CashierUI.Adornee = CashierScreen.Display
					end
				end
			end

			local Touch = CashierScreen:FindFirstChild("Touch")

			if CashierUI and CustomerUI then
				CashierUI.Main.Title.Text = string.gsub(CashierUI.Main.Title.Text, "$name", Settings.GroupName)
				CashierUI.Main.Logo.Image = Settings.Logo

				SetStatus(CustomerUI, "Lane closed") -- string.gsub(CustomerUI.Main.Top.Status.Text, "$name", Settings.GroupName)
			else
				warn(Prefix.. "UI not found!")
			end

			task.spawn(function()
				task.wait(3)

				for _, Plr in pairs(game.Players:GetChildren()) do
					local Btn = Plr.PlayerGui:WaitForChild("CASHIER_GUI_".. System.Name).Main.Categories.ScrollingFrame.Template
					Btn.Parent = nil

					for key, v in pairs(Settings.Products) do
						task.spawn(function()
							local c1 = Btn:Clone()

							c1.Text = "<b>".. key .."</b>".. "\n(".. Settings.FormatCurrency(v.Price) .. ")"
							c1.Parent = Plr.PlayerGui:WaitForChild("CASHIER_GUI_".. System.Name).Main.Categories.ScrollingFrame

							c1.MouseButton1Click:Connect(function()
								CashierScreen.Display.Scan:Play()

								for _, v in pairs(CustomerUI.Main:WaitForChild("Advertisements"):GetChildren()) do
									if v:IsA("Frame") then
										v.Visible = false
									end
								end
								
								if v.ItemLocation then
									local c1 = v.ItemLocation:Clone()
									
									c1.Parent = Folder
								end

								task.spawn(function()
									if System:FindFirstChild("ScannerModel") then
										System.ScannerModel.ScanPart.BrickColor = BrickColor.new("Really red")
										task.wait(.15)
										System.ScannerModel.ScanPart.BrickColor = BrickColor.new("Black")
									end
								end)

								d = true

								local Products = Settings.Products

								CashierScreen.Display.Scan:Play()


								if CustomerUI.Main.Cart:FindFirstChild(key) then
									CustomerUI.Main.Cart:WaitForChild(key).Amount.Value += 1
									CustomerUI.Main.Cart:WaitForChild(key).AmountLbl.Text = CustomerUI.Main.Cart:WaitForChild(key).Amount.Value.. "x"
									CustomerUI.Main.Cart:WaitForChild(key).Price.Text = Settings.FormatCurrency(v.Price)

									Total += v.Price

									CustomerUI.Main.Total.Text = "Total: ".. Settings.FormatCurrency(Total)

									task.wait(.5)

									d = false

									for _, Player in pairs(game.Players:GetChildren()) do
										Player.PlayerGui:WaitForChild("CASHIER_GUI_".. System.Name).Main.Total.Text = "Total: ".. Settings.FormatCurrency(Total)
										Player.PlayerGui:WaitForChild("CASHIER_GUI_".. System.Name).Main.ItemList:WaitForChild(key).AmountLbl.Text = CustomerUI.Main.Cart:WaitForChild(key).Amount.Value.. "x"

										APIItemScanned(Addons, Player, key, v.Price, Total)
									end

									return
								end
								
								Total += v.Price

								local clone = script.Item:Clone()
								
								clone.Name = key

								clone.Price.Text = Settings.FormatCurrency(Products[key].Price)

								clone.ItemName.Text = key

								clone.Parent = CustomerUI.Main.Cart

								for _, Player in pairs(game.Players:GetChildren()) do
									Player.PlayerGui:WaitForChild("CASHIER_GUI_".. System.Name).Main.Total.Text = "Total: ".. Settings.FormatCurrency(Total)
									clone:Clone().Parent = Player.PlayerGui:WaitForChild("CASHIER_GUI_".. System.Name).Main.ItemList


									APIItemScanned(Addons, Player, key, v.Price, Total)
								end
								
								CustomerUI.Main.Total.Text = "Total: ".. Settings.FormatCurrency(Total)

								task.wait(.5)

								d = false
							end)
						end)

						task.wait()
					end

					task.wait()
				end
			end)

			if Touch then
				Touch.Touched:Connect(function(part)
					if d == true then return end

					local FoundPlayer = game.Players:GetPlayerFromCharacter(part.Parent.Parent) or game.Players:GetPlayerFromCharacter(part.Parent.Parent.Parent)

					if FoundPlayer then
						local Rank = FoundPlayer:GetRankInGroup(Settings.GroupId)

						if Rank >= Settings.CashierRank then
							if System.LoggedIn.Value == false then
								if part.Parent:FindFirstChild("NeptunePosCashierID") then
									task.spawn(function()
										if System:FindFirstChild("ScannerModel") then
											System.ScannerModel.ScanPart.BrickColor = BrickColor.new("Really red")
											task.wait(.15)
											System.ScannerModel.ScanPart.BrickColor = BrickColor.new("Black")
										end
									end)

									d = true
									CashierScreen.Display.Scan:Play()

									System.LoggedIn.Value = true

									local Player = game.Players:GetPlayerFromCharacter(part.Parent.Parent) or game.Players:GetPlayerFromCharacter(part.Parent.Parent.Parent)

									if Player then
										if Player.PlayerGui:FindFirstChild("CASHIER_GUI_".. System.Name) then
											Player.PlayerGui:WaitForChild("CASHIER_GUI_".. System.Name).LoggedOut.Visible = false
											Player.PlayerGui:WaitForChild("CASHIER_GUI_".. System.Name).Main.Visible = true
										end
									end

									SetStatus(CustomerUI, "Welcome to ".. Settings.GroupName)
									CustomerUI.Main.Visible = true
									CustomerUI.Closed.Visible = false

									APILogIn(Addons, Player)

									task.wait(.5)

									d = false
								end
							else
								--print(part.Name)

								if part.Parent:FindFirstChild("NeptunePosProduct") then
									CashierScreen.Display.Scan:Play()

									for _, v in pairs(CustomerUI.Main:WaitForChild("Advertisements"):GetChildren()) do
										if v:IsA("Frame") then
											v.Visible = false
										end
									end

									task.spawn(function()
										if System:FindFirstChild("ScannerModel") then
											System.ScannerModel.ScanPart.BrickColor = BrickColor.new("Really red")
											task.wait(.15)
											System.ScannerModel.ScanPart.BrickColor = BrickColor.new("Black")
										end
									end)

									d = true

									local Products = Settings.Products

									local Player = game.Players:GetPlayerFromCharacter(part.Parent.Parent) or game.Players:GetPlayerFromCharacter(part.Parent.Parent.Parent)

									if CustomerUI.Main.Cart:FindFirstChild(part.Parent.Name) then
										CustomerUI.Main.Cart:WaitForChild(part.Parent.Name).Amount.Value += 1
										CustomerUI.Main.Cart:WaitForChild(part.Parent.Name).AmountLbl.Text = CustomerUI.Main.Cart:WaitForChild(part.Parent.Name).Amount.Value.. "x"
										CustomerUI.Main.Cart:WaitForChild(part.Parent.Name).Price.Text = Settings.FormatCurrency(Products[part.Parent.Name].Price)

										Total += Products[part.Parent.Name].Price
										Player.PlayerGui:WaitForChild("CASHIER_GUI_".. System.Name).Main.Total.Text = "Total: ".. Settings.FormatCurrency(Total)
										Player.PlayerGui:WaitForChild("CASHIER_GUI_".. System.Name).Main.ItemList:WaitForChild(part.Parent.Name).AmountLbl.Text = CustomerUI.Main.Cart:WaitForChild(part.Parent.Name).Amount.Value.. "x"

										CustomerUI.Main.Total.Text = "Total: ".. Settings.FormatCurrency(Total)

										part.Parent.Parent = Folder

										APIItemScanned(Addons, Player, part.Parent.Name, Products[part.Parent.Name].Price, Total)

										task.wait(.5)

										d = false

										return
									end

									--if table.find(Products, part.Parent.Name) then

									CashierScreen.Display.Scan:Play()

									local clone = script.Item:Clone()

									clone.Name = part.Parent.Name

									--print(Products[part.Parent.Name])

									Total += Products[part.Parent.Name].Price
									Player.PlayerGui:WaitForChild("CASHIER_GUI_".. System.Name).Main.Total.Text = "Total: ".. Settings.FormatCurrency(Total)

									clone.Price.Text = Settings.FormatCurrency(Products[part.Parent.Name].Price)

									clone.ItemName.Text = part.Parent.Name

									--if Player then
									--if Player.PlayerGui:FindFirstChild("CASHIER_GUI_".. System.Name) then
									clone:Clone().Parent = Player.PlayerGui:WaitForChild("CASHIER_GUI_".. System.Name).Main.ItemList
									--end
									--end

									clone.Parent = CustomerUI.Main.Cart

									CustomerUI.Main.Total.Text = "Total: ".. Settings.FormatCurrency(Total)

									part.Parent.Parent = Folder

									APIItemScanned(Addons, Player, part.Parent.Name, Products[part.Parent.Name].Price, Total)

									task.wait(.5)

									d = false
									--end
								end
							end
						else
							print(Prefix.. "Missing permissions to use this system. (under min. rank)")
						end
					end
				end)
			else
				warn(Prefix.. "Cashier ID Touch Part not found!")
			end

			while wait(3) do
				for _, Player in pairs(game.Players:GetChildren()) do
					Player.PlayerGui:WaitForChild(CashierUI.Name).Main.VoidButtonClicked.OnServerEvent:Connect(function()
						--System.LoggedIn.Value = false

						--SetStatus(CustomerUI, "Lane closed")
						RemoveCartItem(CustomerUI.Main.Cart, Player.PlayerGui:WaitForChild("CASHIER_GUI_".. System.Name).Main.ItemList)
						GiveItems(Player, Folder.Name)

						--CustomerUI.Main.Visible = false
						--CustomerUI.Closed.Visible = true

						Total = 0
						Player.PlayerGui:WaitForChild("CASHIER_GUI_".. System.Name).Main.Total.Text = "Total: ".. Settings.FormatCurrency(Total)

						--APILogOut(Addons, Player)
					end)

					Player.PlayerGui:WaitForChild(CashierUI.Name).Main.LogOutPressed.OnServerEvent:Connect(function()
						if System.LoggedIn.Value == true then
							d = true
							--CashierScreen.Display.Scan:Play()

							System.LoggedIn.Value = false

							if Player then
								if Player.PlayerGui:FindFirstChild("CASHIER_GUI_".. System.Name) then
									Player.PlayerGui:WaitForChild("CASHIER_GUI_".. System.Name).LoggedOut.Visible = true
									Player.PlayerGui:WaitForChild("CASHIER_GUI_".. System.Name).Main.Visible = false
								end
							end

							for _, Plr in pairs(game.Players:GetChildren()) do
								if Plr.PlayerGui:FindFirstChild("CASHIER_GUI_".. System.Name) then
									Plr.PlayerGui:WaitForChild("CASHIER_GUI_".. System.Name).LoggedOut.Visible = true
									Plr.PlayerGui:WaitForChild("CASHIER_GUI_".. System.Name).Main.Visible = false
								end
							end

							SetStatus(CustomerUI, "Lane closed")
							RemoveCartItem(CustomerUI.Main.Cart, Player.PlayerGui:WaitForChild("CASHIER_GUI_".. System.Name).Main.ItemList)
							GiveItems(Player, Folder.Name)

							CustomerUI.Main.Visible = false
							CustomerUI.Closed.Visible = true

							Total = 0
							Player.PlayerGui:WaitForChild("CASHIER_GUI_".. System.Name).Main.Total.Text = "Total: ".. Settings.FormatCurrency(Total)

							APILogOut(Addons, Player)

							task.wait(.5)

							d = false
						end
					end)

					Player.PlayerGui:WaitForChild(CashierUI.Name).Main.PayButtonClicked.OnServerEvent:Connect(function()
						if Total > 0 and paying == false then
							paying = true
							
							System.ScannerModel.ScanPart.BrickColor = BrickColor.new("Really red")

							ToggleCashierStatus(Player.PlayerGui:WaitForChild(CashierUI.Name))
							SetCashierStatus(Player.PlayerGui:WaitForChild(CashierUI.Name), "Waiting for card...")

							Player.PlayerGui:WaitForChild(CashierUI.Name).Main.Pay.Visible = false
							Player.PlayerGui:WaitForChild(CashierUI.Name).Main.Void.Visible = false
							Player.PlayerGui:WaitForChild(CashierUI.Name).Main.AddManual.Visible = false
							Player.PlayerGui:WaitForChild(CashierUI.Name).Main.Logout.Visible = false

							local Status, Player1 = Payment(CardReader, CardReaderUI, Total)

							repeat task.wait() until Status == true

							--API:WaitForChild("OrderCompleted"):FireServer(Status,Player1,Folder:GetChildren())
							APIOrderComplete(Addons, Player1,Folder:GetChildren())

							task.wait(1)

							Player.PlayerGui:WaitForChild(CashierUI.Name).Main.Pay.Visible = false
							Player.PlayerGui:WaitForChild(CashierUI.Name).Main.Void.Visible = false

							SetCashierStatus(Player.PlayerGui:WaitForChild(CashierUI.Name), "Processing...")

							task.wait(2)


							RemoveCartItem(CustomerUI.Main.Cart, Player.PlayerGui:WaitForChild("CASHIER_GUI_".. System.Name).Main.ItemList)
							SetCashierStatus(Player.PlayerGui:WaitForChild(CashierUI.Name), "Payment successful!")
							GiveItems(Player1, Folder.Name)

							task.wait(2)

							ToggleCashierStatus(Player.PlayerGui:WaitForChild(CashierUI.Name))

							task.spawn(function()
								CustomerUI.Main.ThankYou.Visible = true

								task.wait(3)

								CustomerUI.Main.ThankYou.Visible = false
							end)

							Player.PlayerGui:WaitForChild(CashierUI.Name).Main.Pay.Visible = true

							Player.PlayerGui:WaitForChild(CashierUI.Name).Main.Receipt.Visible = true
							
							if CashierScreen.Display:FindFirstChild("Error") then
								CashierScreen.Display.Error:Play()
							end

							Player.PlayerGui:WaitForChild(CashierUI.Name).Main.PrintReceiptYes.OnServerEvent:Connect(function() -- Print receipt
								PrintReceipt(System.Name, System.ReceiptPrinter, Player1, Total)

								Player.PlayerGui:WaitForChild(CashierUI.Name).Main.Receipt.Visible = false

								Total = 0
								Player.PlayerGui:WaitForChild("CASHIER_GUI_".. System.Name).Main.Total.Text = "Total: ".. Settings.FormatCurrency(Total)

								paying = false

								Player.PlayerGui:WaitForChild(CashierUI.Name).Main.Void.Visible = true
								Player.PlayerGui:WaitForChild(CashierUI.Name).Main.AddManual.Visible = true
								Player.PlayerGui:WaitForChild(CashierUI.Name).Main.Logout.Visible = true

								ClearItems(Folder.Name)
								
								System.ScannerModel.ScanPart.BrickColor = BrickColor.new("Black")
							end)

							Player.PlayerGui:WaitForChild(CashierUI.Name).Main.PrintReceiptNo.OnServerEvent:Connect(function() -- Dont print receipt
								Player.PlayerGui:WaitForChild(CashierUI.Name).Main.Receipt.Visible = false

								Total = 0
								Player.PlayerGui:WaitForChild("CASHIER_GUI_".. System.Name).Main.Total.Text = "Total: ".. Settings.FormatCurrency(Total)

								paying = false

								Player.PlayerGui:WaitForChild(CashierUI.Name).Main.Void.Visible = true
								Player.PlayerGui:WaitForChild(CashierUI.Name).Main.AddManual.Visible = true
								Player.PlayerGui:WaitForChild(CashierUI.Name).Main.Logout.Visible = true

								ClearItems(Folder.Name)
								
								System.ScannerModel.ScanPart.BrickColor = BrickColor.new("Black")
							end)
						end
					end)
				end
			end
		end
	end)

	task.spawn(function()
		while true do
			local CashierScreen = System.Screens:FindFirstChild("Cashier")
			local CustomerScreen = System.Screens:FindFirstChild("Customer")

			local CashierUI = CashierScreen.Display:FindFirstChild("GUI")
			local CustomerUI = CustomerScreen.Display:FindFirstChild("GUI")

			local Ads = CustomerUI.Main:FindFirstChild("Advertisements")

			if Ads then
				if #CustomerUI.Main.Cart:GetChildren() <= 2 then
					for _, v in pairs(Ads:GetChildren()) do
						if v:IsA("Frame") then
							v.Visible = false
						end
					end

					local Ad = Ads:GetChildren()[math.random(1, #Ads:GetChildren())]
					Ad.Visible = true
				end
			end

			task.wait(5)
		end
	end)
end

-- ArchiTotem 主文件
-- 兼容性：保留一些可能被外部引用的全局变量
local _, class = UnitClass("player")

-- 确保只有萨满祭司才加载数据
if class == "SHAMAN" then
	-- 这里的初始化代码已经移动到 Data.lua 中
	-- 保留此文件主要用于向后兼容
	
	-- 立即初始化数据（如果尚未初始化）
	if not ArchiTotem_Options then
		ArchiTotem_InitializeOptions()
	end
	
	if not ArchiTotem_TotemData then
		ArchiTotem_InitializeTotemData()
	end
	
	-- 兼容性检查
	ArchiTotem_CheckCompatibility()
else
	-- 如果不是萨满祭司，确保变量为空
	ArchiTotem_Options = nil
	ArchiTotem_TotemData = nil
end
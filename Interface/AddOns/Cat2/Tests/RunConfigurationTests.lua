-- 从仓库根目录运行；兼容 Lua 5.1 和 Fengari 测试环境。
table.getn = table.getn or function(value) return #value end
unpack = unpack or table.unpack
print("ConfigurationJumpTest passed: " .. dofile("Cat2/Tests/ConfigurationJumpTest.lua"))
dofile("Cat2/Tests/ConfigurationCallTest.lua")

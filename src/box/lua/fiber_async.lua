-- fiber_async.lua


-- -- start async:
-- local f = box.fiber.async(function(...) do something retrun 123 end, arg1)
--
-- -- wait for f is done:
-- result = f:join()
-- print(result)    -- prints 123

function box.fiber.async(f, ...)

    args = { ... }
    local self = {
        w = {},                 -- waiters for join
        join = function(self)
            local ch = box.ipc.channel(1)
            table.insert(self.w, ch)
            ch:get()
            return self:join()
        end
    }

    local fiber = box.fiber.create(function() 
        box.fiber.detach()

        local res = { pcall(f, unpack(args)) }

        if res[1] then
            table.remove(res, 1)
            self.join = function()
                return unpack(res)
            end
        else
            self.join = function()
                error(res[2])
            end
        end

        -- wakeup all waiters
        local wlist = self.w
        self.w = nil
        for i, ch in pairs(wlist) do
            ch:put(true, 0)
        end
    end)


    box.fiber.resume(fiber)


    return self
end

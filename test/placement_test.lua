local placement = require('placement')

local display = {x = 0, y = 0, width = 2560, height = 1366}

return {
  {'round goes half away from zero', function()
    assert(placement.round(2.5) == 3)
    assert(placement.round(-2.5) == -3)
    assert(placement.round(-1461.5) == -1462)
    assert(placement.round(0.4) == 0 and placement.round(-0.4) == 0)
  end},
  {'truncate goes toward zero', function()
    assert(placement.truncate(1366.9) == 1366)
    assert(placement.truncate(-3.7) == -3)
  end},
  {'usable removes the bottom inset and keeps one point', function()
    local area = placement.usable(10, 25, 2560, 1410, 44)
    assert(area.x == 10 and area.y == 25 and area.width == 2560 and area.height == 1366)
    assert(placement.usable(0, 0, 100, 30, 44).height == 1)
  end},
  {'centre rounds each axis', function()
    local x, y = placement.centre({x = -1921, y = 0, width = 1920, height = 1000}, 1001, 500)
    assert(x == -1462 and y == 250, x .. ',' .. y)
  end},
  {'the ladder matches the README table', function()
    local expected = {{1016, 861}, {1613, 1084}, {2113, 1241}, {2560, 1366}}
    local height = display.height
    for stage = 1, placement.stages do
      local width
      width, height = placement.next_stage(display, height)
      assert(width == expected[stage][1] and height == expected[stage][2],
        stage .. ': ' .. width .. 'x' .. height)
    end
  end},
  {'a height between stages steps from the nearest one', function()
    local width, height = placement.next_stage(display, 870)
    assert(width == 1613 and height == 1084)
  end},
}

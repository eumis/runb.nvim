---@diagnostic disable: need-check-nil

local assert = require "luassert"

local util = require "runb.util"

describe("util.append", function()
    local cases = {
        {
            list = { 1 },
            items = {},
            expected = { 1 },
        },
        {
            list = {},
            items = { 2 },
            expected = { 2 },
        },
        {
            list = { 1, 2 },
            items = { 3, 4 },
            expected = { 1, 2, 3, 4 },
        },
    }
    for i, case in ipairs(cases) do
        it("should append items to list " .. tostring(i), function()
            util.append(case.list, case.items)

            assert.are.same(case.expected, case.list)
        end)
    end
end)

describe("util.join", function()
    local cases = {
        {
            one = { 1 },
            two = {},
            expected = { 1 },
        },
        {
            one = {},
            two = { 2 },
            expected = { 2 },
        },
        {
            one = { 1, 2 },
            two = { 3, 4 },
            expected = { 1, 2, 3, 4 },
        },
    }
    for i, case in ipairs(cases) do
        it("should join two lists " .. tostring(i), function()
            local actual = util.join(case.one, case.two)

            assert.are.same(case.expected, actual)
        end)
    end
end)

describe("util.flatten", function()
    local cases = {
        {
            list = { 1, 2 },
            expected = { 1, 2 },
        },
        {
            list = { 1, { 2, 3 }, 4 },
            expected = { 1, 2, 3, 4 },
        },
    }
    for i, case in ipairs(cases) do
        it("should append items to list " .. tostring(i), function()
            local actual = util.flatten(case.list)

            assert.are.same(case.expected, actual)
        end)
    end
end)

describe("util.util.index", function()
    local cases = {
        {
            list = { 1, 2, 3 },
            value = 1,
            expected = 1,
        },
        {
            list = { 1, 2, 3 },
            value = 2,
            expected = 2,
        },
        {
            list = { 1, 2, 3 },
            value = 3,
            expected = 3,
        },
        {
            list = { 1, 2, 3 },
            value = 4,
            expected = nil,
        },

    }
    for i, case in ipairs(cases) do
        it("should return item index " .. tostring(i), function()
            local actual = util.index(case.list, case.value)

            assert.are.same(case.expected, actual)
        end)
    end
end)

describe("util.for_each", function()
    it("should return item index", function()
        local actual = {}
        local input = { 1, 2, 3, 4 }

        util.for_each(input,
            function(i, _) return i % 2 == 0 end,
            function(_, value)
                table.insert(actual, value)
            end)

        assert.are.same({ 2, 4 }, actual)
    end)
end)

describe("util.take", function()
    local input = { 1, 2, 3, 4 }
    local cases = {
        { n = 0, expected = {} },
        { n = 1, expected = { 1 } },
        { n = 3, expected = { 1, 2, 3 } },
        { n = 4, expected = { 1, 2, 3, 4 } },
        { n = 5, expected = { 1, 2, 3, 4 } },
    }
    for i, case in ipairs(cases) do
        it("should return first n items " .. i, function()
            local actual = util.take(input, case.n)

            assert.are.same(case.expected, actual)
        end)
    end
end)

describe("util.skip", function()
    local input = { 1, 2, 3, 4 }
    local cases = {
        { n = 0, expected = { 1, 2, 3, 4 } },
        { n = 1, expected = { 2, 3, 4 } },
        { n = 3, expected = { 4 } },
        { n = 4, expected = {} },
    }
    for i, case in ipairs(cases) do
        it("should return list with skipped n items " .. i, function()
            local actual = util.skip(input, case.n)

            assert.are.same(case.expected, actual)
        end)
    end
end)

describe("util.split", function()
    local cases = {
        { s = "1 2 3",           delimeter = " ",  expected = { "1", "2", "3" } },
        { s = "a,b, c",          delimeter = ",",  expected = { "a", "b", " c" } },
        { s = "one--two--three", delimeter = "--", expected = { "one", "two", "three" } },
    }
    for i, case in ipairs(cases) do
        it("should return list of split items " .. i, function()
            local actual = util.split(case.s, case.delimeter)

            assert.are.same(case.expected, actual)
        end)
    end
end)

describe("starts_with", function()
    local cases = {
        { s = "one",          prefix = "o",     expected = true },
        { s = "one",          prefix = "one",   expected = true },
        { s = "one",          prefix = "One",   expected = false },
        { s = "one",          prefix = "oN",    expected = false },
        { s = "ONe",          prefix = "ON",    expected = true },
        { s = "> some start", prefix = "> som", expected = true },
        { s = "> some start", prefix = "< som", expected = false },
        { s = "> some start", prefix = "<som",  expected = false },
    }
    for i, case in ipairs(cases) do
        it("should return true if string starts with prefix " .. i, function()
            local actual = util.starts_with(case.s, case.prefix)

            assert.are.same(case.expected, actual)
        end)
    end
end)

describe("util.decode", function()
    local cases = {
        { json = '{ "a": 1, "b": 2 }', expected = { a = 1, b = 2 } },
        {
            json = {
                '{',
                '  "a": 1,',
                '  "b": 2',
                '}',
            },
            expected = { a = 1, b = 2 }
        },
    }
    for i, case in ipairs(cases) do
        it("should decode json " .. i, function()
            local actual = util.decode(case.json)

            assert.are.same(case.expected, actual)
        end)
    end
end)

return {
  "nvim-mini/mini.hipatterns",
  recommended = true,
  desc = "Highlight colors in your code. Also includes Tailwind CSS support.",
  event = "LazyFile",
  opts = function()
    local hi = require("mini.hipatterns")

    -- Pure Lua OKLCH to RGB conversion
    local function oklch_to_rgb(l, c, h)
      -- Convert to OKLAB
      local a = c * math.cos(math.rad(h))
      local b = c * math.sin(math.rad(h))

      -- OKLAB to linear RGB
      local l_ = l + 0.3963377774 * a + 0.2158037573 * b
      local m_ = l - 0.1055613458 * a - 0.0638541728 * b
      local s_ = l - 0.0894841775 * a - 1.2914855480 * b

      local l_cubed = l_ * l_ * l_
      local m_cubed = m_ * m_ * m_
      local s_cubed = s_ * s_ * s_

      local r_linear = 4.0767416621 * l_cubed - 3.3077115913 * m_cubed + 0.2309699292 * s_cubed
      local g_linear = -1.2684380046 * l_cubed + 2.6097574011 * m_cubed - 0.3413193965 * s_cubed
      local b_linear = -0.0041960863 * l_cubed - 0.7034186147 * m_cubed + 1.7076147010 * s_cubed

      -- Clamp to [0, 1]
      r_linear = math.max(0, math.min(1, r_linear))
      g_linear = math.max(0, math.min(1, g_linear))
      b_linear = math.max(0, math.min(1, b_linear))

      -- Apply sRGB gamma correction
      local function srgb_gamma(x)
        if x <= 0.0031308 then
          return 12.92 * x
        else
          return 1.055 * math.pow(x, 1 / 2.4) - 0.055
        end
      end

      local r = math.floor(srgb_gamma(r_linear) * 255 + 0.5)
      local g = math.floor(srgb_gamma(g_linear) * 255 + 0.5)
      local b = math.floor(srgb_gamma(b_linear) * 255 + 0.5)

      return r, g, b
    end

    return {
      highlighters = {
        hex_color = hi.gen_highlighter.hex_color(),

        -- OKLCH color pattern: oklch(L C H) or oklch(L C H / A)
        oklch = {
          pattern = "oklch%([^%)]+%)",
          group = function(_, match, data)
            -- Parse the values from the match string
            local content = match:match("oklch%(([^%)]+)%)")
            if not content then
              return nil
            end

            -- Try to parse: L C H (with optional / A)
            local l_str, c_str, h_str = content:match("^%s*([%d.]+%%?)%s+([%d.]+%%?)%s+([%d.]+%%?)")

            if not l_str or not c_str or not h_str then
              return nil
            end

            local l = tonumber(l_str:match("[%d.]+"))
            local c = tonumber(c_str:match("[%d.]+"))
            local h = tonumber(h_str:match("[%d.]+"))

            if not l or not c or not h then
              return nil
            end

            -- Handle percentage notation
            if l_str:find("%%") then
              l = l / 100
            end
            if c_str:find("%%") then
              c = c / 100
            end

            local r, g, b = oklch_to_rgb(l, c, h)
            local hex = string.format("#%02x%02x%02x", r, g, b)

            return hi.compute_hex_color_group(hex, "bg")
          end,
          extmark_opts = { priority = 2000 },
        },
      },
    }
  end,
  config = function(_, opts)
    require("mini.hipatterns").setup(opts)
  end,
}

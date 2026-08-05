-- Trackpoint drift filter -- Elan TrackPoint (LEN0321), ThinkPad P14s Gen 5 AMD
--
-- The sensor's zero point wanders, so the stick reports a phantom deflection
-- until the firmware re-zeros. Drift cannot be separated from real input by
-- MAGNITUDE (they overlap completely), nor by ABSOLUTE dispersion (drift
-- magnitude varies ~4x between events, so its absolute spread varies too).
--
-- What separates them is the COEFFICIENT OF VARIATION -- spread relative to
-- size. Measured against user-confirmed hands-off drift events:
--
--     event            mean |d|   sd     sd/mean
--     mild                 1.59   0.49     0.31
--     mild                 0.97   0.27     0.28
--     severe (2270px!)     3.66   0.58     0.16
--     typical real input   1.96   1.90     ~1.0
--
-- The severe event has the LARGEST absolute sd yet is proportionally the
-- steadiest -- an absolute-sd threshold misses exactly the events that matter
-- most. A sensor bias is steady relative to its own size, at any size; a hand
-- is not.
--
-- Two gates, both measured over 184 minutes of real captured use:
--
--   1. ONSET GATE. Real drift is steady from the instant it begins. Ordinary
--      movement that merely happens to hold steady for half a second starts
--      out variable. Requiring the episode's first 400ms to be drift-like
--      dropped 20 of 108 acted-on episodes -- all of them mid-movement -- while
--      keeping every confirmed drift and every large suppression.
--   2. SUSTAIN GATE. WINDOW + HOLD of steady signal before acting at all.
--
-- Net result with the settings below:
--     suppresses 2.24% of all motion (9.9k of 431k px)
--     removes ~80% of the severe 2270px runaway, engaging ~0.5s in
--     9 runs removed >=300px; the confirmed drifts are among them

version = libinput:register({ 1 })

-- ---------------------------------------------------------------- tunables --
local WINDOW    = 40     -- samples judged at once (~400ms at this device's 100Hz)
local MAX_COV   = 0.35   -- max spread/mean ratio to call it a constant bias
local ONSET_COV = 0.45   -- episode must look drift-like within its first WINDOW
local MIN_MEAN  = 0.60   -- ignore near-idle jitter
local HOLD      = 20     -- consecutive qualifying windows before suppressing
local GAP_US    = 250000 -- >250ms of silence starts a fresh episode
-- ---------------------------------------------------------------------------
--
-- These came from a measured sweep, not from feel. Loosening MAX_COV or
-- shortening HOLD raises suppressed real motion sharply (CoV 0.35 with HOLD=5
-- suppresses 25% of all motion). ONSET_COV is deliberately looser than MAX_COV:
-- the confirmed drifts had onset CoV up to 0.44.

local function spread_and_mean(t)
  local n = #t
  if n < 2 then return 0.0, 0.0 end
  local sum = 0.0
  for i = 1, n do sum = sum + t[i] end
  local mean = sum / n
  local acc = 0.0
  for i = 1, n do
    local d = t[i] - mean
    acc = acc + d * d
  end
  return math.sqrt(acc / n), mean
end

-- Returns spread/mean ratio for the paired sample buffers, or nil if the
-- deflection is too small to judge.
local function cov(xs, ys)
  local sdx, mx = spread_and_mean(xs)
  local sdy, my = spread_and_mean(ys)
  local mag = math.sqrt(mx * mx + my * my)
  if mag < MIN_MEAN then return nil end
  return math.max(sdx, sdy) / mag
end

libinput:connect("new-evdev-device", function(device)
  local props = device:udev_properties() or {}
  -- udev spells it ID_INPUT_POINTINGSTICK on this kernel; accept both.
  if not (props.ID_INPUT_POINTINGSTICK or props.ID_INPUT_POINTSTICK) then
    return
  end

  local xs, ys = {}, {}
  local last_ts = nil
  local streak = 0
  local onset_judged = false
  local disqualified = false
  local scroll_btn_down = false

  local function reset()
    xs, ys = {}, {}
    streak = 0
    onset_judged = false
    disqualified = false
  end

  device:connect("evdev-frame", function(dev, frame, ts)
    local has_motion = false
    local dx, dy = 0, 0

    for _, ev in ipairs(frame) do
      if ev.usage == evdev.REL_X then
        dx = ev.value; has_motion = true
      elseif ev.usage == evdev.REL_Y then
        dy = ev.value; has_motion = true
      elseif ev.usage == evdev.BTN_MIDDLE then
        -- While the scroll button is held, a steady deflection IS the user
        -- scrolling -- and it looks exactly like drift. Never filter then.
        scroll_btn_down = (ev.value ~= 0)
        reset()
      end
    end

    if not has_motion or scroll_btn_down then
      return nil
    end

    -- New episode after a gap: the firmware has had a chance to re-zero.
    if last_ts == nil or (ts - last_ts) > GAP_US then
      reset()
    end
    last_ts = ts

    xs[#xs + 1] = dx
    ys[#ys + 1] = dy

    -- Onset gate: judge the episode's first WINDOW samples, once.
    if not onset_judged and #xs >= WINDOW then
      onset_judged = true
      local c = cov(xs, ys)
      disqualified = (c == nil) or (c > ONSET_COV)
    end

    if #xs > WINDOW then
      table.remove(xs, 1)
      table.remove(ys, 1)
    end

    local low = false
    if not disqualified and #xs >= WINDOW then
      local c = cov(xs, ys)
      low = (c ~= nil) and (c <= MAX_COV)
    end
    streak = low and (streak + 1) or 0

    if streak < HOLD then
      return nil
    end

    -- Drop motion, keep everything else (buttons especially).
    local out = {}
    for _, ev in ipairs(frame) do
      if ev.usage ~= evdev.REL_X and ev.usage ~= evdev.REL_Y then
        out[#out + 1] = ev
      end
    end
    return out
  end)
end)

-- CAVEATS:
--   * Ground truth is four confirmed hands-off drift events. The other ~84
--     episodes this acts on are unconfirmed, but they are statistically
--     indistinguishable from the confirmed ones (onset CoV p25=0.28, p50=0.34,
--     p75=0.41 vs 0.25-0.44 for confirmed) and occur once per ~2.1 min, which
--     matches the reported "drifts every couple of minutes".
--   * Expected failure mode: the pointer stalling during slow, deliberate,
--     unusually steady movement. If that happens, it is this filter.
--   * To disable: remove the environment.etc block in configuration.nix.

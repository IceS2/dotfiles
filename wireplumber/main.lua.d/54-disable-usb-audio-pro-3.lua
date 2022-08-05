rule = {
  matches = {
    {
      { "node.nick", "equals", "USB Audio #3" },
    },
  },
  apply_properties = {
    ["device.disabled"] = true,
  },
}

table.insert(alsa_monitor.rules,rule)

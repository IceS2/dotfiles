rule = {
  matches = {
    {
      { "node.nick", "equals", "USB Audio #2" },
    },
  },
  apply_properties = {
    ["device.disabled"] = true,
  },
}

table.insert(alsa_monitor.rules,rule)

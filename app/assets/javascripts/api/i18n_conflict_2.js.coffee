# window.credport_hosttranslations
credport_translations = I18n.translations

# merge translations
merge_translation = (source, target) ->
  for key, val of target
    if source[key]?
      if source instanceof Object and val instanceof Object
        source[key] = merge_translation source[key], val
    else
      source[key] = val
  source

I18n.translations = merge_translation window.credport_hosttranslations, I18n.translations
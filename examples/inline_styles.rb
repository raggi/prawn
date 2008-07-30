# encoding: utf-8

$LOAD_PATH << File.join(File.dirname(__FILE__), '..', 'lib')
require "prawn"

Prawn::Document.generate("inline_styles.pdf") do
  text "This is some plain text"
  
  text "<i>This text is italic</i>"
  
  text "<b>This text is bold</b>"  
  
  text "This is ordinary text again"
end